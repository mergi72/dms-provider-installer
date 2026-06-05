param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramData\\DmsProviderBridge",
    [string]$BridgeSourceRepoPath,
    [string]$BridgeReleaseZipPath,
    [string]$WfxPluginBinaryPath,
    [string]$WfxPluginTargetPath = "$env:APPDATA\\GHISLER\\Plugins\\wfx\\TcWfxPlugin\\TcWfxPlugin.wfx64",
    [string]$NssmExePath
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Require-Command([string]$name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Command not found: $name"
    }
    return $cmd.Source
}

if (-not (Test-IsAdministrator)) {
    throw "Install requires elevated PowerShell (Run as Administrator)."
}

if ([string]::IsNullOrWhiteSpace($NssmExePath) -or -not (Test-Path $NssmExePath)) {
    throw "NSSM executable not found. Provide -NssmExePath."
}

if ([string]::IsNullOrWhiteSpace($BridgeSourceRepoPath) -and [string]::IsNullOrWhiteSpace($BridgeReleaseZipPath)) {
    throw "Provide either -BridgeSourceRepoPath or -BridgeReleaseZipPath."
}

$pythonExe = Require-Command "python"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$bridgeRoot = Join-Path $InstallRoot "bridge"
$bridgeLogs = Join-Path $InstallRoot "logs"
$configDir = Join-Path $bridgeRoot "config"
$venvDir = Join-Path $bridgeRoot ".venv312"
$venvPython = Join-Path $venvDir "Scripts\\python.exe"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bridgeLogs -Force | Out-Null

if (Test-Path $bridgeRoot) {
    Remove-Item -Path $bridgeRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $bridgeRoot -Force | Out-Null

if (-not [string]::IsNullOrWhiteSpace($BridgeReleaseZipPath)) {
    if (-not (Test-Path $BridgeReleaseZipPath)) {
        throw "Bridge release ZIP not found: $BridgeReleaseZipPath"
    }
    Expand-Archive -Path $BridgeReleaseZipPath -DestinationPath $bridgeRoot -Force
}
else {
    if (-not (Test-Path $BridgeSourceRepoPath)) {
        throw "Bridge source repo path not found: $BridgeSourceRepoPath"
    }

    robocopy $BridgeSourceRepoPath $bridgeRoot /E /NFL /NDL /NJH /NJS /NP /XD .git .venv .venv312 artifacts .pytest_cache .mypy_cache
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with code $LASTEXITCODE"
    }
}

& $pythonExe -m venv $venvDir
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create venv at $venvDir"
}

Push-Location $bridgeRoot
try {
    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed" }

    & $venvPython -m pip install -e .
    if ($LASTEXITCODE -ne 0) { throw "bridge dependency install failed" }
}
finally {
    Pop-Location
}

New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$userLocalPath = Join-Path $configDir "user.local.json"
$templatePath = Join-Path $repoRoot "templates\\user.local.json"
if (-not (Test-Path $userLocalPath)) {
    Copy-Item -Path $templatePath -Destination $userLocalPath -Force
}

& $NssmExePath stop $ServiceName | Out-Null
& $NssmExePath remove $ServiceName confirm | Out-Null

$appArgs = "-m uvicorn dms_provider_bridge.app.server:app --app-dir src --host 127.0.0.1 --port 8765"
& $NssmExePath install $ServiceName $venvPython $appArgs
& $NssmExePath set $ServiceName AppDirectory $bridgeRoot
& $NssmExePath set $ServiceName AppStdout (Join-Path $bridgeLogs "bridge-stdout.log")
& $NssmExePath set $ServiceName AppStderr (Join-Path $bridgeLogs "bridge-stderr.log")
& $NssmExePath set $ServiceName Start SERVICE_AUTO_START
& $NssmExePath start $ServiceName

if (-not [string]::IsNullOrWhiteSpace($WfxPluginBinaryPath)) {
    if (-not (Test-Path $WfxPluginBinaryPath)) {
        throw "WFX plugin binary not found: $WfxPluginBinaryPath"
    }

    $wfxTargetDir = Split-Path -Parent $WfxPluginTargetPath
    New-Item -ItemType Directory -Path $wfxTargetDir -Force | Out-Null
    Copy-Item -Path $WfxPluginBinaryPath -Destination $WfxPluginTargetPath -Force
}

Write-Host "Install finished. Service: $ServiceName"
Write-Host "Bridge root: $bridgeRoot"
Write-Host "Logs: $bridgeLogs"
