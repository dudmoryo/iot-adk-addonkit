@echo off
REM Run setenv before running this script
REM This script creates the folder structure and copies the template files for a new package


goto START

:Usage
echo Usage: newappxpkg filename.appx [fga/bgt/none] [CompName.SubCompName]
echo    filename.appx........... Required, Input appx package. Expects dependencies in a sub folder
echo    fga/bgt/none............ Required, Startup ForegroundApp / Startup BackgroundTask / No startup
echo    CompName.SubCompName.... Optional, default is Appx.filename
echo    [/?]............ Displays this usage string.
echo    Example:
echo        newappxpkg C:\test\MainAppx_1.0.0.0_arm.appx fga Appx.Main
echo        newappxpkg C:\test\MainAppx_1.0.0.0_arm.appx none 
echo Existing packages are
dir /b /AD %SRC_DIR%\Packages

exit /b 1

:START
setlocal ENABLEDELAYEDEXPANSION

if [%1] == [/?] goto Usage
if [%1] == [-?] goto Usage
if [%1] == [] goto Usage
if [%2] == [] goto Usage

set FILE_TYPE=%~x1
set FILE_NAME=%~n1
set "FILE_PATH=%~dp1"

if [%FILE_TYPE%] == [.appx] (
    set COMP_NAME=Appx
    for /f "tokens=1 delims=_" %%i in ("%FILE_NAME%") do (
        set SUB_NAME=%%i
    )
) else (
    echo. Unsupported filetype.
    goto Usage
)

set STARTUP_OPTIONS=fga bgt none
for %%A in (%STARTUP_OPTIONS%) do (
    if [%%A] == [%2] (
        set STARTUP=%2
    )
)
if not defined STARTUP (
    echo. Error : Invalid Startup option.
    goto Usage
)

if not [%3] == [] (
    for /f "tokens=1,2 delims=." %%i in ("%3") do (
        set COMP_NAME=%%i
        set SUB_NAME=%%j
    )
)

if not defined SRC_DIR (
    echo Environment not defined. Call setenv
    goto End
)
set "NEWPKG_DIR=%SRC_DIR%\Packages\%COMP_NAME%.%SUB_NAME%"

REM Error Checks
if /i exist %NEWPKG_DIR% (
    echo Error : %COMP_NAME%.%SUB_NAME% already exists
    goto End
)

REM Start processing command
echo Creating %COMP_NAME%.%SUB_NAME% package

mkdir "%NEWPKG_DIR%"

REM Create Appx Package using template files
echo. Creating package xml files
call appx2pkg.cmd %1 %STARTUP% %COMP_NAME%.%SUB_NAME%
REM Copy the files to the package directory
move "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.pkg.xml" "%NEWPKG_DIR%\%COMP_NAME%.%SUB_NAME%.pkg.xml" >nul
move "%FILE_PATH%\customizations.xml" "%NEWPKG_DIR%\customizations.xml" >nul
if exist "%FILE_PATH%\Dependencies\%ARCH%" (
    mkdir "%NEWPKG_DIR%\Dependencies\%ARCH%"
    copy "%FILE_PATH%\Dependencies\%ARCH%\*.appx" "%NEWPKG_DIR%\Dependencies\%ARCH%\" >nul
) else if exist "%FILE_PATH%\Dependencies" (
    mkdir "%NEWPKG_DIR%\Dependencies"
    copy "%FILE_PATH%\Dependencies\*.appx" "%NEWPKG_DIR%\Dependencies\" >nul 2>nul
) else if exist "%FILE_PATH%\%ARCH%" (
    mkdir "%NEWPKG_DIR%\%ARCH%"
    copy "%FILE_PATH%\%ARCH%\*.appx" "%NEWPKG_DIR%\%ARCH%\" >nul 2>nul
) else (
    copy "%FILE_PATH%\*%ARCH%*.appx" "%NEWPKG_DIR%\" >nul 2>nul
)

copy "%FILE_PATH%\*.cer" "%NEWPKG_DIR%\" >nul 2>nul
copy "%FILE_PATH%\*License*.xml" "%NEWPKG_DIR%\" >nul 2>nul
copy "%FILE_PATH%\%FILE_NAME%.appx" "%NEWPKG_DIR%\%FILE_NAME%.appx" >nul


echo %NEWPKG_DIR% ready
goto End

:Error
endlocal
echo "newappxpkg %APPX% %STARTUP% %2" failed with error %ERRORLEVEL%
exit /b 1

:End
endlocal
exit /b 0
