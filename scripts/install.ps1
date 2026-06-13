param(
    [string]$InstallRoot = "$env:ProgramFiles\DMS Provider",
    [string]$BridgeSetupPath,
    [string]$BrokerSetupPath,
    [string]$WfxPluginPath,
    [string]$PluginConfigPath,
    [string]$PluginLocalizePath,
    [int]$HealthTimeoutSeconds = 60,
    [string]$BridgeHealthUrl = "http://127.0.0.1:8765/health",
    [string]$BrokerHealthUrl = "http://127.0.0.1:8776/health",
    [string]$WinCmdIniPath,
    [switch]$SkipBridge,
    [switch]$SkipBroker,
    [switch]$SkipHealthCheck,
    [switch]$DisableTcRegistration
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
        "Registry::HKEY_CURRENT_USER\Software\Ghisler\Total Commander",
        "Registry::HKEY_LOCAL_MACHINE\Software\Ghisler\Total Commander",
        "Registry::HKEY_LOCAL_MACHINE\Software\WOW6432Node\Ghisler\Total Commander"
    )

    foreach ($location in $registryLocations) {
        try {
            $item = Get-ItemProperty -Path $location -ErrorAction Stop
            $iniCandidates = @(
                $item.IniFileName
                $item.Wini
                $item.WinIni
            )

            if ($item.InstallDir) {
                $iniCandidates += Join-Path $item.InstallDir "wincmd.ini"
            }

            if ($item.Path) {
                $iniCandidates += Join-Path $item.Path "wincmd.ini"
            }

            $found = Resolve-FirstExistingPath -Candidates $iniCandidates
            if (-not [string]::IsNullOrWhiteSpace($found)) {
                return $found
            }
        }
        catch {
            # Total Commander can be portable or absent.
        }
    }

    $pathCandidates = @(
        "$env:APPDATA\GHISLER\wincmd.ini",
        "$env:LOCALAPPDATA\GHISLER\wincmd.ini",
        "$env:ProgramFiles\totalcmd\wincmd.ini",
        "$env:ProgramFiles(x86)\totalcmd\wincmd.ini",
        "C:\totalcmd\wincmd.ini"
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

function Invoke-SetupInstaller {
    param(
        [string]$Name,
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "$Name setup not found: $Path"
    }

    Write-Host "Starting $Name setup: $Path"
    $process = Start-Process -FilePath $Path -ArgumentList @("/SP-", "/NORESTART") -Wait -PassThru -WindowStyle Normal
    if ($process.ExitCode -ne 0) {
        throw "$Name setup failed with exit code $($process.ExitCode)."
    }
    Write-Host "$Name setup finished."
}

function Wait-Health {
    param(
        [string]$Name,
        [string]$Url,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-RestMethod -Method Get -Uri $Url -TimeoutSec 5
            if ($response.ok -eq $true -or $response.status -eq "ok" -or $response.service) {
                Write-Host "$Name health check passed: $Url"
                return
            }
        }
        catch {
            # Child setup can still be finishing startup.
        }
        Start-Sleep -Seconds 1
    }

    throw "$Name health check did not pass within $TimeoutSeconds s: $Url"
}

if (-not (Test-IsAdministrator)) {
    throw "Install requires elevated PowerShell (Run as Administrator)."
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot

if ([string]::IsNullOrWhiteSpace($BridgeSetupPath)) {
    $BridgeSetupPath = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $scriptRoot "installers\DmsProviderBridgeSetup.exe"),
        (Join-Path $repoRoot "payload\installers\DmsProviderBridgeSetup.exe")
    )
}

if ([string]::IsNullOrWhiteSpace($BrokerSetupPath)) {
    $BrokerSetupPath = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $scriptRoot "installers\CredentialBrokerSetup.exe"),
        (Join-Path $repoRoot "payload\installers\CredentialBrokerSetup.exe")
    )
}

if ([string]::IsNullOrWhiteSpace($WfxPluginPath)) {
    $WfxPluginPath = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $scriptRoot "tc-wfx\TcWfxPlugin.wfx64"),
        (Join-Path $repoRoot "payload\tc-wfx\TcWfxPlugin.wfx64"),
        (Join-Path $repoRoot "payload\TcWfxPlugin.wfx64")
    )
}

