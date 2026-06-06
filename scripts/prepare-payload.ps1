param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$BridgeExeRelativePath = "dist\dms-provider-bridge.exe",
    [string]$TcPluginRepoPath = "..\tc-wfx-plugin",
    [string]$TcPluginRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.wfx64",
    [string]$TcPluginDllRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll",
    [string]$TcPluginConfigRelativePath = "config\config.json",
    [string]$PayloadDir = "payload"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRoot = Resolve-Path (Join-Path $scriptRoot "..")

if (-not [System.IO.Path]::IsPathRooted($BridgeRepoPath)) {
    $BridgeRepoPath = Join-Path $installerRoot $BridgeRepoPath
}
$BridgeRepoPath = (Resolve-Path $BridgeRepoPath).Path

if (-not [System.IO.Path]::IsPathRooted($TcPluginRepoPath)) {
    $TcPluginRepoPath = Join-Path $installerRoot $TcPluginRepoPath
}
$TcPluginRepoPath = (Resolve-Path $TcPluginRepoPath).Path

if (-not [System.IO.Path]::IsPathRooted($PayloadDir)) {
    $PayloadDir = Join-Path $installerRoot $PayloadDir
}

$sourceExe = Join-Path $BridgeRepoPath $BridgeExeRelativePath
$targetExe = Join-Path $PayloadDir "dms-provider-bridge.exe"
$sourcePluginWfx = Join-Path $TcPluginRepoPath $TcPluginRelativePath
$sourcePluginDll = Join-Path $TcPluginRepoPath $TcPluginDllRelativePath
$sourcePluginConfig = Join-Path $TcPluginRepoPath $TcPluginConfigRelativePath
$targetPluginWfx = Join-Path $PayloadDir "TcWfxPlugin.wfx64"
$targetPluginConfig = Join-Path $PayloadDir "config.json"

if (-not (Test-Path $sourceExe)) {
    throw "Bridge executable not found: $sourceExe"
}

$pluginSourceToCopy = $null
if (Test-Path $sourcePluginWfx) {
    $pluginSourceToCopy = $sourcePluginWfx
}
elseif (Test-Path $sourcePluginDll) {
    $pluginSourceToCopy = $sourcePluginDll
}
else {
    throw "TC plugin binary not found. Checked: $sourcePluginWfx and $sourcePluginDll"
}

if (-not (Test-Path $sourcePluginConfig)) {
    throw "TC plugin config not found: $sourcePluginConfig"
}

New-Item -ItemType Directory -Path $PayloadDir -Force | Out-Null
Copy-Item -Path $sourceExe -Destination $targetExe -Force
Copy-Item -Path $pluginSourceToCopy -Destination $targetPluginWfx -Force
Copy-Item -Path $sourcePluginConfig -Destination $targetPluginConfig -Force

$sourceInfo = Get-Item $sourceExe
$targetInfo = Get-Item $targetExe
$pluginTargetInfo = Get-Item $targetPluginWfx
$configTargetInfo = Get-Item $targetPluginConfig

Write-Host "Payload prepared."
Write-Host "Source: $($sourceInfo.FullName)"
Write-Host "Target: $($targetInfo.FullName)"
Write-Host "Size:   $($targetInfo.Length) bytes"
Write-Host "Time:   $($targetInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Plugin: $($pluginTargetInfo.FullName)"
Write-Host "Config: $($configTargetInfo.FullName)"
