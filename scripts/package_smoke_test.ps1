param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [int]$WaitSeconds = 5,
  [switch]$StrictCleanup,
  [switch]$TryCleanupExisting
)

$ErrorActionPreference = 'Stop'

function Get-NamedProcesses {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Names
  )

  @(Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $Names -contains $_.ProcessName })
}

function Format-ProcessSummary {
  param(
    [AllowEmptyCollection()]
    [System.Diagnostics.Process[]]$Processes = @()
  )

  if (-not $Processes) {
    return '<none>'
  }

  ($Processes | Sort-Object ProcessName, Id | ForEach-Object {
    "$($_.ProcessName)#$($_.Id)"
  }) -join ', '
}

function Stop-NamedProcesses {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Names,
    [int]$GraceSeconds = 2
  )

  $targets = @(Get-NamedProcesses -Names $Names)
  foreach ($proc in $targets) {
    try {
      if ($proc.MainWindowHandle -and $proc.MainWindowHandle -ne 0) {
        $null = $proc.CloseMainWindow()
      }
    } catch {
    }
  }

  if ($GraceSeconds -gt 0 -and $targets) {
    Start-Sleep -Seconds $GraceSeconds
  }

  $remaining = @(Get-NamedProcesses -Names $Names)
  if (-not $remaining) {
    return [pscustomobject]@{
      Succeeded = $true
      Attempts = @('graceful-close')
      RemainingProcesses = '<none>'
    }
  }

  $attempts = @('graceful-close')
  $stopErrors = @()
  foreach ($proc in $remaining) {
    try {
      Stop-Process -Id $proc.Id -Force -ErrorAction Stop
      $attempts += "stop-process#$($proc.Id)"
    } catch {
      $stopErrors += $_.Exception.Message
    }
  }

  Start-Sleep -Seconds 1
  $left = @(Get-NamedProcesses -Names $Names)
  [pscustomobject]@{
    Succeeded = (-not $left)
    Attempts = $attempts
    Errors = $stopErrors
    RemainingProcesses = (Format-ProcessSummary -Processes $left)
  }
}

function Start-SmokeProcess {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  try {
    Start-Process -FilePath $Path -WorkingDirectory (Split-Path -Parent $Path) -PassThru -ErrorAction Stop
  } catch {
    throw "Failed to start $(Split-Path -Leaf $Path): $($_.Exception.Message)"
  }
}

function Assert-NoExistingProcess {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Names
  )

  $existing = @(Get-NamedProcesses -Names $Names)

  if ($existing) {
    $summary = Format-ProcessSummary -Processes $existing
    throw "Smoke test requires a clean process list. Existing processes: $summary"
  }
}

function Try-CleanupExistingProcesses {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PackageDir
  )

  $null = Stop-NamedProcesses -Names @('TypeTwo')
}

# Tests single-instance behavior of a GUI EXE:
# - first launch stays alive
# - second launch exits immediately (signals first)
# - cleanup via Stop-Process
function Test-SingleInstanceUi {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$ProcessName,
    [int]$WaitSeconds = 3,
    [switch]$StrictCleanup
  )

  if (-not (Test-Path $Path)) {
    throw "Missing file: $Path"
  }

  $before = @(Get-NamedProcesses -Names @($ProcessName)).Count
  $first = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds $WaitSeconds
  $afterFirst = @(Get-NamedProcesses -Names @($ProcessName)).Count

  if ($first.HasExited) {
    throw "$ProcessName.exe first launch exited within $WaitSeconds seconds. ExitCode=$($first.ExitCode)"
  }

  $second = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds $WaitSeconds
  $afterSecond = @(Get-NamedProcesses -Names @($ProcessName)).Count
  $second.Refresh()

  $cleanup = Stop-NamedProcesses -Names @($ProcessName)
  $cleanupSucceeded = $cleanup.Succeeded
  $remaining = @(Get-NamedProcesses -Names @($ProcessName))

  $result = [pscustomobject]@{
    Name = "$ProcessName.exe"
    Before = $before
    AfterFirstLaunch = $afterFirst
    AfterSecondLaunch = $afterSecond
    SecondProcessExited = $second.HasExited
    CleanupSucceeded = $cleanupSucceeded
    CleanupOutput = (($cleanup.Attempts -join ', ') + '; ' + (($cleanup.Errors -join ' | ').Trim())).Trim('; ')
    RemainingProcesses = (Format-ProcessSummary -Processes $remaining)
  }

  if ($afterFirst -ne ($before + 1)) {
    throw "$ProcessName.exe first launch should add exactly one process. Before=$before AfterFirst=$afterFirst"
  }
  if ($afterSecond -ne $afterFirst) {
    throw "$ProcessName.exe second launch should not create another process. AfterFirst=$afterFirst AfterSecond=$afterSecond"
  }
  if ($StrictCleanup -and -not $cleanupSucceeded) {
    throw "$ProcessName.exe single-instance check passed but cleanup failed: $($result.CleanupOutput). Remaining=$($result.RemainingProcesses)"
  }

  $result
}

$packageDir = Join-Path $Root 'package'
if ($TryCleanupExisting) {
  Try-CleanupExistingProcesses -PackageDir $packageDir
}
Assert-NoExistingProcess -Names @('TypeTwo')
$results = @(
  Test-SingleInstanceUi -Path (Join-Path $packageDir 'TypeTwo.exe') -ProcessName 'TypeTwo' -WaitSeconds $WaitSeconds -StrictCleanup:$StrictCleanup
)

$results | ConvertTo-Json -Depth 3
