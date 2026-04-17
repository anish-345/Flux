# Quick Start - Firebase Test Lab Testing

**APK Ready:** ✅ `build/app/outputs/flutter-apk/app-release.apk` (46.2 MB)  
**Status:** Ready for testing

---

## Fastest Way: Web Console (No CLI Required)

### Step 1: Open Firebase Console
```
https://console.firebase.google.com/project/pictopdf/testlab
```

### Step 2: Click "Run a test"

### Step 3: Upload APK
- Click "Choose file"
- Select: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Configure
- Device: Pixel 7a (lynx)
- OS: Android 13 (API 33)
- Locale: English (US)

### Step 5: Click "Start test"

### Step 6: Wait 5-10 minutes for results

---

## Command-Line Method (If gcloud is installed)

### Test 1: Baseline (Fastest)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### Test 2: Multi-Device
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35
```

### Test 3: Full Matrix
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky,caiman,komodo `
  --os-version-ids=32,33,34,35 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape
```

---

## What to Check in Results

### ✅ Success Indicators
- Crash rate: 0%
- ANR rate: 0%
- Startup time: <3 seconds
- Memory: <200 MB

### ❌ Failure Indicators
- Crash rate: >0.5%
- ANR rate: >0.1%
- Startup time: >5 seconds
- Memory: >300 MB

---

## If Tests Fail

1. Check crash logs in Firebase Console
2. Review error messages
3. Fix issues in code
4. Rebuild: `flutter build apk --release`
5. Re-test

---

## Documentation

- **Full Guide:** `.kiro/FIREBASE_TESTLAB_MANUAL_GUIDE.md`
- **Test Scenarios:** `.kiro/FIREBASE_TESTLAB_EXECUTION.md`
- **Rust Fixes:** `.kiro/RUST_COMPILATION_FIXES_SUMMARY.md`
- **Summary:** `.kiro/TASK_COMPLETION_SUMMARY.md`

---

**Ready to test!** 🚀
