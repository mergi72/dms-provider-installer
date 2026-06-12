param(
    [string]$InstallRoot = "$env:ProgramFiles\DMS Provider",
    [switch]$KeepWfxFiles
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

$wfxRoot = Join-Path $InstallRoot "tc-wfx"

if (-not $KeepWfxFiles -and (Test-Path $wfxRoot)) {
    Remove-Item -Path $wfxRoot -Recurse -Force
}

Write-Host "DMS Provider orchestrator uninstall finished."
Write-Host "WFX files removed: $(-not $KeepWfxFiles)"
Write-Host "Bridge and Credential Broker are owned by their own installers."
