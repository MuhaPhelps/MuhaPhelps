@echo off
setlocal
cd /d "%~dp0backend"

set "PB_VERSION=0.40.4"
set "PB_EXE=%CD%\pocketbase.exe"
set "PB_ZIP=%CD%\pocketbase.zip"
set "PB_TMP=%CD%\_pbtmp"

if exist "%PB_EXE%" goto RUN_SERVER

echo PocketBase not found. Downloading version %PB_VERSION%...

curl.exe -L --fail -o "%PB_ZIP%" "https://github.com/pocketbase/pocketbase/releases/download/v%PB_VERSION%/pocketbase_%PB_VERSION%_windows_amd64.zip"
if errorlevel 1 goto DOWNLOAD_ERROR

if exist "%PB_TMP%" rmdir /s /q "%PB_TMP%"
mkdir "%PB_TMP%"

tar.exe -xf "%PB_ZIP%" -C "%PB_TMP%"
if errorlevel 1 goto EXTRACT_ERROR

copy /y "%PB_TMP%\pocketbase.exe" "%PB_EXE%" >nul
if errorlevel 1 goto EXTRACT_ERROR

del /q "%PB_ZIP%" 2>nul
rmdir /s /q "%PB_TMP%" 2>nul

echo PocketBase downloaded successfully.

:RUN_SERVER
echo.
echo API:       http://127.0.0.1:8090/api/
echo Dashboard: http://127.0.0.1:8090/_/
echo Superuser: admin@cae.local / Admin123!
echo.
"%PB_EXE%" serve --http=127.0.0.1:8090
set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo PocketBase stopped with code %EXIT_CODE%.
pause
exit /b %EXIT_CODE%

:DOWNLOAD_ERROR
echo.
echo ERROR: PocketBase download failed.
echo Check the internet connection and try again.
pause
exit /b 1

:EXTRACT_ERROR
echo.
echo ERROR: PocketBase archive extraction failed.
echo Delete backend\pocketbase.zip and backend\_pbtmp if they exist, then try again.
pause
exit /b 1
