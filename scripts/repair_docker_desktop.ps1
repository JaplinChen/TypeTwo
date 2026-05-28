param(
  [switch]$Apply,
  [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

function Invoke-WithTimeout {
  param(
    [scriptblock]$ScriptBlock,
    [int]$Seconds,
    [string]$Label
  )

  $job = Start-Job -ScriptBlock $ScriptBlock
  try {
    $completed = Wait-Job -Job $job -Timeout $Seconds
    if ($null -eq $completed) {
      Stop-Job -Job $job -Force
      return [pscustomobject]@{
        Label = $Label
        Ok = $false
        TimedOut = $true
        Output = "逾時超過 $Seconds 秒"
      }
    }

    $output = Receive-Job -Job $job -ErrorAction Stop
    return [pscustomobject]@{
      Label = $Label
      Ok = $true
      TimedOut = $false
      Output = ($output -join [Environment]::NewLine)
    }
  }
  catch {
    return [pscustomobject]@{
      Label = $Label
      Ok = $false
      TimedOut = $false
      Output = $_.Exception.Message
    }
  }
  finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
}

function Get-DockerDesktopPath {
  $paths = @(
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "$env:LocalAppData\Docker\Docker Desktop.exe"
  )
  return $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

Write-Output "Docker Desktop 診斷"
Write-Output "-------------------"

$service = Get-Service com.docker.service -ErrorAction SilentlyContinue
if ($service) {
  Write-Output "Windows service：$($service.Name) / $($service.Status) / $($service.StartType)"
}
else {
  Write-Output "Windows service：找不到 com.docker.service"
}

Write-Output ""
Write-Output "Docker 相關 process："
$processes = Get-Process -ErrorAction SilentlyContinue |
  Where-Object {
    $_.ProcessName -like "*Docker*" -or
    $_.ProcessName -like "*com.docker*" -or
    $_.ProcessName -in @("docker", "docker-compose", "docker-buildx")
  } |
  Select-Object ProcessName, Id, CPU, WorkingSet |
  Sort-Object ProcessName

if ($processes) {
  $processes | Format-Table -AutoSize | Out-String | Write-Output
}
else {
  Write-Output "沒有找到 Docker 相關 process"
}

Write-Output "Docker context："
Invoke-WithTimeout -Seconds $TimeoutSeconds -Label "docker context ls" -ScriptBlock {
  docker context ls
} | Select-Object Label, Ok, TimedOut, Output | Format-List | Out-String | Write-Output

Write-Output "Docker daemon："
$daemon = Invoke-WithTimeout -Seconds $TimeoutSeconds -Label "docker ps" -ScriptBlock {
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
}
$daemon | Select-Object Label, Ok, TimedOut, Output | Format-List | Out-String | Write-Output

Write-Output "WSL distro："
Invoke-WithTimeout -Seconds $TimeoutSeconds -Label "wsl -l -v" -ScriptBlock {
  wsl -l -v
} | Select-Object Label, Ok, TimedOut, Output | Format-List | Out-String | Write-Output

if (-not $Apply) {
  Write-Output "診斷完成。"
  Write-Output "若 docker ps 或 docker images 逾時，可執行："
  Write-Output ".\scripts\repair_docker_desktop.ps1 -Apply"
  exit 0
}

Write-Output "開始修復：關閉 Docker Desktop process 並重啟 docker-desktop WSL distro。"
Write-Output "注意：這會暫停目前正在跑的 Docker container，但不會刪除 image、container 或 volume。"

Get-Process "Docker Desktop", "com.docker.backend", "com.docker.build", "docker", "docker-compose", "docker-buildx" -ErrorAction SilentlyContinue |
  Stop-Process -Force

Start-Sleep -Seconds 3
wsl --terminate docker-desktop 2>$null
Start-Sleep -Seconds 3

$dockerDesktop = Get-DockerDesktopPath
if (-not $dockerDesktop) {
  throw "找不到 Docker Desktop.exe，請手動啟動 Docker Desktop"
}

Start-Process -FilePath $dockerDesktop -WindowStyle Hidden

Write-Output "已重新啟動 Docker Desktop，等待 daemon 回應..."
$deadline = (Get-Date).AddMinutes(3)
do {
  Start-Sleep -Seconds 5
  $daemon = Invoke-WithTimeout -Seconds 10 -Label "docker ps" -ScriptBlock {
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
  }
  if ($daemon.Ok) {
    Write-Output "Docker daemon 已恢復："
    Write-Output $daemon.Output
    exit 0
  }
} while ((Get-Date) -lt $deadline)

throw "Docker Desktop 已重啟，但 daemon 仍未在期限內回應"
