# Firebase Test Lab - Quick Command Reference

## Build Commands

### Build APK (for testing)
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Build App Bundle (AAB)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build with specific flavor
```bash
flutter build apk --release --flavor production
```

---

## Firebase Test Lab Commands

### Basic Test Run (APK)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US
```

### Test Multiple Devices
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35 `
  --locales=en_US
```

### Test with Custom Timeout
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --timeout=900s
```

### Test with Orientations
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape
```

### Test with Instrumentation Tests
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --test=build/app/outputs/apk/androidTest/release/app-release-androidTest.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33
```

### Test with Robo Script
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --robo-script=path/to/robo-script.json
```

---

## Information & Configuration Commands

### List Available Devices
```powershell
gcloud firebase test android models list
gcloud firebase test android models list --filter="brand:Google"
```

### List Available OS Versions
```powershell
gcloud firebase test android versions list
```

### List Available Locales
```powershell
gcloud firebase test android locales list
```

### List Available Orientations
```powershell
gcloud firebase test android orientations list
```

### Get Device Details
```powershell
gcloud firebase test android models describe Pixel6Pro
```

---

## Results & Monitoring Commands

### List All Test Runs
```powershell
gcloud firebase test android results-list
```

### Get Specific Test Results
```powershell
gcloud firebase test android results describe <test-id>
```

### Download Test Results
```powershell
gcloud firebase test android results download <test-id> --destination=./results
```

### View Test Logs
```powershell
gcloud firebase test android results log <test-id>
```

### Monitor Test Progress
```powershell
gcloud firebase test android results describe <test-id> --format=json
```

---

## Configuration Commands

### Set Default Project
```powershell
gcloud config set project pictopdf
```

### List Current Configuration
```powershell
gcloud config list
```

### Set Default Region
```powershell
gcloud config set compute/region us-central1
```

### View Firebase Project Info
```powershell
gcloud firebase projects describe pictopdf
```

---

## Firebase CLI Commands

### Login to Firebase
```powershell
firebase login
```

### List Firebase Projects
```powershell
firebase projects:list
```

### Use Specific Project
```powershell
firebase use pictopdf
```

### View Firebase Configuration
```powershell
firebase projects:describe pictopdf
```

### Deploy to Firebase Hosting (if applicable)
```powershell
firebase deploy --only hosting
```

---

## Advanced Testing Scenarios

### Performance Testing
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --performance-metrics
```

### Test with Network Throttling
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --network-profile=LTE
```

### Test Multiple Configurations (Matrix)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro,Pixel5,Pixel4 `
  --os-versions=32,33,34 `
  --locales=en_US,es_ES,fr_FR `
  --orientations=portrait,landscape
```

### Test with Custom Environment Variables
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/apk/release/app-release.apk `
  --device-ids=Pixel6Pro `
  --os-versions=33 `
  --environment-variables=KEY1=value1,KEY2=value2
```

---

## Troubleshooting Commands

### Check gcloud Installation
```powershell
gcloud --version
gcloud components list
```

### Update gcloud Components
```powershell
gcloud components update
```

### Check Authentication
```powershell
gcloud auth list
gcloud auth application-default login
```

### Verify Firebase Project Access
```powershell
gcloud firebase projects describe pictopdf
```

### Check Available Quota
```powershell
gcloud firebase test android quotas
```

### View Recent Test Runs
```powershell
gcloud firebase test android results-list --limit=10
```

---

## Common Device IDs for Testing

| Device | ID | OS Range |
|--------|----|----|
| Pixel 6 Pro | `Pixel6Pro` | 31-34 |
| Pixel 5 | `Pixel5` | 30-34 |
| Pixel 4 | `Pixel4` | 29-33 |
| Pixel 3 | `Pixel3` | 28-32 |
| Samsung Galaxy S21 | `GalaxyS21` | 31-34 |
| Samsung Galaxy S20 | `GalaxyS20` | 29-33 |
| OnePlus 9 | `OnePlus9` | 31-34 |
| Motorola Moto G7 | `MotoG7` | 28-32 |

---

## Tips & Best Practices

1. **Always build in release mode** for production testing
2. **Test on multiple devices** to catch device-specific issues
3. **Use matrix testing** to test multiple configurations at once
4. **Monitor quota** to avoid hitting limits
5. **Save test results** for regression testing
6. **Use robo scripts** for automated UI testing
7. **Test different orientations** for responsive design
8. **Include performance metrics** to catch performance regressions

---

## Useful Links

- [Firebase Test Lab Documentation](https://firebase.google.com/docs/test-lab)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference/firebase/test)
- [Android Testing Guide](https://developer.android.com/training/testing)
- [Firebase Console](https://console.firebase.google.com)
