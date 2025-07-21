# Task: Enable PDF-to-Markdown Tool to Handle Remote URLs

**Priority**: Medium  
**Complexity**: Medium  
**Estimated Time**: 2-4 hours  
**Created**: July 21, 2025  

## Problem Description

The `pdf-to-markdown` tool currently only accepts local file paths and fails when provided with remote PDF URLs. This limitation requires users to manually download PDF files before conversion, creating friction in the user experience.

### Current Behavior

```typescript
// Current implementation expects local file path
mcp_markdownify_pdf-to-markdown({
  filepath: "D:\\tools\\markdownify-mcp\\simple_test.pdf" // ✅ Works
})

// Remote URL fails
mcp_markdownify_pdf-to-markdown({
  filepath: "https://example.com/document.pdf" // ❌ Fails
})
```

### Error Details

When a remote URL is provided, the tool fails with:
```
OSError: [Errno 22] Invalid argument: './https:/example.com/document.pdf'
```

This occurs because the underlying `markitdown` library attempts to open the URL as a local file path.

## Expected Behavior

The tool should seamlessly handle both local file paths and remote URLs:

```typescript
// Should work with local files
mcp_markdownify_pdf-to-markdown({
  filepath: "/path/to/local/file.pdf"
})

// Should also work with remote URLs
mcp_markdownify_pdf-to-markdown({
  filepath: "https://example.com/document.pdf"
})
```

## Technical Analysis

### Root Cause
The issue stems from the `Markdownify.ts` implementation where URLs are passed directly to the `markitdown` CLI tool, which expects local file paths.

### Current Implementation Flow
1. User provides URL to `pdf-to-markdown` tool
2. URL is passed to `Markdownify.convertToMarkdown()`
3. Method calls `uv run markitdown <url>` directly
4. `markitdown` tries to open URL as local file → **FAILS**

### Proposed Solution Flow
1. User provides URL to `pdf-to-markdown` tool
2. Implementation detects if input is URL vs local path
3. If URL: Download file to temporary location
4. Convert temporary file using existing logic
5. Clean up temporary file
6. Return markdown result

## Implementation Requirements

### 1. URL Detection
Add utility function to distinguish between URLs and local file paths:

```typescript
function isUrl(input: string): boolean {
  try {
    new URL(input);
    return input.startsWith('http://') || input.startsWith('https://');
  } catch {
    return false;
  }
}
```

### 2. File Download Logic
Implement secure file download with appropriate safeguards:

```typescript
async function downloadFile(url: string): Promise<string> {
  // Validate URL format and protocol
  // Download file to temporary location using Node.js built-in fetch (18+)
  // Return temporary file path
  // Handle download errors appropriately
}
```

### 3. Temporary File Management
- Use OS temporary directory with cross-platform path resolution
- Generate unique filenames to avoid conflicts using `fs.mkdtemp()`
- Implement cleanup logic for successful and failed conversions
- Consider file size limits to prevent abuse

### 4. Error Handling
- Network connectivity issues
- Invalid/inaccessible URLs
- File size limits exceeded
- Unsupported file types after download
- Cleanup failures

## Cross-Platform Implementation Guidelines

### Path Handling
**Critical**: Use Node.js built-in `path` module for all path operations:

```typescript
import path from 'path';
import os from 'os';
import fs from 'fs/promises';

// ✅ Cross-platform correct
const tempFile = path.join(tempDir, 'downloaded.pdf');

// ❌ Platform-specific (breaks on Windows)
const tempFile = tempDir + '/downloaded.pdf';
```

### Secure Temporary Directory Creation
Use Node.js built-in APIs for secure, cross-platform temp file handling:

```typescript
// Cross-platform reliable temp directory resolution
const createTempDir = async (): Promise<string> => {
  const baseTempDir = await fs.realpath(os.tmpdir());
  return await fs.mkdtemp(path.join(baseTempDir, 'markdownify-'));
};
```

**Why this approach**:
- `os.tmpdir()` can return symlinks on macOS - `fs.realpath()` resolves them
- `fs.mkdtemp()` creates secure directories (0o700 permissions) with guaranteed uniqueness
- `path.join()` handles platform-specific path separators correctly

### File Cleanup
Use Node.js built-in recursive directory removal:

```typescript
// Cross-platform cleanup (Node.js 12+)
const cleanup = async (tempDir: string): Promise<void> => {
  try {
    await fs.rm(tempDir, { recursive: true, force: true });
  } catch (error) {
    // Log but don't throw - cleanup is best effort
    console.warn('Cleanup failed:', error);
  }
};
```

**Note**: `fs.rm()` with `recursive: true` replaces the need for `rimraf` package.

### HTTP Downloads
Use Node.js built-in capabilities:

```typescript
// Node.js 18+ - built-in fetch
const downloadFile = async (url: string, filePath: string): Promise<void> => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  const buffer = await response.arrayBuffer();
  await fs.writeFile(filePath, Buffer.from(buffer));
};
```

### Complete Cross-Platform Pattern
Recommended disposer pattern using only built-in modules:

