param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$BridgeSetupRelativePath,
    [string]$CredentialBrokerRepoPath = "..\credential-broker",
    [string]$TcPluginRepoPath = "..\tc-wfx-plugin",
    [string]$InnoCompilerPath,
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"

function Resolve-IsccPath {
    param([string]$ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath) -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }

    $candidates = @(
        "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
$preparePayloadScript = Join-Path $scriptRoot "prepare-payload.ps1"
$issPath = Join-Path $repoRoot "installer.iss"

if (-not (Test-Path $preparePayloadScript)) {
    throw "prepare-payload.ps1 not found: $preparePayloadScript"
}

if (-not (Test-Path $issPath)) {
    throw "installer.iss not found: $issPath"
}

$prepareParams = @{
    BridgeRepoPath = $BridgeRepoPath
    CredentialBrokerRepoPath = $CredentialBrokerRepoPath
    TcPluginRepoPath = $TcPluginRepoPath
}

if (-not [string]::IsNullOrWhiteSpace($BridgeSetupRelativePath)) {
    $prepareParams.BridgeSetupRelativePath = $BridgeSetupRelativePath
}

& $preparePayloadScript @prepareParams
if (-not $?) {
    throw "prepare-payload.ps1 failed."
}

Write-Host "Payload prepared for Inno Setup build."

if ($SkipCompile) {
    Write-Host "SkipCompile enabled, not invoking ISCC.exe."
    return
}

$iscc = Resolve-IsccPath -ExplicitPath $InnoCompilerPath
if ([string]::IsNullOrWhiteSpace($iscc)) {
    throw "Inno Setup compiler (ISCC.exe) not found. Install Inno Setup 6 or provide -InnoCompilerPath."
}

Push-Location $repoRoot
try {
    & $iscc $issPath
    if ($LASTEXITCODE -ne 0) {
        throw "ISCC build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "DMS Provider orchestrator installer build completed."
Write-Host "Output directory: $(Join-Path $repoRoot 'artifacts\installer')"
