# VSBTek Unified App Manager - Modularized
# Combines installation, management, and remote execution capabilities
# Refactored for performance and maintainability

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = $null,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Install', 'Update', 'Uninstall', 'List', 'Upgrade')]
    [string]$Action = $null,

    [Parameter(Mandatory=$false)]
    [ValidateSet('basic', 'dev', 'community', 'gaming', 'remote')]
    [string]$Preset = $null,

    [Parameter(Mandatory=$false)]
    [ValidateSet('local', 'remote')]
    [string]$Mode = 'local',

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$UseWinget,

    [Parameter(Mandatory=$false)]
    [switch]$KeepWindowOpen
)

# Configuration
$GitHubRepo = "https://raw.githubusercontent.com/HenryBui21/VSBTek-Unified-App-Manager/main"
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ============================================================================
# MODULE LOADING
# ============================================================================

$ModulesPath = Join-Path $PSScriptRoot "scripts\modules"

# If modules not found (e.g. running remote one-liner without full repo), download them?
# For now, assume structure exists. If remote, quick-install handles it or we'd need a bootstrap.
# Since we are refactoring the repo, we assume modules exist relative to script.

Import-Module (Join-Path $ModulesPath "Logger.psm1") -Force
Import-Module (Join-Path $ModulesPath "Core.psm1") -Force
Import-Module (Join-Path $ModulesPath "Config.psm1") -Force
Import-Module (Join-Path $ModulesPath "Detection.psm1") -Force
Import-Module (Join-Path $ModulesPath "PackageManager.psm1") -Force
Import-Module (Join-Path $ModulesPath "UI.psm1") -Force

# Initialize Global State
Initialize-Detection -RootPath $PSScriptRoot -GitHubRepo $GitHubRepo
Import-PackagePolicy -RootPath $PSScriptRoot

# ============================================================================
# AUTO-ELEVATION
# ============================================================================

if (-not (Test-Administrator)) {
    Write-WarningMsg "Requesting Administrator privileges..."
    
    $runningFromFile = $null -ne $MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -ne ''
    if ($runningFromFile) {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($ConfigFile) { $arguments += " -ConfigFile `"$ConfigFile`"" }
        if ($Action) { $arguments += " -Action `"$Action`"" }
        if ($Preset) { $arguments += " -Preset `"$Preset`"" }
        if ($Mode) { $arguments += " -Mode `"$Mode`"" }
        if ($Force) { $arguments += " -Force" }
        if ($UseWinget) { $arguments += " -UseWinget" }
        $arguments += " -KeepWindowOpen"
        Start-Process PowerShell.exe -ArgumentList $arguments -Verb RunAs
        exit
    }
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

function Invoke-MainWorkflow {
    param(
        [string]$InitialAction = $null,
        [string]$InitialPreset = $null,
        [string]$InitialConfigFile = $null,
        [string]$ExecutionMode = 'local',
        [bool]$ForceFlag = $false
    )

    $selectedAction = $InitialAction
    if (-not $selectedAction) {
        $selectedAction = Show-MainMenu
    }

    Write-Host ""
    Write-ColorOutput "Selected Action: $selectedAction" -Color Yellow

    if ($selectedAction -eq 'Upgrade') {
        Invoke-UpgradeAll
        return $true
    }

    $applications = $null
    if ($InitialPreset -or $InitialConfigFile) {
        if ($InitialPreset -eq 'custom') {
            $applications = Show-CustomSelectionMenu -Mode $ExecutionMode -RootPath $PSScriptRoot -GitHubRepo $GitHubRepo
        } else {
            $applications = Get-ConfigApplications -Preset $InitialPreset -ConfigFile $InitialConfigFile -Mode $ExecutionMode -RootPath $PSScriptRoot -GitHubRepo $GitHubRepo
        }
    } else {
        $selectedPreset = Show-PresetMenu -RootPath $PSScriptRoot
        if ($selectedPreset -eq 'custom') {
            $applications = Show-CustomSelectionMenu -Mode $ExecutionMode -RootPath $PSScriptRoot -GitHubRepo $GitHubRepo
        } else {
            $applications = Get-ConfigApplications -Preset $selectedPreset -Mode $ExecutionMode -RootPath $PSScriptRoot -GitHubRepo $GitHubRepo
        }
    }

    if (-not $applications -or $applications.Count -eq 0) {
        Write-ErrorMsg "No applications found/selected"
        return $true
    }

    # Execute Action
    switch ($selectedAction) {
        'Install' {
            foreach ($app in $applications) {
                $appName = if ($app.name) { $app.name } else { $app.Name }
                $appVer = if ($app.version) { $app.version } else { $app.Version }
                $appParams = if ($app.params) { $app.params } else { $app.Params }
                
                $source = Get-PreferredSource -AppName $appName -UseWinget $UseWinget
                
                $success = $false
                if ($source -eq 'Winget') {
                    $success = Install-WingetPackage -PackageName $appName -Version $appVer -Params $appParams -ForceInstall $ForceFlag
                    if (-not $success) { $success = Install-ChocoPackage -PackageName $appName -Version $appVer -Params $appParams -ForceInstall $ForceFlag }
                } else {
                    $success = Install-ChocoPackage -PackageName $appName -Version $appVer -Params $appParams -ForceInstall $ForceFlag
                    if (-not $success -and $UseWinget) { $success = Install-WingetPackage -PackageName $appName -Version $appVer -Params $appParams -ForceInstall $ForceFlag }
                }
                
                # Handle Pinning
                $policy = Get-PackagePolicy
                if ($policy.pinned -contains $appName.ToLower()) {
                    if ($source -eq 'Winget') { Set-WingetPin -PackageName $appName } else { Set-ChocoPin -PackageName $appName }
                }
            }
        }
        'Update' {
            foreach ($app in $applications) {
                $appName = if ($app.name) { $app.name } else { $app.Name }
                $appVer = if ($app.version) { $app.version } else { $app.Version }
                Update-ChocoPackage -PackageName $appName -Version $appVer
            }
        }
        'Uninstall' {
            foreach ($app in $applications) {
                $appName = if ($app.name) { $app.name } else { $app.Name }
                Uninstall-ChocoPackage -PackageName $appName
            }
        }
        'List' {
            Show-InstalledPackages -Applications $applications
        }
    }

    return $true
}

# ============================================================================
# ENTRY POINT
# ============================================================================

Write-ColorOutput "VSBTek Unified App Manager (Modularized)" -Color Magenta

if (-not (Install-Chocolatey)) { exit 1 }
Update-SessionEnvironment

if (Get-Command winget -ErrorAction SilentlyContinue) {
    if (-not $UseWinget) { $UseWinget = $true }
}

$continueRunning = $true
if ($Action -or $Preset -or $ConfigFile) {
    Invoke-MainWorkflow -InitialAction $Action -InitialPreset $Preset -InitialConfigFile $ConfigFile -ExecutionMode $Mode -ForceFlag $Force
    if ($KeepWindowOpen) { $continueRunning = Show-ContinuePrompt } else { $continueRunning = $false }
}

while ($continueRunning) {
    $result = Invoke-MainWorkflow -ExecutionMode $Mode -ForceFlag $Force
    if ($result) { $continueRunning = Show-ContinuePrompt } else { $continueRunning = $false }
}
