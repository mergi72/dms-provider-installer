param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramFiles\DMS Provider",
    [string]$BridgeExePath,
    [string]$WfxPluginPath,
    [string]$PluginConfigPath,
    [string]$NssmExePath,
    [int]$HealthTimeoutSeconds = 30,
    [string]$HealthUrl = "http://127.0.0.1:8765/health",
    [string]$WinCmdIniPath,
    [switch]$DisableTcRegistration,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installScript = Join-Path $scriptRoot "install.ps1"

if (-not (Test-Path $installScript)) {
    throw "install.ps1 not found: $installScript"
}

Write-Host "Installing bridge Windows Service..."
$installParams = @{
    ServiceName = $ServiceName
    InstallRoot = $InstallRoot
    NssmExePath = $NssmExePath
    HealthTimeoutSeconds = $HealthTimeoutSeconds
    HealthUrl = $HealthUrl
}

if (-not [string]::IsNullOrWhiteSpace($BridgeExePath)) {
    $installParams.BridgeExePath = $BridgeExePath
}

if (-not [string]::IsNullOrWhiteSpace($WfxPluginPath)) {
    $installParams.WfxPluginPath = $WfxPluginPath
}

if (-not [string]::IsNullOrWhiteSpace($PluginConfigPath)) {
    $installParams.PluginConfigPath = $PluginConfigPath
}

if (-not [string]::IsNullOrWhiteSpace($WinCmdIniPath)) {
    $installParams.WinCmdIniPath = $WinCmdIniPath
}

if ($DisableTcRegistration) {
    $installParams.DisableTcRegistration = $true
}

& $installScript @installParams
if ($LASTEXITCODE -ne 0) {
    throw "Bridge service installation failed with exit code $LASTEXITCODE"
}

if (-not $Silent) {
    Write-Host "Bridge installation and health check finished."
    Write-Host "Bundle installed: bridge.exe + service + TcWfxPlugin.wfx64 + config.json."
}
