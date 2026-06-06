param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramFiles\\DMS Provider",
    [string]$NssmExePath,
    [switch]$KeepBridgeFiles
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw "Uninstall requires elevated PowerShell (Run as Administrator)."
}

if ([string]::IsNullOrWhiteSpace($NssmExePath) -or -not (Test-Path $NssmExePath)) {
    throw "NSSM executable not found. Provide -NssmExePath."
}

& $NssmExePath stop $ServiceName | Out-Null 2>&1
& $NssmExePath remove $ServiceName confirm | Out-Null 2>&1

if (-not $KeepBridgeFiles -and (Test-Path $InstallRoot)) {
    Remove-Item -Path $InstallRoot -Recurse -Force
}

Write-Host "Uninstall finished. Service removed: $ServiceName"
