@echo off
REM SimpleDaily Build Script for Windows

echo Building SimpleDaily for Windows...
flutter build windows --release

echo Build completed.
echo Functionality to create an installer (e.g. Inno Setup) would go here.
echo For now, the executable is located in: build\windows\runner\Release\simple_daily.exe

REM Optional: Create a ZIP (requires 7-Zip or PowerShell command)
REM powershell Compress-Archive -Path build\windows\runner\Release\* -DestinationPath build\windows\simple_daily_windows.zip -Force
