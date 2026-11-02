@echo off
rem BlackOcean server launcher. Keep this file ASCII-only (Korean text here breaks cmd parsing).
rem All real work is in server-start.ps1, which is downloaded fresh on every start.
cd /d "%~dp0"
title BlackOcean Server
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; $ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri ('https://raw.githubusercontent.com/summim/blackocean-pack/main/server-tools/server-start.ps1?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -OutFile '.blackocean-start.tmp' -TimeoutSec 30; Move-Item -Force '.blackocean-start.tmp' '.blackocean-start.ps1' } catch { Write-Host 'Could not download the latest start script. Using the saved copy.' }"
if not exist ".blackocean-start.ps1" goto nostart
powershell -NoProfile -ExecutionPolicy Bypass -File ".blackocean-start.ps1"
echo.
pause
exit /b 0

:nostart
echo.
echo Could not download the start script. Check the internet connection and try again.
pause
exit /b 1
