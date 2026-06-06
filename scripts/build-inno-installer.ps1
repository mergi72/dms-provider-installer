param(
    [string]$BridgeRepoPath = "..\dms-provider-bridge",
    [string]$TcPluginRepoPath = "..\tc-wfx-plugin",
    [string]$NssmExePath,
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
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Resolve-NssmPath {
    param([string]$ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath) -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }

    $candidates = @(
        "C:\\tools\\nssm\\win64\\nssm.exe",
        "C:\\tools\\nssm\\nssm.exe",
        "$env:ProgramFiles\\nssm\\nssm.exe",
        "$env:ProgramFiles(x86)\\nssm\\nssm.exe"
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

$resolvedNssmPath = Resolve-NssmPath -ExplicitPath $NssmExePath
if ([string]::IsNullOrWhiteSpace($resolvedNssmPath)) {
    throw "NSSM executable not found. Provide -NssmExePath."
}

& $preparePayloadScript -BridgeRepoPath $BridgeRepoPath -TcPluginRepoPath $TcPluginRepoPath
if (-not $?) {
    throw "prepare-payload.ps1 failed."
}

$payloadDir = Join-Path $repoRoot "payload"
$payloadNssmPath = Join-Path $payloadDir "nssm.exe"
$resolvedNssmSourcePath = (Resolve-Path $resolvedNssmPath).Path
$resolvedNssmTargetPath = $null
if (Test-Path $payloadNssmPath) {
    $resolvedNssmTargetPath = (Resolve-Path $payloadNssmPath).Path
}

if ($resolvedNssmSourcePath -ne $resolvedNssmTargetPath) {
    Copy-Item -Path $resolvedNssmPath -Destination $payloadNssmPath -Force
}

Write-Host "Payload prepared for Inno Setup build."
Write-Host "NSSM copied: $payloadNssmPath"

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

Write-Host "Inno Setup installer build completed."
Write-Host "Output directory: $(Join-Path $repoRoot 'artifacts\installer')"
