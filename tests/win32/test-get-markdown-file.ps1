# Test script for get-markdown-file MCP tool
# Tests the get-markdown-file functionality with local markdown files

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

# Create test data directory
$TestDataDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Get-Location))) "tmp\test-data"
if (!(Test-Path $TestDataDir)) {
    New-Item -Path $TestDataDir -ItemType Directory -Force | Out-Null
}

Write-Host "=== Testing get-markdown-file MCP Tool ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Test Data Directory: $TestDataDir" -ForegroundColor Gray
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Create test markdown files
$TestFiles = @()

# Simple markdown file
$simpleMarkdown = @"
# Simple Test Markdown

This is a simple test markdown file for testing the get-markdown-file tool.

## Features

- Basic formatting
- Lists
- Headers

## Code Example

``````powershell
Write-Host "Hello, World!"
``````

*Created for testing purposes.*
"@

$simpleFile = Join-Path $TestDataDir "simple-test.md"
$simpleMarkdown | Out-File -FilePath $simpleFile -Encoding UTF8
$TestFiles += @{ Name = "Simple Markdown"; Path = $simpleFile }

# Complex markdown file
$complexMarkdown = @"
# Complex Test Markdown Document

This document tests various markdown features and formatting options.

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Code Examples](#code-examples)
4. [Tables](#tables)
5. [Conclusion](#conclusion)

## Introduction

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

### Subsection

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

## Features

- **Bold text**
- *Italic text*
- ``Inline code``
- [Links](https://example.com)
- ~~Strikethrough~~

### Nested Lists

1. First item
   - Nested bullet
   - Another nested item
2. Second item
   1. Nested number
   2. Another nested number

## Code Examples

### PowerShell
``````powershell
# PowerShell example
Get-Process | Where-Object { `$_.ProcessName -like "chrome*" }
``````

### JavaScript
``````javascript
// JavaScript example
function greet(name) {
    return `Hello, `${name}!`;
}
``````

### Python
``````python
# Python example
def factorial(n):
    return 1 if n <= 1 else n * factorial(n - 1)
``````

## Tables

| Feature | Status | Priority |
|---------|--------|----------|
| Headers | ✅ Working | High |
| Lists | ✅ Working | High |
| Code blocks | ✅ Working | Medium |
| Tables | ✅ Working | Low |

## Blockquotes

> This is a blockquote.
> 
> It can span multiple lines and contain **formatting**.

## Images

![Alt text](https://via.placeholder.com/150x150.png?text=Test+Image)

## Horizontal Rule

---

## Conclusion

This complex markdown file tests various features to ensure the get-markdown-file tool can handle different formatting elements correctly.

### Metadata

- **Author**: Test Script
- **Created**: $(Get-Date -Format "yyyy-MM-dd")
- **Purpose**: Testing get-markdown-file functionality
- **File Size**: Approximately 2KB
"@

$complexFile = Join-Path $TestDataDir "complex-test.md"
$complexMarkdown | Out-File -FilePath $complexFile -Encoding UTF8
$TestFiles += @{ Name = "Complex Markdown"; Path = $complexFile }

# Empty markdown file
$emptyFile = Join-Path $TestDataDir "empty-test.md"
"" | Out-File -FilePath $emptyFile -Encoding UTF8
$TestFiles += @{ Name = "Empty Markdown"; Path = $emptyFile }

# Test execution
$SuccessCount = 0
$FailCount = 0
$ProjectPath = Split-Path -Parent (Split-Path -Parent (Get-Location))

foreach ($testCase in $TestFiles) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Yellow
    Write-Host "File Path: $($testCase.Path)" -ForegroundColor Gray
    
    # Check if test file exists
    if (!(Test-Path $testCase.Path)) {
        Write-Host "[FAIL] Test file does not exist" -ForegroundColor Red
        $FailCount++
        Write-Host ""
        continue
    }
    
    try {
        # Execute MCP tool via CLI
        $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name get-markdown-file --tool-arg filepath="$($testCase.Path)" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Parse JSON response
            $jsonResponse = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            if ($jsonResponse -and $jsonResponse.content) {
                # Save output to file
                $safeFileName = $testCase.Name -replace '[^\w\s-]', '' -replace '\s+', '_'
                $outputFile = Join-Path $OutputDir "get_markdown_$safeFileName.md"
                
                # Extract markdown content
                $markdownContent = ""
                foreach ($contentBlock in $jsonResponse.content) {
                    if ($contentBlock.type -eq "text") {
                        $markdownContent += $contentBlock.text + "`n"
                    }
                }
                
                $markdownContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                Write-Host "[PASS] Successfully retrieved markdown file" -ForegroundColor Green
                Write-Host "   Output saved to: $outputFile" -ForegroundColor Green
                Write-Host "   Content blocks: $($jsonResponse.content.Count)" -ForegroundColor Green
                Write-Host "   Original size: $((Get-Item $testCase.Path).Length) bytes" -ForegroundColor Green
                Write-Host "   Retrieved size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Green
                
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

# Test with non-existent file (error handling)
Write-Host "Testing error handling with non-existent file:" -ForegroundColor Yellow
$nonExistentFile = Join-Path $TestDataDir "non-existent-file.md"
try {
    $result = & npx @modelcontextprotocol/inspector --cli node "$ProjectPath\dist\index.js" --method tools/call --tool-name get-markdown-file --tool-arg filepath="$nonExistentFile" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[PASS] Properly handles non-existent file" -ForegroundColor Green
        Write-Host "   Expected error occurred" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "[FAIL] Should have failed with non-existent file" -ForegroundColor Red
        $FailCount++
    }
} catch {
    Write-Host "[PASS] Exception properly caught for non-existent file" -ForegroundColor Green
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
Write-Host "Test data files created in: $TestDataDir" -ForegroundColor Gray

# Exit with appropriate code
if ($FailCount -eq 0) {
    Write-Host "[SUCCESS] All get-markdown-file tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}