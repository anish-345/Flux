# Flux - Build Instructions

## Prerequisites

### Required Tools
- **Flutter SDK** (3.10.7 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Android Studio** (for Android builds)
- **Visual Studio 2022** (for Windows builds) with C++ desktop development workload
- **Git** for version control

### Verify Installation
```bash
flutter doctor
```

All checks should pass before proceeding.

---

## Android APK Build

### 1. Clean Build Files
```bash
cd C:\Users\anish\Documents\flux
flutter clean
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Build Release APK
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 4. Build App Bundle (for Google Play)
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 5. Install on Device
```bash
flutter install
```

Or manually transfer `app-release.apk` to your Android device and install.

---

## Windows App Build

### 1. Clean Build Files
```bash
cd C:\Users\anish\Documents\flux
flutter clean
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Enable Windows Desktop Support
```bash
flutter config --enable-windows-desktop
```

### 4. Build Windows Release
```bash
flutter build windows --release
```

**Output:** `build/windows/x64/runner/Release/`

### 5. Build Windows Installer (Optional)
Create an installer using Inno Setup or WiX Toolset with the generated files.

---

## Development Build (Debug Mode)

### Android
```bash
flutter run
```

### Windows
```bash
flutter run -d windows
```

---

## Web Share Usage

Once the app is running:

1. **Start Web Share** from the app
2. **Note the URL** displayed (e.g., `http://192.168.1.100:12345`)
3. **On other device:**
   - Open any web browser
   - Type the URL in address bar
   - Click download buttons for files

### Key Features:
- ✅ Clean white UI matching the app theme
- ✅ Download buttons for each file
- ✅ Real-time progress tracking
- ✅ Multiple users can download simultaneously
- ✅ Works on any device with a browser
- ✅ No app installation needed for recipients

---

## Build Configuration

### Android (app/build.gradle.kts)
- **Application ID:** `com.example.flux`
- **Min SDK:** Flutter default
- **Target SDK:** Flutter default
- **Compile SDK:** Flutter default

### Windows
- **Architecture:** x64
- **Output:** Executable (.exe) with all required DLLs

---

## Troubleshooting

### Android Build Issues
1. **Gradle errors:**
   ```bash
   cd android
   .\gradlew clean
   cd ..
   flutter build apk
   ```

2. **SDK not found:**
   - Set `ANDROID_HOME` environment variable
   - Verify via Android Studio SDK Manager

### Windows Build Issues
1. **Visual Studio not found:**
   - Install Visual Studio 2022 with "Desktop development with C++" workload
   - Run `flutter doctor` to verify

2. **CMake errors:**
   - Ensure CMake is installed via Visual Studio Installer

---

## Quick Build Commands Summary

```bash
# Full clean build for Android
flutter clean && flutter pub get && flutter build apk --release

# Full clean build for Windows
flutter clean && flutter pub get && flutter build windows --release

# Build both platforms
flutter clean && flutter pub get && flutter build apk --release && flutter build windows --release
```

---

## Distribution

### Android
- **APK:** Direct installation (share file)
- **AAB:** Upload to Google Play Store

### Windows
- Zip the `Release` folder contents
- Share the zip file
- Or create installer using Inno Setup

---

## Features Verified

✅ **Dynamic Port Allocation** - Works on both platforms
✅ **TCP File Transfers** - Real file streaming
✅ **Web Share Server** - HTTP server with concurrent downloads
✅ **WiFi/Hotspot Management** - Auto-fallback on Android
✅ **AES-256 Encryption** - Secure transfers
✅ **Resume Support** - Interrupted transfers auto-resume
✅ **Radar Animation** - Device discovery UI
✅ **Progress Tracking** - Real-time speed display
✅ **Offline Mode** - Works without internet via hotspot

---

**Build Version:** 1.0.0+1
**Flutter SDK:** ^3.10.7
**Last Updated:** 2024
