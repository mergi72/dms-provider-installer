param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramData\\DmsProviderBridge",
    [string]$WfxPluginTargetPath = "$env:APPDATA\\GHISLER\\Plugins\\wfx\\TcWfxPlugin\\TcWfxPlugin.wfx64",
    [string]$NssmExePath,
    [switch]$KeepBridgeFiles,
    [switch]$KeepWfxPlugin
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

& $NssmExePath stop $ServiceName | Out-Null
& $NssmExePath remove $ServiceName confirm | Out-Null

if (-not $KeepBridgeFiles -and (Test-Path $InstallRoot)) {
    Remove-Item -Path $InstallRoot -Recurse -Force
}

if (-not $KeepWfxPlugin -and (Test-Path $WfxPluginTargetPath)) {
    Remove-Item -Path $WfxPluginTargetPath -Force
}

Write-Host "Uninstall finished. Service removed: $ServiceName"
