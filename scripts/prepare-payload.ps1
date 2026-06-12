param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$BridgeSetupRelativePath,
    [string]$CredentialBrokerRepoPath = "..\credential-broker",
    [string]$BrokerSetupRelativePath,
    [string]$TcPluginRepoPath = "..\tc-wfx-plugin",
    [string]$TcPluginRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.wfx64",
    [string]$TcPluginDllRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll",
    [string]$TcPluginConfigRelativePath = "config\config.json",
    [string]$PayloadDir = "payload"
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param(
        [string]$Path,
        [string]$InstallerRoot
    )

    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $InstallerRoot $Path
    }

    return (Resolve-Path $Path).Path
}

function Resolve-LatestInstaller {
    param(
        [string]$RepoPath,
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Name
    )

    if (-not [string]::IsNullOrWhiteSpace($RelativePath)) {
        $candidate = Join-Path $RepoPath $RelativePath
        if (-not (Test-Path $candidate)) {
            throw "$Name setup not found: $candidate"
        }
        return (Resolve-Path $candidate).Path
    }

    $installerDir = Join-Path $RepoPath "artifacts\installer"
    if (-not (Test-Path $installerDir)) {
        throw "$Name installer directory not found: $installerDir"
    }

    $latest = Get-ChildItem -Path $installerDir -Filter $Pattern -File |
        Sort-Object LastWriteTime, Name -Descending |
        Select-Object -First 1

    if ($null -eq $latest) {
        throw "$Name setup not found in $installerDir with pattern $Pattern"
    }

    return $latest.FullName
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRoot = Resolve-Path (Join-Path $scriptRoot "..")

$BridgeRepoPath = Resolve-RepoPath -Path $BridgeRepoPath -InstallerRoot $installerRoot
$CredentialBrokerRepoPath = Resolve-RepoPath -Path $CredentialBrokerRepoPath -InstallerRoot $installerRoot
$TcPluginRepoPath = Resolve-RepoPath -Path $TcPluginRepoPath -InstallerRoot $installerRoot

if (-not [System.IO.Path]::IsPathRooted($PayloadDir)) {
    $PayloadDir = Join-Path $installerRoot $PayloadDir
}

$installersPayloadDir = Join-Path $PayloadDir "installers"
$tcPayloadDir = Join-Path $PayloadDir "tc-wfx"
$targetBridgeSetup = Join-Path $installersPayloadDir "DmsProviderBridgeSetup.exe"
$targetBrokerSetup = Join-Path $installersPayloadDir "CredentialBrokerSetup.exe"
$targetPluginWfx = Join-Path $tcPayloadDir "TcWfxPlugin.wfx64"
$targetPluginConfig = Join-Path $tcPayloadDir "config.json"

$sourceBridgeSetup = Resolve-LatestInstaller -RepoPath $BridgeRepoPath -RelativePath $BridgeSetupRelativePath -Pattern "DmsProviderBridgeSetup-*.exe" -Name "Bridge"
$sourceBrokerSetup = Resolve-LatestInstaller -RepoPath $CredentialBrokerRepoPath -RelativePath $BrokerSetupRelativePath -Pattern "CredentialBrokerSetup-*.exe" -Name "Credential Broker"

$sourcePluginWfx = Join-Path $TcPluginRepoPath $TcPluginRelativePath
$sourcePluginDll = Join-Path $TcPluginRepoPath $TcPluginDllRelativePath
$sourcePluginConfig = Join-Path $TcPluginRepoPath $TcPluginConfigRelativePath

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

New-Item -ItemType Directory -Path $installersPayloadDir -Force | Out-Null
New-Item -ItemType Directory -Path $tcPayloadDir -Force | Out-Null

Copy-Item -Path $sourceBridgeSetup -Destination $targetBridgeSetup -Force
Copy-Item -Path $sourceBrokerSetup -Destination $targetBrokerSetup -Force
Copy-Item -Path $pluginSourceToCopy -Destination $targetPluginWfx -Force
Copy-Item -Path $sourcePluginConfig -Destination $targetPluginConfig -Force

$bridgeInfo = Get-Item $targetBridgeSetup
$brokerInfo = Get-Item $targetBrokerSetup
$pluginInfo = Get-Item $targetPluginWfx
$configInfo = Get-Item $targetPluginConfig

Write-Host "Payload prepared."
Write-Host "Bridge setup: $($bridgeInfo.FullName) ($($bridgeInfo.Length) bytes)"
Write-Host "Broker setup: $($brokerInfo.FullName) ($($brokerInfo.Length) bytes)"
Write-Host "Plugin:       $($pluginInfo.FullName) ($($pluginInfo.Length) bytes)"
Write-Host "Config:       $($configInfo.FullName)"
