@echo off
echo ==========================================
echo Flux - Build Script for Android & Windows
echo ==========================================
echo.

:: Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo Flutter found!
flutter --version
echo.

:: Clean previous builds
echo [1/6] Cleaning previous builds...
flutter clean
if errorlevel 1 (
    echo ERROR: Clean failed
    pause
    exit /b 1
)

:: Get dependencies
echo [2/6] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

:: Run tests (optional but recommended)
echo [3/6] Running tests...
flutter test
if errorlevel 1 (
    echo WARNING: Tests failed, continuing with build...
)

:: Build Android APK
echo [4/6] Building Android APK (Release)...
flutter build apk --release
if errorlevel 1 (
    echo ERROR: Android build failed
    pause
    exit /b 1
)
echo ✅ Android APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk

:: Build Windows
echo [5/6] Building Windows App (Release)...
flutter config --enable-windows-desktop
flutter build windows --release
if errorlevel 1 (
    echo ERROR: Windows build failed
    pause
    exit /b 1
)
echo ✅ Windows app built successfully!
echo Location: build\windows\x64\runner\Release\

:: Summary
echo.
echo ==========================================
echo BUILD COMPLETED SUCCESSFULLY! 🎉
echo ==========================================
echo.
echo Android APK:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo Windows App:
echo   build\windows\x64\runner\Release\
echo.
echo Next steps:
echo   1. Install Android APK on your device
echo   2. Run Windows app on your PC
echo   3. Use Web Share to transfer files!
echo.
pause
