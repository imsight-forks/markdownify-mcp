# Test script for webpage-to-markdown MCP tool
# Tests the webpage-to-markdown functionality with various public web pages

param(
    [string]$OutputDir = "$((Get-Location).Path)\tmp\output",
    [Alias("o")]
    [string]$Output = $null
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

# Test URLs from public-files guide
$TestUrls = @(
    @{ Name = "Lorem Ipsum Generator"; Url = "https://www.lipsum.com/" },
    @{ Name = "Example.com"; Url = "https://example.com/" },
    @{ Name = "File Examples Homepage"; Url = "https://file-examples.com/" },
    @{ Name = "Wikipedia Lorem Ipsum"; Url = "https://en.wikipedia.org/wiki/Lorem_ipsum" },
    @{ Name = "Simple HTML Test"; Url = "https://httpbin.org/html" }
)

Write-Host "=== Testing webpage-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestUrls) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    try {
        # Execute MCP tool via CLI
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name webpage-to-markdown --tool-arg url="$($testCase.Url)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse JSON response
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                # Save output to file
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "webpage_$safeFileName.md"
                
                # Extract markdown content
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted webpage" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
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

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All webpage-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}