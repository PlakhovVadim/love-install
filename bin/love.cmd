@echo off
REM Love.css CLI wrapper for Windows Command Prompt.
REM This script locates Git Bash and forwards all arguments to bin/love.
REM It contains no logic — only the path discovery and invocation.

setlocal enabledelayedexpansion

set "LOVE_BIN=%~dp0"
set "BASH_EXE="

REM Try bash from PATH first.
for %%I in (bash.exe) do (
    if not "%%~$PATH:I"=="" set "BASH_EXE=%%~$PATH:I"
)

REM Fall back to standard Git for Windows locations.
if not defined BASH_EXE (
    if exist "%ProgramFiles%\Git\bin\bash.exe" (
        set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
    )
)
if not defined BASH_EXE (
    if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
        set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"
    )
)
if not defined BASH_EXE (
    if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" (
        set "BASH_EXE=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
    )
)

if not defined BASH_EXE (
    echo love: Git Bash not found. Install Git for Windows: https://git-scm.com/download/win >&2
    exit /b 1
)

REM Convert Windows path to a POSIX path that Git Bash understands.
for /f "delims=" %%I in ('"%BASH_EXE%" -c "cygpath -u \"%LOVE_BIN%love\""') do set "LOVE_POSIX=%%I"

"%BASH_EXE%" -l -c "\"%LOVE_POSIX%\" %*"
exit /b %ERRORLEVEL%
