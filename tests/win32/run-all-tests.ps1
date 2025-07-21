# Master test runner for all MCP markdownify tools
# Runs all individual test scripts and provides comprehensive reporting

param(
    [string]$OutputDir = "$((Get-Location).Path)\tmp\output",
    [Alias("o")]
    [string]$Output = $null,
    [switch]$SkipDownload = $false,
    [switch]$QuickTest = $false,
    [string[]]$Tools = @()
)

# Use -o/--output parameter if provided
if ($Output) {
    $OutputDir = $Output
}

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

# Define all available test scripts
$AllTests = @{
    "webpage-to-markdown" = @{ Script = "test-webpage-to-markdown.ps1"; Category = "Web"; QuickTest = $true }
    "youtube-to-markdown" = @{ Script = "test-youtube-to-markdown.ps1"; Category = "Web"; QuickTest = $false }
    "bing-search-to-markdown" = @{ Script = "test-bing-search-to-markdown.ps1"; Category = "Web"; QuickTest = $true }
    "get-markdown-file" = @{ Script = "test-get-markdown-file.ps1"; Category = "File"; QuickTest = $true }
    "pdf-to-markdown" = @{ Script = "test-pdf-to-markdown.ps1"; Category = "Document"; QuickTest = $false }
    "docx-to-markdown" = @{ Script = "test-docx-to-markdown.ps1"; Category = "Document"; QuickTest = $false }
    "xlsx-to-markdown" = @{ Script = "test-xlsx-to-markdown.ps1"; Category = "Document"; QuickTest = $false }
    "pptx-to-markdown" = @{ Script = "test-pptx-to-markdown.ps1"; Category = "Document"; QuickTest = $false }
    "image-to-markdown" = @{ Script = "test-image-to-markdown.ps1"; Category = "Media"; QuickTest = $false }
    "audio-to-markdown" = @{ Script = "test-audio-to-markdown.ps1"; Category = "Media"; QuickTest = $false }
}

Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "    MCP Markdownify Tool Test Suite" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Skip Downloads: $SkipDownload" -ForegroundColor Gray
Write-Host "Quick Test Mode: $QuickTest" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Determine which tests to run
$TestsToRun = @{}
if ($Tools.Count -gt 0) {
    # Run specific tools
    foreach ($tool in $Tools) {
        if ($AllTests.ContainsKey($tool)) {
            $TestsToRun[$tool] = $AllTests[$tool]
        } else {
            Write-Host "Warning: Unknown tool '$tool' specified" -ForegroundColor Yellow
        }
    }
} elseif ($QuickTest) {
    # Run only quick tests
    foreach ($tool in $AllTests.Keys) {
        if ($AllTests[$tool].QuickTest) {
            $TestsToRun[$tool] = $AllTests[$tool]
        }
    }
} else {
    # Run all tests
    $TestsToRun = $AllTests
}

if ($TestsToRun.Count -eq 0) {
    Write-Host "No tests to run!" -ForegroundColor Red
    exit 1
}

Write-Host "Running $($TestsToRun.Count) test suites:" -ForegroundColor Cyan
foreach ($tool in $TestsToRun.Keys) {
    Write-Host "  - $tool ($($TestsToRun[$tool].Category))" -ForegroundColor Gray
}
Write-Host ""

# Initialize results tracking
$TestResults = @{}
$TotalPassed = 0
$TotalFailed = 0
$StartTime = Get-Date

