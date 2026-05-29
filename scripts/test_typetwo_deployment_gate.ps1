param(
  [Parameter(Mandatory = $true)][string]$BaseUrl,
  [string]$AdminEmail = $env:ADMIN_EMAIL,
  [string]$AdminPassword = $env:ADMIN_PASSWORD,
  [string]$ExpectedEnvironment = "",
  [string]$BackupZip = "",
  [string]$EvidencePath = ".\deployment-evidence.json",
  [switch]$AllowHttp,
  [switch]$SkipSmoke,
  [switch]$SkipBackupVerify
)

$ErrorActionPreference = "Stop"

function Add-Step {
  param(
    [System.Collections.Generic.List[object]]$Steps,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Status,
    [object]$Details = $null
  )

  $Steps.Add([pscustomobject]@{
    name = $Name
    status = $Status
    details = $Details
    checkedAt = (Get-Date).ToUniversalTime().ToString("o")
  })
}

function Assert-Url {
  param([string]$Value)

  try {
    $uri = [Uri]$Value
  } catch {
    throw "BaseUrl 必須是有效 URL：$Value"
  }

  if (-not $AllowHttp -and $uri.Scheme -ne "https") {
    throw "BaseUrl 必須使用 https://；本機或臨時測試才可加 -AllowHttp"
  }

  if ($uri.AbsolutePath -ne "/") {
    return $Value.TrimEnd("/")
  }

  return "$($uri.Scheme)://$($uri.Authority)"
}

function Wait-TypeTwoHealth {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [int]$TimeoutSeconds = 90
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $lastError = $null

  do {
    try {
      $body = Invoke-RestMethod -Method Get -Uri "$Url/health"
      if ($body.ok -eq $true -and $body.db -eq "ok") {
        return $body
      }
      $lastError = "/health 回傳異常：$($body | ConvertTo-Json -Compress -Depth 8)"
    } catch {
      $lastError = $_.Exception.Message
    }

    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)

  throw "API healthcheck 未在期限內通過：$lastError"
}

$normalizedBaseUrl = Assert-Url -Value $BaseUrl
$steps = New-Object "System.Collections.Generic.List[object]"
$summary = [ordered]@{
  ok = $false
  baseUrl = $normalizedBaseUrl
  expectedEnvironment = $ExpectedEnvironment
  startedAt = (Get-Date).ToUniversalTime().ToString("o")
  completedAt = $null
  steps = $steps
}

try {
  $health = Wait-TypeTwoHealth -Url $normalizedBaseUrl

  if (-not [string]::IsNullOrWhiteSpace($ExpectedEnvironment) -and
      $health.environment -ne $ExpectedEnvironment) {
    throw "/health environment 不符合預期：expected=$ExpectedEnvironment actual=$($health.environment)"
  }

  Add-Step -Steps $steps -Name "health" -Status "passed" -Details $health

  if ($SkipSmoke) {
    Add-Step -Steps $steps -Name "smoke" -Status "skipped" -Details "已使用 -SkipSmoke"
  } else {
    if ([string]::IsNullOrWhiteSpace($AdminEmail) -or [string]::IsNullOrWhiteSpace($AdminPassword)) {
      throw "執行 smoke 需要 AdminEmail/AdminPassword，或使用 -SkipSmoke"
    }

    $smokeJson = & "$PSScriptRoot\smoke_typetwo_glossary_api.ps1" `
      -BaseUrl $normalizedBaseUrl `
      -AdminEmail $AdminEmail `
      -AdminPassword $AdminPassword
    if ($LASTEXITCODE -ne 0) {
      throw "smoke script 失敗"
    }

    $smokeResult = $smokeJson | ConvertFrom-Json
    if ($smokeResult.ok -ne $true) {
      throw "smoke result 不符合預期：$($smokeResult | ConvertTo-Json -Compress -Depth 8)"
    }

    Add-Step -Steps $steps -Name "smoke" -Status "passed" -Details $smokeResult
  }

  if ($SkipBackupVerify) {
    Add-Step -Steps $steps -Name "backup-restore" -Status "skipped" -Details "已使用 -SkipBackupVerify"
  } elseif ([string]::IsNullOrWhiteSpace($BackupZip)) {
    Add-Step -Steps $steps -Name "backup-restore" -Status "skipped" -Details "未提供 BackupZip"
  } else {
    & "$PSScriptRoot\verify_typetwo_postgres_backup.ps1" -BackupZip $BackupZip
    if ($LASTEXITCODE -ne 0) {
      throw "備份還原驗證失敗"
    }

    Add-Step -Steps $steps -Name "backup-restore" -Status "passed" -Details @{
      backupZip = (Resolve-Path -LiteralPath $BackupZip).Path
    }
  }

  $summary.ok = $true
} catch {
  Add-Step -Steps $steps -Name "deployment-gate" -Status "failed" -Details $_.Exception.Message
  throw
} finally {
  $summary.completedAt = (Get-Date).ToUniversalTime().ToString("o")
  $evidenceDir = Split-Path -Parent $EvidencePath
  if (-not [string]::IsNullOrWhiteSpace($evidenceDir)) {
    New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
  }
  [pscustomobject]$summary | ConvertTo-Json -Depth 12 |
    Set-Content -Encoding utf8 -Path $EvidencePath
  Write-Output "部署 gate 證據已寫入：$EvidencePath"
}
