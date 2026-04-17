# Firebase Test Lab Setup & Configuration

**Date:** April 12, 2026  
**Project:** Flux (Flutter + Rust File Transfer)  
**Status:** Ready for Testing

---

## 🎯 Prerequisites

### Required Tools
- ✅ gcloud CLI installed
- ✅ Firebase project configured
- ✅ Google Cloud project with billing enabled
- ✅ Release APK built

### Verification
```bash
gcloud --version
firebase --version
gcloud config list
```

---

## 📱 Device Configuration

### Recommended Test Devices

| Device | Model ID | OS Version | Use Case |
|--------|----------|-----------|----------|
| Pixel 7a | lynx | 33 | Baseline device |
| Pixel 8a | akita | 34 | Latest Android |
| Pixel 8 Pro | husky | 34 | High-end device |
| Pixel 6a | bluejay | 32 | Older device |
| Pixel Fold | felix | 33 | Foldable device |

### Get Available Devices
```bash
gcloud firebase test android models list
gcloud firebase test android versions list
gcloud firebase test android locales list
```

---

## 🧪 Test Scenarios

### Scenario 1: Basic Compatibility Test
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US
```

**Purpose:** Test app on latest Pixel device with Android 13  
**Duration:** ~10 minutes  
**Metrics:** Crashes, ANR, performance

### Scenario 2: Multi-Version Compatibility
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=31,32,33,34,35
```

**Purpose:** Test across multiple Android versions  
**Duration:** ~30 minutes  
**Metrics:** Version compatibility, API differences

### Scenario 3: Device Diversity
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky,caiman,komodo `
  --os-version-ids=33,34,35
```

**Purpose:** Test on different device types and sizes  
**Duration:** ~45 minutes  
**Metrics:** Device compatibility, screen sizes

### Scenario 4: Orientation Testing
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape
```

**Purpose:** Test UI in both orientations  
**Duration:** ~15 minutes  
**Metrics:** Layout, rotation handling

### Scenario 5: Localization Testing
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE,ja_JP,zh_CN
```

**Purpose:** Test with different language settings  
**Duration:** ~20 minutes  
**Metrics:** Text layout, localization

### Scenario 6: Comprehensive Matrix Test
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=32,33,34,35 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape
```

**Purpose:** Test all combinations (comprehensive coverage)  
**Duration:** ~60 minutes  
**Metrics:** Complete compatibility matrix

---

## 🚀 Running Tests

### Step 1: Set Google Cloud Project
```bash
gcloud config set project flux-project-id
```

### Step 2: Build Release APK
```bash
flutter build apk --release
```

### Step 3: Run Test
```bash
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### Step 4: Monitor Results
- Command shows test matrix ID
- Results appear in Firebase Console in 5-10 minutes
- Check for crashes, performance issues, UI problems

---

## 📊 Performance Metrics to Monitor

### Crash Rate
- **Target:** < 0.5%
- **Acceptable:** < 1%
- **Critical:** > 2%

### ANR (Application Not Responding) Rate
- **Target:** < 0.1%
- **Acceptable:** < 0.5%
- **Critical:** > 1%

### App Rating
- **Target:** > 4.0 stars
- **Acceptable:** > 3.5 stars
- **Critical:** < 3.0 stars

### Performance
- **Startup Time:** < 3 seconds
- **Memory Usage:** < 200 MB
- **Battery Impact:** Minimal
- **Network Usage:** Efficient

---

## 🔍 Test Results Analysis

### Firebase Console
1. Go to: https://console.firebase.google.com/project/flux/testlab
2. Find your test matrix ID
3. Review results:
   - Screenshots from test execution
   - Performance metrics
   - Logs and errors
   - Device information
   - Test duration

### Key Metrics to Check
- ✅ Crash rate
- ✅ ANR rate
- ✅ Startup time
- ✅ Memory usage
- ✅ Battery impact
- ✅ Network efficiency
- ✅ UI responsiveness
- ✅ Error logs

---

## 🛠️ Troubleshooting

### Error: "unrecognized arguments: --os-versions"
**Fix:** Use `--os-version-ids` instead of `--os-versions`

### Error: "model ['Pixel6Pro'] not found"
**Fix:** Use model ID like `lynx` instead of product name

### Error: "APK not found"
**Fix:** Use correct path: `build/app/outputs/flutter-apk/app-release.apk`

### Error: "Http error while creating test matrix: ResponseError 400"
**Fix:** Check device supports that OS version

### Test takes too long
**Fix:** Add `--timeout=900s` for longer tests

---

## 📈 Performance Benchmarks

### Expected Performance

| Operation | Time | Status |
|-----------|------|--------|
| App Startup | < 3s | ✅ |
| File Selection | < 1s | ✅ |
| Transfer Start | < 2s | ✅ |
| UI Responsiveness | < 100ms | ✅ |
| Memory Usage | < 200MB | ✅ |

---

## 🎯 Test Execution Plan

### Phase 1: Basic Testing (Day 1)
- [ ] Build release APK
- [ ] Run basic compatibility test (lynx, Android 33)
- [ ] Check for crashes
- [ ] Verify app launches

### Phase 2: Compatibility Testing (Day 2)
- [ ] Multi-version test (Android 31-35)
- [ ] Device diversity test (5 devices)
- [ ] Orientation testing
- [ ] Verify all combinations work

### Phase 3: Performance Testing (Day 3)
- [ ] Localization testing
- [ ] Memory profiling
- [ ] Battery impact analysis
- [ ] Network efficiency check

### Phase 4: Analysis & Optimization (Day 4)
- [ ] Review all results
- [ ] Identify issues
- [ ] Optimize performance
- [ ] Fix bugs

---

## 📋 Checklist

- [ ] gcloud CLI installed and configured
- [ ] Firebase project set up
- [ ] Google Cloud project with billing
- [ ] Release APK built successfully
- [ ] Test devices identified
- [ ] Test scenarios planned
- [ ] Performance targets defined
- [ ] Results analysis plan ready

---

## 🔗 Resources

- **Firebase Console:** https://console.firebase.google.com/project/flux/testlab
- **gcloud CLI Docs:** https://cloud.google.com/sdk/gcloud/reference
- **Firebase Test Lab Docs:** https://firebase.google.com/docs/test-lab
- **Android Testing Guide:** https://developer.android.com/training/testing

---

**Status:** ✅ Ready for Testing  
**Last Updated:** April 12, 2026

