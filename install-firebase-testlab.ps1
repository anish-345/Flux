# Firebase Test Lab Setup Script for Windows
# This script installs and configures all necessary tools for Firebase Test Lab

param(
    [switch]$SkipGcloud = $false,
    [switch]$SkipAndroidSDK = $false,
    [switch]$SkipFirebaseInit = $false
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check prerequisites
Write-Header "Checking Prerequisites"

# Check Firebase CLI
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Success "Firebase CLI installed: $firebaseVersion"
} catch {
    Write-Error "Firebase CLI not found. Install from: https://firebase.google.com/docs/cli"
    exit 1
}

# Check Java
try {
    $javaVersion = java -version 2>&1
    Write-Success "Java installed: $(($javaVersion | Select-Object -First 1))"
} catch {
    Write-Error "Java not found. Install from: https://adoptium.net/"
    exit 1
}

# Check gcloud
$gcloudExists = $null -ne (Get-Command gcloud -ErrorAction SilentlyContinue)
if ($gcloudExists) {
    $gcloudVersion = gcloud --version 2>&1 | Select-Object -First 1
    Write-Success "Google Cloud SDK already installed: $gcloudVersion"
} else {
    Write-Warning "Google Cloud SDK not installed"
    
    if (-not $SkipGcloud) {
        Write-Header "Installing Google Cloud SDK"
        
        $installerPath = "$env:TEMP\GoogleCloudSDKInstaller.exe"
        
        if (-not (Test-Path $installerPath)) {
            Write-Host "Downloading Google Cloud SDK installer..." -ForegroundColor Cyan
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" `
                -OutFile $installerPath -ErrorAction Stop
            Write-Success "Downloaded to: $installerPath"
        } else {
            Write-Success "Installer already downloaded: $installerPath"
        }
        
        Write-Host "Starting Google Cloud SDK installer..." -ForegroundColor Cyan
        Write-Host "Please follow the installation wizard:" -ForegroundColor Yellow
        Write-Host "  1. Accept the license agreement" -ForegroundColor Yellow
        Write-Host "  2. Choose installation directory (default is fine)" -ForegroundColor Yellow
        Write-Host "  3. Check 'Install Python' if needed" -ForegroundColor Yellow
        Write-Host "  4. Check 'Create Start Menu shortcuts'" -ForegroundColor Yellow
        Write-Host "  5. Click 'Install'" -ForegroundColor Yellow
        
        & $installerPath
        
        Write-Host "Waiting for installation to complete..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        if ($null -ne (Get-Command gcloud -ErrorAction SilentlyContinue)) {
            Write-Success "Google Cloud SDK installed successfully"
        } else {
            Write-Error "Google Cloud SDK installation may have failed. Please restart PowerShell and try again."
        }
    }
}

# Initialize gcloud if not already done
Write-Header "Configuring Google Cloud SDK"

try {
    $gcloudConfig = gcloud config list 2>&1
    if ($gcloudConfig -match "project") {
        Write-Success "Google Cloud SDK already configured"
    } else {
        Write-Warning "Google Cloud SDK needs configuration"
        Write-Host "Run: gcloud init" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Could not verify gcloud configuration"
}

# Check Android SDK
Write-Header "Checking Android SDK"

$adbExists = $null -ne (Get-Command adb -ErrorAction SilentlyContinue)
if ($adbExists) {
    Write-Success "Android SDK Platform Tools found"
} else {
    Write-Warning "Android SDK Platform Tools not found"
    
    if (-not $SkipAndroidSDK) {
        Write-Host "Installing Android SDK components..." -ForegroundColor Cyan
        try {
            gcloud components install android-emulator --quiet
            gcloud components install android-sdk-platform-tools --quiet
            Write-Success "Android SDK components installed"
        } catch {
            Write-Warning "Could not install Android SDK components automatically"
            Write-Host "Install manually: gcloud components install android-sdk-platform-tools" -ForegroundColor Yellow
        }
    }
}

# Firebase CLI configuration
Write-Header "Configuring Firebase CLI"

if (-not $SkipFirebaseInit) {
    Write-Host "Checking Firebase authentication..." -ForegroundColor Cyan
    try {
        $authStatus = firebase auth:list 2>&1
        if ($authStatus -match "logged in") {
            Write-Success "Firebase CLI already authenticated"
        } else {
            Write-Host "Run: firebase login" -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Firebase authentication check failed"
        Write-Host "Run: firebase login" -ForegroundColor Yellow
    }
}

# Summary
Write-Header "Setup Summary"

Write-Host "`nInstalled Components:" -ForegroundColor Cyan
Write-Success "Firebase CLI: $(firebase --version 2>&1)"
Write-Success "Java: $(java -version 2>&1 | Select-Object -First 1)"

if ($null -ne (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Success "Google Cloud SDK: $(gcloud --version 2>&1 | Select-Object -First 1)"
} else {
    Write-Warning "Google Cloud SDK: Not yet installed"
}

if ($adbExists) {
    Write-Success "Android SDK Platform Tools: Installed"
} else {
    Write-Warning "Android SDK Platform Tools: Not installed"
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Restart PowerShell to refresh PATH" -ForegroundColor Yellow
Write-Host "2. Run: gcloud init" -ForegroundColor Yellow
Write-Host "3. Run: firebase login" -ForegroundColor Yellow
Write-Host "4. Build your app: flutter build apk --release" -ForegroundColor Yellow
Write-Host "5. Test on Firebase Test Lab: gcloud firebase test android run --app=path/to/app.apk" -ForegroundColor Yellow

Write-Host "`nFor more information, see: FIREBASE_TEST_LAB_SETUP.md" -ForegroundColor Cyan
Write-Host "`n"