if ([string]::IsNullOrWhiteSpace($PluginConfigPath)) {
    $PluginConfigPath = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $scriptRoot "tc-wfx\config.json"),
        (Join-Path $repoRoot "payload\tc-wfx\config.json"),
        (Join-Path $repoRoot "payload\config.json")
    )
}

if ([string]::IsNullOrWhiteSpace($PluginLocalizePath)) {
    $PluginLocalizePath = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $scriptRoot "tc-wfx\localize.json"),
        (Join-Path $scriptRoot "tc-wfx\config\localize.json"),
        (Join-Path $repoRoot "payload\tc-wfx\localize.json"),
        (Join-Path $repoRoot "payload\tc-wfx\config\localize.json")
    )
}

if (-not $SkipBridge) {
    Invoke-SetupInstaller -Name "DMS Provider Bridge" -Path $BridgeSetupPath
}
else {
    Write-Host "Bridge setup skipped."
}

if (-not $SkipBroker) {
    Invoke-SetupInstaller -Name "Credential Broker" -Path $BrokerSetupPath
}
else {
    Write-Host "Credential Broker setup skipped."
}

if ([string]::IsNullOrWhiteSpace($WfxPluginPath) -or -not (Test-Path $WfxPluginPath)) {
    throw "WFX plugin not found: $WfxPluginPath"
}

if ([string]::IsNullOrWhiteSpace($PluginConfigPath) -or -not (Test-Path $PluginConfigPath)) {
    throw "Plugin config not found: $PluginConfigPath"
}

$wfxRoot = Join-Path $InstallRoot "tc-wfx"
$wfxConfigRoot = Join-Path $wfxRoot "config"
$pluginTargetPath = Join-Path $wfxRoot "TcWfxPlugin.wfx64"
$pluginConfigTargetPath = Join-Path $wfxRoot "config.json"
$pluginNestedConfigTargetPath = Join-Path $wfxConfigRoot "config.json"
$pluginLocalizeTargetPath = Join-Path $wfxConfigRoot "localize.json"

New-Item -ItemType Directory -Path $wfxRoot -Force | Out-Null
New-Item -ItemType Directory -Path $wfxConfigRoot -Force | Out-Null

Copy-Item -Path $WfxPluginPath -Destination $pluginTargetPath -Force
Copy-Item -Path $PluginConfigPath -Destination $pluginConfigTargetPath -Force
Copy-Item -Path $PluginConfigPath -Destination $pluginNestedConfigTargetPath -Force
if (-not [string]::IsNullOrWhiteSpace($PluginLocalizePath) -and (Test-Path $PluginLocalizePath)) {
    Copy-Item -Path $PluginLocalizePath -Destination $pluginLocalizeTargetPath -Force
}

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

if (-not $SkipHealthCheck) {
    if (-not $SkipBridge) {
        Wait-Health -Name "Bridge" -Url $BridgeHealthUrl -TimeoutSeconds $HealthTimeoutSeconds
    }
    if (-not $SkipBroker) {
        Wait-Health -Name "Credential Broker" -Url $BrokerHealthUrl -TimeoutSeconds $HealthTimeoutSeconds
    }
}

Write-Host ""
Write-Host "DMS Provider orchestration summary"
Write-Host "Install root:       $InstallRoot"
Write-Host "Bridge setup:       $(if ($SkipBridge) { 'skipped' } else { $BridgeSetupPath })"
Write-Host "Broker setup:       $(if ($SkipBroker) { 'skipped' } else { $BrokerSetupPath })"
Write-Host "WFX plugin:         $pluginTargetPath"
Write-Host "WFX config:         $pluginConfigTargetPath"
Write-Host "WFX localization:   $(if (Test-Path $pluginLocalizeTargetPath) { $pluginLocalizeTargetPath } else { 'not installed' })"
Write-Host "Bridge health:      $BridgeHealthUrl"
Write-Host "Broker health:      $BrokerHealthUrl"
Write-Host "Install finished."
