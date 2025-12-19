
function Update-SessionEnvironment {
    Write-Host "Refreshing environment variables..." -ForegroundColor Cyan

    $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
                 'HKCU:\Environment'

    $locations | ForEach-Object {
        $k = Get-Item $_
        $k.GetValueNames() | ForEach-Object {
            $name = $_
            $value = $k.GetValue($name)
            if ($name -eq 'Path') {
                $env:Path = $value
            } else {
                Set-Item -Path "Env:\$name" -Value $value
            }
        }
    }

    # Append chocolatey to path if not already there
    $chocoPath = "$env:ALLUSERSPROFILE\chocolatey\bin"
    if ($env:Path -notlike "*$chocoPath*") {
        $env:Path = "$env:Path;$chocoPath"
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Export-ModuleMember -Function Update-SessionEnvironment, Test-Administrator
