# Firebase Test Lab - Global Knowledge Base

**Last Updated:** April 12, 2026  
**Status:** Active Learning Document  
**Use Case:** Testing Flutter/Android apps on real devices via cloud

---

## 🎯 Quick Reference

### Correct Command Template
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US
```

### Key Parameters (CORRECT)
- `--os-version-ids` (NOT `--os-versions`)
- `--device-ids=lynx` (NOT `--device-ids=Pixel6Pro`)
- `--app=build/app/outputs/flutter-apk/app-release.apk` (Flutter output path)

---

## ❌ Common Mistakes & Fixes

### Mistake 1: Wrong OS Parameter
```
❌ WRONG: --os-versions=33
✅ CORRECT: --os-version-ids=33
ERROR: unrecognized arguments: --os-versions
```

### Mistake 2: Product Name Instead of Model ID
```
❌ WRONG: --device-ids=Pixel6Pro
✅ CORRECT: --device-ids=lynx
ERROR: model ['Pixel6Pro'] not found
```

### Mistake 3: Wrong APK Path
```
❌ WRONG: build/app/outputs/apk/release/app-release.apk
✅ CORRECT: build/app/outputs/flutter-apk/app-release.apk
ERROR: APK not found
```

---

## 📱 Device Model IDs Reference

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
| Pixel 2 (Arm) | `Pixel2.arm` | 26-33 | Virtual device |

**Get full list:** `gcloud firebase test android models list`

---

## 🔧 Useful Commands

### Discovery Commands
```powershell
# List all available devices
gcloud firebase test android models list

# List devices by brand
gcloud firebase test android models list --filter="brand:Google"

# Get details for specific device
gcloud firebase test android models describe lynx

# List available OS versions
gcloud firebase test android versions list

# List available locales
gcloud firebase test android locales list
```

### Build Commands
```bash
# Build APK for testing
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (AAB)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Test Commands
```powershell
# Single device test
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33

# Multi-device test
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35

# With orientations
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape

# With locales
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR

# Matrix test (all combinations)
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35 `
  --locales=en_US,es_ES `
  --orientations=portrait,landscape

# With custom timeout
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --timeout=900s
```

---

## 📊 Test Scenarios

### Scenario 1: Basic Compatibility Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```
**Purpose:** Test app on latest Pixel device with Android 13

### Scenario 2: Multi-Version Compatibility
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=31,32,33,34,35
```
**Purpose:** Test across multiple Android versions

### Scenario 3: Device Diversity
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky,caiman,komodo `
  --os-version-ids=33,34,35
```
**Purpose:** Test on different device types and sizes

### Scenario 4: Orientation Testing
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape
```
**Purpose:** Test UI in both portrait and landscape

### Scenario 5: Localization Testing
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE,ja_JP,zh_CN
```
**Purpose:** Test with different language settings

### Scenario 6: Comprehensive Matrix
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=32,33,34,35 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape
```
**Purpose:** Test all combinations (comprehensive coverage)

---

## 📈 Test Results

### Viewing Results
1. **Firebase Console:** https://console.firebase.google.com/project/pictopdf/testlab
2. **Test Matrix ID:** Shown in command output (e.g., `matrix-1fa82n18ojk6k`)
3. **Results include:**
   - Screenshots from test execution
   - Performance metrics
   - Logs and errors
   - Device information
   - Test duration

### Typical Timeline
- **0-2 min:** Test matrix created, devices allocated
- **2-5 min:** App installed on devices
- **5-10 min:** Test execution (Robo test by default)
- **10+ min:** Results available in console

---

## 🚀 Workflow

### Step 1: Build
```bash
flutter build apk --release
```

### Step 2: Run Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### Step 3: Wait for Results
- Command shows test matrix ID
- Results appear in Firebase Console in 5-10 minutes
- Check for crashes, performance issues, UI problems

### Step 4: Review & Iterate
- Fix any issues found
- Re-build and re-test
- Repeat until satisfied

---

## 💡 Best Practices

1. **Always use release builds** - `flutter build apk --release`
2. **Test multiple devices** - Don't just test on one device
3. **Test multiple OS versions** - Android fragmentation is real
4. **Test orientations** - Many users rotate their devices
5. **Test locales** - Text layout changes with different languages
6. **Monitor quota** - Firebase Test Lab has usage limits
7. **Save results** - Download for regression testing
8. **Automate testing** - Integrate into CI/CD pipeline

---

## 🔍 Troubleshooting

### Error: "unrecognized arguments: --os-versions"
**Cause:** Using wrong parameter name  
**Fix:** Use `--os-version-ids` instead of `--os-versions`

### Error: "model ['Pixel6Pro'] not found"
**Cause:** Using product name instead of model ID  
**Fix:** Use `--device-ids=lynx` instead of `--device-ids=Pixel6Pro`

### Error: "APK not found"
**Cause:** Wrong APK path  
**Fix:** Use `build/app/outputs/flutter-apk/app-release.apk` (Flutter output)

### Error: "Http error while creating test matrix: ResponseError 400"
**Cause:** Invalid device ID or OS version combination  
**Fix:** Check device supports that OS version with `gcloud firebase test android models describe DEVICE_ID`

### Test takes too long
**Cause:** Default timeout is 300 seconds  
**Fix:** Add `--timeout=900s` for longer tests

---

## 📚 Related Commands

### gcloud Configuration
```powershell
# Initialize gcloud
gcloud init

# Set project
gcloud config set project pictopdf

# List projects
gcloud projects list

# View current config
gcloud config list
```

### Firebase CLI
```powershell
# Login to Firebase
firebase login

# List projects
firebase projects:list

# Use specific project
firebase use pictopdf
```

---

## 🎓 Learning Notes

**Date Learned:** April 12, 2026

**Key Insights:**
1. Parameter names are strict - `--os-version-ids` not `--os-versions`
2. Device IDs are model codes - `lynx` not `Pixel6Pro`
3. Flutter builds to `flutter-apk` folder, not `apk` folder
4. Tests take 5-10 minutes to complete
5. Results are comprehensive - screenshots, logs, metrics
6. Matrix testing allows testing multiple configurations at once

**Common Pitfalls:**
1. Using wrong parameter names causes immediate errors
2. Using product names instead of model IDs causes HTTP 400 errors
3. Using wrong APK path causes file not found errors
4. Interrupting tests wastes quota

---

## 🔗 Resources

- **Firebase Console:** https://console.firebase.google.com/project/pictopdf/testlab
- **gcloud CLI Docs:** https://cloud.google.com/sdk/gcloud/reference
- **Firebase Test Lab Docs:** https://firebase.google.com/docs/test-lab
- **Android Testing Guide:** https://developer.android.com/training/testing

---

## ✅ Checklist for Testing

- [ ] Build app: `flutter build apk --release`
- [ ] Check APK exists: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Choose device ID from list (e.g., `lynx`)
- [ ] Choose OS version supported by device (e.g., `33`)
- [ ] Run test with correct parameters
- [ ] Wait 5-10 minutes for results
- [ ] Check Firebase Console for results
- [ ] Review screenshots and logs
- [ ] Fix any issues found
- [ ] Re-test if needed

---

**Status:** ✅ Active Knowledge Base  
**Last Used:** April 12, 2026  
**Confidence Level:** High (tested and verified)
