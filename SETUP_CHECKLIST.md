# Firebase Test Lab Setup Checklist

## ✅ Installation Status

- [x] **Firebase CLI** - v15.3.1 installed
- [x] **Google Cloud SDK** - v564.0.0 installed
- [x] **Java (JDK)** - OpenJDK 17.0.16 installed
- [x] **Android SDK Platform Tools** - installed
- [x] **Flutter SDK** - v3.38.7 installed

---

## 📋 Configuration Checklist

### Phase 1: Google Cloud Setup (Do This First)

- [ ] **Initialize Google Cloud**
  ```powershell
  gcloud init
  ```
  - [ ] Sign in with your Google account
  - [ ] Select project: `pictopdf`
  - [ ] Choose region: `us-central1`

- [ ] **Verify Configuration**
  ```powershell
  gcloud config list
  gcloud auth list
  ```

### Phase 2: Firebase Configuration

- [ ] **Login to Firebase**
  ```powershell
  firebase login
  ```

- [ ] **Set Firebase Project**
  ```powershell
  firebase use --add
  # Select: pictopdf
  ```

- [ ] **Verify Firebase Setup**
  ```powershell
  firebase projects:list
  ```

### Phase 3: Build Your App

- [ ] **Build APK for Testing**
  ```bash
  cd your_flutter_project
  flutter build apk --release
  ```
  - [ ] Verify output: `build/app/outputs/apk/release/app-release.apk`

- [ ] **Optional: Build App Bundle (AAB)**
  ```bash
  flutter build appbundle --release
  ```
  - [ ] Verify output: `build/app/outputs/bundle/release/app-release.aab`

### Phase 4: Run Your First Test

- [ ] **Run Single Device Test**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro `
    --os-versions=33 `
    --locales=en_US
  ```
  - [ ] Note the test ID from the output

- [ ] **Wait for Test to Complete**
  - [ ] Check Firebase Console: https://console.firebase.google.com/project/pictopdf/testlab
  - [ ] Wait 5-10 minutes for results

- [ ] **View Test Results**
  ```powershell
  gcloud firebase test android results-list
  gcloud firebase test android results describe <test-id>
  ```

---

## 🧪 Testing Scenarios to Try

### Basic Tests

- [ ] **Single Device, Single OS**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro `
    --os-versions=33
  ```

- [ ] **Multiple Devices**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro,Pixel5,Pixel4 `
    --os-versions=33
  ```

- [ ] **Multiple OS Versions**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro `
    --os-versions=31,32,33,34
  ```

### Advanced Tests

- [ ] **Portrait and Landscape**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro `
    --os-versions=33 `
    --orientations=portrait,landscape
  ```

- [ ] **Multiple Locales**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro `
    --os-versions=33 `
    --locales=en_US,es_ES,fr_FR
  ```

- [ ] **Matrix Test (All Combinations)**
  ```powershell
  gcloud firebase test android run `
    --app=build/app/outputs/apk/release/app-release.apk `
    --device-ids=Pixel6Pro,Pixel5 `
    --os-versions=33,34 `
    --locales=en_US,es_ES `
    --orientations=portrait,landscape
  ```

---

## 🔍 Verification Commands

Run these to verify everything is working:

- [ ] **Check All Tools**
  ```powershell
  & ".\verify-firebase-setup.ps1"
  ```

- [ ] **Check gcloud**
  ```powershell
  gcloud --version
  gcloud config list
  ```

- [ ] **Check Firebase**
  ```powershell
  firebase --version
  firebase projects:list
  ```

- [ ] **Check Java**
  ```powershell
  java -version
  ```

- [ ] **Check Flutter**
  ```bash
  flutter --version
  ```

- [ ] **Check Android Tools**
  ```powershell
  adb version
  ```

---

## 📊 Monitoring & Results

- [ ] **View Test Results in Console**
  - Go to: https://console.firebase.google.com/project/pictopdf/testlab
  - Click on your test run
  - Review screenshots, logs, and metrics

- [ ] **Download Test Results**
  ```powershell
  gcloud firebase test android results download <test-id> --destination=./results
  ```

- [ ] **View Test Logs**
  ```powershell
  gcloud firebase test android results log <test-id>
  ```

---

## 🚀 Integration & Automation

- [ ] **Add to CI/CD Pipeline**
  - [ ] Create GitHub Actions workflow
  - [ ] Add Firebase Test Lab step
  - [ ] Configure test matrix

- [ ] **Setup Automated Testing**
  - [ ] Schedule nightly tests
  - [ ] Test on every release
  - [ ] Monitor performance metrics

- [ ] **Create Test Reports**
  - [ ] Save test results
  - [ ] Track performance over time
  - [ ] Identify regressions

---

## 📚 Documentation Review

- [ ] **Read Setup Guide**
  - [ ] Review: `FIREBASE_TEST_LAB_SETUP.md`

- [ ] **Review Command Reference**
  - [ ] Review: `FIREBASE_TEST_LAB_COMMANDS.md`

- [ ] **Check Quick Start**
  - [ ] Review: `QUICK_START_FIREBASE_TESTLAB.md`

- [ ] **Bookmark Resources**
  - [ ] Firebase Test Lab Docs: https://firebase.google.com/docs/test-lab
  - [ ] gcloud CLI Reference: https://cloud.google.com/sdk/gcloud/reference
  - [ ] Firebase Console: https://console.firebase.google.com/project/pictopdf/testlab

---

## 🐛 Troubleshooting

If you encounter issues:

- [ ] **Check Prerequisites**
  ```powershell
  & ".\verify-firebase-setup.ps1"
  ```

- [ ] **Verify Authentication**
  ```powershell
  gcloud auth list
  firebase auth:list
  ```

- [ ] **Check Project Configuration**
  ```powershell
  gcloud config list
  firebase projects:list
  ```

- [ ] **Review Logs**
  ```powershell
  gcloud firebase test android results describe <test-id>
  ```

- [ ] **Consult Documentation**
  - Review: `FIREBASE_TEST_LAB_SETUP.md` (Troubleshooting section)
  - Visit: https://firebase.google.com/docs/test-lab/troubleshooting

---

## ✨ Success Criteria

You'll know everything is working when:

- [x] All tools are installed and verified
- [ ] `gcloud init` completes successfully
- [ ] `firebase login` completes successfully
- [ ] `flutter build apk --release` creates an APK
- [ ] `gcloud firebase test android run` starts a test
- [ ] Test results appear in Firebase Console within 10 minutes
- [ ] You can view screenshots and logs from the test

---

## 📝 Notes

Use this space to track your progress:

```
Date: _______________
Test ID: _______________
Device: _______________
OS Version: _______________
Result: _______________
Notes: _______________
```

---

## 🎯 Next Steps After Setup

1. **Integrate into CI/CD** - Add Firebase Test Lab to your build pipeline
2. **Create Test Matrix** - Define devices and OS versions to test
3. **Monitor Performance** - Track test results over time
4. **Automate Testing** - Schedule regular test runs
5. **Share Results** - Set up reporting for your team

---

**Last Updated:** April 12, 2026  
**Status:** Ready to Use ✅
