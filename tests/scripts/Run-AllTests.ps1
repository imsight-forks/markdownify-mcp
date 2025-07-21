# Run-AllTests.ps1
# Master test runner for MCP markdownify server

param(
    [string]$ProjectPath = "D:\tools\markdownify-mcp",
    [string]$OutputPath = "D:\tools\markdownify-mcp\tests\output",
    [string]$ReportsPath = "D:\tools\markdownify-mcp\tests\reports"
)

# Test suite configuration
$testScripts = @(
    @{ Name = "Basic Server Functionality"; Script = "Test-BasicServerFunctionality.ps1"; Critical = $true },
    @{ Name = "All Tools Testing"; Script = "Test-AllTools.ps1"; Critical = $false },
    @{ Name = "Error Handling"; Script = "Test-ErrorHandling.ps1"; Critical = $false }
)

$script:OverallResults = @()
$script:TotalPassed = 0
$script:TotalFailed = 0
$script:CriticalFailures = 0

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
}

function Run-TestScript {
    param(
        [string]$ScriptName,
        [string]$DisplayName,
        [bool]$IsCritical = $false
    )
    
    $scriptPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) $ScriptName
    
    if (!(Test-Path $scriptPath)) {
        Write-Host "[ERROR] Test script not found: $scriptPath" -ForegroundColor Red
        return @{ Success = $false; ExitCode = -1; Output = "Script not found"; Duration = "0ms" }
    }
    
    Write-Host "`n>> Starting: $DisplayName" -ForegroundColor Cyan
    Write-Host "   Script: $ScriptName" -ForegroundColor Gray
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Run the test script
        $output = & powershell -ExecutionPolicy Bypass -File $scriptPath -ProjectPath $ProjectPath -OutputPath $OutputPath 2>&1
        $exitCode = $LASTEXITCODE
        
        $stopwatch.Stop()
        $duration = "$($stopwatch.Elapsed.TotalSeconds.ToString('F2'))s"
        
        if ($exitCode -eq 0) {
            Write-Host "[SUCCESS] $DisplayName completed successfully" -ForegroundColor Green
            return @{ Success = $true; ExitCode = $exitCode; Output = $output; Duration = $duration }
        } else {
            Write-Host "[FAILED] $DisplayName failed (exit code: $exitCode)" -ForegroundColor Red
            if ($IsCritical) {
                Write-Host "[WARNING] CRITICAL TEST FAILED!" -ForegroundColor Yellow
            }
            return @{ Success = $false; ExitCode = $exitCode; Output = $output; Duration = $duration }
        }
    }
    catch {
        $stopwatch.Stop()
        $duration = "$($stopwatch.Elapsed.TotalSeconds.ToString('F2'))s"
        Write-Host "[EXCEPTION] $DisplayName threw an exception" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        return @{ Success = $false; ExitCode = -1; Output = $_.Exception.Message; Duration = $duration }
    }
}

function Load-TestResults {
    param([string]$ResultFile)
    
    if (Test-Path $ResultFile) {
        try {
            $content = Get-Content $ResultFile -Raw | ConvertFrom-Json
            return $content
        }
        catch {
            Write-Warning "Failed to load results from $ResultFile`: $($_.Exception.Message)"
            return @()
        }
    }
    return @()
}

# Main execution
Write-Header "MCP Markdownify Server - Comprehensive Test Suite"

Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "Reports Path: $ReportsPath" -ForegroundColor Gray
Write-Host "Test Start Time: $(Get-Date)" -ForegroundColor Gray

# Ensure directories exist
@($OutputPath, $ReportsPath) | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Ensure we're in the correct directory
Set-Location $ProjectPath

# Check prerequisites
Write-Header "Prerequisites Check"

# Check if server is built
$distPath = Join-Path $ProjectPath "dist"
if (Test-Path $distPath) {
    Write-Host "[OK] Build directory exists" -ForegroundColor Green
} else {
    Write-Host "[INFO] Build directory missing - running build..." -ForegroundColor Yellow
    & npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Build failed! Cannot continue with tests." -ForegroundColor Red
        exit 1
    }
}

# Check if MCP Inspector is available
try {
    $null = & npx @modelcontextprotocol/inspector --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] MCP Inspector is available" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] MCP Inspector may not be installed properly" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[WARNING] Could not verify MCP Inspector installation" -ForegroundColor Yellow
}

