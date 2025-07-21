# Test script for image-to-markdown MCP tool
# Tests the image-to-markdown functionality with various public image files

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

# Test image files from Wikipedia/Wikimedia Commons and other reliable sources  
$TestImages = @(
    @{ Name = "Random 800x600 Image"; Url = "https://picsum.photos/800/600"; FileName = "random_800x600.jpg" },
    @{ Name = "Specific Picsum Image"; Url = "https://picsum.photos/id/237/800/600"; FileName = "picsum_237.jpg" },
    @{ Name = "Wikipedia Portrait"; Url = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Alois_Mentasti.jpg/120px-Alois_Mentasti.jpg"; FileName = "wikipedia_portrait.jpg" }
)

# Remote URL tests (new feature) - test direct image URL processing
$RemoteImageTests = @(
    @{ Name = "Remote Random Image"; Url = "https://picsum.photos/400/300" },
    @{ Name = "Remote Wikipedia Image"; Url = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Alois_Mentasti.jpg/120px-Alois_Mentasti.jpg" }
)

Write-Host "=== Testing image-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestImages) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    $localFilePath = Join-Path $TestDataDir $testCase.FileName
    
    if (!(Test-Path $localFilePath) -and !$SkipDownload) {
        Write-Host "Downloading image file..." -ForegroundColor Yellow
        try {
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $testCase.Url -OutFile $localFilePath -TimeoutSec 60
            Write-Host "   Downloaded: $localFilePath" -ForegroundColor Green
            
            # Check if file is actually an image
            $fileSize = (Get-Item $localFilePath).Length
            if ($fileSize -lt 1000) {
                Write-Host "   Warning: Downloaded file is very small ($fileSize bytes)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "[FAIL] Failed to download image file" -ForegroundColor Red
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
    
    Write-Host "Processing image with MCP tool..." -ForegroundColor Yellow
    try {
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name image-to-markdown --tool-arg filepath="$localFilePath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "image_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully processed image to markdown" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Image file size: $((Get-Item $localFilePath).Length) bytes" -ForegroundColor Green
                
                # Check for image analysis content
                if ($markdownContent -match "image|picture|photo|width|height|dimension" -and $markdownContent.Length -gt 50) {
                    Write-Host "   Image analysis: Detailed metadata/description" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 20) {
                    Write-Host "   Image analysis: Basic information" -ForegroundColor Green
                } else {
                    Write-Host "   Image analysis: Minimal content" -ForegroundColor Yellow
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
Write-Host "=== Testing Remote Image URLs (New Feature) ===" -ForegroundColor Cyan
Write-Host "Testing direct URL processing without local file download" -ForegroundColor Gray
Write-Host ""

foreach ($remoteTest in $RemoteImageTests) {
    Write-Host "Testing Remote Image URL: $($remoteTest.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($remoteTest.Url)" -ForegroundColor Gray
    
    Write-Host "Processing image URL directly with MCP tool..." -ForegroundColor Yellow
    try {
        # Test direct URL processing - this is the new feature
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name image-to-markdown --tool-arg filepath="$($remoteTest.Url)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $remoteTest.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "remote_image_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully processed remote image URL" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Remote URL: $($remoteTest.Url)" -ForegroundColor Green
                
                # Check for image analysis content
                if ($markdownContent -match "image|picture|photo|width|height|dimension" -and $markdownContent.Length -gt 50) {
                    Write-Host "   Image analysis: Detailed metadata/description" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 20) {
                    Write-Host "   Image analysis: Basic information" -ForegroundColor Green
                } else {
                    Write-Host "   Image analysis: Minimal content" -ForegroundColor Yellow
                }
                
                $SuccessCount++
            } else {
                Write-Host "[FAIL] Invalid response format from remote image URL" -ForegroundColor Red
                Write-Host "   Response: $result" -ForegroundColor Red
                $FailCount++
            }
        } else {
            Write-Host "[FAIL] Remote image URL processing failed" -ForegroundColor Red
            Write-Host "   Error: $result" -ForegroundColor Red
            $FailCount++
        }
    }
    catch {
        Write-Host "[FAIL] Exception during remote image URL processing" -ForegroundColor Red
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
Write-Host "Downloaded images in: $TestDataDir" -ForegroundColor Gray
Write-Host "Note: Tool supports JPG, PNG, GIF, TIFF, ICO, SVG, WEBP formats" -ForegroundColor Gray

if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All image-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}