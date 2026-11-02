@echo off
chcp 65001 >nul
cd /d "%~dp0"
title BlackOcean Server

:loop
echo.
echo [1/2] 모드 업데이트 확인 중...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; try { Invoke-WebRequest -UseBasicParsing -Uri ('https://raw.githubusercontent.com/summim/blackocean-pack/main/server-tools/server-update.ps1?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -OutFile '.blackocean-update.ps1' -TimeoutSec 30 } catch { }"
if exist ".blackocean-update.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File ".blackocean-update.ps1"
) else (
  echo 업데이트 도구를 못 받았어요. 지금 모드 그대로 켭니다.
)

echo.
echo [2/2] 서버 시작
set "ARGS="
for /d %%d in ("libraries\net\neoforged\neoforge\*") do set "ARGS=%%d\win_args.txt"
if not defined ARGS (
  echo [오류] NeoForge 서버 파일을 못 찾았어요. 이 파일을 서버 폴더(run.bat 이 있는 곳)에 넣어 주세요.
  pause
  exit /b 1
)
if exist user_jvm_args.txt (
  java @user_jvm_args.txt @%ARGS% nogui
) else (
  java @%ARGS% nogui
)

echo.
echo 서버가 꺼졌어요. 10초 뒤 업데이트 확인 후 다시 켭니다.
echo 완전히 끄려면 지금 이 창을 닫거나 Ctrl+C 를 누르세요.
timeout /t 10
goto loop
