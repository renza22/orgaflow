@echo off
echo ========================================
echo Building OrgaFlow Android APK
echo ========================================
echo.

echo [1/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Error: Failed to get dependencies
    pause
    exit /b %errorlevel%
)

echo.
echo [2/3] Generating launcher icons...
call dart run flutter_launcher_icons
if %errorlevel% neq 0 (
    echo Error: Failed to generate icons
    pause
    exit /b %errorlevel%
)

echo.
echo [3/3] Building APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo Error: Failed to build APK
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
