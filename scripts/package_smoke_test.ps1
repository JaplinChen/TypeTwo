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
    [Parameter(Mandatory = $true)]
    [System.Diagnostics.Process[]]$Processes
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

  $null = Stop-NamedProcesses -Names @('TypeTwoUI')

  $typeTwoExe = Join-Path $PackageDir 'TypeTwo.exe'
  if (Test-Path $typeTwoExe) {
    for ($i = 0; $i -lt 4; $i++) {
      & cmd /c "`"$typeTwoExe`" --quit" *> $null
      Start-Sleep -Seconds 1
      if (-not (Get-NamedProcesses -Names @('TypeTwo'))) {
        break
      }
    }
  }
}

function Test-ExeSmoke {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [int]$WaitSeconds = 5
  )

  if (-not (Test-Path $Path)) {
    throw "Missing file: $Path"
  }

  $before = @(Get-NamedProcesses -Names @('TypeTwo')).Count
  $proc = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds $WaitSeconds
  $proc.Refresh()
  $afterFirst = @(Get-NamedProcesses -Names @('TypeTwo')).Count

  if ($proc.HasExited) {
    $exitCode = $proc.ExitCode
    throw "$Name exited within $WaitSeconds seconds. ExitCode=$exitCode"
  }

  $second = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds 2
  $afterSecond = @(Get-NamedProcesses -Names @('TypeTwo')).Count
  $second.Refresh()

  $quitOutput = & cmd /c "`"$Path`" --quit 2>&1"
  Start-Sleep -Seconds 2
  $proc.Refresh()
  $second.Refresh()
  $remaining = @(Get-NamedProcesses -Names @('TypeTwo'))
  $cleanupSucceeded = $proc.HasExited

  $result = [pscustomobject]@{
    Name = $Name
    Path = $Path
    WaitSeconds = $WaitSeconds
    Before = $before
    Started = $true
    AliveAfterWait = $true
    AfterFirstLaunch = $afterFirst
    AfterSecondLaunch = $afterSecond
    SecondProcessExited = $second.HasExited
    CleanupSucceeded = $cleanupSucceeded
    CleanupOutput = ($quitOutput | Out-String).Trim()
    RemainingProcesses = (Format-ProcessSummary -Processes $remaining)
  }

  if ($afterFirst -ne ($before + 1)) {
    throw "$Name first launch should add exactly one process. Before=$before AfterFirst=$afterFirst"
  }
  if ($afterSecond -ne $afterFirst) {
    throw "$Name second launch should not create another process. AfterFirst=$afterFirst AfterSecond=$afterSecond"
  }

  if ($StrictCleanup -and -not $cleanupSucceeded) {
    throw "$Name passed startup and single-instance checks but cleanup failed: $($result.CleanupOutput). Remaining=$($result.RemainingProcesses)"
  }

  $result
}

function Test-SingleInstanceUi {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [int]$WaitSeconds = 3,
    [switch]$StrictCleanup
  )

  $before = @(Get-NamedProcesses -Names @('TypeTwoUI')).Count
  $first = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds $WaitSeconds
  $afterFirst = @(Get-NamedProcesses -Names @('TypeTwoUI')).Count

  if ($first.HasExited) {
    throw "TypeTwoUI.exe first launch exited within $WaitSeconds seconds. ExitCode=$($first.ExitCode)"
  }

  $second = Start-SmokeProcess -Path $Path
  Start-Sleep -Seconds $WaitSeconds
  $afterSecond = @(Get-NamedProcesses -Names @('TypeTwoUI')).Count
  $second.Refresh()

  $cleanup = Stop-NamedProcesses -Names @('TypeTwoUI')
  $cleanupSucceeded = $cleanup.Succeeded
  $remaining = @(Get-NamedProcesses -Names @('TypeTwoUI'))

  $result = [pscustomobject]@{
    Name = 'TypeTwoUI.exe'
    Before = $before
    AfterFirstLaunch = $afterFirst
    AfterSecondLaunch = $afterSecond
    SecondProcessExited = $second.HasExited
    CleanupSucceeded = $cleanupSucceeded
    CleanupOutput = (($cleanup.Attempts -join ', ') + '; ' + (($cleanup.Errors -join ' | ').Trim())).Trim('; ')
    RemainingProcesses = (Format-ProcessSummary -Processes $remaining)
  }

  if ($afterFirst -ne ($before + 1)) {
    throw "TypeTwoUI.exe first launch should add exactly one process. Before=$before AfterFirst=$afterFirst"
  }
  if ($afterSecond -ne $afterFirst) {
    throw "TypeTwoUI.exe second launch should not create another process. AfterFirst=$afterFirst AfterSecond=$afterSecond"
  }
  if ($StrictCleanup -and -not $cleanupSucceeded) {
    throw "TypeTwoUI.exe single-instance check passed but cleanup failed: $($result.CleanupOutput). Remaining=$($result.RemainingProcesses)"
  }

  $result
}

$packageDir = Join-Path $Root 'package'
if ($TryCleanupExisting) {
  Try-CleanupExistingProcesses -PackageDir $packageDir
}
Assert-NoExistingProcess -Names @('TypeTwo', 'TypeTwoUI')
$results = @(
  Test-SingleInstanceUi -Path (Join-Path $packageDir 'TypeTwoUI.exe') -WaitSeconds 3 -StrictCleanup:$StrictCleanup
  Test-ExeSmoke -Path (Join-Path $packageDir 'TypeTwo.exe') -Name 'TypeTwo.exe' -WaitSeconds $WaitSeconds
)

$results | ConvertTo-Json -Depth 3
