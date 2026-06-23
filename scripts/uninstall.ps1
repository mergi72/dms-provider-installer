param(
    [string]$InstallRoot = "$env:LOCALAPPDATA\Programs\DMS Provider",
    [switch]$KeepWfxFiles
)

$ErrorActionPreference = "Stop"

$wfxRoot = Join-Path $InstallRoot "tc-wfx"

if (-not $KeepWfxFiles -and (Test-Path $wfxRoot)) {
    Remove-Item -Path $wfxRoot -Recurse -Force
}

Write-Host "DMS Provider orchestrator uninstall finished."
Write-Host "WFX files removed: $(-not $KeepWfxFiles)"
Write-Host "Bridge and Credential Broker are owned by their own installers."
