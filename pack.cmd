@echo off

setlocal enabledelayedexpansion

set BASE_DIR=HappyButton

set ZIPFILE=%BASE_DIR%-Beta-0.2.3.zip
set TEMP_DIR=%BASE_DIR%

mkdir "%TEMP_DIR%"

:: use robocpy copy file exculde some dir
robocopy . "%TEMP_DIR%" /E /XD ".git" ".idea" ".vscode" "Script" "%TEMP_DIR%" /XF "pack.cmd"

:: use 7zip 
7z a -tzip "%ZIPFILE%" "%TEMP_DIR%\*"

rd /S /Q "%TEMP_DIR%"

if exist "%ZIPFILE%" (
    echo success: %ZIPFILE%
) else (
    echo error
)

echo.
echo type any to exist...
pause >nul

endlocal