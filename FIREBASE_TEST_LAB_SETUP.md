# Firebase Test Lab Setup Guide for Windows

## Prerequisites Status

✅ **Already Installed:**
- Firebase CLI: v15.3.1
- Java: OpenJDK 17.0.16

⏳ **To Install:**
- Google Cloud SDK (gcloud CLI)
- Android SDK (if not already present)
- Additional Firebase Test Lab components

---

## Step 1: Install Google Cloud SDK

### Option A: Automated Installation (Recommended)

Run the installer that's been downloaded:
```powershell
& "$env:TEMP\GoogleCloudSDKInstaller.exe"
```

**During installation:**
1. Accept the license agreement
2. Choose installation directory (default: `C:\Program Files (x86)\Google\Cloud SDK`)
3. Check "Install Python" (if not already installed)
4. Check "Create Start Menu shortcuts"
5. Click "Install"
6. After installation, check "Run gcloud init" to configure

### Option B: Manual Download

If the automated download didn't work:
1. Visit: https://cloud.google.com/sdk/docs/install-sdk#windows
2. Download the Windows installer
3. Run the `.exe` file
4. Follow the installation wizard

---

## Step 2: Initialize Google Cloud SDK

After installation, open a new PowerShell terminal and run:

```powershell
gcloud init
```

**During initialization:**
1. Choose "Y" to log in with your Google account
2. A browser window will open - sign in with your Google account
3. Select your Firebase project (pictopdf)
4. Choose default region (e.g., `us-central1`)

Verify installation:
```powershell
gcloud --version
gcloud auth list
```

---

## Step 3: Configure Firebase CLI with Google Cloud

Link Firebase CLI to your Google Cloud project:

```powershell
firebase login
firebase use --add
```

Select your project: `pictopdf`

---

## Step 4: Install Android SDK Components (if needed)

Check if you have Android SDK:
```powershell
Get-Command adb -ErrorAction SilentlyContinue
```

If not found, install via Android Studio or:

```powershell
# Using Google Cloud SDK
gcloud components install android-emulator
gcloud components install android-sdk-platform-tools
```

---

## Step 5: Build Your Flutter App for Testing

### Build APK for Firebase Test Lab

```bash
cd your_flutter_project
flutter build apk --release
```

Output location: `build/app/outputs/apk/release/app-release.apk`

### Build App Bundle (AAB) - Recommended

```bash
flutter build appbundle --release
```

Output location: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 6: Run Tests on Firebase Test Lab

### Option A: Using Firebase Console (Easiest)

1. Go to: https://console.firebase.google.com/project/pictopdf/testlab
2. Click "Run a test"
3. Upload your APK or AAB
4. Select devices and configurations
5. Click "Start testing"

### Option B: Using gcloud CLI

```powershell
# Test with APK
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --test=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --locales=en_US

# Or with AAB
gcloud firebase test android run `
  --app=build/app/outputs/bundle/release/app-release.aab `
  --device-ids=Pixel6Pro,Pixel5 `
  --os-versions=33,34 `
  --locales=en_US
```

---

## Step 7: View Test Results

### Via Firebase Console
- Go to: https://console.firebase.google.com/project/pictopdf/testlab
- Click on your test run
- View logs, screenshots, and performance metrics

### Via gcloud CLI
```powershell
gcloud firebase test android results-list
gcloud firebase test android results describe <test-id>
```

---

## Useful Commands Reference

```powershell
# Check gcloud installation
gcloud --version

# List installed components
gcloud components list

# Update gcloud
gcloud components update

# List available devices for testing
gcloud firebase test android models list

# List available OS versions
gcloud firebase test android versions list

# List available locales
gcloud firebase test android locales list

# Run tests with custom configuration
gcloud firebase test android run `
  --app=path/to/app.apk `
  --device-ids=Pixel6Pro,Pixel5,Pixel4 `
  --os-versions=33,34 `
  --locales=en_US,es_ES `
  --orientations=portrait,landscape `
  --timeout=900s
```

---

## Troubleshooting

### "gcloud command not found"
- Restart PowerShell after installation
- Add to PATH manually: `C:\Program Files (x86)\Google\Cloud SDK\bin`

### "Authentication failed"
```powershell
gcloud auth login
gcloud auth application-default login
```

### "Project not found"
```powershell
gcloud config set project pictopdf
gcloud firebase test android models list
```

### "APK not found"
- Ensure you've built the app: `flutter build apk --release`
- Check the output path is correct

### "No devices available"
```powershell
gcloud firebase test android models list
gcloud firebase test android versions list
```

---

## Next Steps

1. ✅ Install Google Cloud SDK (see Step 1)
2. ✅ Initialize gcloud (see Step 2)
3. ✅ Build your Flutter app (see Step 5)
4. ✅ Run tests on Firebase Test Lab (see Step 6)
5. ✅ View results (see Step 7)

---

## Additional Resources

- [Firebase Test Lab Documentation](https://firebase.google.com/docs/test-lab)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Android Testing Guide](https://developer.android.com/training/testing)
