param(
  [string]$ImageName = "typetwo-glossary-api:latest",
  [switch]$RunHealthCheck,
  [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

function Invoke-Docker {
  param([string[]]$Arguments)

  $output = & docker @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "docker $($Arguments -join ' ') 執行失敗"
  }
  return $output
}

function Remove-TypeTwoTestContainers {
  $containers = & docker ps -a `
    --filter "label=com.docker.compose.project=typetwo" `
    --filter "label=com.docker.compose.service=api" `
    --format "{{.ID}}"

  if ($containers) {
    & docker rm -f @containers | Out-Null
  }
}

Write-Output "檢查 Docker daemon..."
Invoke-Docker @("version", "--format", "{{.Server.Version}}") | Out-Null

Write-Output "建立 Docker image：$ImageName"
Invoke-Docker @("compose", "build", "api") | Write-Output

$image = Invoke-Docker @(
  "images",
  $ImageName,
  "--format",
  "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}"
)

if (($image | Measure-Object).Count -le 1) {
  throw "找不到 Docker image：$ImageName"
}

Write-Output "Docker image 已建立："
$image | Write-Output

if (-not $RunHealthCheck) {
  Write-Output "完成。若要啟動 API 並驗證 /health，請加上 -RunHealthCheck。"
  return
}

$isHealthy = $false

try {
  Write-Output "啟動 TypeTwo Docker Compose stack..."
  Invoke-Docker @("compose", "up", "-d") | Write-Output

  $deadline = (Get-Date).AddSeconds(90)
  do {
    Start-Sleep -Seconds 2
    $health = & docker inspect -f "{{.State.Health.Status}}" typetwo-api-1 2>$null
    if ($LASTEXITCODE -eq 0 -and $health -eq "healthy") {
      $body = Invoke-RestMethod -Uri "http://localhost:18000/health"
      if ($body.ok -ne $true -or $body.db -ne "ok") {
        throw "/health 回傳異常：$($body | ConvertTo-Json -Compress)"
      }
      Write-Output "API healthcheck 通過：$($body | ConvertTo-Json -Compress)"
      Write-Output "目前服務："
      Invoke-Docker @("compose", "ps") | Write-Output
      $isHealthy = $true
      break
    }
  } while ((Get-Date) -lt $deadline)

  if ($isHealthy) {
    return
  }

  Write-Output "API logs："
  & docker logs typetwo-api-1
  throw "API container 未在期限內變成 healthy"
}
finally {
  if ($Cleanup) {
    Write-Output "清理測試 container 與 volume..."
    & docker compose down -v
    Remove-TypeTwoTestContainers
  }
}
