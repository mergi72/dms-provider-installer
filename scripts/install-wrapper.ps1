param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramData\DmsProviderBridge",
    [string]$BridgeSourceRepoPath,
    [string]$BridgeReleaseZipPath,
    [string]$NssmExePath,
    [string]$PluginDeployRoot = "$env:LOCALAPPDATA\DMSProvider\TCPlugin",
    [string]$WfxPluginBinaryPath,
    [string]$WfxPluginConfigPath,
    [int]$HealthTimeoutSeconds = 30,
    [string]$HealthUrl = "http://127.0.0.1:8765/health",
    [switch]$InstallPluginWhenTcDetected,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

function Resolve-FirstExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Resolve-TcExecutable {
    $tcPaths = @(
        "C:\totalcmd\TOTALCMD64.EXE",
        "C:\Program Files\totalcmd\TOTALCMD64.EXE",
        "C:\Program Files (x86)\totalcmd\TOTALCMD.EXE"
    )

    return Resolve-FirstExistingPath -Candidates $tcPaths
}

function Resolve-PluginSourcePaths {
    param(
        [string]$RepoRoot,
        [string]$ExplicitBinaryPath,
        [string]$ExplicitConfigPath
    )

    $workspaceRoot = Split-Path -Parent $RepoRoot
    $defaultBinaryCandidates = @(
        $ExplicitBinaryPath,
        (Join-Path $workspaceRoot "tc-wfx-plugin\artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll")
    )

    $defaultConfigCandidates = @(
        $ExplicitConfigPath,
        (Join-Path $workspaceRoot "tc-wfx-plugin\artifacts\TcWfxPlugin-win-x64\config\config.json"),
        (Join-Path $workspaceRoot "tc-wfx-plugin\config\config.json")
    )

    return @{
        Binary = Resolve-FirstExistingPath -Candidates $defaultBinaryCandidates
        Config = Resolve-FirstExistingPath -Candidates $defaultConfigCandidates
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
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

if (-not [string]::IsNullOrWhiteSpace($BridgeSourceRepoPath)) {
    $installParams.BridgeSourceRepoPath = $BridgeSourceRepoPath
}

if (-not [string]::IsNullOrWhiteSpace($BridgeReleaseZipPath)) {
    $installParams.BridgeReleaseZipPath = $BridgeReleaseZipPath
}

& $installScript @installParams
if ($LASTEXITCODE -ne 0) {
    throw "Bridge service installation failed with exit code $LASTEXITCODE"
}

Write-Host "Bridge installation and health check finished."

$tcExe = Resolve-TcExecutable
if ([string]::IsNullOrWhiteSpace($tcExe)) {
    Write-Host "Total Commander not detected. Skipping optional WFX plugin deployment."
    return
}

Write-Host "Total Commander detected: $tcExe"
$shouldInstallPlugin = $false
if ($Silent -or $InstallPluginWhenTcDetected) {
    $shouldInstallPlugin = $true
}
else {
    $response = Read-Host "Total Commander detected. Install WFX plugin files now? [A/N]"
    if ($response -match "^(a|A|y|Y)$") {
        $shouldInstallPlugin = $true
    }
}

if (-not $shouldInstallPlugin) {
    Write-Host "Skipping WFX plugin deployment by user choice."
    return
}

$pluginSources = Resolve-PluginSourcePaths -RepoRoot $repoRoot -ExplicitBinaryPath $WfxPluginBinaryPath -ExplicitConfigPath $WfxPluginConfigPath
if ([string]::IsNullOrWhiteSpace($pluginSources.Binary)) {
    throw "WFX plugin binary not found. Provide -WfxPluginBinaryPath."
}

$pluginDir = $PluginDeployRoot
$configDir = Join-Path $pluginDir "config"
$pluginTarget = Join-Path $pluginDir "TcWfxPlugin.wfx64"

New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

Copy-Item -Path $pluginSources.Binary -Destination $pluginTarget -Force
if (-not [string]::IsNullOrWhiteSpace($pluginSources.Config)) {
    Copy-Item -Path $pluginSources.Config -Destination (Join-Path $configDir "config.json") -Force
}
else {
    Write-Host "WFX config.json source not found, copied plugin binary only."
}

Write-Host "WFX plugin files prepared: $pluginDir"
Write-Host "Automatic wincmd.ini modification is intentionally skipped in this version."
Write-Host ""
Write-Host "Total Commander detected."
Write-Host "Plugin files are ready in: $pluginDir"
Write-Host "To add plugin in Total Commander:"
Write-Host "Configuration -> Options -> Plugins -> File system plugins (WFX)."
