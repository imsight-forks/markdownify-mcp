# MCP Markdownify Server - Test Framework

**Test Coverage**: 6/10 tools tested (60%)  
**Success Rate**: 100% for all tested tools  
**Last Updated**: 2025-07-21

## Test Results

### Tested Tools (All 100% Pass Rate)

| Tool | Tests | Local Files | Remote URLs | Notes |
|------|-------|-------------|-------------|-------|
| webpage-to-markdown | 5/5 | N/A | ✅ | HTML conversion |
| pdf-to-markdown | 5/5 | ✅ | ✅ | Text extraction |
| docx-to-markdown | 1/1 | ✅ | ✅ | Document formatting |
| image-to-markdown | 5/5 | ✅ | ✅ | Metadata extraction |
| bing-search-to-markdown | 4/4 | N/A | ✅ | Search results |
| get-markdown-file | 4/4 | ✅ | N/A | File retrieval + error handling |

### Untested Tools

| Tool | Test Script | Implementation |
|------|-------------|----------------|
| audio-to-markdown | Ready | Complete |
| youtube-to-markdown | Ready | Complete |
| xlsx-to-markdown | Ready | Complete |
| pptx-to-markdown | Ready | Complete |

### Remote URL Support (v0.0.4+)

File-based tools accept HTTP/HTTPS URLs:
- Secure temporary file handling
- File size warnings (50MB+)
- Automatic cleanup

## Prerequisites

**Required**:
- Node.js v18+
- Python 3.11+ (managed by uv)
- uv package manager: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"`

**Optional for testing**:
- MCP Inspector: `npm install -g @modelcontextprotocol/inspector`

## Setup

```bash
# Build project
npm run build

# Verify dependencies
uv --version
node --version
```

## Running Tests (Windows)

```powershell
# Run all tests
cd tests/win32
./run-all-tests.ps1

# Run individual test
./test-pdf-to-markdown.ps1

# Custom output directory
./run-all-tests.ps1 -OutputPath "C:\results"
```

## Test Framework Structure

```
tests/
├── README.md              # This documentation
├── win32/                 # Windows PowerShell tests
│   ├── run-all-tests.ps1 # Master test runner
│   ├── test-*.ps1        # Individual tool tests (10 files)
│   └── tmp/output/       # Test output files
├── linux/                # Linux tests (planned)
└── macos/                # macOS tests (planned)
```

## Known Issues

### Current Issues

1. **MCP Inspector Port Conflict**: Kill existing process if port 6277 is in use:
   ```bash
   taskkill /F /IM node.exe /FI "COMMANDLINE eq *inspector*"
   ```
2. **PowerShell Execution Policy**: New systems may need:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```

### Test Data Sources

**Reliable Sources**:
- Wikipedia/Wikimedia Commons for PDFs, images, audio
- Government/educational sites (.gov/.edu) for documents
- Picsum Photos for test images

**Deprecated Sources**:
- file-examples.com (403 Forbidden errors as of July 2025)

## Performance

- Full test suite: ~2.5 minutes (10 tools)
- Individual tests: 5-30 seconds
- Network-dependent tests: Variable (5-60 seconds)

## Platform Support

- **Windows**: Fully implemented (PowerShell)
- **Linux**: Planned (Bash)
- **macOS**: Planned (Bash/Zsh)