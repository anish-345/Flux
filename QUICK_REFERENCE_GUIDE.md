# Quick Reference Guide - Knowledge Base & Tools

**Last Updated:** April 12, 2026

---

## 🚀 Quick Start Commands

### Build the App
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Test on Firebase Test Lab (Single Device)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### Test on Multiple Devices
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35
```

### View Test Results
```
https://console.firebase.google.com/project/pictopdf/testlab
```

---

## 📱 Device Model IDs (Quick Reference)

| Device | Model ID | OS Versions |
|--------|----------|-------------|
| Pixel 7a | `lynx` | 33 |
| Pixel 8a | `akita` | 34, 35 |
| Pixel 8 Pro | `husky` | 34, 35 |
| Pixel 7 Pro | `cheetah` | 33 |
| Pixel 6a | `bluejay` | 32 |
| Pixel Fold | `felix` | 33, 34 |
| Pixel 9 Pro | `caiman` | 34, 35 |
| Pixel 9 Pro XL | `komodo` | 34, 35 |

**Get full list:** `gcloud firebase test android models list`

---

## ⚠️ Common Mistakes (Don't Do These!)

### ❌ WRONG → ✅ CORRECT

```
❌ --os-versions=33
✅ --os-version-ids=33

❌ --device-ids=Pixel6Pro
✅ --device-ids=lynx

❌ build/app/outputs/apk/release/app-release.apk
✅ build/app/outputs/flutter-apk/app-release.apk

❌ flutter build apk
✅ flutter build apk --release
```

---

## 📚 Knowledge Base Files

### Firebase Test Lab Knowledge
**File:** `.kiro/steering/firebase-testlab.md`  
**When to use:** When testing apps  
**Contains:**
- Correct parameters and syntax
- Device reference table
- Common mistakes and fixes
- Useful commands
- Test scenarios
- Troubleshooting guide

### Android Development & PlayStore Growth
**File:** `.kiro/steering/android-playstore-agency.md`  
**When to use:** When developing Android apps or planning PlayStore strategy  
**Contains:**
- Development best practices
- Architecture patterns
- Security guidelines
- PlayStore optimization (ASO)
- User acquisition strategies
- Monetization models
- Analytics and retention
- Business model and consulting

---

## 🔧 Useful gcloud Commands

### Discovery
```powershell
# List all devices
gcloud firebase test android models list

# List devices by brand
gcloud firebase test android models list --filter="brand:Google"

# Get device details
gcloud firebase test android models describe lynx

# List OS versions
gcloud firebase test android versions list

# List locales
gcloud firebase test android locales list
```

### Configuration
```powershell
# Set project
gcloud config set project pictopdf

# View current config
gcloud config list

# Initialize gcloud
gcloud init
```

---

## 📊 Test Scenarios

### Scenario 1: Basic Test (Recommended for First Test)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```
**Time:** 5-10 minutes  
**Cost:** ~$1-2

### Scenario 2: Multi-Device Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35
```
**Time:** 10-15 minutes  
**Cost:** ~$5-10

### Scenario 3: Orientation Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape
```
**Time:** 10-15 minutes  
**Cost:** ~$2-4

### Scenario 4: Locale Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE
```
**Time:** 10-15 minutes  
**Cost:** ~$3-5

---

## 🎯 Firebase Test Lab Workflow

### Step 1: Build
```bash
flutter build apk --release
```
**Expected output:** `build/app/outputs/flutter-apk/app-release.apk (46.0MB)`

### Step 2: Run Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```
**Expected output:** `matrix-XXXXXXXXXX` (test matrix ID)

### Step 3: Wait for Results
- Command shows test matrix ID
- Results appear in Firebase Console in 5-10 minutes
- Check for crashes, performance issues, UI problems

### Step 4: Review Results
1. Go to: https://console.firebase.google.com/project/pictopdf/testlab
2. Find your test matrix ID
3. Review screenshots and logs
4. Check for crashes and errors

---

## 💡 Pro Tips

### Tip 1: Always Use Release Build
```bash
# ✅ CORRECT
flutter build apk --release

# ❌ WRONG (debug build)
flutter build apk
```

### Tip 2: Test Multiple Devices
Don't just test on one device. Android fragmentation is real.

### Tip 3: Check Device Compatibility
```powershell
# Before running test, verify device supports OS version
gcloud firebase test android models describe lynx
```

### Tip 4: Use Timeout for Long Tests
```powershell
# Default timeout is 300 seconds (5 minutes)
# For longer tests, add:
--timeout=900s
```

### Tip 5: Monitor Quota
Firebase Test Lab has usage limits. Check your quota in Google Cloud Console.

---

## 🔍 Troubleshooting Quick Fixes

### Error: "unrecognized arguments: --os-versions"
**Fix:** Use `--os-version-ids` instead of `--os-versions`

### Error: "model ['Pixel6Pro'] not found"
**Fix:** Use model ID `lynx` instead of product name `Pixel6Pro`

### Error: "APK not found"
**Fix:** Use correct path: `build/app/outputs/flutter-apk/app-release.apk`

### Error: "Http error while creating test matrix: ResponseError 400"
**Fix:** Check device supports that OS version with `gcloud firebase test android models describe DEVICE_ID`

### Test takes too long
**Fix:** Add `--timeout=900s` for custom timeout

---

## 📈 Key Metrics to Monitor

### Quality Metrics
- **Crash Rate:** Target <0.5%
- **ANR Rate:** Target <0.1%
- **App Rating:** Target >4.0
- **Review Sentiment:** Positive vs negative

### Engagement Metrics
- **DAU:** Daily Active Users
- **Session Length:** Average session duration
- **Day 1 Retention:** Target >40%
- **Day 7 Retention:** Target >25%
- **Day 30 Retention:** Target >10%

### Monetization Metrics
- **ARPU:** Average Revenue Per User (target >$0.50)
- **Conversion Rate:** % users who make purchase (target 1-5%)
- **LTV:** Lifetime Value (target >$5.00)

---

## 🔗 Important Links

| Resource | URL |
|----------|-----|
| Firebase Console | https://console.firebase.google.com/project/pictopdf |
| Firebase Test Lab | https://console.firebase.google.com/project/pictopdf/testlab |
| Google Cloud Console | https://console.cloud.google.com |
| Google Play Console | https://play.google.com/console |
| AppMetrica Dashboard | https://appmetrica.yandex.com |
| Android Developers | https://developer.android.com |
| Flutter Docs | https://flutter.dev/docs |

---

## ✅ Pre-Test Checklist

- [ ] App builds successfully: `flutter build apk --release`
- [ ] APK file exists: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] gcloud is configured: `gcloud config list`
- [ ] Firebase project is set: `pictopdf`
- [ ] Device ID is valid: Check with `gcloud firebase test android models list`
- [ ] OS version is supported by device: Check with `gcloud firebase test android models describe DEVICE_ID`
- [ ] You have quota available: Check in Google Cloud Console

---

## 🎓 Learning Resources

### In This Workspace
- `KNOWLEDGE_BASE_SETUP_COMPLETE.md` - Knowledge base overview
- `PROJECT_STATUS.md` - Project status and next steps
- `.kiro/steering/firebase-testlab.md` - Firebase Test Lab guide
- `.kiro/steering/android-playstore-agency.md` - Android development guide

### External Resources
- [Firebase Test Lab Docs](https://firebase.google.com/docs/test-lab)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [Android Testing Guide](https://developer.android.com/training/testing)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)

---

**Last Updated:** April 12, 2026  
**Status:** ✅ Ready to Use
