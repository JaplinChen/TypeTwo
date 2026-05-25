param(
  [Parameter(Mandatory = $true)]
  [string]$BackupZip
)

$ErrorActionPreference = "Stop"

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("typetwo_restore_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
  Expand-Archive -Path $BackupZip -DestinationPath $tempDir -Force
  $sql = Get-ChildItem -Path $tempDir -Filter "*.sql" | Select-Object -First 1
  if ($null -eq $sql) {
    throw "找不到 .sql 備份檔"
  }

  Get-Content -Raw $sql.FullName | docker compose exec -T db psql -U typetwo typetwo
  Write-Output "還原完成：$BackupZip"
}
finally {
  Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
