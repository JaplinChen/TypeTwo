param(
  [string]$BaseUrl = "http://localhost:18000",
  [string]$AdminEmail = "admin@example.com",
  [string]$AdminPassword = "change-me-now",
  [switch]$KeepSmokeData
)

$ErrorActionPreference = "Stop"

function Invoke-TypeTwoJson {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [hashtable]$Headers = @{},
    [object]$Body = $null
  )

  $uri = "$BaseUrl$Path"
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $Headers
  }

  return Invoke-RestMethod `
    -Method $Method `
    -Uri $uri `
    -Headers $Headers `
    -ContentType "application/json" `
    -Body ($Body | ConvertTo-Json -Depth 10)
}

function Wait-TypeTwoHealth {
  $deadline = (Get-Date).AddSeconds(60)
  $lastError = $null

  do {
    try {
      $body = Invoke-TypeTwoJson -Method "Get" -Path "/health"
      if ($body.ok -eq $true -and $body.db -eq "ok") {
        return $body
      }
      $lastError = "/health 回傳異常：$($body | ConvertTo-Json -Compress)"
    } catch {
      $lastError = $_.Exception.Message
    }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)

  throw "API healthcheck 未在期限內通過：$lastError"
}

$health = Wait-TypeTwoHealth
if ($health.ok -ne $true -or $health.db -ne "ok") {
  throw "/health 回傳異常：$($health | ConvertTo-Json -Compress)"
}

$adminLogin = Invoke-TypeTwoJson -Method "Post" -Path "/auth/login" -Body @{
  email = $AdminEmail
  password = $AdminPassword
}
$adminHeaders = @{ Authorization = "Bearer $($adminLogin.accessToken)" }

$stamp = Get-Date -Format "yyyyMMddHHmmss"
$approvedSource = "smoke-approved-$stamp"
$pendingSource = "smoke-pending-$stamp"
$userEmail = "smoke-$stamp@example.com"
$userPassword = "smoke-pass"

$approved = $null
$pendingTerm = $null
$approvedPending = $null
$user = $null
$userHeaders = $null
$result = $null
$cleanupFailures = @()

try {
  $approved = Invoke-TypeTwoJson -Method "Post" -Path "/glossary" -Headers $adminHeaders -Body @{
    contextKey = "global"
    sourceText = $approvedSource
    targetText = "Smoke approved $stamp"
    status = "approved"
  }
  if ($approved.status -ne "approved") {
    throw "admin 新增 approved 詞彙失敗：$($approved | ConvertTo-Json -Compress)"
  }

  $bundle = Invoke-TypeTwoJson -Method "Get" -Path "/glossary?status=approved" -Headers $adminHeaders
  if ($bundle.glossary.$approvedSource -ne "Smoke approved $stamp") {
    throw "approved 詞彙包未包含 smoke 詞彙"
  }

  $user = Invoke-TypeTwoJson -Method "Post" -Path "/users" -Headers $adminHeaders -Body @{
    email = $userEmail
    password = $userPassword
    role = "user"
  }

  $userLogin = Invoke-TypeTwoJson -Method "Post" -Path "/auth/login" -Body @{
    email = $userEmail
    password = $userPassword
  }
  $userHeaders = @{ Authorization = "Bearer $($userLogin.accessToken)" }

  $suggested = Invoke-TypeTwoJson -Method "Post" -Path "/glossary" -Headers $userHeaders -Body @{
    contextKey = "global"
    sourceText = $pendingSource
    targetText = "Smoke pending $stamp"
    status = "approved"
  }
  if ($suggested.status -ne "pending") {
    throw "一般 user 建議詞未被強制轉為 pending：$($suggested | ConvertTo-Json -Compress)"
  }

  $pending = Invoke-TypeTwoJson -Method "Get" -Path "/glossary/terms?status=pending" -Headers $adminHeaders
  $pendingTerm = $pending | Where-Object { $_.sourceText -eq $pendingSource } | Select-Object -First 1
  if ($null -eq $pendingTerm) {
    throw "admin 查不到一般 user 建議的 pending 詞彙"
  }

  $approvedPending = Invoke-TypeTwoJson `
    -Method "Post" `
    -Path "/glossary/$($pendingTerm.id)/approve" `
    -Headers $adminHeaders
  if ($approvedPending.status -ne "approved") {
    throw "admin approve pending 詞彙失敗：$($approvedPending | ConvertTo-Json -Compress)"
  }

  $finalBundle = Invoke-TypeTwoJson -Method "Get" -Path "/glossary?status=approved" -Headers $adminHeaders
  if ($finalBundle.glossary.$pendingSource -ne "Smoke pending $stamp") {
    throw "approve 後詞彙包未包含 pending smoke 詞彙"
  }

  $result = [pscustomobject]@{
    ok = $true
    baseUrl = $BaseUrl
    health = $health
    adminRole = $adminLogin.role
    approvedTermId = $approved.id
    userId = $user.id
    userRole = $userLogin.role
    pendingTermId = $pendingTerm.id
    approvedPendingStatus = $approvedPending.status
    cleanup = -not $KeepSmokeData
  }
}
finally {
  if (-not $KeepSmokeData) {
    foreach ($termId in @($approved.id, $approvedPending.id)) {
      if (-not [string]::IsNullOrWhiteSpace($termId)) {
        try {
          Invoke-TypeTwoJson -Method "Delete" -Path "/glossary/$termId" -Headers $adminHeaders | Out-Null
        } catch {
          $cleanupFailures += "清理 smoke 詞彙失敗：$termId，$($_.Exception.Message)"
        }
      }
    }

    if (-not [string]::IsNullOrWhiteSpace($user.id)) {
      try {
        Invoke-TypeTwoJson `
          -Method "Put" `
          -Path "/users/$($user.id)" `
          -Headers $adminHeaders `
          -Body @{ isActive = $false } | Out-Null
      } catch {
        $cleanupFailures += "停用 smoke 使用者失敗：$($user.id)，$($_.Exception.Message)"
      }
    }

    try {
      $activeTerms = Invoke-TypeTwoJson -Method "Get" -Path "/glossary/terms" -Headers $adminHeaders
      $remainingSmokeTerms = $activeTerms | Where-Object {
        $_.sourceText -eq $approvedSource -or $_.sourceText -eq $pendingSource
      }
      if ($remainingSmokeTerms) {
        $cleanupFailures += "清理後仍查到 smoke 詞彙：$($remainingSmokeTerms.sourceText -join ', ')"
      }
    } catch {
      $cleanupFailures += "驗證 smoke 詞彙清理失敗：$($_.Exception.Message)"
    }

    if (-not [string]::IsNullOrWhiteSpace($user.id)) {
      try {
        $users = Invoke-TypeTwoJson -Method "Get" -Path "/users" -Headers $adminHeaders
        $smokeUser = $users | Where-Object { $_.id -eq $user.id } | Select-Object -First 1
        if ($null -eq $smokeUser) {
          $cleanupFailures += "清理後查不到 smoke 使用者，無法確認停用狀態：$($user.id)"
        } elseif ($smokeUser.isActive -ne $false) {
          $cleanupFailures += "清理後 smoke 使用者仍為 active：$($user.id)"
        }
      } catch {
        $cleanupFailures += "驗證 smoke 使用者停用失敗：$($_.Exception.Message)"
      }
    }

    if ($null -ne $userHeaders) {
      try {
        Invoke-TypeTwoJson -Method "Get" -Path "/glossary" -Headers $userHeaders | Out-Null
        $cleanupFailures += "停用 smoke 使用者後，既有 token 仍可呼叫 API"
      } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -ne 401) {
          $cleanupFailures += "停用 smoke 使用者後 token 驗證回傳非預期狀態：$statusCode"
        }
      }
    }

    foreach ($message in $cleanupFailures) {
      Write-Warning $message
    }

    if ($cleanupFailures.Count -gt 0) {
      throw "smoke 測試資料清理失敗"
    }
  }
}

if ($null -ne $result) {
  $result | ConvertTo-Json -Depth 5
}
