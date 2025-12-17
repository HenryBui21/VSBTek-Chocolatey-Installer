# Script to maintain winget-map.json (Validate, Discover, and Auto-Update)
# Combines functionality of validation and auto-discovery from config files

$ErrorActionPreference = 'Continue'
$mapFile = Join-Path $PSScriptRoot "winget-map.json"

# 1. Load existing map
$wingetMap = @{}
if (Test-Path $mapFile) {
    Write-Host "Loading existing map..." -ForegroundColor Cyan
    $jsonMap = Get-Content $mapFile -Raw | ConvertFrom-Json
    foreach ($prop in $jsonMap.PSObject.Properties) {
        $wingetMap[$prop.Name] = $prop.Value
    }
}

# 2. Scan config files for apps
Write-Host "Scanning config files..." -ForegroundColor Cyan
$configFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*-config.json"
$configApps = @()

foreach ($file in $configFiles) {
    try {
        $config = Get-Content $file.FullName -Raw | ConvertFrom-Json
        if ($config.applications) {
            foreach ($app in $config.applications) {
                $name = if ($app.name) { $app.name } else { $app.Name }
                if ($name -and $configApps -notcontains $name) {
                    $configApps += $name
                }
            }
        }
    } catch {
        Write-Warning "Could not read $($file.Name)"
    }
}

# 3. Merge lists (Config apps + Existing Map keys) to ensure full coverage
$allAppsToProcess = $configApps + ($wingetMap.Keys | Where-Object { $configApps -notcontains $_ })
$allAppsToProcess = $allAppsToProcess | Sort-Object | Get-Unique

Write-Host "Found $($allAppsToProcess.Count) unique applications to process." -ForegroundColor Green
Write-Host ""

# 4. Process applications
$changesMade = $false

foreach ($appName in $allAppsToProcess) {
    $lowerName = $appName.ToLower()
    $currentId = $wingetMap[$lowerName]
    $isValid = $false
    $isUsedInConfig = $configApps -contains $appName

    # Step A: Validate existing ID if present
    if ($currentId) {
        Write-Host "Checking '$appName' -> '$currentId' ... " -NoNewline
        
        if (-not $isUsedInConfig) {
            Write-Host "[UNUSED] " -NoNewline -ForegroundColor Yellow
        }

        $null = winget show --id $currentId --exact --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "OK" -ForegroundColor Green
            $isValid = $true
        } else {
            Write-Host "INVALID/NOT FOUND" -ForegroundColor Red
        }
    } else {
        Write-Host "Checking '$appName' ... " -NoNewline
        Write-Host "MISSING MAP" -ForegroundColor Yellow
    }

    # Step B: Search if invalid or missing
    if (-not $isValid) {
        Write-Host "  Searching Winget for '$appName'..." -ForegroundColor DarkCyan
        
        # Search winget
        $searchResult = winget search --query "$appName" --accept-source-agreements --source winget 2>&1
        
        # Parse results (heuristic: split by 2+ spaces, take 2nd column as ID)
        $bestMatchId = $null
        
        # Skip header lines (starts with Name or ----)
        $lines = $searchResult | Where-Object { $_ -and $_ -notmatch '^(Name|-)' }
        
        foreach ($line in $lines) {
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) {
                $candidateId = $parts[1]
                # Basic validation: ID usually contains a dot, isn't a version number
                if ($candidateId -match '\.' -and $candidateId -notmatch '^\d') {
                    $bestMatchId = $candidateId
                    break # Take the first/best match
                }
            }
        }

        if ($bestMatchId) {
            Write-Host "  Found match: $bestMatchId" -ForegroundColor Green
            $wingetMap[$lowerName] = $bestMatchId
            $changesMade = $true
        } else {
            Write-Host "  No match found on Winget." -ForegroundColor Magenta
        }
    }
}

# 5. Save changes
if ($changesMade) {
    Write-Host ""
    Write-Host "Updating winget-map.json..." -ForegroundColor Cyan
    
    # Sort keys for clean JSON
    $sortedMap = [ordered]@{}
    foreach ($key in ($wingetMap.Keys | Sort-Object)) {
        $sortedMap[$key] = $wingetMap[$key]
    }
    
    $sortedMap | ConvertTo-Json -Depth 2 | Out-File $mapFile -Encoding UTF8
    Write-Host "File saved successfully." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "No changes needed." -ForegroundColor Green
}