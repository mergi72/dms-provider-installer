param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$BridgeSetupRelativePath,
    [string]$CredentialBrokerRepoPath = "..\credential-broker",
    [string]$TcPluginRepoPath = "..\tc-wfx-plugin",
    [string]$TcPluginRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.wfx64",
    [string]$TcPluginDllRelativePath = "artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll",
    [string]$TcPluginConfigRelativePath = "config\config.json",
    [string]$TcPluginLocalizeRelativePath = "config\localize.json",
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

function Resolve-LatestWfxPlugin {
    param(
        [string]$RepoPath,
        [string]$RelativePath,
        [string]$DllRelativePath
    )

    $wfxCandidate = Join-Path $RepoPath $RelativePath
    if (Test-Path $wfxCandidate) {
        return (Resolve-Path $wfxCandidate).Path
    }

    $releaseDir = Join-Path $RepoPath "artifacts\release"
    if (Test-Path $releaseDir) {
        $latest = Get-ChildItem -Path $releaseDir -Filter "TcWfxPlugin-*-win-x64" -Directory |
            Sort-Object LastWriteTime, Name -Descending |
            ForEach-Object { Join-Path $_.FullName "TcWfxPlugin.wfx64" } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($latest)) {
            return (Resolve-Path $latest).Path
        }
    }

    $dllCandidate = Join-Path $RepoPath $DllRelativePath
    if (Test-Path $dllCandidate) {
        return (Resolve-Path $dllCandidate).Path
    }

    throw "TC plugin binary not found. Checked: $wfxCandidate, $dllCandidate, and $releaseDir"
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
$oldBrokerSetup = Join-Path $installersPayloadDir "CredentialBrokerSetup.exe"
$brokerPayloadDir = Join-Path $PayloadDir "credential-broker"
$targetPluginWfx = Join-Path $tcPayloadDir "TcWfxPlugin.wfx64"
$targetPluginConfig = Join-Path $tcPayloadDir "config.json"
$targetPluginLocalize = Join-Path $tcPayloadDir "localize.json"

$sourceBridgeSetup = Resolve-LatestInstaller -RepoPath $BridgeRepoPath -RelativePath $BridgeSetupRelativePath -Pattern "DmsProviderBridgeSetup-*.exe" -Name "Bridge"
$sourceBrokerPayloadDir = Join-Path $CredentialBrokerRepoPath "artifacts\broker-installer-payload"
if (-not (Test-Path $sourceBrokerPayloadDir)) {
    throw "Credential Broker payload directory not found: $sourceBrokerPayloadDir"
}

$sourcePluginConfig = Join-Path $TcPluginRepoPath $TcPluginConfigRelativePath
$sourcePluginLocalize = Join-Path $TcPluginRepoPath $TcPluginLocalizeRelativePath

$pluginSourceToCopy = Resolve-LatestWfxPlugin -RepoPath $TcPluginRepoPath -RelativePath $TcPluginRelativePath -DllRelativePath $TcPluginDllRelativePath

if (-not (Test-Path $sourcePluginConfig)) {
    throw "TC plugin config not found: $sourcePluginConfig"
}

New-Item -ItemType Directory -Path $installersPayloadDir -Force | Out-Null
if (Test-Path $oldBrokerSetup) {
    Remove-Item -Path $oldBrokerSetup -Force
}
if (Test-Path $brokerPayloadDir) {
    Remove-Item -Path $brokerPayloadDir -Recurse -Force
}
New-Item -ItemType Directory -Path $brokerPayloadDir -Force | Out-Null
New-Item -ItemType Directory -Path $tcPayloadDir -Force | Out-Null

Copy-Item -Path $sourceBridgeSetup -Destination $targetBridgeSetup -Force
Copy-Item -Path (Join-Path $sourceBrokerPayloadDir "*") -Destination $brokerPayloadDir -Recurse -Force
Copy-Item -Path $pluginSourceToCopy -Destination $targetPluginWfx -Force
Copy-Item -Path $sourcePluginConfig -Destination $targetPluginConfig -Force
if (Test-Path $sourcePluginLocalize) {
    Copy-Item -Path $sourcePluginLocalize -Destination $targetPluginLocalize -Force
}

$bridgeInfo = Get-Item $targetBridgeSetup
$brokerExeInfo = Get-Item (Join-Path $brokerPayloadDir "credential-broker.exe")
$pluginInfo = Get-Item $targetPluginWfx
$configInfo = Get-Item $targetPluginConfig
$localizeInfo = if (Test-Path $targetPluginLocalize) { Get-Item $targetPluginLocalize } else { $null }

Write-Host "Payload prepared."
Write-Host "Bridge setup: $($bridgeInfo.FullName) ($($bridgeInfo.Length) bytes)"
Write-Host "Broker payload: $brokerPayloadDir"
Write-Host "Broker exe:     $($brokerExeInfo.FullName) ($($brokerExeInfo.Length) bytes)"
Write-Host "Plugin:       $($pluginInfo.FullName) ($($pluginInfo.Length) bytes)"
Write-Host "Config:       $($configInfo.FullName)"
if ($null -ne $localizeInfo) {
    Write-Host "Localize:     $($localizeInfo.FullName)"
}
