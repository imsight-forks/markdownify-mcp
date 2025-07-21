# How to Fix IDE Integration for Markdownify MCP

This guide provides step-by-step instructions for properly installing and configuring the Markdownify MCP server for IDE integration, particularly with VS Code and other editors that support the Model Context Protocol.

## Prerequisites

- Node.js and npm installed
- Git (for cloning the repository)
- PowerShell or Command Prompt with administrator privileges (Windows)
- Internet connection for downloading dependencies

## Installation Methods

### Method 1: Install from npm (Recommended for End Users)

**⚠️ Current Issue**: The published npm package has Windows compatibility issues with the setup script.

```bash
# This will currently fail on Windows due to setup script issues
npm install -g mcp-markdownify-server
```

**Problem**: The package tries to run `./setup.sh` on Windows, which fails because:
1. Windows doesn't recognize the `.sh` extension
2. The script should be `setup.bat` for Windows

### Method 2: Install from Source (Recommended for Development/Current Workaround)

This is the currently working method:

#### Step 1: Clone and Build
```bash
# Clone the repository
git clone https://github.com/zcaceres/mcp-markdownify-server.git
cd mcp-markdownify-server

# Install Node.js dependencies
npm install

# Build the TypeScript project
npm run build
```

#### Step 2: Set Up Python Dependencies
**On Windows:**
```bat
# Run the Windows setup script
.\setup.bat
```

**On Linux/Mac:**
```bash
# Run the Unix setup script
./setup.sh
```

**Manual setup if scripts fail:**
```bash
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh  # Linux/Mac
# OR for Windows: powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Sync Python dependencies
uv sync
```

#### Step 3: Install Globally
```bash
# Install the built package globally
npm install -g .
```

#### Step 4: Verify Installation
```bash
# Check if installed correctly
npm list -g mcp-markdownify-server

# Test the Python dependencies
uv run --project . markitdown --help
```

## Original Error Analysis and Troubleshooting Journey

### The Initial Problem

When attempting to use the markdownify MCP tool to convert a Wikipedia page, the following error occurred:

```
Error: Error processing to Markdown: Command failed: C:/Users/igamenovoer/.local/bin/uv.exe run D:/tools/markdownify-mcp/.venv/Scripts/markitdown.exe C:/Users/IGAMEN~1/AppData/Local/Temp/markdown_output_1753086697711.md
Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "D:\tools\markdownify-mcp\.venv\Scripts\markitdown.exe\__main__.py", line 4, in <module>
ModuleNotFoundError: No module named 'markitdown'
```

### Root Cause Analysis

The error indicated that the `markitdown` Python module was not properly installed in the virtual environment, even though the project appeared to be set up correctly.

### Troubleshooting Steps Attempted

#### Step 1: Check UV Installation
```bash
# Checked if uv was available
where uv
# Result: Command produced no output (uv not in PATH)

where uvx
# Result: Command produced no output (uvx not in PATH)
```

#### Step 2: Verify Python Dependencies
```bash
# Attempted to sync dependencies
cd d:\tools\markdownify-mcp
uv sync
# Result: "Resolved 51 packages in 1ms, Audited 47 packages in 0.02ms"
# This appeared successful but didn't fix the issue
```

#### Step 3: NPM Package Issues
When trying to install from npm:
```bash
npm install -g mcp-markdownify-server
```

**Error encountered:**
```
npm error command failed
npm error command C:\WINDOWS\system32\cmd.exe /d /s /c ./setup.sh
npm error '.' is not recognized as an internal or external command,
npm error operable program or batch file.
```

**Root Cause:** The npm package was trying to execute `./setup.sh` (Unix shell script) on Windows instead of `setup.bat`.

#### Step 4: Finding the UV Executable
```powershell
Get-Command uv -ErrorAction SilentlyContinue | Select-Object Source
# Result: C:\Users\igamenovoer\.local\bin\uv.exe
```

This revealed that `uv` was installed but not in the system PATH.

#### Step 5: Testing Direct UV Command
```bash
C:\Users\igamenovoer\.local\bin\uv.exe run --project d:\tools\markdownify-mcp markitdown --help
```

**Success!** This worked and showed that markitdown was available when using the correct uv path and project specification.

#### Step 6: Unicode Encoding Issues
When attempting to convert the webpage:
```
UnicodeEncodeError: 'gbk' codec can't encode character '\xe2' in position 3516: illegal multibyte sequence
```

**Solution:** Set UTF-8 encoding:
```powershell
$env:PYTHONIOENCODING="utf-8"
```

### Successful Workaround Process

1. **Uninstall broken npm package:**
   ```bash
   npm uninstall -g mcp-markdownify-server
   ```

