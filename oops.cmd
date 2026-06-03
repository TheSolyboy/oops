@echo off
REM oops - fix your last shell command with AI (CMD edition).
REM Delegates the network/JSON work to oops.ps1; handles history + running here.
REM https://github.com/TheSolyboy/oops
setlocal EnableDelayedExpansion

set "subcmd=%~1"
if /i "%subcmd%"=="config"   goto :passthrough
if /i "%subcmd%"=="model"    goto :passthrough
if /i "%subcmd%"=="provider" goto :passthrough
if /i "%subcmd%"=="help"     goto :help
if /i "%subcmd%"=="-h"       goto :help
if /i "%subcmd%"=="/?"       goto :help
if /i "%subcmd%"=="version"  goto :version
if /i "%subcmd%"=="-v"       goto :version

REM --- find the last non-oops command in this console's history ---
set "lastcmd="
for /f "delims=" %%L in ('doskey /history 2^>nul') do (
  set "line=%%L"
  echo(!line!| findstr /i /b /c:"oops" >nul
  if errorlevel 1 set "lastcmd=!line!"
)
if not defined lastcmd (
  echo oops: could not find a previous command in history.>&2
  endlocal & exit /b 1
)

echo oops: re-running "!lastcmd!" to capture the error...>&2
set "errfile=%TEMP%\oops_err_%RANDOM%%RANDOM%.txt"
cmd /c !lastcmd! > "!errfile!" 2>&1

echo oops: asking the AI...>&2
set "fix="
for /f "usebackq delims=" %%F in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0oops.ps1" -Fix -Command "!lastcmd!" -ErrorPath "!errfile!"`) do set "fix=%%F"
del "!errfile!" 2>nul

if not defined fix (
  echo oops: no suggestion returned.>&2
  endlocal & exit /b 1
)

echo oops: !fix!
set /p "ans=Run it? [Y/n] "
if /i "!ans!"=="n"  goto :cancel
if /i "!ans!"=="no" goto :cancel
REM %fix% is substituted now (in scope); endlocal then runs it in the parent env.
endlocal & %fix%
exit /b %errorlevel%

:cancel
echo oops: cancelled.
endlocal & exit /b 1

:help
echo oops - fix your last shell command with AI
echo.
echo usage:
echo   oops                  fix the last command that failed
echo   oops config           re-run the interactive setup
echo   oops model ^<name^>     switch the model
echo   oops provider ^<name^>  switch provider (anthropic^|openrouter^|ollama^|opencode)
echo   oops help             show this help
echo   oops version          show the version
endlocal & exit /b 0

:version
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'oops 0.1.0'"
endlocal & exit /b 0

:passthrough
REM config / model / provider need the interactive PowerShell setup
powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0oops.ps1'; oops %*"
endlocal & exit /b %errorlevel%
