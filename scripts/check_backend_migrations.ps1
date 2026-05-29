param(
  [string]$Python = "python",
  [string[]]$PythonArgs = @()
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot "backend"
$oldDatabaseUrl = [Environment]::GetEnvironmentVariable("DATABASE_URL", "Process")

function Invoke-SelectedPython {
  & $Python @PythonArgs @args
}

try {
  Push-Location $backendDir

  $heads = Invoke-SelectedPython -m alembic heads
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  $headLines = @($heads | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($headLines.Count -ne 1) {
    throw "Alembic 必須只有一個 head，目前為 $($headLines.Count) 個：$($headLines -join '; ')"
  }

  if ([string]::IsNullOrWhiteSpace($env:DATABASE_URL)) {
    Invoke-SelectedPython -m alembic upgrade head --sql | Out-Null
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Warning "DATABASE_URL 未設定，只完成 head 檢查與 SQL 產生；CI/部署前應用 PostgreSQL 執行 upgrade head。"
    Write-Output "Alembic migration gate 通過：$($headLines[0])"
    return
  }

  Invoke-SelectedPython -m alembic upgrade head
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $current = Invoke-SelectedPython -m alembic current
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  if (($current -join "`n") -notmatch "\(head\)") {
    throw "Alembic upgrade 後未到 head：$($current -join '; ')"
  }

  Write-Output "Alembic migration gate 通過：$($headLines[0])"
}
finally {
  Pop-Location
  if ($null -eq $oldDatabaseUrl) {
    [Environment]::SetEnvironmentVariable("DATABASE_URL", $null, "Process")
  } else {
    $env:DATABASE_URL = $oldDatabaseUrl
  }
}
