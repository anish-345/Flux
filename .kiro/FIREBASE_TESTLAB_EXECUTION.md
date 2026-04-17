# Firebase Test Lab Execution - Flux Project

**Date:** April 12, 2026  
**Project:** Flux (Flutter + Rust File Transfer)  
**APK:** `build/app/outputs/flutter-apk/app-release.apk` (46.2 MB)  
**Status:** ✅ Ready for Testing

---

## Test Scenarios

### Scenario 1: Basic Bluetooth Functionality (Baseline)
**Purpose:** Verify app launches and Bluetooth adapter state is detected

```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US `
  --timeout=300s
```

**Expected Results:**
- App launches without crashes
- Bluetooth adapter state is detected
- No ANR (Application Not Responding) errors
- Crash rate: 0%

---

### Scenario 2: Multi-Device Compatibility
**Purpose:** Test on different device types and Android versions

```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=32,33,34,35 `
  --locales=en_US `
  --timeout=600s
```

**Expected Results:**
- App works on all device types
- No device-specific crashes
- Consistent UI across devices
- Performance acceptable on all devices

---

### Scenario 3: Orientation Testing
**Purpose:** Verify UI works in both portrait and landscape

```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape `
  --timeout=300s
```

**Expected Results:**
- UI adapts correctly to orientation changes
- No layout issues
- All buttons and controls accessible
- No crashes on rotation

---

### Scenario 4: Localization Testing
**Purpose:** Test with different language settings

```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE,ja_JP,zh_CN `
  --timeout=600s
```

**Expected Results:**
- App handles different locales
- Text displays correctly
- No encoding issues
- UI remains functional

---

### Scenario 5: Comprehensive Matrix Test (All Combinations)
**Purpose:** Full compatibility matrix testing

```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky,caiman,komodo `
  --os-version-ids=32,33,34,35 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape `
  --timeout=900s
```

**Expected Results:**
- Comprehensive coverage of device/OS/locale combinations
- Identifies any edge cases
- Performance metrics across all combinations
- Detailed crash and ANR reports

---

## Performance Metrics to Monitor

### Critical Metrics
- **Crash Rate:** Target <0.5%
- **ANR Rate:** Target <0.1%
- **Startup Time:** Target <3 seconds
- **Memory Usage:** Target <200 MB

### Secondary Metrics
- **Frame Rate:** Target 60 FPS
- **Battery Impact:** Monitor drain rate
- **Network Performance:** Monitor data usage
- **Bluetooth Stability:** Monitor connection drops

---

## Test Execution Steps

### Step 1: Verify Prerequisites
```powershell
# Check gcloud is installed
gcloud --version

# Check Firebase project is set
gcloud config get-value project

# Verify APK exists
Test-Path build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: Run Baseline Test
```powershell
# Run basic test first
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### Step 3: Monitor Test Progress
```powershell
# Watch test matrix status
gcloud firebase test android results-list

# Get specific test results
gcloud firebase test android results describe <MATRIX_ID>
```

### Step 4: Review Results
1. Open Firebase Console: https://console.firebase.google.com/project/pictopdf/testlab
2. Find your test matrix
3. Review:
   - Screenshots
   - Performance metrics
   - Logs
   - Crash reports
   - ANR reports

### Step 5: Analyze and Fix
- Identify any crashes or ANRs
- Check performance metrics
- Review device-specific issues
- Fix issues and re-test

---

## Expected Test Timeline

| Phase | Duration | Activity |
|-------|----------|----------|
| Setup | 0-2 min | Test matrix created, devices allocated |
| Install | 2-5 min | APK installed on devices |
| Execution | 5-10 min | Robo test runs (automated exploration) |
| Results | 10+ min | Results available in Firebase Console |

**Total Time:** ~15-20 minutes per test matrix

---

## Troubleshooting

### Error: "APK not found"
```powershell
# Verify APK path
Get-ChildItem build/app/outputs/flutter-apk/app-release.apk
```

### Error: "model ['lynx'] not found"
```powershell
# List available devices
gcloud firebase test android models list
```

### Error: "unrecognized arguments: --os-versions"
```powershell
# Use correct parameter name
# WRONG: --os-versions=33
# RIGHT: --os-version-ids=33
```

### Test hangs or times out
```powershell
# Increase timeout
--timeout=900s  # 15 minutes
```

---

## Success Criteria

### Baseline Test (Scenario 1)
- ✅ App launches without crash
- ✅ Bluetooth adapter state detected
- ✅ No ANR errors
- ✅ Crash rate: 0%

### Multi-Device Test (Scenario 2)
- ✅ Works on all 3 devices
- ✅ Works on all 4 OS versions
- ✅ No device-specific crashes
- ✅ Consistent performance

### Orientation Test (Scenario 3)
- ✅ UI adapts to both orientations
- ✅ No layout issues
- ✅ All controls accessible
- ✅ No crashes on rotation

### Localization Test (Scenario 4)
- ✅ Handles all 6 locales
- ✅ Text displays correctly
- ✅ No encoding issues
- ✅ UI remains functional

### Comprehensive Matrix (Scenario 5)
- ✅ All combinations tested
- ✅ No critical issues found
- ✅ Performance acceptable
- ✅ Ready for production

---

## Next Steps After Testing

1. **If all tests pass:**
   - Deploy to PlayStore
   - Monitor real-world performance
   - Gather user feedback

2. **If issues found:**
   - Analyze crash reports
   - Fix identified issues
   - Re-test on Firebase Test Lab
   - Repeat until all tests pass

3. **Performance optimization:**
   - Review performance metrics
   - Optimize slow operations
   - Reduce memory usage
   - Improve startup time

---

## Resources

- **Firebase Console:** https://console.firebase.google.com/project/pictopdf/testlab
- **gcloud CLI Docs:** https://cloud.google.com/sdk/gcloud/reference
- **Firebase Test Lab Docs:** https://firebase.google.com/docs/test-lab
- **Android Testing Guide:** https://developer.android.com/training/testing

---

**Status:** ✅ Ready for Execution  
**Last Updated:** April 12, 2026  
**APK Size:** 46.2 MB  
**Rust Compilation:** ✅ Fixed (0 errors, 0 warnings)  
**Flutter Analysis:** ✅ Clean (0 issues)
