@echo off
if "%~1"=="" (
    echo Usage: obfuscate.bat file1.lua [file2.lua file3.lua ...]
    echo Output: file1.obfuscated.lua [file2.obfuscated.lua ...]
    echo.
    echo You can drag and drop multiple .lua files onto this bat file.
    pause
    exit /b 1
)

set "FILES="
set "COUNT=0"
:loop
if "%~1"=="" goto run
set "FILES=%FILES% "%~1""
set /a COUNT+=1
shift
goto loop

:run
lua5.1.exe cli.lua --config custom_config.lua %FILES%
echo.
if %COUNT%==1 (
    echo Done! 1 file obfuscated.
) else (
    echo Done! %COUNT% files obfuscated.
)
pause
