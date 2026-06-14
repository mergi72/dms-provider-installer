param(
    [string]$InstallRoot = "$env:LOCALAPPDATA\Programs\DMS Provider",
    [string]$BridgeSetupPath,
    [string]$BrokerPayloadPath,
    [string]$BrokerInstallRoot,
    [string]$WfxPluginPath,
    [string]$PluginConfigPath,
    [string]$PluginLocalizePath,
    [int]$HealthTimeoutSeconds = 60,
    [string]$BridgeHealthUrl = "http://127.0.0.1:8765/health",
    [string]$WinCmdIniPath,
    [switch]$SkipBridge,
    [switch]$SkipBroker,
    [switch]$SkipHealthCheck,
    [switch]$DisableTcRegistration,
    [switch]$PauseOnError
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installScript = Join-Path $scriptRoot "install.ps1"

if (-not (Test-Path $installScript)) {
    throw "install.ps1 not found: $installScript"
}

$installParams = @{
    InstallRoot = $InstallRoot
    HealthTimeoutSeconds = $HealthTimeoutSeconds
    BridgeHealthUrl = $BridgeHealthUrl
}

foreach ($name in @("BridgeSetupPath", "BrokerPayloadPath", "BrokerInstallRoot", "WfxPluginPath", "PluginConfigPath", "PluginLocalizePath", "WinCmdIniPath")) {
    $value = Get-Variable -Name $name -ValueOnly
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $installParams[$name] = $value
    }
}

if ($SkipBridge) { $installParams.SkipBridge = $true }
if ($SkipBroker) { $installParams.SkipBroker = $true }
if ($SkipHealthCheck) { $installParams.SkipHealthCheck = $true }
if ($DisableTcRegistration) { $installParams.DisableTcRegistration = $true }
if ($PauseOnError) { $installParams.PauseOnError = $true }
& $installScript @installParams
if ($LASTEXITCODE -ne 0) {
    throw "DMS Provider orchestration failed with exit code $LASTEXITCODE"
}
