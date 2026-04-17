# Firebase Test Lab Performance Testing Script
# Project: Flux (Flutter + Rust File Transfer)
# Date: April 12, 2026

# Configuration
$PROJECT_ID = "flux"
$APK_PATH = "build/app/outputs/flutter-apk/app-release.apk"
$RESULTS_DIR = "test_results"

# Colors for output
$GREEN = "`e[32m"
$RED = "`e[31m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

# Create results directory
if (-not (Test-Path $RESULTS_DIR)) {
    New-Item -ItemType Directory -Path $RESULTS_DIR | Out-Null
}

Write-Host "${BLUE}========================================${RESET}"
Write-Host "${BLUE}Firebase Test Lab - Performance Testing${RESET}"
Write-Host "${BLUE}========================================${RESET}"
Write-Host ""

# Function to run test
function Run-Test {
    param(
        [string]$TestName,
        [string]$DeviceIds,
        [string]$OsVersionIds,
        [string]$Locales = "en_US",
        [string]$Orientations = "portrait"
    )
    
    Write-Host "${YELLOW}[TEST] $TestName${RESET}"
    Write-Host "Devices: $DeviceIds"
    Write-Host "OS Versions: $OsVersionIds"
    Write-Host "Locales: $Locales"
    Write-Host "Orientations: $Orientations"
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = "$RESULTS_DIR/${TestName}_${timestamp}.log"
    
    try {
        Write-Host "${BLUE}Running test...${RESET}"
        
        $command = @(
            "gcloud firebase test android run",
            "--app=$APK_PATH",
            "--device-ids=$DeviceIds",
            "--os-version-ids=$OsVersionIds",
            "--locales=$Locales",
            "--orientations=$Orientations",
            "--timeout=900s"
        ) -join " "
        
        # Run the test
        Invoke-Expression $command 2>&1 | Tee-Object -FilePath $logFile
        
        Write-Host "${GREEN}✅ Test completed: $TestName${RESET}"
        Write-Host "Results saved to: $logFile"
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "${RED}❌ Test failed: $TestName${RESET}"
        Write-Host "Error: $_"
        Write-Host ""
        return $false
    }
}

# Function to check APK
function Check-APK {
    Write-Host "${YELLOW}[CHECK] Verifying APK...${RESET}"
    
    if (Test-Path $APK_PATH) {
        $size = (Get-Item $APK_PATH).Length / 1MB
        Write-Host "${GREEN}✅ APK found: $APK_PATH${RESET}"
        Write-Host "Size: $([Math]::Round($size, 2)) MB"
        Write-Host ""
        return $true
    }
    else {
        Write-Host "${RED}❌ APK not found: $APK_PATH${RESET}"
        Write-Host "Please build the APK first: flutter build apk --release"
        Write-Host ""
        return $false
    }
}

# Function to check gcloud
function Check-GCloud {
    Write-Host "${YELLOW}[CHECK] Verifying gcloud CLI...${RESET}"
    
    try {
        $version = gcloud --version 2>&1 | Select-Object -First 1
        Write-Host "${GREEN}✅ gcloud CLI found${RESET}"
        Write-Host $version
        Write-Host ""
        return $true
    }
    catch {
        Write-Host "${RED}❌ gcloud CLI not found${RESET}"
        Write-Host "Please install gcloud CLI: https://cloud.google.com/sdk/docs/install"
        Write-Host ""
        return $false
    }
}

# Function to set project
function Set-Project {
    Write-Host "${YELLOW}[CONFIG] Setting Google Cloud project...${RESET}"
    
    try {
        gcloud config set project $PROJECT_ID 2>&1 | Out-Null
        Write-Host "${GREEN}✅ Project set to: $PROJECT_ID${RESET}"
        Write-Host ""
        return $true
    }
    catch {
        Write-Host "${RED}❌ Failed to set project${RESET}"
        Write-Host "Error: $_"
        Write-Host ""
        return $false
    }
}

# Main execution
Write-Host "${BLUE}Starting Firebase Test Lab Performance Testing${RESET}"
Write-Host ""

# Pre-flight checks
Write-Host "${BLUE}=== PRE-FLIGHT CHECKS ===${RESET}"
Write-Host ""

if (-not (Check-GCloud)) { exit 1 }
if (-not (Check-APK)) { exit 1 }
if (-not (Set-Project)) { exit 1 }

# Test execution
Write-Host "${BLUE}=== TEST EXECUTION ===${RESET}"
Write-Host ""

$results = @()

# Test 1: Basic Compatibility
$results += @{
    Name = "Test 1: Basic Compatibility"
    Result = Run-Test -TestName "01_basic_compatibility" -DeviceIds "lynx" -OsVersionIds "33"
}

# Test 2: Multi-Version Compatibility
$results += @{
    Name = "Test 2: Multi-Version Compatibility"
    Result = Run-Test -TestName "02_multi_version" -DeviceIds "lynx" -OsVersionIds "31,32,33,34,35"
}

# Test 3: Device Diversity
$results += @{
    Name = "Test 3: Device Diversity"
    Result = Run-Test -TestName "03_device_diversity" -DeviceIds "lynx,akita,husky" -OsVersionIds "33,34,35"
}

# Test 4: Orientation Testing
$results += @{
    Name = "Test 4: Orientation Testing"
    Result = Run-Test -TestName "04_orientation" -DeviceIds "lynx" -OsVersionIds "33" -Orientations "portrait,landscape"
}

# Test 5: Localization Testing
$results += @{
    Name = "Test 5: Localization Testing"
    Result = Run-Test -TestName "05_localization" -DeviceIds "lynx" -OsVersionIds "33" -Locales "en_US,es_ES,fr_FR,de_DE,ja_JP,zh_CN"
}

# Summary
Write-Host "${BLUE}=== TEST SUMMARY ===${RESET}"
Write-Host ""

$passed = 0
$failed = 0

foreach ($result in $results) {
    if ($result.Result) {
        Write-Host "${GREEN}✅ $($result.Name)${RESET}"
        $passed++
    }
    else {
        Write-Host "${RED}❌ $($result.Name)${RESET}"
        $failed++
    }
}

Write-Host ""
Write-Host "Total: $($passed + $failed) | Passed: $passed | Failed: $failed"
Write-Host ""

# Performance metrics
Write-Host "${BLUE}=== PERFORMANCE METRICS ===${RESET}"
Write-Host ""
Write-Host "Expected Performance Targets:"
Write-Host "  • Crash Rate: < 0.5%"
Write-Host "  • ANR Rate: < 0.1%"
Write-Host "  • Startup Time: < 3 seconds"
Write-Host "  • Memory Usage: < 200 MB"
Write-Host "  • App Rating: > 4.0 stars"
Write-Host ""

# Results location
Write-Host "${BLUE}=== RESULTS ===${RESET}"
Write-Host ""
Write-Host "Test results saved to: $RESULTS_DIR"
Write-Host "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/testlab"
Write-Host ""

# Final status
if ($failed -eq 0) {
    Write-Host "${GREEN}✅ All tests completed successfully!${RESET}"
    exit 0
}
else {
    Write-Host "${RED}❌ Some tests failed. Please review the logs.${RESET}"
    exit 1
}
