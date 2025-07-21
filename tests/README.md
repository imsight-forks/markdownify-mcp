# MCP Markdownify Server - Test Framework Documentation

## Overview

This directory contains a comprehensive CLI-based test framework for the MCP markdownify server. The framework tests all 10 MCP tools across different platforms and provides detailed reporting on functionality, performance, and reliability.

**Last Updated**: 2025-07-21  
**Framework Status**: ✅ **OPERATIONAL**  
**Overall Success Rate**: **50% (5/10 tools fully functional)**

## 🎯 Test Results Summary

### ✅ FULLY FUNCTIONAL TOOLS (Production Ready)

#### Web Content Processing Tools
| Tool | Success Rate | Test Coverage | Notes |
|------|-------------|---------------|-------|
| **webpage-to-markdown** | 100% (5/5) | Multiple websites tested | Reliable HTML→Markdown conversion |
| **bing-search-to-markdown** | 100% (4/4) | Various search queries | Search results properly parsed |
| **youtube-to-markdown** | 100% (3/3) | Educational videos tested | Metadata extraction works |

#### Document Processing Tools  
| Tool | Success Rate | Test Coverage | Notes |
|------|-------------|---------------|-------|
| **xlsx-to-markdown** | 100% (1/1) | Excel files (.xls/.xlsx) | Spreadsheet conversion functional |
| **pptx-to-markdown** | 100% | PowerPoint presentations | Slide content extraction works |

### ⚠️ PARTIALLY FUNCTIONAL TOOLS

| Tool | Success Rate | Test Coverage | Issues |
|------|-------------|---------------|--------|
| **image-to-markdown** | 67% (2/3) | Multiple image formats | External download restrictions (403 errors) |

### ❌ NON-FUNCTIONAL TOOLS (Require Investigation)

| Tool | Category | Likely Issues |
|------|----------|---------------|
| **audio-to-markdown** | Media | Missing audio processing dependencies |
| **docx-to-markdown** | Document | Word document processing dependencies |
| **get-markdown-file** | File | File access/permission issues |
| **pdf-to-markdown** | Document | PDF processing dependencies (Python/UV) |

## 🏗️ Platform Support

### Windows (win32) - ✅ **FULLY IMPLEMENTED**
- **Location**: `tests/win32/`
- **Status**: Complete test suite with 10 individual tool tests
- **Runner**: `run-all-tests.ps1` - Master test orchestrator
- **Requirements**: PowerShell, Node.js, MCP Inspector
- **Tested On**: Windows 11

### Linux - 📋 **PLANNED**
- **Location**: `tests/linux/`
- **Status**: Directory structure created, scripts needed
- **Requirements**: Bash, Node.js, MCP Inspector

### macOS - 📋 **PLANNED**  
- **Location**: `tests/macos/`
- **Status**: Directory structure created, scripts needed
- **Requirements**: Bash/Zsh, Node.js, MCP Inspector

## 🚀 Quick Start

### Prerequisites
```bash
# Ensure MCP server is built
npm run build

# Install MCP Inspector (if not already installed)
npm install -g @modelcontextprotocol/inspector
```

### Running Tests (Windows)

#### Run All Tests
```powershell
cd tests/win32
./run-all-tests.ps1
```

#### Run with Custom Output Directory
```powershell
./run-all-tests.ps1 -OutputPath "C:\my-test-results"
```

#### Run Individual Tool Test
```powershell
./test-webpage-to-markdown.ps1 -OutputDir "../../tmp/output"
```

#### Quick Test Mode (Subset of tests)
```powershell
./run-all-tests.ps1 -QuickTest
```

## 📁 Test Framework Structure

```
tests/
├── README.md                    # This documentation
├── win32/                       # Windows PowerShell tests
│   ├── run-all-tests.ps1       # Master test runner
│   ├── test-*.ps1              # Individual tool tests (10 files)
│   └── tmp/output/              # Test output files
├── linux/                      # Linux Bash tests (planned)
├── macos/                      # macOS tests (planned)
└── [platform]/
    ├── README.md               # Platform-specific documentation
    └── test-scripts...
```

## 🔧 Test Framework Features

### Comprehensive Coverage
- **10 Individual Tool Tests**: Each MCP tool has dedicated test script
- **Multiple Test Cases**: Each tool tested with various inputs
- **Real-World Data**: Uses public URLs and files for realistic testing
- **Error Handling**: Tests both success and failure scenarios

### Robust Execution
- **Path Independence**: Fixed path calculation works regardless of execution context
- **Parallel Execution**: Master runner executes tests efficiently
- **Detailed Logging**: Comprehensive output with timestamps and performance metrics
- **JSON Results**: Structured data for automated analysis

### Output Management
- **Configurable Output**: `--output` or `-o` flag to specify directory
- **Organized Results**: Test outputs saved with descriptive filenames
- **Test Data Caching**: Downloaded files reused to minimize network load

## 📊 Detailed Test Results

