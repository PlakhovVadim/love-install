# Love.css installer for Windows PowerShell.
# Adds the love command to PATH and optionally clones love-css.

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LoveCmd = Join-Path $ScriptDir 'bin\love.cmd'

if (-not (Test-Path $LoveCmd)) {
    Write-Error 'install.ps1: bin\love.cmd not found. Run from the repository root.'
    exit 1
}

# Verify Git Bash availability.
$bash = Get-Command bash.exe -ErrorAction SilentlyContinue
if (-not $bash) {
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $bash = Get-Item $c; break }
    }
}
if (-not $bash) {
    Write-Error 'install.ps1: Git Bash not found. Install Git for Windows: https://git-scm.com/download/win'
    exit 1
}
Write-Host "install.ps1: Git Bash found: $($bash.Source)"

# Add the bin directory to the user PATH.
$BinDir = Join-Path $ScriptDir 'bin'
$UserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if ($UserPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;$BinDir", 'User')
    Write-Host "install.ps1: added $BinDir to user PATH"
} else {
    Write-Host "install.ps1: $BinDir already in user PATH"
}

# Create a shim in WindowsApps for immediate availability.
$ShimDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
if (Test-Path $ShimDir) {
    Copy-Item $LoveCmd (Join-Path $ShimDir 'love.cmd') -Force
    Write-Host "install.ps1: shim created in $ShimDir"
} else {
    Write-Host "install.ps1: WindowsApps directory not found, skipping shim"
}

# Optional: clone love-css.
Write-Host ''
$answer = Read-Host 'Clone love-css into the current directory? [y/N]'
if ($answer -match '^[yY]') {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $dest = Join-Path (Get-Location) 'love-css'
        if (Test-Path $dest) {
            Write-Host "install.ps1: $dest already exists, skipping"
        } else {
            git clone --depth=1 https://github.com/PlakhovVadim/love-css.git $dest
            Write-Host "install.ps1: love-css cloned into $dest"
        }
    } else {
        Write-Warning 'install.ps1: git not found, skipping clone'
    }
} else {
    Write-Host 'install.ps1: skipping love-css clone'
}

Write-Host ''
Write-Host 'install.ps1: done. Restart your terminal and run: love status'
