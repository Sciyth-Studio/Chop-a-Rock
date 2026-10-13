param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)
$ErrorActionPreference = "Stop"
$key = [Environment]::GetEnvironmentVariable("ROBLOX_API_KEY", "User")
if (-not $key) { $key = $env:ROBLOX_API_KEY }
if (-not $key) { throw "ROBLOX_API_KEY missing" }
$request = @{
    assetType = "Model"
    displayName = $Name
    description = "Chop a Rock rock model"
    creationContext = @{ creator = @{ groupId = "10962733" } }
} | ConvertTo-Json -Compress -Depth 5
$reqFile = Join-Path $env:TEMP "oc_request_$([guid]::NewGuid()).json"
[IO.File]::WriteAllText($reqFile, $request)
try {
    $raw = & curl.exe -s -X POST "https://apis.roblox.com/assets/v1/assets" -H "x-api-key: $key" `
        -F "request=<$reqFile;type=application/json" -F "fileContent=@$Path;type=model/fbx"
} finally { Remove-Item $reqFile -ErrorAction SilentlyContinue }
$op = $raw | ConvertFrom-Json
if (-not $op.path) { Write-Output "UPLOAD FAILED: $raw"; exit 1 }
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    $status = & curl.exe -s "https://apis.roblox.com/assets/v1/$($op.path)" -H "x-api-key: $key" | ConvertFrom-Json
    if ($status.done) {
        if ($status.response.assetId) { Write-Output "$Name $($status.response.assetId)"; exit 0 }
        Write-Output "FAILED: $($status | ConvertTo-Json -Depth 6 -Compress)"; exit 1
    }
}
Write-Output "TIMEOUT $($op.path)"
exit 1
