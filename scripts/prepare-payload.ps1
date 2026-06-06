param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$BridgeExeRelativePath = "dist\dms-provider-bridge.exe",
    [string]$PayloadDir = "payload"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRoot = Resolve-Path (Join-Path $scriptRoot "..")

if (-not [System.IO.Path]::IsPathRooted($BridgeRepoPath)) {
    $BridgeRepoPath = Join-Path $installerRoot $BridgeRepoPath
}
$BridgeRepoPath = (Resolve-Path $BridgeRepoPath).Path

if (-not [System.IO.Path]::IsPathRooted($PayloadDir)) {
    $PayloadDir = Join-Path $installerRoot $PayloadDir
}

$sourceExe = Join-Path $BridgeRepoPath $BridgeExeRelativePath
$targetExe = Join-Path $PayloadDir "dms-provider-bridge.exe"

if (-not (Test-Path $sourceExe)) {
    throw "Bridge executable not found: $sourceExe"
}

New-Item -ItemType Directory -Path $PayloadDir -Force | Out-Null
Copy-Item -Path $sourceExe -Destination $targetExe -Force

$sourceInfo = Get-Item $sourceExe
$targetInfo = Get-Item $targetExe

Write-Host "Payload prepared."
Write-Host "Source: $($sourceInfo.FullName)"
Write-Host "Target: $($targetInfo.FullName)"
Write-Host "Size:   $($targetInfo.Length) bytes"
Write-Host "Time:   $($targetInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
