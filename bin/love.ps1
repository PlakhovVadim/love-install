# Love.css CLI wrapper for Windows PowerShell.
# This script locates Git Bash and forwards all arguments to bin/love.
# It contains no logic — only the path discovery and invocation.

$ErrorActionPreference = 'Stop'

$LoveBin = Join-Path $PSScriptRoot 'love'

function Find-GitBash {
    $candidates = @(
        'bash.exe',
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($candidate in $candidates) {
        $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.Source }
    }
    return $null
}

$BashExe = Find-GitBash
if (-not $BashExe) {
    Write-Error 'love: Git Bash not found. Install Git for Windows: https://git-scm.com/download/win'
    exit 1
}

# Convert the Windows path to a POSIX path usable by Git Bash.
$LovePosix = & $BashExe -c "cygpath -u '$LoveBin'"
if ($LASTEXITCODE -ne 0) {
    Write-Error 'love: failed to resolve script path.'
    exit 1
}

& $BashExe -l -c "`"$LovePosix`" $args"
exit $LASTEXITCODE