```typescript
const withTempFile = async <T>(fn: (filePath: string) => Promise<T>): Promise<T> => {
  const tempDir = await fs.mkdtemp(
    path.join(await fs.realpath(os.tmpdir()), 'markdownify-')
  );
  
  try {
    const filePath = path.join(tempDir, 'download.pdf');
    return await fn(filePath);
  } finally {
    // Non-blocking cleanup
    fs.rm(tempDir, { recursive: true, force: true }).catch(console.warn);
  }
};
```

## Files to Modify

### Primary Files
1. **`src/Markdownify.ts`**
   - Add URL detection logic
   - Implement file download functionality
   - Update `convertToMarkdown()` method
   - Add temporary file cleanup

2. **`src/tools.ts`**
   - Update `pdf-to-markdown` tool documentation
   - Consider parameter validation updates

### Supporting Files
3. **`package.json`**
   - **No additional dependencies needed** for cross-platform HTTP requests
   - Use Node.js built-in `fetch` (Node.js 18+) or `https` module
   - Avoid unnecessary dependencies like `node-fetch`, `axios` for basic downloads

4. **Test files**
   - Update existing tests
   - Add new test cases for remote URLs

## Security Considerations

### 1. URL Validation
- Restrict to HTTP/HTTPS protocols only
- Validate URL format before processing
- Consider whitelist/blacklist for domains if needed

### 2. File Size Limits
```typescript
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB limit
```

### 3. Timeout Handling
```typescript
const DOWNLOAD_TIMEOUT = 30000; // 30 second timeout
```

### 4. Temporary File Security
- Use secure temporary directories with `fs.mkdtemp()` for guaranteed unique names
- Ensure files are cleaned up even on error using disposer pattern
- Set appropriate file permissions automatically (Node.js handles this)
- Use `fs.realpath(os.tmpdir())` for cross-platform temp directory resolution

## Cross-Platform Dependencies

**No third-party packages required!** The implementation should use only Node.js built-in modules:

- **Path handling**: `path` module for cross-platform path operations
- **Temp directories**: `os.tmpdir()` + `fs.realpath()` + `fs.mkdtemp()`
- **File cleanup**: `fs.rm()` with `recursive: true` option
- **HTTP downloads**: `fetch()` (Node 18+) or `https` module
- **URL validation**: `URL` constructor

This approach ensures maximum compatibility without external dependencies.

## Testing Strategy

### Unit Tests
- URL detection function
- File download with valid URLs
- Error handling for invalid URLs
- Temporary file cleanup

### Integration Tests
- End-to-end conversion from remote PDF URLs
- Network error scenarios
- Large file handling
- Concurrent request handling

### Test URLs
Use the public test files from `context/hints/about-public-files.md`:
- Simple PDF: `https://s24.q4cdn.com/216390268/files/doc_downloads/test.pdf`
- Various size PDFs from reliable sources

## Implementation Steps

### Phase 1: Core Functionality
1. Add URL detection utility
2. Implement basic file download
3. Update `convertToMarkdown()` to handle URLs
4. Add basic error handling

### Phase 2: Robustness
1. Add comprehensive error handling
2. Implement file size and timeout limits
3. Add proper temporary file cleanup
4. Security validations

### Phase 3: Testing & Documentation
1. Write comprehensive tests
2. Update tool documentation
3. Add usage examples
4. Test with various PDF sources

## Success Criteria

- [ ] Tool accepts both local file paths and remote URLs
- [ ] Remote PDFs are successfully downloaded and converted
- [ ] Appropriate error messages for network/download failures
- [ ] No memory leaks or orphaned temporary files
- [ ] Security measures prevent abuse
- [ ] Comprehensive test coverage
- [ ] Updated documentation with examples

## Example Usage After Implementation

```typescript
// Both should work seamlessly:
await mcp_markdownify_pdf_to_markdown({
  filepath: "https://example.com/report.pdf"
});

await mcp_markdownify_pdf_to_markdown({
  filepath: "/local/path/report.pdf"
});
```

## References

- Current implementation: `src/Markdownify.ts`
- Test files guide: `context/hints/about-public-files.md`
- Similar pattern may exist in other tools (check `webpage-to-markdown`)
- Node.js fetch API documentation
- Temporary file handling best practices
- Cross-platform Node.js guide: https://github.com/ehmicky/cross-platform-node-guide
- Secure tempfiles without dependencies: https://advancedweb.hu/secure-tempfiles-in-nodejs-without-dependencies/

## Notes

- This enhancement would bring consistency with tools like `webpage-to-markdown` that handle URLs
- Consider applying similar pattern to other file-based tools (DOCX, XLSX, PPTX)
- Monitor for potential performance impact with large files
- Consider caching mechanism for frequently accessed URLs (future enhancement)
- **Cross-platform compatibility**: Implementation uses only Node.js built-in modules, ensuring compatibility across Windows, macOS, and Linux without additional dependencies

---

**Assignee**: TBD  
**Status**: Open  
**Labels**: enhancement, pdf-conversion, remote-files  
