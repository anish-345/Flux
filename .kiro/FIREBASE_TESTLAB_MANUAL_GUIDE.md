# Firebase Test Lab - Manual Testing Guide

**Project:** Flux (Flutter + Rust File Transfer)  
**APK:** `build/app/outputs/flutter-apk/app-release.apk` (46.2 MB)  
**Status:** ✅ Ready for Testing

---

## Prerequisites

### 1. Install Google Cloud SDK
If gcloud is not installed:

```powershell
# Download from: https://cloud.google.com/sdk/docs/install-sdk
# Or use Chocolatey:
choco install google-cloud-sdk

# Verify installation
gcloud --version
```

### 2. Initialize gcloud
```powershell
# Initialize gcloud
gcloud init

# Set project to pictopdf
gcloud config set project pictopdf

# Verify project
gcloud config get-value project
```

### 3. Authenticate
```powershell
# Login to Google Cloud
gcloud auth login

# Set application default credentials
gcloud auth application-default login
```

---

## Web-Based Testing (Easiest Method)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/project/pictopdf/testlab
2. Click **"Run a test"**
3. Select **"Robo test"** (automated exploration)

### Step 2: Upload APK
1. Click **"Choose file"**
2. Select: `build/app/outputs/flutter-apk/app-release.apk`
3. Click **"Next"**

### Step 3: Configure Test
1. **Device Selection:**
   - Select: Pixel 7a (lynx)
   - OS Version: Android 13 (API 33)
   - Locale: English (US)

2. **Test Configuration:**
   - Test type: Robo test
   - Timeout: 300 seconds
   - Click **"Start test"**

### Step 4: Monitor Test
1. Test matrix ID will be displayed
2. Status updates in real-time
3. Wait 5-10 minutes for completion

### Step 5: Review Results
1. Click on test matrix
2. View:
   - Screenshots
   - Performance metrics
   - Logs
   - Crash reports
   - ANR reports

---

## Command-Line Testing (Advanced)

### Prerequisites
```powershell
# Verify gcloud is in PATH
gcloud --version

# Verify project is set
gcloud config get-value project
# Should output: pictopdf

# Verify APK exists
Test-Path build/app/outputs/flutter-apk/app-release.apk
# Should output: True
```

### Test 1: Baseline Test (Pixel 7a, Android 13)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US `
  --timeout=300s
```

**Expected Output:**
```
Uploading [build/app/outputs/flutter-apk/app-release.apk]...
Uploading [...]
Test [matrix-xxxxx] created.
Waiting for test to complete...
Test [matrix-xxxxx] PASSED
```

### Test 2: Multi-Device Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35 `
  --locales=en_US `
  --timeout=600s
```

### Test 3: Orientation Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape `
  --timeout=300s
```

### Test 4: Localization Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE,ja_JP,zh_CN `
  --timeout=600s
```

### Test 5: Comprehensive Matrix
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky,caiman,komodo `
  --os-version-ids=32,33,34,35 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape `
  --timeout=900s
```

---

## Monitoring Tests

### List All Tests
```powershell
gcloud firebase test android results-list
```

### Get Specific Test Results
```powershell
gcloud firebase test android results describe <MATRIX_ID>
```

### Download Test Results
```powershell
gcloud firebase test android results download <MATRIX_ID> --destination=./test-results
```

---

## Device Reference

| Device | Model ID | OS Versions | Notes |
|--------|----------|-------------|-------|
| Pixel 7a | `lynx` | 33 | Good baseline device |
| Pixel 8a | `akita` | 34, 35 | Latest Android |
| Pixel 8 Pro | `husky` | 34, 35 | High-end device |
| Pixel 7 Pro | `cheetah` | 33 | Older flagship |
| Pixel 6a | `bluejay` | 32 | Older device |
| Pixel Fold | `felix` | 33, 34 | Foldable device |
| Pixel 9 Pro | `caiman` | 34, 35 | Latest flagship |
| Pixel 9 Pro XL | `komodo` | 34, 35 | Largest device |

---

## Performance Metrics to Check

### In Firebase Console
1. **Crash Rate:** Should be 0%
2. **ANR Rate:** Should be 0%
3. **Startup Time:** Should be <3 seconds
4. **Memory Usage:** Should be <200 MB
5. **Frame Rate:** Should be 60 FPS

### In Test Logs
1. Look for Bluetooth-related errors
2. Check for permission issues
3. Monitor network operations
4. Check for memory leaks

---

## Troubleshooting

### Issue: "gcloud: command not found"
**Solution:**
1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install-sdk
2. Add to PATH if needed
3. Restart PowerShell

### Issue: "Project not set"
**Solution:**
```powershell
gcloud config set project pictopdf
```

### Issue: "APK not found"
**Solution:**
```powershell
# Verify APK exists
Get-ChildItem build/app/outputs/flutter-apk/app-release.apk

# If not found, rebuild
flutter build apk --release
```

### Issue: "Authentication failed"
**Solution:**
```powershell
gcloud auth login
gcloud auth application-default login
```

### Issue: "Test times out"
**Solution:**
```powershell
# Increase timeout
--timeout=900s  # 15 minutes instead of 5
```

---

## Success Criteria

### ✅ Baseline Test Should Pass
- App launches without crash
- Bluetooth adapter state detected
- No ANR errors
- Crash rate: 0%

### ✅ Multi-Device Test Should Pass
- Works on all 3 devices
- Works on all 3 OS versions
- No device-specific crashes
- Consistent performance

### ✅ Orientation Test Should Pass
- UI adapts to both orientations
- No layout issues
- All controls accessible
- No crashes on rotation

### ✅ Localization Test Should Pass
- Handles all 6 locales
- Text displays correctly
- No encoding issues
- UI remains functional

---

## Next Steps

### If Tests Pass ✅
1. Review performance metrics
2. Check for any warnings
3. Deploy to PlayStore
4. Monitor real-world performance

### If Tests Fail ❌
1. Review crash reports
2. Check logs for errors
3. Fix identified issues
4. Rebuild APK
5. Re-run tests

---

## Resources

- **Firebase Console:** https://console.firebase.google.com/project/pictopdf/testlab
- **Google Cloud SDK:** https://cloud.google.com/sdk/docs/install-sdk
- **Firebase Test Lab Docs:** https://firebase.google.com/docs/test-lab
- **Android Testing Guide:** https://developer.android.com/training/testing

---

## Current Status

| Component | Status | Details |
|-----------|--------|---------|
| APK Build | ✅ Success | 46.2 MB, ready for testing |
| Rust Compilation | ✅ Fixed | 0 errors, 0 warnings |
| Flutter Analysis | ✅ Clean | 0 issues |
| Bluetooth Service | ✅ Implemented | Device discovery, adapter state |
| Progress Tracking | ✅ Implemented | Real-time metrics, accuracy |
| Firebase Test Lab | ⏳ Ready | Awaiting manual execution |

---

**Last Updated:** April 12, 2026  
**APK Size:** 46.2 MB  
**Ready for Testing:** ✅ Yes