# Run each test
foreach ($toolName in $TestsToRun.Keys) {
    $testInfo = $TestsToRun[$toolName]
    $scriptPath = Join-Path $PSScriptRoot $testInfo.Script
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Running: $toolName" -ForegroundColor Cyan
    Write-Host "Category: $($testInfo.Category)" -ForegroundColor Gray
    Write-Host "Script: $($testInfo.Script)" -ForegroundColor Gray
    Write-Host "================================================" -ForegroundColor Cyan
    
    if (!(Test-Path $scriptPath)) {
        Write-Host "[ERROR] Test script not found: $scriptPath" -ForegroundColor Red
        $TestResults[$toolName] = @{ Status = "Error"; Message = "Script not found"; ExitCode = -1 }
        $TotalFailed++
        continue
    }
    
    try {
        $testStart = Get-Date
        
        # Build arguments for the test script
        $scriptArgs = @("-OutputDir", $OutputDir)
        if ($SkipDownload) {
            $scriptArgs += "-SkipDownload"
        }
        
        # Run the test script
        & powershell.exe -ExecutionPolicy Bypass -File $scriptPath @scriptArgs
        $exitCode = $LASTEXITCODE
        
        $testEnd = Get-Date
        $duration = $testEnd - $testStart
        
        if ($exitCode -eq 0) {
            Write-Host "[SUCCESS] $toolName completed successfully" -ForegroundColor Green
            $TestResults[$toolName] = @{ 
                Status = "Passed"
                Message = "All tests passed"
                ExitCode = $exitCode
                Duration = $duration
            }
            $TotalPassed++
        } else {
            Write-Host "[FAILURE] $toolName had test failures" -ForegroundColor Red
            $TestResults[$toolName] = @{ 
                Status = "Failed"
                Message = "Some tests failed"
                ExitCode = $exitCode
                Duration = $duration
            }
            $TotalFailed++
        }
    }
    catch {
        Write-Host "[ERROR] Exception running $toolName" -ForegroundColor Red
        Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
        $TestResults[$toolName] = @{ 
            Status = "Error"
            Message = $_.Exception.Message
            ExitCode = -1
            Duration = New-TimeSpan
        }
        $TotalFailed++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 1
}

$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

# Generate comprehensive report
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "           COMPREHENSIVE REPORT" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "=== Test Suite Summary ===" -ForegroundColor Cyan
Write-Host "Total Test Suites: $($TestResults.Count)" -ForegroundColor White
Write-Host "Passed: $TotalPassed" -ForegroundColor Green
Write-Host "Failed: $TotalFailed" -ForegroundColor Red
Write-Host "Total Duration: $($TotalDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan

if ($TestResults.Count -gt 0) {
    $successRate = [math]::Round(($TotalPassed / $TestResults.Count) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

Write-Host ""

# Results by category
Write-Host "=== Results by Category ===" -ForegroundColor Cyan
$categories = $TestsToRun.Values | Group-Object Category
foreach ($category in $categories) {
    $categoryResults = $TestResults.GetEnumerator() | Where-Object { $TestsToRun[$_.Key].Category -eq $category.Name }
    $categoryPassed = ($categoryResults | Where-Object { $_.Value.Status -eq "Passed" }).Count
    $categoryTotal = $categoryResults.Count
    
    $status = if ($categoryPassed -eq $categoryTotal) { "[OK]" } else { "[WARN]" }
    Write-Host "$status $($category.Name): $categoryPassed/$categoryTotal passed" -ForegroundColor $(if ($categoryPassed -eq $categoryTotal) { "Green" } else { "Yellow" })
}

Write-Host ""

# Detailed results
Write-Host "=== Detailed Results ===" -ForegroundColor Cyan
foreach ($tool in $TestResults.Keys | Sort-Object) {
    $result = $TestResults[$tool]
    $category = $TestsToRun[$tool].Category
    
    $statusColor = switch ($result.Status) {
        "Passed" { "Green" }
        "Failed" { "Yellow" }
        "Error" { "Red" }
    }
    
    $statusIcon = switch ($result.Status) {
        "Passed" { "[PASS]" }
        "Failed" { "[FAIL]" }
        "Error" { "[ERROR]" }
    }
    
    Write-Host "$statusIcon $tool" -ForegroundColor $statusColor
    Write-Host "   Category: $category" -ForegroundColor Gray
    Write-Host "   Duration: $($result.Duration.ToString('mm\:ss'))" -ForegroundColor Gray
    Write-Host "   Message: $($result.Message)" -ForegroundColor Gray
    
    if ($result.Status -ne "Passed") {
        Write-Host "   Exit Code: $($result.ExitCode)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Final recommendations
Write-Host "=== Recommendations ===" -ForegroundColor Cyan
if ($TotalFailed -eq 0) {
    Write-Host "[SUCCESS] All tests passed! Your MCP markdownify server is working correctly." -ForegroundColor Green
    Write-Host "   • All 10 tools are functional" -ForegroundColor Green
    Write-Host "   • Ready for production use" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Some tests failed. Review the following:" -ForegroundColor Yellow
    
    $failedTests = $TestResults.GetEnumerator() | Where-Object { $_.Value.Status -ne "Passed" }
    foreach ($failed in $failedTests) {
        Write-Host "   • Check $($failed.Key): $($failed.Value.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Gray
    Write-Host "   • Network connectivity for file downloads" -ForegroundColor Gray
    Write-Host "   • Missing dependencies (Python, uv, Node.js packages)" -ForegroundColor Gray
    Write-Host "   • File access permissions" -ForegroundColor Gray
    Write-Host "   • MCP server build issues" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Output files saved to: $OutputDir" -ForegroundColor Gray
Write-Host "Test data files in: $((Split-Path -Parent (Split-Path -Parent (Get-Location))))\tmp\test-data" -ForegroundColor Gray

# Exit with appropriate code
if ($TotalFailed -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] ALL TESTS PASSED! MCP Server is ready!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "[FAIL] Some tests failed. Check individual test results above." -ForegroundColor Red
    exit 1
}