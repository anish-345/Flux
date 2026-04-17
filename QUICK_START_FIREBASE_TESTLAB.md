# Firebase Test Lab - Quick Start Guide

## ✅ What's Already Installed

- **Firebase CLI**: v15.3.1 ✓
- **Java**: OpenJDK 17.0.16 ✓

## ⏳ What You Need to Do

### Step 1: Install Google Cloud SDK (5 minutes)

**Option A: Automatic Installation**
```powershell
# The installer has been downloaded to:
& "$env:TEMP\GoogleCloudSDKInstaller.exe"
```

**Option B: Manual Download**
1. Visit: https://cloud.google.com/sdk/docs/install-sdk#windows
2. Download the Windows installer
3. Run the `.exe` file
4. Follow the wizard (accept defaults)

**After Installation:**
- Close and reopen PowerShell
- Verify: `gcloud --version`

---

### Step 2: Initialize Google Cloud (3 minutes)

```powershell
# Initialize gcloud with your Google account
gcloud init

# During the process:
# 1. Choose "Y" to log in
# 2. Sign in with your Google account in the browser
# 3. Select project: pictopdf
# 4. Choose default region: us-central1
```

**Verify:**
```powershell
gcloud auth list
gcloud config list
```

---

### Step 3: Configure Firebase CLI (2 minutes)

```powershell
# Link Firebase to your project
firebase login
firebase use --add

# Select: pictopdf
```

---

### Step 4: Install Android SDK Components (2 minutes)

```powershell
# Install Android testing tools
gcloud components install android-emulator
gcloud components install android-sdk-platform-tools
```

---

### Step 5: Build Your Flutter App (5 minutes)

```bash
# Navigate to your Flutter project
cd your_flutter_project

# Build APK for testing
flutter build apk --release

# Or build App Bundle (AAB)
flutter build appbundle --release
```

**Output locations:**
- APK: `build/app/outputs/apk/release/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

### Step 6: Run Your First Test (2 minutes)

```powershell
# Test on a single device (Pixel 7a with Android 13)
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US
```

**Note:** Use `--os-version-ids` (not `--os-versions`) and device model IDs like `lynx` (not `Pixel6Pro`)

**What happens:**
1. Your app is uploaded to Firebase Test Lab
2. It runs on a real Pixel 6 Pro device with Android 13
3. Results appear in Firebase Console in ~5-10 minutes

---

### Step 7: View Results

**Option A: Firebase Console (Easiest)**
1. Go to: https://console.firebase.google.com/project/pictopdf/testlab
2. Click on your test run
3. View screenshots, logs, and performance metrics

**Option B: Command Line**
```powershell
# List all test runs
gcloud firebase test android results-list

# Get details of a specific test
gcloud firebase test android results describe <test-id>

# Download results
gcloud firebase test android results download <test-id> --destination=./results
```

---

## Common Testing Scenarios

### Test Multiple Devices
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro,Pixel5,Pixel4 `
  --os-versions=33,34 `
  --locales=en_US
```

### Test with Different Orientations
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --orientations=portrait,landscape
```

### Test with Longer Timeout
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --timeout=900s
```

---

## Troubleshooting

### "gcloud command not found"
- Restart PowerShell after installing Google Cloud SDK
- Or add to PATH: `C:\Program Files (x86)\Google\Cloud SDK\bin`

### "Authentication failed"
```powershell
gcloud auth login
gcloud auth application-default login
```

### "Project not found"
```powershell
gcloud config set project pictopdf
```

### "APK not found"
- Make sure you built the app: `flutter build apk --release`
- Check the path is correct

### "No devices available"
```powershell
# List available devices
gcloud firebase test android models list

# List available OS versions
gcloud firebase test android versions list
```

---

## Next Steps

1. **Install Google Cloud SDK** (see Step 1)
2. **Initialize gcloud** (see Step 2)
3. **Build your app** (see Step 5)
4. **Run your first test** (see Step 6)
5. **View results** (see Step 7)

---

## Useful Resources

- 📖 [Firebase Test Lab Docs](https://firebase.google.com/docs/test-lab)
- 🔧 [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- 🚀 [Firebase CLI Docs](https://firebase.google.com/docs/cli)
- 📱 [Android Testing Guide](https://developer.android.com/training/testing)

---

## Files Created for You

1. **FIREBASE_TEST_LAB_SETUP.md** - Detailed setup guide
2. **FIREBASE_TEST_LAB_COMMANDS.md** - Complete command reference
3. **install-firebase-testlab.ps1** - Automated installation script
4. **QUICK_START_FIREBASE_TESTLAB.md** - This file (quick reference)

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review FIREBASE_TEST_LAB_SETUP.md for detailed steps
3. Visit: https://firebase.google.com/docs/test-lab/troubleshooting