### Web Tools Performance
```
webpage-to-markdown:
  ✅ Lorem Ipsum Generator (lipsum.com)
  ✅ Example.com  
  ✅ File Examples Homepage
  ✅ Wikipedia Lorem Ipsum
  ✅ Simple HTML Test (httpbin.org)

bing-search-to-markdown:
  ✅ Lorem ipsum search
  ✅ Sample files download search  
  ✅ Test documents search
  ✅ Markdown converter search

youtube-to-markdown:
  ✅ Educational Video 1 (Khan Academy style)
  ✅ Khan Academy Sample
  ✅ Short Educational (Rick Roll for testing)
  Note: Transcript availability varies by video
```

### Document Tools Performance  
```
xlsx-to-markdown:
  ✅ CMU Test Excel File (.xls format)
  Supports: .xlsx, .xls formats
  
pptx-to-markdown:
  ✅ PowerPoint presentations  
  Slide content extraction functional
```

### Media Tools Performance
```
image-to-markdown:
  ✅ Random 800x600 Image (16,665 bytes)
  ✅ Specific Picsum Image (68,842 bytes) 
  ❌ File Examples JPG (403 Forbidden)
  
  Supported formats: JPG, PNG, GIF, TIFF, ICO, SVG, WEBP
  Analysis: Detailed metadata/description generation
```

## 🐛 Known Issues & Troubleshooting

### Common Issues

#### 1. MCP Connection Errors
**Symptom**: `MCP error -32000: Connection closed`
**Cause**: Server not built or path issues
**Solution**: 
```bash
npm run build
# Verify dist/index.js exists
```

#### 2. PowerShell Execution Policy  
**Symptom**: Script execution blocked
**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

#### 3. Network Download Failures
**Symptom**: 403 Forbidden or timeout errors
**Cause**: External site restrictions
**Impact**: Some test files may not download
**Mitigation**: Tests use cached files when available

#### 4. Missing Dependencies  
**Symptom**: Tool-specific failures (audio, docx, pdf)
**Cause**: Python/UV environment or specific libraries missing
**Investigation Needed**: Dependency audit for failed tools

### Path Calculation Fix (Historical)
**Previous Issue**: Tests failed when run from different working directories
**Fix Applied**: Robust script-based path calculation
```powershell
# Before (broken):
$ProjectPath = Split-Path -Parent (Split-Path -Parent (Get-Location))

# After (robust):
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path  
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)
```

## 📈 Performance Metrics

### Test Execution Times (Windows)
- **Full Test Suite**: ~2.5 minutes (10 tools)
- **Individual Web Tool**: ~15-30 seconds
- **Individual Document Tool**: ~5-15 seconds  
- **Network-dependent tests**: Variable (5-60 seconds)

### Success Rates by Category
- **Web Tools**: 100% (3/3)
- **Document Tools**: 50% (2/4)
- **Media Tools**: 33% (1/3)  
- **File Tools**: 0% (0/1)

## 🔮 Future Improvements

### High Priority
1. **Linux/macOS Support**: Port PowerShell tests to Bash
2. **Dependency Investigation**: Resolve failed tool requirements
3. **CI/CD Integration**: Automated testing pipeline
4. **Error Recovery**: Enhanced retry logic for network failures

### Medium Priority  
1. **Performance Testing**: Load testing and benchmarks
2. **Test Data Hosting**: Local test file hosting to avoid external dependencies
3. **Mock Testing**: Offline testing capabilities
4. **Security Testing**: Input validation and edge cases

### Low Priority
1. **UI Dashboard**: Web-based test results viewer  
2. **Test Scheduling**: Automated periodic testing
3. **Comparative Analysis**: Version-to-version test comparisons

## 🔧 Contributing to Tests

### Adding New Tests
1. Create new test script following naming convention: `test-[tool-name].ps1`
2. Use the robust path calculation pattern
3. Include comprehensive test cases
4. Add proper error handling and logging
5. Update this README with new test information

### Test Script Template
```powershell
# Test script for [tool-name] MCP tool
param(
    [string]$OutputDir = "$((Get-Location).Path)\tmp\output",
    [Alias("o")]
    [string]$Output = $null
)

# Robust path calculation
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Test implementation...
```

## 📞 Support & Maintenance

### Test Framework Maintainers
- Framework designed for autonomous operation
- Comprehensive logging for troubleshooting
- Modular design for easy updates

### When Tests Fail
1. Check recent commits for breaking changes
2. Verify build status (`npm run build`)
3. Review network connectivity for external resources
4. Check individual tool logs for specific errors
5. Validate dependencies for failed tools

### Updating Tests
- Add new test cases as new public URLs become available
- Update external URLs if current ones become unavailable  
- Enhance error handling based on observed failure patterns
- Improve performance optimization as needed

---

**Framework Status**: ✅ **Production Ready**  
**Next Major Release**: Linux/macOS support  
**Maintenance**: Ongoing monitoring of external dependencies