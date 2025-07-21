# Test script for youtube-to-markdown MCP tool
# Tests the youtube-to-markdown functionality with educational videos

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

# Test YouTube URLs from public-files guide (educational content)
$TestVideos = @(
    @{ Name = "Educational Video 1"; Url = "https://www.youtube.com/watch?v=7bwkuudEfmc"; Description = "General educational content" },
    @{ Name = "Khan Academy Sample"; Url = "https://www.youtube.com/watch?v=Kas0tIxDvrg"; Description = "Khan Academy math video" },
    @{ Name = "Short Educational"; Url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"; Description = "Short video for testing" }
)

Write-Host "=== Testing youtube-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
$ProjectPath = Split-Path -Parent (Split-Path -Parent (Get-Location))

foreach ($testCase in $TestVideos) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    Write-Host "Description: $($testCase.Description)" -ForegroundColor Gray
    
    try {
        # Execute MCP tool via CLI with longer timeout for video processing
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name youtube-to-markdown --tool-arg url="$($testCase.Url)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse JSON response
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                # Save output to file
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "youtube_$safeFileName.md"
                
                # Extract markdown content
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully converted YouTube video" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                
                # Check if transcript was included
                if ($markdownContent -match "transcript|caption|subtitle") {
                    Write-Host "   Transcript detected: Yes" -ForegroundColor Green
                } else {
                    Write-Host "   Transcript detected: No (may not be available)" -ForegroundColor Yellow
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
    
    # Add small delay between requests to be respectful to YouTube
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
Write-Host "Note: YouTube transcript availability varies by video." -ForegroundColor Gray
Write-Host "Some videos may not have captions/transcripts available." -ForegroundColor Gray

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All youtube-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}