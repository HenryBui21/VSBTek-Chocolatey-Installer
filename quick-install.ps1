# VSBTek Chocolatey Quick Installer - Wrapper Script
# This lightweight wrapper enables one-liner execution via: irm URL | iex
# Downloads and executes the main install-apps.ps1 script

$tempPath = "$env:TEMP\vsbtek-install-apps.ps1"
$scriptUrl = "https://scripts.vsbtek.com/install-apps.ps1"

Write-Host "VSBTek Quick Installer" -ForegroundColor Cyan
Write-Host "Downloading installer script..." -ForegroundColor Yellow

try {
    # Download the main script
    Invoke-RestMethod -Uri $scriptUrl -OutFile $tempPath -ErrorAction Stop

    Write-Host "Starting installation..." -ForegroundColor Green
    Write-Host ""

    # Execute the main script with interactive mode
    & $tempPath

    # Clean up
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Error: Failed to download or execute installer" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    # Clean up on error
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }

    exit 1
}
