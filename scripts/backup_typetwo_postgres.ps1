param(
  [string]$OutputDir = ".\backups",
  [int]$KeepDays = 30
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path $OutputDir "typetwo_$stamp.sql"

docker compose exec -T db pg_dump -U typetwo typetwo | Out-File -Encoding utf8 $backupPath
Compress-Archive -Path $backupPath -DestinationPath "$backupPath.zip" -Force
Remove-Item $backupPath -Force

$cutoff = (Get-Date).AddDays(-$KeepDays)
Get-ChildItem -Path $OutputDir -Filter "typetwo_*.sql.zip" |
  Where-Object { $_.LastWriteTime -lt $cutoff } |
  Remove-Item -Force

Write-Output "備份完成：$backupPath.zip"
