# Test-ErrorHandling.ps1
# Tests error handling and edge cases for MCP markdownify server

param(
    [string]$ProjectPath = "D:\tools\markdownify-mcp",
    [string]$OutputPath = "D:\tools\markdownify-mcp\tests\output"
)

# Initialize test results
$script:TestResults = @()
$script:PassCount = 0
$script:FailCount = 0

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message,
        [string]$Details = "",
        [string]$Duration = ""
    )
    
    $result = @{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Details = $Details
        Duration = $Duration
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:TestResults += $result
    
    if ($Passed) {
        $script:PassCount++
        $status = "[PASS]"
        $color = "Green"
    } else {
        $script:FailCount++
        $status = "[FAIL]"
        $color = "Red"
    }
    
    Write-Host "$status: $TestName - $Message" -ForegroundColor $color
    if ($Duration) { Write-Host "   Duration: $Duration" -ForegroundColor Gray }
    if ($Details -and !$Passed) { Write-Host "   Details: $Details" -ForegroundColor Yellow }
}

function Invoke-MCPToolWithErrorHandling {
    param(
        [string]$ToolName,
        [hashtable]$Arguments,
        [int]$TimeoutSeconds = 30
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Build argument string
        $argString = ""
        foreach ($key in $Arguments.Keys) {
            $value = $Arguments[$key]
            $argString += " --tool-arg $key=`"$value`""
        }
        
        # Execute command with timeout
        $cmd = "npx @modelcontextprotocol/inspector --cli node `"$ProjectPath\dist\index.js`" --method tools/call --tool-name $ToolName$argString"
        
        $job = Start-Job -ScriptBlock {
            param($command)
            Invoke-Expression $command 2>&1
        } -ArgumentList $cmd
        
        $completed = Wait-Job $job -Timeout $TimeoutSeconds
        $result = Receive-Job $job
        Remove-Job $job -Force
        
        $stopwatch.Stop()
        $duration = "$($stopwatch.ElapsedMilliseconds)ms"
        
        if ($completed -and $LASTEXITCODE -eq 0) {
            return @{ Success = $true; Result = $result; Duration = $duration; TimedOut = $false }
        } elseif (!$completed) {
            return @{ Success = $false; Result = "Operation timed out"; Duration = $duration; TimedOut = $true }
        } else {
            return @{ Success = $false; Result = $result; Duration = $duration; TimedOut = $false }
        }
    }
    catch {
        $stopwatch.Stop()
        $duration = "$($stopwatch.ElapsedMilliseconds)ms"
        return @{ Success = $false; Result = $_.Exception.Message; Duration = $duration; TimedOut = $false }
    }
}

function Test-InvalidURLs {
    Write-Host "`n=== Testing Invalid URLs ===" -ForegroundColor Cyan
    
    $invalidUrls = @(
        @{ Name = "Malformed URL"; Url = "not-a-url" },
        @{ Name = "Non-existent Domain"; Url = "https://this-domain-does-not-exist-12345.com" },
        @{ Name = "Invalid Protocol"; Url = "ftp://example.com" },
        @{ Name = "Empty URL"; Url = "" },
        @{ Name = "SQL Injection"; Url = "https://example.com'; DROP TABLE users; --" },
        @{ Name = "XSS Attempt"; Url = "https://example.com<script>alert('xss')</script>" }
    )
    
    foreach ($testCase in $invalidUrls) {
        $result = Invoke-MCPToolWithErrorHandling "webpage-to-markdown" @{ url = $testCase.Url } 10
        
        # For invalid URLs, we expect the tool to fail gracefully
        if (!$result.Success) {
            if ($result.TimedOut) {
                Add-TestResult "Invalid URL ($($testCase.Name))" $false "Operation timed out" "URL: $($testCase.Url)" $result.Duration
            } else {
                # Check if error message is reasonable
                $errorMsg = $result.Result -join " "
                if ($errorMsg -match "invalid|error|failed|not found|timeout|unreachable") {
                    Add-TestResult "Invalid URL ($($testCase.Name))" $true "Properly rejected invalid URL" "URL: $($testCase.Url)" $result.Duration
                } else {
                    Add-TestResult "Invalid URL ($($testCase.Name))" $false "Unexpected error response" $errorMsg $result.Duration
                }
            }
        } else {
            # If it succeeded with an invalid URL, that might be unexpected
            Add-TestResult "Invalid URL ($($testCase.Name))" $false "Unexpectedly succeeded with invalid URL" "URL: $($testCase.Url)" $result.Duration
        }
    }
}

function Test-NonExistentFiles {
    Write-Host "`n=== Testing Non-existent Files ===" -ForegroundColor Cyan
    
    $fileTools = @(
        "pdf-to-markdown",
        "docx-to-markdown", 
        "xlsx-to-markdown",
        "pptx-to-markdown",
        "image-to-markdown",
        "audio-to-markdown",
        "get-markdown-file"
    )
    
    $nonExistentPaths = @(
        "C:\non\existent\file.ext",
        "D:\invalid\path\file.ext",
        "",
        "   ",
        "null",
        "undefined"
    )
    
    foreach ($tool in $fileTools) {
        foreach ($path in $nonExistentPaths) {
            $testName = if ($path.Trim() -eq "") { "Empty Path" } elseif ($path.Trim() -eq "   ") { "Whitespace Path" } else { "Non-existent: $(Split-Path $path -Leaf)" }
            
            $result = Invoke-MCPToolWithErrorHandling $tool @{ filepath = $path } 10
            
            if (!$result.Success) {
                $errorMsg = $result.Result -join " "
                if ($errorMsg -match "not found|does not exist|no such file|cannot find|invalid path|file not found") {
                    Add-TestResult "$tool ($testName)" $true "Properly handles non-existent file" "Path: $path" $result.Duration
                } else {
                    Add-TestResult "$tool ($testName)" $false "Unexpected error message" $errorMsg $result.Duration
                }
            } else {
                Add-TestResult "$tool ($testName)" $false "Unexpectedly succeeded with non-existent file" "Path: $path" $result.Duration
            }
        }
    }
}

function Test-InvalidYouTubeURLs {
    Write-Host "`n=== Testing Invalid YouTube URLs ===" -ForegroundColor Cyan
    
    $invalidYouTubeUrls = @(
        @{ Name = "Invalid Video ID"; Url = "https://www.youtube.com/watch?v=invalid123" },
        @{ Name = "Malformed YouTube URL"; Url = "https://youtube.com/notavalidpath" },
        @{ Name = "Private Video"; Url = "https://www.youtube.com/watch?v=PrivateVideo" },
        @{ Name = "Empty Video ID"; Url = "https://www.youtube.com/watch?v=" }
    )
    
    foreach ($testCase in $invalidYouTubeUrls) {
        $result = Invoke-MCPToolWithErrorHandling "youtube-to-markdown" @{ url = $testCase.Url } 15
        
        if (!$result.Success) {
            $errorMsg = $result.Result -join " "
            if ($errorMsg -match "not found|unavailable|private|invalid|error|failed") {
                Add-TestResult "YouTube Invalid ($($testCase.Name))" $true "Properly handles invalid YouTube URL" "URL: $($testCase.Url)" $result.Duration
            } else {
                Add-TestResult "YouTube Invalid ($($testCase.Name))" $false "Unexpected error message" $errorMsg $result.Duration
            }
        } else {
            # Some invalid URLs might still return content (like error pages), which could be valid behavior
            Add-TestResult "YouTube Invalid ($($testCase.Name))" $true "Handled invalid URL (may have returned error page content)" "URL: $($testCase.Url)" $result.Duration
        }
    }
}

function Test-MalformedArguments {
    Write-Host "`n=== Testing Malformed Arguments ===" -ForegroundColor Cyan
    
    # Test missing required arguments
    $result1 = Invoke-MCPToolWithErrorHandling "webpage-to-markdown" @{} 5
    if (!$result1.Success) {
        Add-TestResult "Missing Arguments (webpage-to-markdown)" $true "Properly rejects missing URL argument" $result1.Result $result1.Duration
    } else {
        Add-TestResult "Missing Arguments (webpage-to-markdown)" $false "Unexpectedly succeeded without required arguments" $result1.Result $result1.Duration
    }
    
    $result2 = Invoke-MCPToolWithErrorHandling "pdf-to-markdown" @{} 5
    if (!$result2.Success) {
        Add-TestResult "Missing Arguments (pdf-to-markdown)" $true "Properly rejects missing filepath argument" $result2.Result $result2.Duration
    } else {
        Add-TestResult "Missing Arguments (pdf-to-markdown)" $false "Unexpectedly succeeded without required arguments" $result2.Result $result2.Duration
    }
}

function Test-LargeContentHandling {
    Write-Host "`n=== Testing Large Content Handling ===" -ForegroundColor Cyan
    
    # Test with a large webpage that might cause issues
    $largeContentUrls = @(
        @{ Name = "Wikipedia Main Page"; Url = "https://en.wikipedia.org/wiki/Main_Page" },
        @{ Name = "Large Technical Document"; Url = "https://tools.ietf.org/rfc/rfc7231.txt" }
    )
    
    foreach ($testCase in $largeContentUrls) {
        $result = Invoke-MCPToolWithErrorHandling "webpage-to-markdown" @{ url = $testCase.Url } 60
        
        if ($result.Success) {
            try {
                $responseJson = $result.Result | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($responseJson -and $responseJson.content) {
                    Add-TestResult "Large Content ($($testCase.Name))" $true "Successfully processed large content" "URL: $($testCase.Url)" $result.Duration
                } else {
                    Add-TestResult "Large Content ($($testCase.Name))" $false "Invalid response format for large content" $result.Result $result.Duration
                }
            }
            catch {
                Add-TestResult "Large Content ($($testCase.Name))" $false "Failed to parse large content response" $_.Exception.Message $result.Duration
            }
        } elseif ($result.TimedOut) {
            Add-TestResult "Large Content ($($testCase.Name))" $false "Timed out processing large content" "URL: $($testCase.Url)" $result.Duration
        } else {
            Add-TestResult "Large Content ($($testCase.Name))" $false "Failed to process large content" $result.Result $result.Duration
        }
    }
}

function Test-ConcurrentRequests {
    Write-Host "`n=== Testing Concurrent Requests ===" -ForegroundColor Cyan
    
    # Test multiple simultaneous requests
    $testUrl = "https://httpbin.org/html"
    $jobs = @()
    
    try {
        # Start 3 concurrent requests
        for ($i = 1; $i -le 3; $i++) {
            $job = Start-Job -ScriptBlock {
                param($projectPath, $url, $id)
                $cmd = "npx @modelcontextprotocol/inspector --cli node `"$projectPath\dist\index.js`" --method tools/call --tool-name webpage-to-markdown --tool-arg url=`"$url`""
                $result = Invoke-Expression $cmd 2>&1
                return @{ ID = $id; Result = $result; ExitCode = $LASTEXITCODE }
            } -ArgumentList $ProjectPath, $testUrl, $i
            
            $jobs += $job
        }
        
        # Wait for all jobs to complete (with timeout)
        $completed = Wait-Job $jobs -Timeout 30
        $results = Receive-Job $jobs
        Remove-Job $jobs -Force
        
        $successCount = ($results | Where-Object { $_.ExitCode -eq 0 }).Count
        $totalCount = $results.Count
        
        if ($successCount -eq $totalCount -and $totalCount -eq 3) {
            Add-TestResult "Concurrent Requests" $true "All concurrent requests succeeded" "Success: $successCount/$totalCount" ""
        } elseif ($successCount -gt 0) {
            Add-TestResult "Concurrent Requests" $true "Partial success with concurrent requests" "Success: $successCount/$totalCount" ""
        } else {
            Add-TestResult "Concurrent Requests" $false "All concurrent requests failed" "Success: $successCount/$totalCount" ""
        }
    }
    catch {
        Add-TestResult "Concurrent Requests" $false "Exception during concurrent test" $_.Exception.Message ""
    }
}

# Main test execution
Write-Host "Starting Error Handling and Edge Case Testing..." -ForegroundColor Magenta
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Ensure we're in the correct directory
Set-Location $ProjectPath

# Create output directory if it doesn't exist
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Run error handling tests
Test-InvalidURLs
Test-NonExistentFiles
Test-InvalidYouTubeURLs
Test-MalformedArguments
Test-LargeContentHandling
Test-ConcurrentRequests

# Generate summary
Write-Host "`n=== Error Handling Test Summary ===" -ForegroundColor Magenta
Write-Host "Total Tests: $($script:PassCount + $script:FailCount)" -ForegroundColor White
Write-Host "Passed: $script:PassCount" -ForegroundColor Green
Write-Host "Failed: $script:FailCount" -ForegroundColor Red

if (($script:PassCount + $script:FailCount) -gt 0) {
    $successRate = [math]::Round(($script:PassCount / ($script:PassCount + $script:FailCount)) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

# Save results to JSON file
$outputFile = Join-Path $OutputPath "error-handling-test-results.json"
$script:TestResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nResults saved to: $outputFile" -ForegroundColor Gray

# Group results by test category
$categories = @{
    "Invalid URLs" = $script:TestResults | Where-Object { $_.TestName -like "*Invalid URL*" }
    "Non-existent Files" = $script:TestResults | Where-Object { $_.TestName -like "*-to-markdown (*" -and $_.TestName -notlike "*Invalid*" -and $_.TestName -notlike "*YouTube*" }
    "YouTube Issues" = $script:TestResults | Where-Object { $_.TestName -like "*YouTube Invalid*" }
    "Malformed Arguments" = $script:TestResults | Where-Object { $_.TestName -like "*Missing Arguments*" }
    "Large Content" = $script:TestResults | Where-Object { $_.TestName -like "*Large Content*" }
    "Concurrent Requests" = $script:TestResults | Where-Object { $_.TestName -like "*Concurrent*" }
}

Write-Host "`n=== Results by Category ===" -ForegroundColor Magenta
foreach ($category in $categories.Keys) {
    $tests = $categories[$category]
    if ($tests) {
        $passed = ($tests | Where-Object { $_.Passed }).Count
        $total = $tests.Count
        $status = if ($passed -eq $total) { "[OK]" } else { "[ISSUES]" }
        Write-Host "$status $category`: $passed/$total passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    }
}

# Exit with appropriate code
if ($script:FailCount -eq 0) {
    Write-Host "`n[SUCCESS] All error handling tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[WARNING] Some error handling tests had issues" -ForegroundColor Yellow
    exit 1
}