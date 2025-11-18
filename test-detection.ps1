# Test script to verify package detection logic

# Load the Test-PackageInstalled function from install-apps.ps1
. "c:\Users\VSBTek\Documents\VSCode\VSBTek-Chocolatey-Installer\install-apps.ps1" -ErrorAction Stop

# Test packages that should be detected
$testPackages = @(
    "googlechrome",
    "firefox",
    "7zip",
    "brave",
    "foxitreader",
    "notepadplusplus"  # This might not be installed
)

Write-Host "`n=== Testing Package Detection ===" -ForegroundColor Cyan
Write-Host ""

foreach ($pkg in $testPackages) {
    $chocoOnly = Test-PackageInstalled -PackageName $pkg -ChocoOnly
    $anyMethod = Test-PackageInstalled -PackageName $pkg

    $status = if ($chocoOnly) {
        "[Chocolatey] "
    } elseif ($anyMethod) {
        "[Windows]    "
    } else {
        "[Not Found]  "
    }

    $color = if ($chocoOnly) { "Green" } elseif ($anyMethod) { "Yellow" } else { "Red" }
    Write-Host "$status $pkg" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== All Chocolatey Packages ===" -ForegroundColor Cyan
$result = & choco list --limit-output 2>&1
if ($LASTEXITCODE -eq 0) {
    $result | Select-Object -First 15 | ForEach-Object {
        if ($_ -match "^([^|]+)\|(.+)$") {
            Write-Host "  $($matches[1]) - v$($matches[2])" -ForegroundColor Gray
        }
    }
}
