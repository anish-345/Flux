# Firebase Test Lab - Web Console Guide (No CLI Required)

**Status:** ✅ APK Ready  
**Size:** 46.2 MB  
**Location:** `build/app/outputs/flutter-apk/app-release.apk`

---

## Why Web Console?

The web console is **easier** and **doesn't require** gcloud CLI installation. You can run tests directly from your browser.

---

## Step-by-Step Guide

### Step 1: Open Firebase Console
```
https://console.firebase.google.com/project/pictopdf/testlab
```

**What you'll see:**
- Firebase Console dashboard
- "Test Lab" section in left sidebar
- "Run a test" button

---

### Step 2: Click "Run a test"

**Location:** Top right of the Test Lab page

**What happens:**
- Test configuration page opens
- You'll see options to upload APK

---

### Step 3: Upload Your APK

**Option A: Drag and Drop**
1. Drag `build/app/outputs/flutter-apk/app-release.apk` onto the upload area
2. Wait for upload to complete

**Option B: Click to Browse**
1. Click "Choose file"
2. Navigate to: `C:\Users\anish\Documents\flux\build\app\outputs\flutter-apk\`
3. Select: `app-release.apk`
4. Click "Open"

**What to expect:**
- File uploads (may take 1-2 minutes for 46 MB)
- Progress bar shows upload status
- "Next" button becomes available

---

### Step 4: Configure Test Settings

**After upload completes, you'll see:**

#### Device Selection
1. Click "Device" section
2. Select: **Pixel 7a** (lynx)
3. OS Version: **Android 13** (API 33)
4. Locale: **English (US)**

#### Test Configuration
1. Test type: **Robo test** (automated exploration)
2. Timeout: **300 seconds** (5 minutes)
3. Orientation: **Portrait** (default)

#### Optional Settings
- Throttling: Leave as default
- Permissions: Leave as default

---

### Step 5: Review Configuration

**Before clicking "Start test", verify:**
- ✅ APK uploaded (46.2 MB)
- ✅ Device: Pixel 7a
- ✅ OS: Android 13
- ✅ Locale: English (US)
- ✅ Timeout: 300 seconds

---

### Step 6: Click "Start test"

**What happens:**
1. Test matrix is created
2. You'll see a **Matrix ID** (e.g., `matrix-xxxxx`)
3. Test status page opens
4. Status updates in real-time

**Timeline:**
- 0-2 min: Devices allocated
- 2-5 min: APK installed
- 5-10 min: Test runs
- 10+ min: Results available

---

### Step 7: Monitor Test Progress

**On the test status page:**
- Green checkmarks = completed steps
- Blue spinner = in progress
- Red X = failed step

**What's happening:**
1. **Allocating devices** - Firebase reserves test devices
2. **Installing app** - APK is installed on device
3. **Running test** - Robo test explores the app
4. **Collecting results** - Screenshots and logs are gathered

---

### Step 8: Review Results

**When test completes:**

#### Screenshots Tab
- Shows app screens captured during test
- Helps verify UI works correctly
- Look for any visual issues

#### Performance Tab
- **Crash rate:** Should be 0%
- **ANR rate:** Should be 0%
- **Startup time:** Should be <3 seconds
- **Memory:** Should be <200 MB

#### Logs Tab
- Detailed logs from test execution
- Look for errors or warnings
- Useful for debugging

#### Crash Reports Tab
- If any crashes occurred
- Shows stack traces
- Helps identify issues

---

## What to Look For

### ✅ Success Indicators
```
Crash rate: 0%
ANR rate: 0%
Startup time: 1-2 seconds
Memory usage: 100-150 MB
Frame rate: 60 FPS
```

### ❌ Failure Indicators
```
Crash rate: >0.5%
ANR rate: >0.1%
Startup time: >5 seconds
Memory usage: >300 MB
Frame rate: <30 FPS
```

---

## Running Multiple Tests

### Test 2: Multi-Device (After Test 1 completes)

1. Go back to Test Lab main page
2. Click "Run a test" again
3. Upload same APK
4. Select multiple devices:
   - Pixel 7a (lynx) - Android 13
   - Pixel 8a (akita) - Android 34
   - Pixel 8 Pro (husky) - Android 35
5. Click "Start test"

### Test 3: Orientation Test

1. Go back to Test Lab main page
2. Click "Run a test" again
3. Upload same APK
4. Select device: Pixel 7a
5. Under "Orientation", select: **Portrait and Landscape**
6. Click "Start test"

### Test 4: Localization Test

1. Go back to Test Lab main page
2. Click "Run a test" again
3. Upload same APK
4. Select device: Pixel 7a
5. Under "Locale", select multiple:
   - English (US)
   - Spanish (Spain)
   - French (France)
   - German (Germany)
   - Japanese (Japan)
   - Chinese (China)
6. Click "Start test"

---

## Troubleshooting

### Issue: "APK upload fails"
**Solution:**
1. Check file size (should be 46.2 MB)
2. Verify file path is correct
3. Try uploading again
4. Check internet connection

### Issue: "Test times out"
**Solution:**
1. Increase timeout to 600 seconds
2. Check if device is responding
3. Try with different device
4. Check Firebase Test Lab quota

### Issue: "Device not available"
**Solution:**
1. Try different device
2. Wait a few minutes and retry
3. Check Firebase Test Lab status page
4. Contact Firebase support

### Issue: "Can't see results"
**Solution:**
1. Refresh the page
2. Wait a few more minutes
3. Check if test is still running
4. Try different browser

---

## Interpreting Results

### Crash Rate
- **0%:** Perfect! No crashes detected
- **<0.5%:** Good, acceptable for production
- **>0.5%:** Investigate crashes, fix issues

### ANR Rate
- **0%:** Perfect! No ANRs detected
- **<0.1%:** Good, acceptable for production
- **>0.1%:** Investigate ANRs, optimize performance

### Startup Time
- **<2 seconds:** Excellent
- **2-3 seconds:** Good
- **3-5 seconds:** Acceptable
- **>5 seconds:** Needs optimization

### Memory Usage
- **<100 MB:** Excellent
- **100-200 MB:** Good
- **200-300 MB:** Acceptable
- **>300 MB:** Needs optimization

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Review performance metrics
2. Check for any warnings
3. Prepare for PlayStore submission
4. Create release notes

### If Issues Found ❌
1. Review crash reports
2. Check logs for errors
3. Fix identified issues
4. Rebuild APK: `flutter build apk --release`
5. Re-run tests

---

## Quick Reference

| Step | Action | Time |
|------|--------|------|
| 1 | Open Firebase Console | 1 min |
| 2 | Click "Run a test" | 1 min |
| 3 | Upload APK | 2 min |
| 4 | Configure settings | 2 min |
| 5 | Click "Start test" | 1 min |
| 6 | Wait for test | 10 min |
| 7 | Review results | 5 min |
| **Total** | | **22 min** |

---

## Resources

- **Firebase Console:** https://console.firebase.google.com/project/pictopdf/testlab
- **Firebase Test Lab Docs:** https://firebase.google.com/docs/test-lab
- **Android Testing Guide:** https://developer.android.com/training/testing
- **Firebase Support:** https://firebase.google.com/support

---

## Summary

The web console is the **easiest way** to run Firebase Test Lab tests:
1. No CLI installation needed
2. Visual interface is intuitive
3. Real-time progress monitoring
4. Easy to review results
5. Can run multiple tests sequentially

**Ready to test?** Open https://console.firebase.google.com/project/pictopdf/testlab now!

---

**Last Updated:** April 12, 2026  
**APK Status:** ✅ Ready  
**Estimated Test Time:** 10-15 minutes
