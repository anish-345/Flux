# Firebase Test Lab - Corrected Commands

## ⚠️ Important Parameter Corrections

The documentation had some incorrect parameters. Here are the **correct** commands to use:

---

## Key Corrections

### ❌ WRONG
```powershell
--os-versions=33
--device-ids=Pixel6Pro
```

### ✅ CORRECT
```powershell
--os-version-ids=33
--device-ids=lynx  # Use model ID, not product name
```

---

## Available Device Model IDs

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
| Pixel 2 (Arm) | `Pixel2.arm` | 26-33 |

Get full list: `gcloud firebase test android models list`

---

## Correct Command Examples

### Single Device Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US
```

### Multiple Devices
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35 `
  --locales=en_US
```

### Multiple OS Versions
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=32,33,34 `
  --locales=en_US
```

### With Orientations
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --orientations=portrait,landscape
```

### With Multiple Locales
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US,es_ES,fr_FR,de_DE
```

### Matrix Test (All Combinations)
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx,akita,husky `
  --os-version-ids=33,34,35 `
  --locales=en_US,es_ES `
  --orientations=portrait,landscape
```

### With Custom Timeout
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --timeout=900s
```

---

## Information Commands (Correct)

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

### Get Device Details
```powershell
gcloud firebase test android models describe lynx
```

---

## View Test Results

### In Firebase Console
1. Go to: https://console.firebase.google.com/project/pictopdf/testlab
2. Click on your test run
3. View screenshots, logs, and metrics

### Via Command Line
```powershell
# The test matrix ID is shown when you run the test
# Example: Test [matrix-1fa82n18ojk6k] has been created

# View results in console (no direct CLI command for results-list)
# Use the URL provided in the test output
```

---

## Common Mistakes to Avoid

| ❌ Wrong | ✅ Correct | Reason |
|---------|-----------|--------|
| `--os-versions=33` | `--os-version-ids=33` | Parameter name is `os-version-ids` |
| `--device-ids=Pixel6Pro` | `--device-ids=lynx` | Use model ID, not product name |
| `--app=build/app/outputs/apk/release/app-release.apk` | `--app=build/app/outputs/flutter-apk/app-release.apk` | Flutter builds to `flutter-apk` folder |
| `gcloud firebase test android results-list` | Use Firebase Console | No direct CLI command for listing results |

---

## Quick Reference

### Build Your App
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Run a Test
```powershell
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33
```

### View Results
- Console: https://console.firebase.google.com/project/pictopdf/testlab
- Look for the test matrix ID in the command output

---

## Helpful Commands

### Get Device Model IDs
```powershell
gcloud firebase test android models list | Select-String "MODEL_ID|lynx|akita|husky"
```

### Get OS Versions for a Device
```powershell
gcloud firebase test android models describe lynx
```

### Get Available Locales
```powershell
gcloud firebase test android locales list | Select-String "LOCALE" -Context 1
```

---

## Your First Successful Test

```powershell
# Build
flutter build apk --release

# Test (Pixel 7a with Android 13)
gcloud firebase test android run `
  --app=build/app/outputs/flutter-apk/app-release.apk `
  --device-ids=lynx `
  --os-version-ids=33 `
  --locales=en_US

# View results at:
# https://console.firebase.google.com/project/pictopdf/testlab
```

---

## Support

For more information:
- Device list: `gcloud firebase test android models list`
- OS versions: `gcloud firebase test android versions list`
- Locales: `gcloud firebase test android locales list`
- Firebase Console: https://console.firebase.google.com/project/pictopdf/testlab

---

**Last Updated:** April 12, 2026  
**Status:** ✅ Corrected Commands