2. **Build from source:**
   ```bash
   cd d:\tools\markdownify-mcp
   npm run build
   ```

3. **Install locally built package:**
   ```bash
   npm install -g .
   ```

4. **Run Windows setup script:**
   ```bash
   .\setup.bat
   ```

5. **Use proper UV command with encoding:**
   ```powershell
   $env:PYTHONIOENCODING="utf-8"
   C:\Users\igamenovoer\.local\bin\uv.exe run --project d:\tools\markdownify-mcp markitdown "input.html" | Out-File -FilePath "output.md" -Encoding UTF8
   ```

### Key Lessons Learned

1. **Path Issues:** The UV executable path detection in the MCP server was failing
2. **Platform Incompatibility:** npm package setup script not Windows-compatible
3. **Environment Variables:** UTF-8 encoding required on Windows
4. **Virtual Environment:** Dependencies were installed but path resolution was incorrect

### Complete Error Log from NPM Installation Attempt

When trying to install from npm, here's the complete error output:

```
⠙⠹⠸⠼⠴⠦⠧⠇⠏⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⠋⠙npm warn cleanup Failed to remove some directories [
npm warn cleanup   [
npm warn cleanup     '\\\\?\\C:\\Users\\igamenovoer\\AppData\\Roaming\\npm\\node_modules\\mcp
p-markdownify-server\\node_modules',
npm warn cleanup     [Error: EPERM: operation not permitted, rmdir 'C:\Users\igamenovoer\AppD
Data\Roaming\npm\node_modules\mcp-markdownify-server\node_modules\zod\src\v4\core\tests'] {   
npm warn cleanup       errno: -4048,
npm warn cleanup       code: 'EPERM',
npm warn cleanup       syscall: 'rmdir',
npm warn cleanup       path: 'C:\\Users\\igamenovoer\\AppData\\Roaming\\npm\\node_modules\\mc
cp-markdownify-server\\node_modules\\zod\\src\\v4\\core\\tests'
npm warn cleanup     }
npm warn cleanup   ]
npm warn cleanup ]
npm error code 1
npm error path C:\Users\igamenovoer\AppData\Roaming\npm\node_modules\mcp-markdownify-server  
npm error command failed
npm error command C:\WINDOWS\system32\cmd.exe /d /s /c ./setup.sh
npm error '.' is not recognized as an internal or external command,
npm error operable program or batch file.
npm error A complete log of this run can be found in: C:\Users\igamenovoer\AppData\Local\npm-
-cache\_logs\2025-07-21T08_36_08_578Z-debug-0.log
Command exited with code 1
```

**Analysis of this error:**
- The package installed partially but failed during the post-install setup
- Windows tried to execute `./setup.sh` which is a Unix shell script
- File permission issues with cleaning up temporary directories
- The package.json likely has a post-install script that runs the wrong setup file for Windows

### PowerShell Execution Policy Issue

During the setup.bat execution, this warning appeared:
```
The 'Get-ExecutionPolicy' command was found in the module 'Microsoft.PowerShell.Security', but the module could not be loaded. For more information, run 'Import-Module Microsoft.PowerShell.Security'.
```

This indicates PowerShell execution policy restrictions, but the script continued and completed successfully.

### Investigation of Package Structure

During troubleshooting, I examined the package structure to understand the dependency chain:

**package.json analysis:**
```json
{
  "scripts": {
    "preinstall": "node preinstall.js",
    // ... other scripts
  }
}
```

**pyproject.toml analysis:**
```toml
[project]
name = "ocr"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "markitdown>=0.0.1a3",
]
```

**Key findings:**
- The project requires both Node.js and Python ecosystems
- The `markitdown` Python package is the core dependency
- The MCP server acts as a bridge between the two ecosystems
- UV (Universal Python package manager) is used instead of pip

### UV Path Resolution Issues

The `UVX.ts` and `Markdownify.ts` files contain path resolution logic that was failing:

**From UVX.ts:**
```typescript
// Standard user installation locations using env-paths for cross-platform directories
if (process.platform === 'win32') {
  // Windows-specific locations
  possiblePaths.push(
    path.join(homeDir, '.local', 'bin', uvxExecutable),
    // ... other paths
  );
}
```

**From Markdownify.ts:**
```typescript
const command = `${quotedUvPath} run ${quotedMarkitdownPath} ${quotedFilePath}`;
```

The issue was that the code was trying to use the markitdown executable directly from the .venv directory, but it needed to use `uv run` with the `--project` flag to properly activate the virtual environment.

### Working Command Discovery