# Run all test scripts
Write-Header "Test Execution"

foreach ($test in $testScripts) {
    $result = Run-TestScript -ScriptName $test.Script -DisplayName $test.Name -IsCritical $test.Critical
    
    $testResult = @{
        TestSuite = $test.Name
        ScriptName = $test.Script
        Success = $result.Success
        ExitCode = $result.ExitCode
        Duration = $result.Duration
        IsCritical = $test.Critical
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:OverallResults += $testResult
    
    if ($result.Success) {
        $script:TotalPassed++
    } else {
        $script:TotalFailed++
        if ($test.Critical) {
            $script:CriticalFailures++
        }
    }
}

# Collect and aggregate individual test results
Write-Header "Results Aggregation"

$allIndividualResults = @()

# Load results from each test suite
$resultFiles = @(
    "basic-functionality-test-results.json",
    "all-tools-test-results.json", 
    "error-handling-test-results.json"
)

foreach ($file in $resultFiles) {
    $filePath = Join-Path $OutputPath $file
    $results = Load-TestResults $filePath
    if ($results) {
        $allIndividualResults += $results
        Write-Host "[INFO] Loaded $(($results | Measure-Object).Count) results from $file" -ForegroundColor Gray
    }
}

# Generate comprehensive report
Write-Header "Test Results Summary"

Write-Host "`n>> Test Suite Results:" -ForegroundColor Cyan
foreach ($result in $script:OverallResults) {
    $status = if ($result.Success) { "[PASS]" } else { "[FAIL]" }
    $critical = if ($result.IsCritical) { " [CRITICAL]" } else { "" }
    Write-Host "$status $($result.TestSuite)$critical - $($result.Duration)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
}

Write-Host "`n>> Overall Statistics:" -ForegroundColor Cyan
Write-Host "Test Suites Passed: $script:TotalPassed" -ForegroundColor Green
Write-Host "Test Suites Failed: $script:TotalFailed" -ForegroundColor Red
Write-Host "Critical Failures: $script:CriticalFailures" -ForegroundColor $(if ($script:CriticalFailures -gt 0) { "Red" } else { "Green" })

if ($allIndividualResults.Count -gt 0) {
    $individualPassed = ($allIndividualResults | Where-Object { $_.Passed }).Count
    $individualTotal = $allIndividualResults.Count
    $individualFailed = $individualTotal - $individualPassed
    
    Write-Host "`n>> Individual Test Results:" -ForegroundColor Cyan
    Write-Host "Individual Tests Passed: $individualPassed" -ForegroundColor Green
    Write-Host "Individual Tests Failed: $individualFailed" -ForegroundColor Red
    Write-Host "Individual Tests Total: $individualTotal" -ForegroundColor White
    
    if ($individualTotal -gt 0) {
        $successRate = [math]::Round(($individualPassed / $individualTotal) * 100, 2)
        Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    }
}

# Save comprehensive report
$reportData = @{
    TestRun = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ProjectPath = $ProjectPath
        TestSuites = $script:OverallResults
        Summary = @{
            TotalSuites = $script:OverallResults.Count
            SuitesPassed = $script:TotalPassed
            SuitesFailed = $script:TotalFailed
            CriticalFailures = $script:CriticalFailures
        }
    }
    IndividualTests = $allIndividualResults
    IndividualSummary = if ($allIndividualResults.Count -gt 0) {
        @{
            TotalTests = $allIndividualResults.Count
            TestsPassed = ($allIndividualResults | Where-Object { $_.Passed }).Count
            TestsFailed = ($allIndividualResults | Where-Object { !$_.Passed }).Count
        }
    } else { $null }
}

$reportFile = Join-Path $ReportsPath "comprehensive-test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`n[INFO] Comprehensive report saved to: $reportFile" -ForegroundColor Gray

# Determine exit code
if ($script:CriticalFailures -gt 0) {
    Write-Host "`n[CRITICAL] CRITICAL TESTS FAILED - Test suite FAILED!" -ForegroundColor Red
    exit 2
} elseif ($script:TotalFailed -gt 0) {
    Write-Host "`n[WARNING] Some tests failed, but no critical failures" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n[SUCCESS] ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}