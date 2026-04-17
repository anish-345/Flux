# Firebase Test Lab Setup Verification Script
# Run this to check if everything is installed and configured correctly

$checks = @()

function Add-Check {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FixCommand
    )
    
    $result = & $Test
    $checks += @{
        Name = $Name
        Passed = $result
        FixCommand = $FixCommand
    }
    
    $status = if ($result) { "✅" } else { "❌" }
    Write-Host "$status $Name"
    
    if (-not $result -and $FixCommand) {
        Write-Host "   Fix: $FixCommand" -ForegroundColor Yellow
    }
}

Write-Host "`n" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Firebase Test Lab Setup Verification" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

# Check Firebase CLI
Add-Check -Name "Firebase CLI" `
    -Test { $null -ne (Get-Command firebase -ErrorAction SilentlyContinue) } `
    -FixCommand "npm install -g firebase-tools"

# Check Java
Add-Check -Name "Java (JDK)" `
    -Test { $null -ne (Get-Command java -ErrorAction SilentlyContinue) } `
    -FixCommand "Install from: https://adoptium.net/"

# Check Google Cloud SDK
Add-Check -Name "Google Cloud SDK (gcloud)" `
    -Test { $null -ne (Get-Command gcloud -ErrorAction SilentlyContinue) } `
    -FixCommand "Run: GoogleCloudSDKInstaller.exe from $env:TEMP"

# Check Android SDK Platform Tools
Add-Check -Name "Android SDK Platform Tools (adb)" `
    -Test { $null -ne (Get-Command adb -ErrorAction SilentlyContinue) } `
    -FixCommand "Run: gcloud components install android-sdk-platform-tools"

# Check gcloud authentication
Add-Check -Name "gcloud Authentication" `
    -Test { 
        try {
            $auth = gcloud auth list 2>&1 | Select-String "ACTIVE"
            $null -ne $auth
        } catch {
            $false
        }
    } `
    -FixCommand "Run: gcloud auth login"

# Check Firebase project configuration
Add-Check -Name "Firebase Project Configuration" `
    -Test {
        try {
            $config = firebase projects:list 2>&1 | Select-String "pictopdf"
            $null -ne $config
        } catch {
            $false
        }
    } `
    -FixCommand "Run: firebase use --add and select pictopdf"

# Check Flutter
Add-Check -Name "Flutter SDK" `
    -Test { $null -ne (Get-Command flutter -ErrorAction SilentlyContinue) } `
    -FixCommand "Install from: https://flutter.dev/docs/get-started/install"

# Check if APK exists
$apkPath = "build/app/outputs/apk/release/app-release.apk"
Add-Check -Name "Built APK (for testing)" `
    -Test { Test-Path $apkPath } `
    -FixCommand "Run: flutter build apk --release"

# Summary
Write-Host "`n" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

$passed = ($checks | Where-Object { $_.Passed }).Count
$total = $checks.Count

Write-Host "`nPassed: $passed / $total" -ForegroundColor Cyan

if ($passed -eq $total) {
    Write-Host "`n✅ All checks passed! You're ready to test on Firebase Test Lab." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Green
    Write-Host "1. Build your app: flutter build apk --release" -ForegroundColor Green
    Write-Host "2. Run a test: gcloud firebase test android run --app=build/app/outputs/apk/release/app-release.apk --device-ids=Pixel6Pro --os-versions=33 --locales=en_US" -ForegroundColor Green
    Write-Host "3. View results: https://console.firebase.google.com/project/pictopdf/testlab" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Some checks failed. Please fix the issues above." -ForegroundColor Yellow
    Write-Host "`nFailed checks:" -ForegroundColor Yellow
    $checks | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Yellow
        if ($_.FixCommand) {
            Write-Host "    $($_.FixCommand)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n"

# Detailed version information
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Version Information" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "Firebase CLI: $firebaseVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Firebase CLI: Not installed" -ForegroundColor Yellow
}

try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "Java: $javaVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Java: Not installed" -ForegroundColor Yellow
}

try {
    $gcloudVersion = gcloud --version 2>&1 | Select-Object -First 1
    Write-Host "Google Cloud SDK: $gcloudVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Google Cloud SDK: Not installed" -ForegroundColor Yellow
}

try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "Flutter: $flutterVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Flutter: Not installed" -ForegroundColor Yellow
}

Write-Host "`n"
