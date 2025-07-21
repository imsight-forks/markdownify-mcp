# Test script for xlsx-to-markdown MCP tool
# Tests the xlsx-to-markdown functionality with various public XLSX files

param(
    [string]$OutputDir = "$((Get-Location).Path)\tmp\output",
    [Alias("o")]
    [string]$Output = $null,
    [switch]$SkipDownload = $false
)

if ($Output) { $OutputDir = $Output }

if (!(Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

$TestDataDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Get-Location))) "tmp\test-data"
if (!(Test-Path $TestDataDir)) {
    New-Item -Path $TestDataDir -ItemType Directory -Force | Out-Null
}

# Test XLSX files from government/educational sources (public-files guide)
# Note: Using .gov and .edu sources for reliability
$TestXlsx = @(
    @{ Name = "Microsoft Learning XLSX"; Url = "https://learn.microsoft.com/en-us/office/dev/scripts/tutorials/on-call-rotation.xlsx"; FileName = "microsoft_learning.xlsx" },
    @{ Name = "CMU Test Excel File"; Url = "https://www.cmu.edu/blackboard/files/evaluate/tests-example.xls"; FileName = "cmu_test.xls" }
)

# Remote URL tests (new feature) - test direct XLSX URL processing
$RemoteXlsxTests = @(
    @{ Name = "Remote Microsoft Learning"; Url = "https://learn.microsoft.com/en-us/office/dev/scripts/tutorials/on-call-rotation.xlsx" },
    @{ Name = "Remote Educational Data"; Url = "https://www.cmu.edu/blackboard/files/evaluate/tests-example.xls" }
)

Write-Host "=== Testing xlsx-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestXlsx) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    $localFilePath = Join-Path $TestDataDir $testCase.FileName
    
    if (!(Test-Path $localFilePath) -and !$SkipDownload) {
        Write-Host "Downloading Excel file..." -ForegroundColor Yellow
        try {
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $testCase.Url -OutFile $localFilePath -TimeoutSec 60
            Write-Host "   Downloaded: $localFilePath" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] Failed to download Excel file" -ForegroundColor Red
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            $FailCount++
            Write-Host ""
            continue
        }
    }
    elseif (!(Test-Path $localFilePath) -and $SkipDownload) {
        Write-Host "[SKIP] File not found and download skipped: $localFilePath" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    else {
        Write-Host "Using existing file: $localFilePath" -ForegroundColor Green
    }
    
    Write-Host "Processing Excel file with MCP tool..." -ForegroundColor Yellow
    try {
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name xlsx-to-markdown --tool-arg filepath="$localFilePath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "xlsx_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted Excel to markdown" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                
                # Check for table structure
                if ($markdownContent -match "\|.*\|" -and $markdownContent -match "\|.*---.*\|") {
                    Write-Host "   Table structure: Detected markdown tables" -ForegroundColor Green
                } else {
                    Write-Host "   Table structure: No clear table formatting" -ForegroundColor Yellow
                }
                
                $SuccessCount++
            } else {
                Write-Host "[FAIL] Invalid response format" -ForegroundColor Red
                $FailCount++
            }
        } else {
            Write-Host "[FAIL] MCP tool execution failed" -ForegroundColor Red
            Write-Host "   Error: $result" -ForegroundColor Red
            $FailCount++
        }
    }
    catch {
        Write-Host "[FAIL] Exception occurred" -ForegroundColor Red
        Write-Host "   Exception: $($_.Exception.Message)" -ForegroundColor Red
        $FailCount++
    }
    
    Write-Host ""
}

# Test remote URLs directly (NEW FEATURE)
Write-Host "=== Testing Remote XLSX URLs (New Feature) ===" -ForegroundColor Cyan
Write-Host "Testing direct URL processing without local file download" -ForegroundColor Gray
Write-Host ""

foreach ($remoteTest in $RemoteXlsxTests) {
    Write-Host "Testing Remote XLSX URL: $($remoteTest.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($remoteTest.Url)" -ForegroundColor Gray
    
    Write-Host "Processing XLSX URL directly with MCP tool..." -ForegroundColor Yellow
    try {
        # Test direct URL processing - this is the new feature
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name xlsx-to-markdown --tool-arg filepath="$($remoteTest.Url)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $remoteTest.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "remote_xlsx_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully processed remote XLSX URL" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Remote URL: $($remoteTest.Url)" -ForegroundColor Green
                
                # Check for spreadsheet content
                if ($markdownContent -match "table|sheet|row|column|\|" -and $markdownContent.Length -gt 300) {
                    Write-Host "   Spreadsheet conversion: Detailed tables extracted" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 100) {
                    Write-Host "   Spreadsheet conversion: Basic content extracted" -ForegroundColor Green
                } else {
                    Write-Host "   Spreadsheet conversion: Minimal content" -ForegroundColor Yellow
                }
                
                $SuccessCount++
            } else {
                Write-Host "[FAIL] Invalid response format from remote XLSX URL" -ForegroundColor Red
                Write-Host "   Response: $result" -ForegroundColor Red
                $FailCount++
            }
        } else {
            Write-Host "[FAIL] Remote XLSX URL processing failed" -ForegroundColor Red
            Write-Host "   Error: $result" -ForegroundColor Red
            $FailCount++
        }
    }
    catch {
        Write-Host "[FAIL] Exception during remote XLSX URL processing" -ForegroundColor Red
        Write-Host "   Exception: $($_.Exception.Message)" -ForegroundColor Red
        $FailCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($SuccessCount + $FailCount)" -ForegroundColor White
Write-Host "Passed: $SuccessCount" -ForegroundColor Green
Write-Host "Failed: $FailCount" -ForegroundColor Red

if (($SuccessCount + $FailCount) -gt 0) {
    $successRate = [math]::Round(($SuccessCount / ($SuccessCount + $FailCount)) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

Write-Host "Output files saved to: $OutputDir" -ForegroundColor Gray
Write-Host "Note: Tool works with both .xlsx and .xls formats" -ForegroundColor Gray

if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All xlsx-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}