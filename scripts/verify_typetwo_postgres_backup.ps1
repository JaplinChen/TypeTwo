param(
  [Parameter(Mandatory = $true)]
  [string]$BackupZip,
  [string]$ProjectName = "typetwo-restore-check",
  [string]$PostgresPassword = "restore-check-password",
  [switch]$KeepContainer
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BackupZip)) {
  throw "找不到備份檔：$BackupZip"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("typetwo_verify_restore_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

function Invoke-Compose {
  docker compose `
    -p $ProjectName `
    -f (Join-Path $repoRoot "docker-compose.yml") `
    @args
}

try {
  Expand-Archive -Path $BackupZip -DestinationPath $tempDir -Force
  $sql = Get-ChildItem -Path $tempDir -Filter "*.sql" | Select-Object -First 1
  if ($null -eq $sql) {
    throw "備份壓縮檔內找不到 .sql 檔"
  }

  $env:POSTGRES_PASSWORD = $PostgresPassword
  Invoke-Compose up -d db
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $deadline = (Get-Date).AddSeconds(60)
  do {
    docker compose -p $ProjectName exec -T db pg_isready -U typetwo -d typetwo | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  if ($LASTEXITCODE -ne 0) {
    throw "驗證用 PostgreSQL 未在期限內 ready"
  }

  Get-Content -Raw -LiteralPath $sql.FullName |
    docker compose -p $ProjectName exec -T db psql -U typetwo -d typetwo
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $tableCount = docker compose -p $ProjectName exec -T db psql `
    -U typetwo `
    -d typetwo `
    -tAc "select count(*) from information_schema.tables where table_schema='public' and table_name in ('users','glossary_terms','glossary_term_history');"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  if ([int]$tableCount.Trim() -lt 3) {
    throw "還原後缺少必要資料表，table count=$($tableCount.Trim())"
  }

  Write-Output "備份還原驗證通過：$BackupZip"
}
finally {
  Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
  if (-not $KeepContainer) {
    Invoke-Compose down -v | Out-Null
  }
}
