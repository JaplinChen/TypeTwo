param(
  [Parameter(Mandatory = $true)][string]$GlossaryDomain,
  [Parameter(Mandatory = $true)][string]$AcmeEmail,
  [Parameter(Mandatory = $true)][string]$AdminEmail,
  [string]$OutputPath = ".\.env.production",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

function New-Secret {
  param([int]$Bytes = 32)

  $buffer = New-Object byte[] $Bytes
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
  return [Convert]::ToBase64String($buffer).TrimEnd("=")
}

function Assert-Email {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Value
  )

  if ($Value -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
    throw "$Name 格式不正確：$Value"
  }
}

if ((Test-Path -LiteralPath $OutputPath) -and -not $Force) {
  throw "$OutputPath 已存在；若要覆蓋請加 -Force"
}

if ($GlossaryDomain -match "^https?://") {
  throw "GlossaryDomain 只填 host，不要包含 https://"
}

if ($GlossaryDomain -match "example\.com$") {
  throw "GlossaryDomain 不應使用 example.com"
}

Assert-Email -Name "AcmeEmail" -Value $AcmeEmail
Assert-Email -Name "AdminEmail" -Value $AdminEmail

$postgresPassword = New-Secret -Bytes 24
$jwtSecret = New-Secret -Bytes 48
$adminPassword = New-Secret -Bytes 24
$publicBaseUrl = "https://$GlossaryDomain"

$content = @(
  "# TypeTwo Server production env"
  "# 產生時間：$((Get-Date).ToUniversalTime().ToString("o"))"
  "ENVIRONMENT=production"
  "POSTGRES_PASSWORD=$postgresPassword"
  "JWT_SECRET=$jwtSecret"
  "ADMIN_EMAIL=$AdminEmail"
  "ADMIN_PASSWORD=$adminPassword"
  "GLOSSARY_DOMAIN=$GlossaryDomain"
  "ACME_EMAIL=$AcmeEmail"
  "PUBLIC_BASE_URL=$publicBaseUrl"
  "CORS_ALLOWED_ORIGINS=$publicBaseUrl"
  "AUTO_CREATE_TABLES=false"
)

$content | Set-Content -Encoding utf8 -Path $OutputPath

$oldEnv = @{}
foreach ($name in @(
  "ENVIRONMENT",
  "POSTGRES_PASSWORD",
  "JWT_SECRET",
  "ADMIN_EMAIL",
  "ADMIN_PASSWORD",
  "GLOSSARY_DOMAIN",
  "ACME_EMAIL",
  "PUBLIC_BASE_URL",
  "CORS_ALLOWED_ORIGINS",
  "AUTO_CREATE_TABLES"
)) {
  $oldEnv[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

try {
  $env:ENVIRONMENT = "production"
  $env:POSTGRES_PASSWORD = $postgresPassword
  $env:JWT_SECRET = $jwtSecret
  $env:ADMIN_EMAIL = $AdminEmail
  $env:ADMIN_PASSWORD = $adminPassword
  $env:GLOSSARY_DOMAIN = $GlossaryDomain
  $env:ACME_EMAIL = $AcmeEmail
  $env:PUBLIC_BASE_URL = $publicBaseUrl
  $env:CORS_ALLOWED_ORIGINS = $publicBaseUrl
  $env:AUTO_CREATE_TABLES = "false"

  & "$PSScriptRoot\check_typetwo_prod_env.ps1"
  if (-not $?) {
    throw "正式環境變數檢查失敗"
  }
} finally {
  foreach ($pair in $oldEnv.GetEnumerator()) {
    if ($null -eq $pair.Value) {
      [Environment]::SetEnvironmentVariable($pair.Key, $null, "Process")
    } else {
      [Environment]::SetEnvironmentVariable($pair.Key, $pair.Value, "Process")
    }
  }
}

Write-Output "已產生正式環境檔：$OutputPath"
Write-Output "請立即把 ADMIN_PASSWORD 保存到密碼管理器，並限制此檔案權限。"
