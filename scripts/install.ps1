param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramFiles\\DMS Provider",
    [string]$BridgeExePath,
    [string]$NssmExePath,
    [int]$HealthTimeoutSeconds = 30,
    [string]$HealthUrl = "http://127.0.0.1:8765/health"
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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

if ([string]::IsNullOrWhiteSpace($BridgeExePath)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = Split-Path -Parent $scriptRoot
    $BridgeExePath = Join-Path $repoRoot "payload\\dms-provider-bridge.exe"
}

if (-not (Test-Path $BridgeExePath)) {
    throw "Bridge executable not found: $BridgeExePath"
}

$bridgeExeTargetPath = Join-Path $InstallRoot "dms-provider-bridge.exe"
$bridgeLogs = Join-Path $InstallRoot "logs"
$stdoutLog = Join-Path $bridgeLogs "bridge-stdout.log"
$stderrLog = Join-Path $bridgeLogs "bridge-stderr.log"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bridgeLogs -Force | Out-Null

Copy-Item -Path $BridgeExePath -Destination $bridgeExeTargetPath -Force

& $NssmExePath stop $ServiceName | Out-Null 2>&1
& $NssmExePath remove $ServiceName confirm | Out-Null 2>&1

& $NssmExePath install $ServiceName $bridgeExeTargetPath
& $NssmExePath set $ServiceName AppDirectory $InstallRoot
& $NssmExePath set $ServiceName AppStdout $stdoutLog
& $NssmExePath set $ServiceName AppStderr $stderrLog
& $NssmExePath set $ServiceName Start SERVICE_AUTO_START
& $NssmExePath start $ServiceName
Wait-BridgeHealth -Url $HealthUrl -TimeoutSeconds $HealthTimeoutSeconds

Write-Host ""
Write-Host "Bridge runtime summary"
Write-Host "Bridge URL:     $HealthUrl"
Write-Host "Service:        $ServiceName"
Write-Host "Install root:   $InstallRoot"
Write-Host "Bridge exe:     $bridgeExeTargetPath"
Write-Host "Logs:           $bridgeLogs"

Write-Host "Install finished. Service: $ServiceName"
Write-Host "Bridge exe: $bridgeExeTargetPath"
Write-Host "Logs: $bridgeLogs"
