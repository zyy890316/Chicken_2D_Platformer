@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" set "GODOT="
if not defined GODOT (
  for /f "delims=" %%i in ('where godot 2^>nul') do (
    set "GODOT=%%i"
    goto :export
  )
)

:export
if not defined GODOT goto :missing
if not exist "%GODOT%" goto :missing

if not exist "build\web" mkdir "build\web"
echo Exporting Web build to build\web ...
"%GODOT%" --headless --path "." --export-release "Web" "build/web/index.html"
if errorlevel 1 (
  echo.
  echo Export failed. In Godot: Editor - Manage Export Templates - download 4.7.2.
  echo Then run this script again.
  pause
  exit /b 1
)

echo.
echo Serve the folder over HTTPS or localhost, then open it on the phone:
echo   python -m http.server -d build\web 8080
echo iPhone cannot load file:// pages. Use the same Wi-Fi and visit http://YOUR-PC-IP:8080
exit /b 0

:missing
echo Godot not found.
echo Install with: winget install GodotEngine.GodotEngine
pause
exit /b 1
