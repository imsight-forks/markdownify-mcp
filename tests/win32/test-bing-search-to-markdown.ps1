# Test script for bing-search-to-markdown MCP tool
# Tests the bing-search-to-markdown functionality with various search queries

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

# Test search URLs from public-files guide
$TestSearches = @(
    @{ Name = "Lorem Ipsum Search"; Url = "https://www.bing.com/search?q=lorem+ipsum"; Query = "lorem ipsum" },
    @{ Name = "Sample Files Search"; Url = "https://www.bing.com/search?q=sample+files+download"; Query = "sample files download" },
    @{ Name = "Test Documents Search"; Url = "https://www.bing.com/search?q=test+documents"; Query = "test documents" },
    @{ Name = "Markdown Converter Search"; Url = "https://www.bing.com/search?q=markdown+converter"; Query = "markdown converter" }
)

Write-Host "=== Testing bing-search-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestSearches) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "Search Query: $($testCase.Query)" -ForegroundColor Gray
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    try {
        # Execute MCP tool via CLI
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name bing-search-to-markdown --tool-arg url="$($testCase.Url)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse JSON response
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                # Save output to file
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "bing_search_$safeFileName.md"
                
                # Extract markdown content
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted Bing search results" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                
                # Check for typical search result elements
                if ($markdownContent -match "result|link|search|found") {
                    Write-Host "   Search results detected: Yes" -ForegroundColor Green
                } else {
                    Write-Host "   Search results detected: Unclear" -ForegroundColor Yellow
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
    
    # Add small delay between requests to be respectful to Bing
    Start-Sleep -Seconds 2
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
Write-Host ""
Write-Host "Note: Bing search results may vary based on location and time." -ForegroundColor Gray
Write-Host "Some results may be affected by anti-bot measures." -ForegroundColor Gray

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All bing-search-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}