After investigation, the working command pattern was discovered:
```bash
# This works:
C:\Users\igamenovoer\.local\bin\uv.exe run --project d:\tools\markdownify-mcp markitdown input.html

# This doesn't work:
C:\Users\igamenovoer\.local\bin\uv.exe run d:\tools\markdownify-mcp\.venv\Scripts\markitdown.exe input.html
```

The difference is using `--project` flag which properly sets up the Python environment and dependencies.

## Common Issues and Solutions

### Issue 1: "markitdown module not found"

**Symptoms:**
```
ModuleNotFoundError: No module named 'markitdown'
```

**Solution:**
```bash
# Ensure you're in the project directory
cd /path/to/markdownify-mcp

# Reinstall Python dependencies
uv sync

# Test that markitdown works
uv run --project . markitdown --help
```

### Issue 2: Unicode Encoding Errors on Windows

**Symptoms:**
```
UnicodeEncodeError: 'gbk' codec can't encode character
```

**Solution:**
Set the Python encoding environment variable:
```powershell
$env:PYTHONIOENCODING="utf-8"
```

Or add to your PowerShell profile:
```powershell
echo '$env:PYTHONIOENCODING="utf-8"' >> $PROFILE
```

### Issue 3: Setup Script Fails on Windows

**Symptoms:**
```
'.' is not recognized as an internal or external command
```

**Root Cause:** The npm package tries to run `./setup.sh` on Windows instead of `setup.bat`.

**Solution:** Use Method 2 (install from source) or manually run setup:
```bat
# Navigate to the installed package directory
cd %APPDATA%\npm\node_modules\mcp-markdownify-server

# Run Windows setup manually
.\setup.bat
```

### Issue 4: UV/UVX Not Found

**Symptoms:**
```
uvx not found. Please ensure uv is installed
```

**Solution:**
```bash
# Install uv package manager
# Windows (PowerShell):
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Linux/Mac:
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"  # Linux/Mac
# Windows: Add %USERPROFILE%\.local\bin to PATH
```

## IDE Integration Configuration

### VS Code Configuration

Add to your VS Code settings (`.vscode/settings.json`):

```json
{
  "mcp.servers": {
    "markdownify": {
      "command": "mcp-markdownify-server",
      "args": [],
      "env": {
        "PYTHONIOENCODING": "utf-8"
      }
    }
  }
}
```

### Claude Desktop Configuration

Add to your Claude Desktop configuration file:

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**Mac:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "markdownify": {
      "command": "mcp-markdownify-server",
      "env": {
        "PYTHONIOENCODING": "utf-8"
      }
    }
  }
}
```

## Testing the Installation

### Basic Functionality Test
```bash
# Test webpage conversion
echo "Testing webpage conversion..."
# This should work if everything is set up correctly
```

### Manual Command Line Test
```bash
# Test markitdown directly
uv run --project /path/to/markdownify-mcp markitdown --help

# Test with a simple file
echo "Hello World" > test.txt
uv run --project /path/to/markdownify-mcp markitdown test.txt
```

## Environment Variables

Set these environment variables for optimal performance:

```bash
# Windows (PowerShell)
$env:PYTHONIOENCODING="utf-8"
$env:UV_PATH="C:\Users\%USERNAME%\.local\bin\uv.exe"

# Linux/Mac (Bash)
export PYTHONIOENCODING="utf-8"
export UV_PATH="$HOME/.local/bin/uv"
```

## Troubleshooting Checklist

Before reporting issues, verify:

- [ ] Node.js and npm are installed and up to date
- [ ] TypeScript project builds successfully (`npm run build`)
- [ ] Python dependencies are installed (`uv sync` succeeds)
- [ ] UV package manager is installed and in PATH
- [ ] markitdown command works (`uv run markitdown --help`)
- [ ] Environment variables are set correctly
- [ ] Package is installed globally (`npm list -g mcp-markdownify-server`)

## Known Limitations

1. **Windows Setup Script**: The published npm package has Windows compatibility issues
2. **Encoding Issues**: Windows may require explicit UTF-8 encoding settings
3. **Path Issues**: UV executable path detection may fail on some systems
4. **Dependencies**: Requires both Node.js and Python ecosystems

## Recommended Workflow

For developers and power users:

1. Clone the repository locally
2. Set up development environment with both Node.js and Python dependencies
3. Build and install locally rather than using npm registry
4. Configure IDE with proper environment variables
5. Test thoroughly before deploying to production

## Future Improvements Needed

1. Fix Windows setup script in npm package
2. Improve UV executable detection
3. Add better error messages for common issues
4. Provide pre-built binaries or Docker images
5. Add automated testing for different platforms

---

*Last updated: July 21, 2025*
*Based on version 0.0.2 of mcp-markdownify-server*
