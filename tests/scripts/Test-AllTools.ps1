# Test-AllTools.ps1
# Comprehensive testing of all MCP markdownify server tools

param(
    [string]$ProjectPath = "D:\tools\markdownify-mcp",
    [string]$OutputPath = "D:\tools\markdownify-mcp\tests\output",
    [string]$DataPath = "D:\tools\markdownify-mcp\tests\data"
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

function Invoke-MCPTool {
    param(
        [string]$ToolName,
        [hashtable]$Arguments
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Build argument string
        $argString = ""
        foreach ($key in $Arguments.Keys) {
            $value = $Arguments[$key]
            $argString += " --tool-arg $key=`"$value`""
        }
        
        # Execute command
        $cmd = "npx @modelcontextprotocol/inspector --cli node `"$ProjectPath\dist\index.js`" --method tools/call --tool-name $ToolName$argString"
        $result = Invoke-Expression $cmd 2>&1
        
        $stopwatch.Stop()
        $duration = "$($stopwatch.ElapsedMilliseconds)ms"
        
        if ($LASTEXITCODE -eq 0) {
            return @{ Success = $true; Result = $result; Duration = $duration }
        } else {
            return @{ Success = $false; Result = $result; Duration = $duration }
        }
    }
    catch {
        $stopwatch.Stop()
        $duration = "$($stopwatch.ElapsedMilliseconds)ms"
        return @{ Success = $false; Result = $_.Exception.Message; Duration = $duration }
    }
}

function Test-WebpageToMarkdown {
    Write-Host "`n=== Testing webpage-to-markdown ===" -ForegroundColor Cyan
    
    $testCases = @(
        @{ Name = "Simple HTML"; Url = "https://httpbin.org/html" },
        @{ Name = "ArXiv Paper"; Url = "https://arxiv.org/html/2503.20020v1" },
        @{ Name = "GitHub README"; Url = "https://raw.githubusercontent.com/microsoft/vscode/main/README.md" }
    )
    
    foreach ($testCase in $testCases) {
        $result = Invoke-MCPTool "webpage-to-markdown" @{ url = $testCase.Url }
        
        if ($result.Success) {
            try {
                $responseJson = $result.Result | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($responseJson -and $responseJson.content) {
                    Add-TestResult "webpage-to-markdown ($($testCase.Name))" $true "Successfully converted webpage" "URL: $($testCase.Url)" $result.Duration
                } else {
                    Add-TestResult "webpage-to-markdown ($($testCase.Name))" $false "Invalid response format" $result.Result $result.Duration
                }
            }
            catch {
                Add-TestResult "webpage-to-markdown ($($testCase.Name))" $false "Failed to parse response" $_.Exception.Message $result.Duration
            }
        } else {
            Add-TestResult "webpage-to-markdown ($($testCase.Name))" $false "Tool execution failed" $result.Result $result.Duration
        }
    }
}

function Test-YoutubeToMarkdown {
    Write-Host "`n=== Testing youtube-to-markdown ===" -ForegroundColor Cyan
    
    $testCases = @(
        @{ Name = "Short Video"; Url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ" },
        @{ Name = "Educational Video"; Url = "https://www.youtube.com/watch?v=3QdU1CjFUdQ" }
    )
    
    foreach ($testCase in $testCases) {
        $result = Invoke-MCPTool "youtube-to-markdown" @{ url = $testCase.Url }
        
        if ($result.Success) {
            try {
                $responseJson = $result.Result | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($responseJson -and $responseJson.content) {
                    Add-TestResult "youtube-to-markdown ($($testCase.Name))" $true "Successfully converted YouTube video" "URL: $($testCase.Url)" $result.Duration
                } else {
                    Add-TestResult "youtube-to-markdown ($($testCase.Name))" $false "Invalid response format" $result.Result $result.Duration
                }
            }
            catch {
                Add-TestResult "youtube-to-markdown ($($testCase.Name))" $false "Failed to parse response" $_.Exception.Message $result.Duration
            }
        } else {
            Add-TestResult "youtube-to-markdown ($($testCase.Name))" $false "Tool execution failed" $result.Result $result.Duration
        }
    }
}

function Test-BingSearchToMarkdown {
    Write-Host "`n=== Testing bing-search-to-markdown ===" -ForegroundColor Cyan
    
    $testCases = @(
        @{ Name = "Simple Search"; Url = "https://www.bing.com/search?q=hello+world" },
        @{ Name = "Technical Search"; Url = "https://www.bing.com/search?q=machine+learning" }
    )
    
    foreach ($testCase in $testCases) {
        $result = Invoke-MCPTool "bing-search-to-markdown" @{ url = $testCase.Url }
        
        if ($result.Success) {
            try {
                $responseJson = $result.Result | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($responseJson -and $responseJson.content) {
                    Add-TestResult "bing-search-to-markdown ($($testCase.Name))" $true "Successfully converted Bing search" "URL: $($testCase.Url)" $result.Duration
                } else {
                    Add-TestResult "bing-search-to-markdown ($($testCase.Name))" $false "Invalid response format" $result.Result $result.Duration
                }
            }
            catch {
                Add-TestResult "bing-search-to-markdown ($($testCase.Name))" $false "Failed to parse response" $_.Exception.Message $result.Duration
            }
        } else {
            Add-TestResult "bing-search-to-markdown ($($testCase.Name))" $false "Tool execution failed" $result.Result $result.Duration
        }
    }
}

function Test-GetMarkdownFile {
    Write-Host "`n=== Testing get-markdown-file ===" -ForegroundColor Cyan
    
    # First, create a test markdown file
    $testMarkdownPath = Join-Path $DataPath "test-sample.md"
    $testContent = @"
# Test Markdown File

This is a test markdown file for testing the get-markdown-file tool.

## Features
- Bullet point 1
- Bullet point 2

## Code Example
``````
function hello() {
    console.log("Hello, World!");
}
``````

*This file was created for testing purposes.*
"@
    
    try {
        # Ensure data directory exists
        if (!(Test-Path $DataPath)) {
            New-Item -Path $DataPath -ItemType Directory -Force | Out-Null
        }
        
        # Create test file
        $testContent | Out-File -FilePath $testMarkdownPath -Encoding UTF8
        
        if (Test-Path $testMarkdownPath) {
            $result = Invoke-MCPTool "get-markdown-file" @{ filepath = $testMarkdownPath }
            
            if ($result.Success) {
                try {
                    $responseJson = $result.Result | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($responseJson -and $responseJson.content) {
                        Add-TestResult "get-markdown-file" $true "Successfully retrieved markdown file" "File: $testMarkdownPath" $result.Duration
                    } else {
                        Add-TestResult "get-markdown-file" $false "Invalid response format" $result.Result $result.Duration
                    }
                }
                catch {
                    Add-TestResult "get-markdown-file" $false "Failed to parse response" $_.Exception.Message $result.Duration
                }
            } else {
                Add-TestResult "get-markdown-file" $false "Tool execution failed" $result.Result $result.Duration
            }
        } else {
            Add-TestResult "get-markdown-file" $false "Failed to create test file" "Path: $testMarkdownPath" "0ms"
        }
    }
    catch {
        Add-TestResult "get-markdown-file" $false "Exception during test setup" $_.Exception.Message "0ms"
    }
}

function Test-FileBasedTools {
    Write-Host "`n=== Testing File-Based Tools (Limited) ===" -ForegroundColor Cyan
    
    # These tools require specific file types that we may not have
    # We'll test their error handling with non-existent files
    
    $fileTools = @(
        @{ Name = "pdf-to-markdown"; Extension = ".pdf" },
        @{ Name = "docx-to-markdown"; Extension = ".docx" },
        @{ Name = "xlsx-to-markdown"; Extension = ".xlsx" },
        @{ Name = "pptx-to-markdown"; Extension = ".pptx" },
        @{ Name = "image-to-markdown"; Extension = ".jpg" },
        @{ Name = "audio-to-markdown"; Extension = ".mp3" }
    )
    
    foreach ($tool in $fileTools) {
        $nonExistentFile = Join-Path $DataPath "nonexistent$($tool.Extension)"
        $result = Invoke-MCPTool $tool.Name @{ filepath = $nonExistentFile }
        
        # For file-based tools with non-existent files, we expect them to fail gracefully
        if (!$result.Success) {
            # Check if it's a reasonable error message
            if ($result.Result -match "not found|does not exist|no such file|cannot find") {
                Add-TestResult "$($tool.Name) (Error Handling)" $true "Properly handles non-existent file" "Expected error for: $nonExistentFile" $result.Duration
            } else {
                Add-TestResult "$($tool.Name) (Error Handling)" $false "Unexpected error message" $result.Result $result.Duration
            }
        } else {
            # If it succeeded with a non-existent file, that's unexpected
            Add-TestResult "$($tool.Name) (Error Handling)" $false "Unexpectedly succeeded with non-existent file" $result.Result $result.Duration
        }
    }
}

# Main test execution
Write-Host "Starting Comprehensive Tool Testing..." -ForegroundColor Magenta
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "Data Path: $DataPath" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Ensure we're in the correct directory
Set-Location $ProjectPath

# Create output directory if it doesn't exist
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Run all tool tests
Test-WebpageToMarkdown
Test-YoutubeToMarkdown
Test-BingSearchToMarkdown
Test-GetMarkdownFile
Test-FileBasedTools

# Generate summary
Write-Host "`n=== Comprehensive Test Summary ===" -ForegroundColor Magenta
Write-Host "Total Tests: $($script:PassCount + $script:FailCount)" -ForegroundColor White
Write-Host "Passed: $script:PassCount" -ForegroundColor Green
Write-Host "Failed: $script:FailCount" -ForegroundColor Red

if (($script:PassCount + $script:FailCount) -gt 0) {
    $successRate = [math]::Round(($script:PassCount / ($script:PassCount + $script:FailCount)) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor Cyan
}

# Save results to JSON file
$outputFile = Join-Path $OutputPath "all-tools-test-results.json"
$script:TestResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nResults saved to: $outputFile" -ForegroundColor Gray

# Group results by tool
$toolGroups = $script:TestResults | Group-Object { $_.TestName.Split('(')[0].Trim() }
Write-Host "`n=== Results by Tool ===" -ForegroundColor Magenta
foreach ($group in $toolGroups) {
    $passed = ($group.Group | Where-Object { $_.Passed }).Count
    $total = $group.Group.Count
    $status = if ($passed -eq $total) { "[OK]" } else { "[ISSUES]" }
    Write-Host "$status $($group.Name): $passed/$total passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
}

# Exit with appropriate code
if ($script:FailCount -eq 0) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[WARNING] Some tests had issues - check results for details" -ForegroundColor Yellow
    exit 1
}