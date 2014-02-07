﻿$packageName = '{{PackageName}}'
$version = '{{PackageVersion}}'
$registryUninstallRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$registryUninstallRootWow6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

function findMsid {
    param([String]$registryUninstallRoot, [string]$keyContentMatch, [string]$version)

    if (Test-Path $registryUninstallRoot) {
        Get-ChildItem -Force -Path $registryUninstallRoot | foreach {
            $currentKey = (Get-ItemProperty -Path $_.PsPath)
            if ($currentKey -match $keyContentMatch -and $currentKey -match $version) {
                return $currentKey.PsChildName
            }
        }
    }

    return $null
}

try {

    $alreadyInstalled = findMsid $registryUninstallRoot 'Adobe Flash Player [\d\.]+ ActiveX' $version
    $alreadyInstalledWow6432 = findMsid $registryUninstallRootWow6432 'Adobe Flash Player [\d\.]+ ActiveX' $version

    if (Get-Process iexplore -ErrorAction SilentlyContinue) {
        Write-Debug 'Internet Explorer is running. If the installation fails with an 1603 error, this is probably the reason.'
    }

    if ([System.Environment]::OSVersion.Version -ge '6.2') {
        Write-Debug 'You have Windows 8 or higher. This package is only for Windows '
    }

    if ($alreadyInstalled -or $alreadyInstalledWow6432) {
        Write-Output "Adobe Flash Player Plugin (ActiveX for IE) $version is already installed."
    } else {
        Install-ChocolateyPackage $packageName 'msi' '/quiet /norestart REMOVE_PREVIOUS=YES' '{{DownloadUrl}}'
    }


} catch {
    Write-ChocolateyFailure $packageName $($_.Exception.Message)
    throw
}
