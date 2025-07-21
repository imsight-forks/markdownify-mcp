# Linux Test Scripts

This directory is reserved for Linux-specific test scripts for the MCP markdownify server.

## TODO

Create bash test scripts equivalent to the Windows PowerShell scripts in `../win32/`.

## Requirements

- Node.js and npm
- MCP Inspector: `npm install -g @modelcontextprotocol/inspector`
- Built MCP server: `npm run build`
- curl or wget for downloading test files

## Usage

Scripts should follow the same pattern as Windows scripts:
- Individual test script per MCP tool
- Default output to `<workspace_root>/tmp/output`
- Support for `--output` or `-o` flag
- Use CLI-only testing with MCP Inspector

## Example

```bash
#!/bin/bash
# test-pdf-to-markdown.sh
./test-pdf-to-markdown.sh --output /custom/output/path
```