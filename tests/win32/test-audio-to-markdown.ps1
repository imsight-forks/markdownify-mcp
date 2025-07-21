# Test script for audio-to-markdown MCP tool
# Tests the audio-to-markdown functionality with public audio files

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

# Test audio files from public-files guide
$TestAudio = @(
    @{ Name = "1MB WAV Sample"; Url = "https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_1MG.wav"; FileName = "sample_1MB.wav" },
    @{ Name = "2MB WAV Sample"; Url = "https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_2MG.wav"; FileName = "sample_2MB.wav" }
)

Write-Host "=== Testing audio-to-markdown MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Audio transcription may take longer than other file types" -ForegroundColor Yellow
Write-Host ""

$SuccessCount = 0
$FailCount = 0
# Calculate project path from script location (works regardless of execution context)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

foreach ($testCase in $TestAudio) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($testCase.Url)" -ForegroundColor Gray
    
    $localFilePath = Join-Path $TestDataDir $testCase.FileName
    
    if (!(Test-Path $localFilePath) -and !$SkipDownload) {
        Write-Host "Downloading audio file..." -ForegroundColor Yellow
        try {
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $testCase.Url -OutFile $localFilePath -TimeoutSec 120
            Write-Host "   Downloaded: $localFilePath" -ForegroundColor Green
            
            $fileSize = (Get-Item $localFilePath).Length
            Write-Host "   File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] Failed to download audio file" -ForegroundColor Red
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
    
    Write-Host "Processing audio with MCP tool (this may take a while)..." -ForegroundColor Yellow
    try {
        # Audio processing can take longer, so we don't set a strict timeout
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name audio-to-markdown --tool-arg filepath="$localFilePath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "audio_$safeFileName.md"
                
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully processed audio to markdown" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Audio file size: $([math]::Round(((Get-Item $localFilePath).Length) / 1MB, 2)) MB" -ForegroundColor Green
                
                # Check for transcription content
                if ($markdownContent -match "transcript|transcription" -and $markdownContent.Length -gt 200) {
                    Write-Host "   Transcription: Detailed transcript detected" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 100) {
                    Write-Host "   Transcription: Some content transcribed" -ForegroundColor Green
                } elseif ($markdownContent.Length -gt 20) {
                    Write-Host "   Transcription: Minimal transcription" -ForegroundColor Yellow
                } else {
                    Write-Host "   Transcription: No clear transcription (may be metadata only)" -ForegroundColor Yellow
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
Write-Host "Downloaded audio files in: $TestDataDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Audio transcription quality depends on:" -ForegroundColor Gray
Write-Host "- Audio quality and clarity" -ForegroundColor Gray
Write-Host "- Language of the audio content" -ForegroundColor Gray
Write-Host "- Available transcription services" -ForegroundColor Gray

if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All audio-to-markdown tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}