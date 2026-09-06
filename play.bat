@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT="
if not defined GODOT (
  for /f "delims=" %%i in ('where godot 2^>nul') do (
    set "GODOT=%%i"
    goto :launch
  )
)

:launch
if not defined GODOT goto :missing
if not exist "%GODOT%" goto :missing

start "" "%GODOT%" --path "."
exit /b 0

:missing
echo Godot not found.
echo Install with: winget install GodotEngine.GodotEngine
echo.
pause
exit /b 1
