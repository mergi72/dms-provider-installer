param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramData\\DmsProviderBridge",
    [string]$BridgeSourceRepoPath,
    [string]$BridgeReleaseZipPath,
    [string]$WfxPluginBinaryPath,
    [string]$WfxPluginTargetPath = "$env:APPDATA\\GHISLER\\Plugins\\wfx\\TcWfxPlugin\\TcWfxPlugin.wfx64",
    [string]$NssmExePath,
    [int]$MinPythonMajor = 3,
    [int]$MinPythonMinor = 11,
    [int]$HealthTimeoutSeconds = 30,
    [string]$HealthUrl = "http://127.0.0.1:8765/health"
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

function Get-PythonVersionInfo([string]$pythonPath) {
    $versionOutput = & $pythonPath --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read Python version from: $pythonPath"
    }

    $versionText = ($versionOutput | Out-String).Trim()
    Write-Host "Using Python: $versionText"

    if ($versionText -notmatch "Python\s+(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)") {
        throw "Unexpected Python version format: $versionText"
    }

    return @{
        Major = [int]$Matches["major"]
        Minor = [int]$Matches["minor"]
        Patch = [int]$Matches["patch"]
        Text = $versionText
    }
}

function Assert-MinPythonVersion {
    param(
        [hashtable]$VersionInfo,
        [int]$RequiredMajor,
        [int]$RequiredMinor
    )

    $isTooOld = $VersionInfo.Major -lt $RequiredMajor -or ($VersionInfo.Major -eq $RequiredMajor -and $VersionInfo.Minor -lt $RequiredMinor)
    if ($isTooOld) {
        throw "Python $RequiredMajor.$RequiredMinor+ is required, detected $($VersionInfo.Text)"
    }
}

function Wait-BridgeHealth {
    param(
        [string]$Url,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Url -TimeoutSec 5
            if ($response.status -eq "ok") {
                Write-Host "Bridge health check passed: $Url"
                return
            }
        }
        catch {
            # Service can still be starting up.
        }

        Start-Sleep -Seconds 1
    }

    throw "Bridge health check did not pass within $TimeoutSeconds s: $Url"
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
$pythonVersion = Get-PythonVersionInfo -pythonPath $pythonExe
Assert-MinPythonVersion -VersionInfo $pythonVersion -RequiredMajor $MinPythonMajor -RequiredMinor $MinPythonMinor

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$bridgeRoot = Join-Path $InstallRoot "bridge"
$bridgeLogs = Join-Path $InstallRoot "logs"
$configDir = Join-Path $bridgeRoot "config"
$venvDir = Join-Path $bridgeRoot ".venv312"
$venvPython = Join-Path $venvDir "Scripts\\python.exe"
$backupRoot = Join-Path $InstallRoot "backup"
$backupUserLocalPath = Join-Path $backupRoot "user.local.json"
$existingUserLocalPath = Join-Path $bridgeRoot "config\\user.local.json"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bridgeLogs -Force | Out-Null
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

if (Test-Path $bridgeRoot) {
    if (Test-Path $existingUserLocalPath) {
        Copy-Item -Path $existingUserLocalPath -Destination $backupUserLocalPath -Force
        Write-Host "Backed up existing config: $existingUserLocalPath -> $backupUserLocalPath"
    }

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
if (Test-Path $backupUserLocalPath) {
    Copy-Item -Path $backupUserLocalPath -Destination $userLocalPath -Force
    Write-Host "Restored user local config from backup: $userLocalPath"
}
elseif (-not (Test-Path $userLocalPath)) {
    Copy-Item -Path $templatePath -Destination $userLocalPath -Force
    Write-Host "Created user local config from template: $userLocalPath"
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
Wait-BridgeHealth -Url $HealthUrl -TimeoutSeconds $HealthTimeoutSeconds

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
