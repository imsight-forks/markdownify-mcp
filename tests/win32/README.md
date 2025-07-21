# Windows Test Scripts for MCP Markdownify

This directory contains PowerShell test scripts for all 10 MCP markdownify tools on Windows platforms.

## Overview

The test suite provides comprehensive testing for:
- **Web-based tools**: webpage-to-markdown, youtube-to-markdown, bing-search-to-markdown
- **File-based tools**: pdf-to-markdown, docx-to-markdown, xlsx-to-markdown, pptx-to-markdown, image-to-markdown, audio-to-markdown
- **Local file tools**: get-markdown-file

## Prerequisites

1. **Node.js and npm** installed
2. **MCP Inspector** installed globally:
   ```powershell
   npm install -g @modelcontextprotocol/inspector
   ```
3. **Built MCP server**:
   ```powershell
   npm run build
   ```
4. **Internet connection** for downloading test files and accessing web resources

## Quick Start

### Run All Tests
```powershell
.\run-all-tests.ps1
```

### Run Quick Tests Only (web-based tools)
```powershell
.\run-all-tests.ps1 -QuickTest
```

### Run Specific Tools
```powershell
.\run-all-tests.ps1 -Tools @("webpage-to-markdown", "pdf-to-markdown")
```

### Custom Output Directory
```powershell
.\run-all-tests.ps1 -Output "C:\MyTests\Output"
```

### Skip File Downloads (use existing files)
```powershell
.\run-all-tests.ps1 -SkipDownload
```

## Individual Test Scripts

Each tool has its own dedicated test script:

| Script | Tool | Description |
|--------|------|-------------|
| `test-webpage-to-markdown.ps1` | webpage-to-markdown | Tests web page conversion with various sites |
| `test-youtube-to-markdown.ps1` | youtube-to-markdown | Tests YouTube video transcript extraction |
| `test-bing-search-to-markdown.ps1` | bing-search-to-markdown | Tests Bing search results conversion |
| `test-get-markdown-file.ps1` | get-markdown-file | Tests local markdown file retrieval |
| `test-pdf-to-markdown.ps1` | pdf-to-markdown | Tests PDF document conversion |
| `test-docx-to-markdown.ps1` | docx-to-markdown | Tests Word document conversion |
| `test-xlsx-to-markdown.ps1` | xlsx-to-markdown | Tests Excel spreadsheet conversion |
| `test-pptx-to-markdown.ps1` | pptx-to-markdown | Tests PowerPoint presentation conversion |
| `test-image-to-markdown.ps1` | image-to-markdown | Tests image analysis and description |
| `test-audio-to-markdown.ps1` | audio-to-markdown | Tests audio transcription |

### Individual Script Usage

All individual scripts support the same parameters:

```powershell
.\test-[tool-name].ps1 [-OutputDir <path>] [-Output <path>] [-SkipDownload]
```

**Examples:**
```powershell
# Test PDF conversion with custom output
.\test-pdf-to-markdown.ps1 -Output "C:\PDFTests"

# Test images without downloading new files
.\test-image-to-markdown.ps1 -SkipDownload

# Test YouTube with default settings
.\test-youtube-to-markdown.ps1
```

## Output Structure

Tests create the following directory structure:

```
<workspace_root>/
├── tmp/
│   ├── output/           # Converted markdown files
│   │   ├── webpage_*.md
│   │   ├── pdf_*.md
│   │   ├── audio_*.md
│   │   └── ...
│   └── test-data/        # Downloaded test files
│       ├── sample_150kB.pdf
│       ├── sample_1MB.wav
│       └── ...
```

## Test Categories

### 🌐 Web-based Tests (Quick)
- **webpage-to-markdown**: Tests with Lorem Ipsum, Wikipedia, Example.com
- **bing-search-to-markdown**: Tests search result conversion
- **get-markdown-file**: Tests local file access (creates test files)

### 📄 Document Tests (File Downloads)
- **pdf-to-markdown**: Downloads 150KB, 500KB, and 1MB PDF samples
- **docx-to-markdown**: Downloads 100KB, 500KB Word documents
- **xlsx-to-markdown**: Downloads Excel spreadsheet samples
- **pptx-to-markdown**: Downloads PowerPoint presentation samples

### 🎥 Media Tests (Large Downloads)
- **youtube-to-markdown**: Tests educational video transcription
- **image-to-markdown**: Downloads and analyzes various image formats
- **audio-to-markdown**: Downloads and transcribes WAV audio files (1-2MB)

## Understanding Test Results

### Success Indicators
- ✅ **[PASS]**: Tool executed successfully and produced valid markdown
- 📊 **Content blocks**: Number of content sections in the response
- 📏 **File sizes**: Original vs. converted file sizes
- 🎯 **Quality indicators**: Content structure analysis

### Failure Indicators
- ❌ **[FAIL]**: Tool execution failed or produced invalid output
- ⚠️ **[SKIP]**: Test skipped (usually due to missing files with -SkipDownload)
- 🚫 **[ERROR]**: Script execution error or exception

### Common Quality Checks
- **PDF**: Text extraction quality, document structure preservation
- **DOCX**: Header detection, formatting preservation
- **XLSX**: Table structure in markdown format
- **Images**: Metadata extraction, description quality
- **Audio**: Transcription accuracy and completeness
- **YouTube**: Transcript availability and quality

## Test File Sources

All test files come from publicly available sources:

- **file-examples.com**: Standard file samples in various sizes
- **Picsum**: Random placeholder images
- **Educational YouTube**: Khan Academy, TED-Ed content
- **Government/Academic**: Harvard, CMU, Oklahoma Senate samples
- **Web Standards**: Lorem Ipsum, Example.com, Wikipedia

## Troubleshooting

### Common Issues

1. **Download Failures**
   ```
   Solution: Check internet connection, try -SkipDownload if files exist
   ```

2. **MCP Tool Execution Fails**
   ```
   Solution: Ensure 'npm run build' completed successfully
   ```

3. **Permission Errors**
   ```
   Solution: Run PowerShell as Administrator or check file permissions
   ```

4. **Python/UV Dependencies Missing**
   ```
   Solution: Ensure Python and uv are installed and in PATH
   ```

### Performance Notes

- **Audio tests**: Can take 2-5 minutes per file due to transcription processing
- **Large PDFs**: May take 30-60 seconds for complex documents
- **YouTube**: Depends on video length and transcript availability
- **File downloads**: First run downloads ~50MB of test files total

## Advanced Usage

### Creating Custom Test Data

```powershell
# Create custom test markdown files
$TestDataDir = "..\..\tmp\test-data"
"# Custom Test File`n`nYour content here" | Out-File "$TestDataDir\custom.md"

# Test with custom file
.\test-get-markdown-file.ps1
```

### Batch Testing with Custom Parameters

```powershell
# Test all document tools with custom output
$DocumentTools = @("pdf-to-markdown", "docx-to-markdown", "xlsx-to-markdown", "pptx-to-markdown")
.\run-all-tests.ps1 -Tools $DocumentTools -Output "C:\DocumentTests"
```

### Integration with CI/CD

```powershell
# Example CI script
.\run-all-tests.ps1 -QuickTest -SkipDownload
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed"
    exit 1
}
```

## File Size Requirements

- **Test data download**: ~50MB total for all files
- **Output directory**: ~10-20MB for all converted markdown files
- **Minimum free space**: 100MB recommended for downloads and temporary files

---

**Last updated**: July 21, 2025  
**Platform**: Windows 11 (PowerShell 5.1+)  
**MCP Server Version**: 0.0.1