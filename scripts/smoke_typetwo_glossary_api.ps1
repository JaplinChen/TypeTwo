param(
  [string]$BaseUrl = "http://localhost:18000",
  [string]$AdminEmail = "admin@example.com",
  [string]$AdminPassword = "change-me-now"
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

$health = Invoke-TypeTwoJson -Method "Get" -Path "/health"
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

[pscustomobject]@{
  ok = $true
  baseUrl = $BaseUrl
  health = $health
  adminRole = $adminLogin.role
  approvedTermId = $approved.id
  userId = $user.id
  userRole = $userLogin.role
  pendingTermId = $pendingTerm.id
  approvedPendingStatus = $approvedPending.status
} | ConvertTo-Json -Depth 5
