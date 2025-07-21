# Test-BasicServerFunctionality.ps1
# Tests basic MCP markdownify server functionality

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
        [string]$Details = ""
    )
    
    $result = @{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:TestResults += $result
    
    if ($Passed) {
        $script:PassCount++
        Write-Host "[PASS] $TestName - $Message" -ForegroundColor Green
    } else {
        $script:FailCount++
        Write-Host "[FAIL] $TestName - $Message" -ForegroundColor Red
        if ($Details) {
            Write-Host "   Details: $Details" -ForegroundColor Yellow
        }
    }
}

function Test-ServerConnection {
    Write-Host "`n=== Testing Server Connection ===" -ForegroundColor Cyan
    
    try {
        # Test if server can list tools
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/list 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $toolsJson = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($toolsJson -and $toolsJson.tools) {
                $toolCount = $toolsJson.tools.Count
                Add-TestResult "Server Connection" $true "Server responds to tools/list request" "Found $toolCount tools"
                return $true
            } else {
                Add-TestResult "Server Connection" $false "Invalid response format from server" $result
                return $false
            }
        } else {
            Add-TestResult "Server Connection" $false "Server failed to respond" $result
            return $false
        }
    }
    catch {
        Add-TestResult "Server Connection" $false "Exception during server connection test" $_.Exception.Message
        return $false
    }
}

function Test-ToolsListing {
    Write-Host "`n=== Testing Tools Listing ===" -ForegroundColor Cyan
    
    try {
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/list 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $toolsJson = $result | ConvertFrom-Json
            $expectedTools = @(
                "audio-to-markdown",
                "bing-search-to-markdown", 
                "docx-to-markdown",
                "get-markdown-file",
                "image-to-markdown",
                "pdf-to-markdown",
                "pptx-to-markdown",
                "webpage-to-markdown",
                "xlsx-to-markdown",
                "youtube-to-markdown"
            )
            
            $actualTools = $toolsJson.tools | ForEach-Object { $_.name }
            $missingTools = $expectedTools | Where-Object { $_ -notin $actualTools }
            $extraTools = $actualTools | Where-Object { $_ -notin $expectedTools }
            
            if ($missingTools.Count -eq 0 -and $extraTools.Count -eq 0) {
                Add-TestResult "Tools Listing" $true "All expected tools present" "Found: $($actualTools -join ', ')"
                return $true
            } else {
                $details = ""
                if ($missingTools.Count -gt 0) { $details += "Missing: $($missingTools -join ', '). " }
                if ($extraTools.Count -gt 0) { $details += "Extra: $($extraTools -join ', '). " }
                Add-TestResult "Tools Listing" $false "Tool list mismatch" $details
                return $false
            }
        } else {
            Add-TestResult "Tools Listing" $false "Failed to get tools list" $result
            return $false
        }
    }
    catch {
        Add-TestResult "Tools Listing" $false "Exception during tools listing test" $_.Exception.Message
        return $false
    }
}

function Test-SimpleWebpageConversion {
    Write-Host "`n=== Testing Simple Webpage Conversion ===" -ForegroundColor Cyan
    
    try {
        # Test with a simple, reliable webpage
        $testUrl = "https://httpbin.org/html"
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name webpage-to-markdown --tool-arg url="$testUrl" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $responseJson = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($responseJson -and $responseJson.content) {
                $content = $responseJson.content
                if ($content -is [array] -and $content.Count -gt 0) {
                    Add-TestResult "Simple Webpage Conversion" $true "Successfully converted webpage to markdown" "Content blocks: $($content.Count)"
                    return $true
                } else {
                    Add-TestResult "Simple Webpage Conversion" $false "Empty or invalid content returned" $responseJson
                    return $false
                }
            } else {
                Add-TestResult "Simple Webpage Conversion" $false "Invalid response format" $result
                return $false
            }
        } else {
            Add-TestResult "Simple Webpage Conversion" $false "Tool execution failed" $result
            return $false
        }
    }
    catch {
        Add-TestResult "Simple Webpage Conversion" $false "Exception during webpage conversion test" $_.Exception.Message
        return $false
    }
}

function Test-BuildStatus {
    Write-Host "`n=== Testing Build Status ===" -ForegroundColor Cyan
    
    try {
        # Check if dist directory exists and has required files
        $distPath = Join-Path $ProjectPath "dist"
        $indexPath = Join-Path $distPath "index.js"
        $serverPath = Join-Path $distPath "server.js"
        
        if (Test-Path $distPath) {
            if ((Test-Path $indexPath) -and (Test-Path $serverPath)) {
                Add-TestResult "Build Status" $true "Required build files exist" "dist/index.js and dist/server.js found"
                return $true
            } else {
                Add-TestResult "Build Status" $false "Missing required build files" "index.js exists: $(Test-Path $indexPath), server.js exists: $(Test-Path $serverPath)"
                return $false
            }
        } else {
            Add-TestResult "Build Status" $false "Build directory does not exist" "Path: $distPath"
            return $false
        }
    }
    catch {
        Add-TestResult "Build Status" $false "Exception during build status test" $_.Exception.Message
        return $false
    }
}

# Main test execution
Write-Host "Starting Basic Server Functionality Tests..." -ForegroundColor Magenta
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Ensure we're in the correct directory
Set-Location $ProjectPath

# Run tests
Test-BuildStatus
Test-ServerConnection
Test-ToolsListing
Test-SimpleWebpageConversion

# Generate summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Magenta
Write-Host "Total Tests: $($script:PassCount + $script:FailCount)" -ForegroundColor White
Write-Host "Passed: $script:PassCount" -ForegroundColor Green
Write-Host "Failed: $script:FailCount" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($script:PassCount / ($script:PassCount + $script:FailCount)) * 100, 2))%" -ForegroundColor Cyan

# Save results to JSON file
$outputFile = Join-Path $OutputPath "basic-functionality-test-results.json"
$script:TestResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nResults saved to: $outputFile" -ForegroundColor Gray

# Exit with appropriate code
if ($script:FailCount -eq 0) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAIL] Some tests failed!" -ForegroundColor Red
    exit 1
}