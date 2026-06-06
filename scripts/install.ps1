param(
    [string]$ServiceName = "DmsProviderBridge",
    [string]$InstallRoot = "$env:ProgramFiles\\DMS Provider",
    [string]$BridgeExePath,
    [string]$WfxPluginPath,
    [string]$PluginConfigPath,
    [string]$NssmExePath,
    [int]$HealthTimeoutSeconds = 30,
    [string]$HealthUrl = "http://127.0.0.1:8765/health",
    [string]$WinCmdIniPath,
    [switch]$DisableTcRegistration
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

function Resolve-FirstExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Resolve-TcWinCmdIniPath {
    param([string]$ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath) -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }

    $registryLocations = @(
        "Registry::HKEY_CURRENT_USER\\Software\\Ghisler\\Total Commander",
        "Registry::HKEY_LOCAL_MACHINE\\Software\\Ghisler\\Total Commander",
        "Registry::HKEY_LOCAL_MACHINE\\Software\\WOW6432Node\\Ghisler\\Total Commander"
    )

    foreach ($location in $registryLocations) {
        try {
            $item = Get-ItemProperty -Path $location -ErrorAction Stop
            $iniCandidates = @(
                $item.IniFileName,
                $item.Wini,
                $item.WinIni,
                if ($item.InstallDir) { Join-Path $item.InstallDir "wincmd.ini" },
                if ($item.Path) { Join-Path $item.Path "wincmd.ini" }
            )

            $found = Resolve-FirstExistingPath -Candidates $iniCandidates
            if (-not [string]::IsNullOrWhiteSpace($found)) {
                return $found
            }
        }
        catch {
            # Key can be missing depending on installation type.
        }
    }

    $pathCandidates = @(
        "$env:APPDATA\\GHISLER\\wincmd.ini",
        "$env:LOCALAPPDATA\\GHISLER\\wincmd.ini",
        "$env:ProgramFiles\\totalcmd\\wincmd.ini",
        "$env:ProgramFiles(x86)\\totalcmd\\wincmd.ini",
        "C:\\totalcmd\\wincmd.ini"
    )

    return Resolve-FirstExistingPath -Candidates $pathCandidates
}

function Backup-File {
    param([string]$Path)

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$Path.$stamp.bak"
    Copy-Item -Path $Path -Destination $backupPath -Force
    return $backupPath
}

function Register-WfxPlugin {
    param(
        [string]$IniPath,
        [string]$PluginPath
    )

    $entryLine = "DMS Provider=$PluginPath"
    $sectionName = "[FileSystemPlugins64]"

    $lines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $IniPath) {
        foreach ($line in (Get-Content -Path $IniPath)) {
            [void]$lines.Add($line)
        }
    }

    $sectionIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -ieq $sectionName) {
            $sectionIndex = $i
            break
        }
    }

    if ($sectionIndex -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim().Length -gt 0) {
            [void]$lines.Add("")
        }
        [void]$lines.Add($sectionName)
        [void]$lines.Add($entryLine)
    }
    else {
        $nextSectionIndex = $lines.Count
        for ($i = $sectionIndex + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -match "^\[.+\]$") {
                $nextSectionIndex = $i
                break
            }
        }

        $entryIndex = -1
        for ($i = $sectionIndex + 1; $i -lt $nextSectionIndex; $i++) {
            if ($lines[$i].Trim() -match "^DMS Provider\s*=") {
                $entryIndex = $i
                break
            }
        }

        if ($entryIndex -ge 0) {
            $lines[$entryIndex] = $entryLine
        }
        else {
            $lines.Insert($nextSectionIndex, $entryLine)
        }
    }

    Set-Content -Path $IniPath -Value $lines -Encoding ASCII
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
    if ([string]::IsNullOrWhiteSpace($WfxPluginPath)) {
        $WfxPluginPath = Join-Path $repoRoot "payload\\TcWfxPlugin.wfx64"
    }
    if ([string]::IsNullOrWhiteSpace($PluginConfigPath)) {
        $PluginConfigPath = Join-Path $repoRoot "payload\\config.json"
    }
}

