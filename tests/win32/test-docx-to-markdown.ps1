# Test script for docx-to-markdown MCP tool
# Tests the docx-to-markdown functionality with various public DOCX files

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

# Test DOCX files from public-files guide
$TestDocx = @(
    @{ Name = "Calibre Demo DOCX"; Url = "https://calibre-ebook.com/downloads/demos/demo.docx"; FileName = "calibre_demo.docx" }
)

Write-Host "=== Testing docx-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Skip Download: $SkipDownload" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestDocx) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    $localFilePath = Join-Path $TestDataDir $testCase.FileName
    
    # Download file if it doesn't exist and not skipping download
    if (!(Test-Path $localFilePath) -and !$SkipDownload) {
        Write-Host "Downloading DOCX file..." -ForegroundColor Yellow
        try {
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $testCase.Url -OutFile $localFilePath -TimeoutSec 60
            Write-Host "   Downloaded: $localFilePath" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] Failed to download DOCX file" -ForegroundColor Red
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
    Write-Host "Processing DOCX with MCP tool..." -ForegroundColor Yellow
    try {
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name docx-to-markdown --tool-arg filepath="$localFilePath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "docx_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted DOCX to markdown" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Original DOCX size: $((Get-Item $localFilePath).Length) bytes" -ForegroundColor Green
                Write-Host "   Markdown output size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Green
                
                # Check content quality
                if ($markdownContent -match "^#|##|###" -and $markdownContent.Length -gt 200) {
                    Write-Host "   Content quality: Good (headers + substantial text)" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 100) {
                    Write-Host "   Content quality: Adequate (>100 chars)" -ForegroundColor Green
                } else {
                    Write-Host "   Content quality: Limited (<100 chars)" -ForegroundColor Yellow
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

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All docx-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}