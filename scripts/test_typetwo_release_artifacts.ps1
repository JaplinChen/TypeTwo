param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Repository = "JaplinChen/TypeTwo",
  [string]$DownloadDir = ".\.tmp-release-artifacts",
  [switch]$KeepDownloads
)

$ErrorActionPreference = "Stop"

if ($Version -notmatch "^v\d+\.\d+\.\d+$") {
  throw "Version 必須是 vX.Y.Z 格式，例如 v1.0.18"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "需要 GitHub CLI：gh"
}

$backendTar = "typetwo-glossary-api-$Version.tar"
$backendSha = "$backendTar.sha256"
$required = @(
  "setup_typetwo.exe",
  "setup_typetwo.exe.sha256",
  $backendTar,
  $backendSha
)

if (Test-Path -LiteralPath $DownloadDir) {
  Remove-Item -LiteralPath $DownloadDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

try {
  gh release view $Version --repo $Repository | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "找不到 GitHub Release：$Repository $Version"
  }

  foreach ($asset in $required) {
    gh release download $Version --repo $Repository --dir $DownloadDir --pattern $asset
    if ($LASTEXITCODE -ne 0) {
      throw "下載 release asset 失敗：$asset"
    }
  }

  foreach ($asset in $required) {
    $path = Join-Path $DownloadDir $asset
    if (-not (Test-Path -LiteralPath $path)) {
      throw "缺少 release asset：$asset"
    }
  }

  $installerExpected = (Get-Content -Raw (Join-Path $DownloadDir "setup_typetwo.exe.sha256")).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
  $installerActual = (Get-FileHash -Algorithm SHA256 -Path (Join-Path $DownloadDir "setup_typetwo.exe")).Hash.ToLowerInvariant()
  if ($installerExpected -ne $installerActual) {
    throw "installer checksum mismatch"
  }

  $backendExpected = (Get-Content -Raw (Join-Path $DownloadDir $backendSha)).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
  $backendActual = (Get-FileHash -Algorithm SHA256 -Path (Join-Path $DownloadDir $backendTar)).Hash.ToLowerInvariant()
  if ($backendExpected -ne $backendActual) {
    throw "backend image checksum mismatch"
  }

  [pscustomobject]@{
    ok = $true
    repository = $Repository
    version = $Version
    installerSha256 = $installerActual
    backendImageSha256 = $backendActual
    checkedAt = (Get-Date).ToUniversalTime().ToString("o")
  } | ConvertTo-Json -Depth 4
} finally {
  if (-not $KeepDownloads -and (Test-Path -LiteralPath $DownloadDir)) {
    Remove-Item -LiteralPath $DownloadDir -Recurse -Force
  }
}
