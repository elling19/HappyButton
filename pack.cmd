@echo off

setlocal enabledelayedexpansion

set BASE_DIR=HappyButton-0.0.5

set ZIPFILE=%BASE_DIR%.zip
set TEMP_DIR=%BASE_DIR%

mkdir "%TEMP_DIR%\HappyButton"

:: use robocpy copy file exculde some dir
robocopy . "%TEMP_DIR%\HappyButton" /E /XD ".git" ".idea" ".vscode" "%TEMP_DIR%" "HappyButton" /XF "pack.cmd"

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