# Test script for pdf-to-markdown MCP tool
# Tests the pdf-to-markdown functionality with various public PDF files

param(
    [string]$OutputDir = "$((Get-Location).Path)\tmp\output",
    [Alias("o")]
    [string]$Output = $null,
    [switch]$SkipDownload = $false
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

# Create test data directory for downloads
$TestDataDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Get-Location))) "tmp\test-data"
if (!(Test-Path $TestDataDir)) {
    New-Item -Path $TestDataDir -ItemType Directory -Force | Out-Null
}

# Test PDF files from public-files guide
$TestPdfs = @(
    @{ Name = "150KB PDF Sample"; Url = "https://file-examples.com/wp-content/storage/2017/10/file-sample_150kB.pdf"; FileName = "sample_150kB.pdf" },
    @{ Name = "500KB PDF Sample"; Url = "https://file-examples.com/wp-content/storage/2017/10/file-sample_500kB.pdf"; FileName = "sample_500kB.pdf" },
    @{ Name = "Simple Test PDF"; Url = "https://s24.q4cdn.com/216390268/files/doc_downloads/test.pdf"; FileName = "simple_test.pdf" }
)

Write-Host "=== Testing pdf-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Skip Download: $SkipDownload" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
$ProjectPath = Split-Path -Parent (Split-Path -Parent (Get-Location))

foreach ($testCase in $TestPdfs) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    $localFilePath = Join-Path $TestDataDir $testCase.FileName
    
    # Download file if it doesn't exist and not skipping download
    if (!(Test-Path $localFilePath) -and !$SkipDownload) {
        Write-Host "Downloading PDF file..." -ForegroundColor Yellow
        try {
            # Use Invoke-WebRequest to download the file
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $testCase.Url -OutFile $localFilePath -TimeoutSec 60
            Write-Host "   Downloaded: $localFilePath" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] Failed to download PDF file" -ForegroundColor Red
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
    
    # Test the MCP tool
    Write-Host "Processing PDF with MCP tool..." -ForegroundColor Yellow
    try {
        # Execute MCP tool via CLI
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name pdf-to-markdown --tool-arg filepath="$localFilePath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse JSON response
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                # Save output to file
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "pdf_$safeFileName.md"
                
                # Extract markdown content
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted PDF to markdown" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Original PDF size: $((Get-Item $localFilePath).Length) bytes" -ForegroundColor Green
                Write-Host "   Markdown output size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Green
                
                # Check if meaningful content was extracted
                if ($markdownContent.Length -gt 100) {
                    Write-Host "   Content extraction: Good (>100 chars)" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 10) {
                    Write-Host "   Content extraction: Limited (10-100 chars)" -ForegroundColor Yellow
                } else {
                    Write-Host "   Content extraction: Minimal (<10 chars)" -ForegroundColor Yellow
                }
                
                $SuccessCount++
            } else {
                Write-Host "[FAIL] Invalid response format" -ForegroundColor Red
                Write-Host "   Response: $result" -ForegroundColor Red
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

# Test error handling with non-existent file
Write-Host "Testing error handling with non-existent PDF:" -ForegroundColor Yellow
$nonExistentPdf = Join-Path $TestDataDir "non-existent-file.pdf"
try {
    $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name pdf-to-markdown --tool-arg filepath="$nonExistentPdf" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[PASS] Properly handles non-existent PDF file" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "[FAIL] Should have failed with non-existent PDF file" -ForegroundColor Red
        $FailCount++
    }
} catch {
    Write-Host "[PASS] Exception properly caught for non-existent PDF" -ForegroundColor Green
    $SuccessCount++
}

Write-Host ""

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($SuccessCount + $FailCount)" -ForegroundColor White
Write-Host "Passed: $SuccessCount" -ForegroundColor Green
Write-Host "Failed: $FailCount" -ForegroundColor Red

if (($SuccessCount + $FailCount) -gt 0) {
    $successRate = [math]::Round(($SuccessCount / ($SuccessCount + $FailCount)) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Output files saved to: $OutputDir" -ForegroundColor Gray
Write-Host "Downloaded test files in: $TestDataDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage: Add -SkipDownload flag to use existing downloaded files only" -ForegroundColor Gray

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All pdf-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}