if (-not (Test-Path $BridgeExePath)) {
    throw "Bridge executable not found: $BridgeExePath"
}

if ([string]::IsNullOrWhiteSpace($WfxPluginPath) -or -not (Test-Path $WfxPluginPath)) {
    throw "WFX plugin not found: $WfxPluginPath"
}

if ([string]::IsNullOrWhiteSpace($PluginConfigPath) -or -not (Test-Path $PluginConfigPath)) {
    throw "Plugin config not found: $PluginConfigPath"
}

$bridgeExeTargetPath = Join-Path $InstallRoot "dms-provider-bridge.exe"
$pluginTargetPath = Join-Path $InstallRoot "TcWfxPlugin.wfx64"
$pluginConfigTargetPath = Join-Path $InstallRoot "config.json"
$pluginConfigDir = Join-Path $InstallRoot "config"
$pluginConfigDirTargetPath = Join-Path $pluginConfigDir "config.json"
$bridgeLogs = Join-Path $InstallRoot "logs"
$stdoutLog = Join-Path $bridgeLogs "bridge-stdout.log"
$stderrLog = Join-Path $bridgeLogs "bridge-stderr.log"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bridgeLogs -Force | Out-Null
New-Item -ItemType Directory -Path $pluginConfigDir -Force | Out-Null

Copy-Item -Path $BridgeExePath -Destination $bridgeExeTargetPath -Force
Copy-Item -Path $WfxPluginPath -Destination $pluginTargetPath -Force
Copy-Item -Path $PluginConfigPath -Destination $pluginConfigTargetPath -Force
Copy-Item -Path $PluginConfigPath -Destination $pluginConfigDirTargetPath -Force

& $NssmExePath stop $ServiceName | Out-Null 2>&1
& $NssmExePath remove $ServiceName confirm | Out-Null 2>&1

& $NssmExePath install $ServiceName $bridgeExeTargetPath
& $NssmExePath set $ServiceName AppDirectory $InstallRoot
& $NssmExePath set $ServiceName AppStdout $stdoutLog
& $NssmExePath set $ServiceName AppStderr $stderrLog
& $NssmExePath set $ServiceName Start SERVICE_AUTO_START
& $NssmExePath start $ServiceName
Wait-BridgeHealth -Url $HealthUrl -TimeoutSeconds $HealthTimeoutSeconds

if (-not $DisableTcRegistration) {
    $resolvedIniPath = Resolve-TcWinCmdIniPath -ExplicitPath $WinCmdIniPath
    if (-not [string]::IsNullOrWhiteSpace($resolvedIniPath)) {
        $iniBackup = Backup-File -Path $resolvedIniPath
        Register-WfxPlugin -IniPath $resolvedIniPath -PluginPath $pluginTargetPath
        Write-Host "Total Commander plugin registration updated: $resolvedIniPath"
        Write-Host "Backup created: $iniBackup"
    }
    else {
        Write-Host "Total Commander config not found."
        Write-Host "Manual registration path: $pluginTargetPath"
    }
}
else {
    Write-Host "Automatic Total Commander registration disabled."
    Write-Host "Manual registration path: $pluginTargetPath"
}

Write-Host ""
Write-Host "Bridge runtime summary"
Write-Host "Bridge URL:     $HealthUrl"
Write-Host "Service:        $ServiceName"
Write-Host "Install root:   $InstallRoot"
Write-Host "Bridge exe:     $bridgeExeTargetPath"
Write-Host "WFX plugin:     $pluginTargetPath"
Write-Host "Plugin config:  $pluginConfigTargetPath"
Write-Host "Logs:           $bridgeLogs"

Write-Host "Install finished. Service: $ServiceName"
Write-Host "Bridge exe: $bridgeExeTargetPath"
Write-Host "Logs: $bridgeLogs"
