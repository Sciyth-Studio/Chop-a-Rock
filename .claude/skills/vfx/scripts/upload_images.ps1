param([Parameter(Mandatory)][string[]]$Path, [string]$Prefix = "VFX")
$ErrorActionPreference = "Stop"
$key = [Environment]::GetEnvironmentVariable("ROBLOX_API_KEY", "User")
if (-not $key) { $key = $env:ROBLOX_API_KEY }
if (-not $key) { throw "ROBLOX_API_KEY missing" }
$files = @(foreach ($p in $Path) { Get-ChildItem -Path $p -Filter *.png -File })
if ($files.Count -eq 0) { throw "No PNG files in $Path" }
$results = [ordered]@{}
foreach ($file in $files) {
    $name = "$Prefix $($file.BaseName -replace '\.flipbook$', '' -creplace '([a-z])([A-Z])', '$1 $2')"
    $request = @{
        assetType = "Image"
        displayName = $name
        description = "Chop a Rock VFX texture"
        creationContext = @{ creator = @{ groupId = "10962733" } }
    } | ConvertTo-Json -Compress -Depth 5
    $reqFile = Join-Path $env:TEMP "oc_request_$([guid]::NewGuid()).json"
    [IO.File]::WriteAllText($reqFile, $request)
    try {
        $raw = & curl.exe -s -X POST "https://apis.roblox.com/assets/v1/assets" -H "x-api-key: $key" `
            -F "request=<$reqFile;type=application/json" -F "fileContent=@$($file.FullName);type=image/png"
    } finally { Remove-Item $reqFile -ErrorAction SilentlyContinue }
    $op = $raw | ConvertFrom-Json
    if (-not $op.path) { Write-Output "UPLOAD FAILED $($file.Name): $raw"; continue }
    $id = $null
    for ($i = 0; $i -lt 30 -and -not $id; $i++) {
        Start-Sleep -Seconds 2
        $status = & curl.exe -s "https://apis.roblox.com/assets/v1/$($op.path)" -H "x-api-key: $key" | ConvertFrom-Json
        if ($status.done) {
            if ($status.response.assetId) { $id = $status.response.assetId }
            else { Write-Output "FAILED $($file.Name): $($status | ConvertTo-Json -Depth 6 -Compress)"; break }
        }
    }
    if ($id) {
        $results[$file.Name] = "rbxassetid://$id"
        Write-Output "$($file.Name) rbxassetid://$id"
    } elseif (-not $status.done) {
        Write-Output "TIMEOUT $($file.Name) $($op.path)"
    }
}
$byFolder = $files | Where-Object { $results.Contains($_.Name) } | Group-Object DirectoryName
foreach ($group in $byFolder) {
    $mapFile = Join-Path $group.Name "assets.json"
    $map = [ordered]@{}
    if (Test-Path $mapFile) {
        (Get-Content $mapFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $map[$_.Name] = $_.Value }
    }
    foreach ($f in $group.Group) { $map[$f.Name] = $results[$f.Name] }
    [IO.File]::WriteAllText($mapFile, ($map | ConvertTo-Json))
    Write-Output "wrote $mapFile"
}
