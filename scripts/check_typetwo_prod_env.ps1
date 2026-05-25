param(
  [switch]$AllowExampleDomain
)

$ErrorActionPreference = "Stop"

$required = @(
  "POSTGRES_PASSWORD",
  "JWT_SECRET",
  "ADMIN_EMAIL",
  "ADMIN_PASSWORD",
  "GLOSSARY_DOMAIN",
  "ACME_EMAIL"
)

$weakValues = @{
  POSTGRES_PASSWORD = @("change-me", "password", "postgres", "typetwo")
  JWT_SECRET = @("change-this-secret", "change-this-secret-before-production", "dev-only-secret")
  ADMIN_PASSWORD = @("change-me-now", "password", "admin", "secret")
}

$errors = New-Object System.Collections.Generic.List[string]

foreach ($name in $required) {
  $value = [Environment]::GetEnvironmentVariable($name, "Process")
  if ([string]::IsNullOrWhiteSpace($value)) {
    $errors.Add("$name 未設定")
    continue
  }

  if ($weakValues.ContainsKey($name) -and $weakValues[$name] -contains $value) {
    $errors.Add("$name 仍使用開發預設值")
  }
}

if ($env:POSTGRES_PASSWORD -and $env:POSTGRES_PASSWORD.Length -lt 12) {
  $errors.Add("POSTGRES_PASSWORD 至少建議 12 個字元")
}

if ($env:JWT_SECRET -and $env:JWT_SECRET.Length -lt 32) {
  $errors.Add("JWT_SECRET 至少需要 32 個字元")
}

if ($env:ADMIN_PASSWORD -and $env:ADMIN_PASSWORD.Length -lt 12) {
  $errors.Add("ADMIN_PASSWORD 至少建議 12 個字元")
}

if ($env:ADMIN_EMAIL -and $env:ADMIN_EMAIL -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
  $errors.Add("ADMIN_EMAIL 格式不正確")
}

if ($env:ACME_EMAIL -and $env:ACME_EMAIL -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
  $errors.Add("ACME_EMAIL 格式不正確")
}

if (-not $AllowExampleDomain -and $env:GLOSSARY_DOMAIN -and $env:GLOSSARY_DOMAIN -match "example\.com$") {
  $errors.Add("GLOSSARY_DOMAIN 不應使用 example.com")
}

if ($errors.Count -gt 0) {
  Write-Output "正式環境變數檢查未通過："
  foreach ($item in $errors) {
    Write-Output "- $item"
  }
  exit 1
}

Write-Output "正式環境變數檢查通過。"
