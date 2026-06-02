$baseUrl = "http://127.0.0.1:8787"
$envPath = Join-Path $PSScriptRoot ".env"
$apiToken = $null

if (Test-Path $envPath) {
    $tokenLine = Get-Content $envPath |
        Where-Object { $_ -match "^\s*API_TOKEN\s*=" } |
        Select-Object -First 1

    if ($tokenLine) {
        $apiToken = ($tokenLine -replace "^\s*API_TOKEN\s*=\s*", "").Trim().Trim('"').Trim("'")
    }
}

if (-not $apiToken) {
    $apiToken = $env:API_TOKEN
}

if (-not $apiToken) {
    Write-Error "API_TOKEN was not found. Create .env or set the API_TOKEN environment variable."
    exit 1
}

$headers = @{ "X-API-Key" = $apiToken }
$workDir = Join-Path $PSScriptRoot "test-work"

New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$text = "clipboard-sync-text-test"
$textResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "$baseUrl/clipboard/text" `
    -Headers $headers `
    -ContentType "text/plain; charset=utf-8" `
    -Body $text
$textGet = Invoke-RestMethod -Uri "$baseUrl/clipboard/text" -Headers $headers

if ($textResponse.text -ne $text -or $textGet.text -ne $text) {
    Write-Error "Text clipboard API test failed."
    exit 1
}

$jsonText = "160.26.235.34"
$jsonBody = @{ text = $jsonText } | ConvertTo-Json -Compress
$jsonTextResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "$baseUrl/clipboard/text" `
    -Headers $headers `
    -ContentType "text/plain; charset=utf-8" `
    -Body $jsonBody
$jsonTextGet = Invoke-RestMethod -Uri "$baseUrl/clipboard/text" -Headers $headers

if ($jsonTextResponse.text -ne $jsonText -or $jsonTextGet.text -ne $jsonText) {
    Write-Error "JSON text field extraction test failed."
    exit 1
}

$imagePath = Join-Path $workDir "sample.png"
$imageBytes = [Convert]::FromBase64String(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
)
[IO.File]::WriteAllBytes($imagePath, $imageBytes)

$imageResponse = curl.exe -s `
    -H "X-API-Key: $apiToken" `
    -F "file=@$imagePath;type=image/png" `
    "$baseUrl/clipboard/image" | ConvertFrom-Json

if (-not $imageResponse.filename) {
    Write-Error "Image upload API test failed."
    exit 1
}

$latestImagePath = Join-Path $workDir "latest-image.png"
Invoke-WebRequest `
    -Uri "$baseUrl/clipboard/image/latest" `
    -Headers $headers `
    -OutFile $latestImagePath

if (-not (Test-Path $latestImagePath)) {
    Write-Error "Latest image API test failed."
    exit 1
}

$filePath = Join-Path $workDir "sample.txt"
Set-Content -Path $filePath -Value "file upload test" -Encoding UTF8

$fileResponse = curl.exe -s `
    -H "X-API-Key: $apiToken" `
    -F "file=@$filePath" `
    "$baseUrl/clipboard/file" | ConvertFrom-Json

if (-not $fileResponse.filename) {
    Write-Error "File upload API test failed."
    exit 1
}

for ($index = 1; $index -le 6; $index++) {
    $extraPath = Join-Path $workDir "extra-$index.txt"
    Set-Content -Path $extraPath -Value "extra file $index" -Encoding UTF8

    curl.exe -s `
        -H "X-API-Key: $apiToken" `
        -F "file=@$extraPath" `
        "$baseUrl/clipboard/file" | Out-Null
}

$uploadCount = (Get-ChildItem `
    -Path (Join-Path $PSScriptRoot "uploads") `
    -Recurse `
    -File | Measure-Object).Count

if ($uploadCount -gt 5) {
    Write-Error "Upload pruning test failed. uploads contains $uploadCount files."
    exit 1
}

$latestFilePath = Join-Path $workDir "latest-file.txt"
Invoke-WebRequest `
    -Uri "$baseUrl/clipboard/file/latest" `
    -Headers $headers `
    -OutFile $latestFilePath

if (-not (Test-Path $latestFilePath)) {
    Write-Error "Latest file API test failed."
    exit 1
}

$unauthorizedStatusCode = $null

try {
    Invoke-WebRequest -Uri "$baseUrl/clipboard/text" | Out-Null
    $unauthorizedStatusCode = 200
} catch {
    if ($_.Exception.Response) {
        $unauthorizedStatusCode = [int]$_.Exception.Response.StatusCode
    }
}

if ($unauthorizedStatusCode -ne 401) {
    Write-Error "API key authentication test failed."
    exit 1
}

Write-Host "Clipboard Sync API test passed."
