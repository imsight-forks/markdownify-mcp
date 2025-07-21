import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

console.log('🔍 Checking system requirements...');

// Check if uv is available
function checkUvInstallation() {
  try {
    const uvExecutable = process.platform === 'win32' ? 'uv.exe' : 'uv';
    
    // Check common locations
    const possiblePaths = [
      join(homedir(), '.local', 'bin', uvExecutable),
    ];
    
    if (process.platform === 'win32') {
      possiblePaths.push(
        join(process.env.APPDATA || join(homedir(), 'AppData', 'Roaming'), 'Python', 'Scripts', uvExecutable),
        join(process.env.LOCALAPPDATA || join(homedir(), 'AppData', 'Local'), 'Programs', 'Python', 'Scripts', uvExecutable)
      );
    } else {
      possiblePaths.push('/usr/local/bin/' + uvExecutable, '/usr/bin/' + uvExecutable);
    }
    
    // Try to find uv in PATH first
    try {
      const whichCommand = process.platform === 'win32' ? `where ${uvExecutable}` : `which ${uvExecutable}`;
      execSync(whichCommand, { stdio: 'pipe' });
      console.log('✅ uv found in PATH');
      return true;
    } catch {
      // Check common installation locations
      for (const path of possiblePaths) {
        if (existsSync(path)) {
          console.log(`✅ uv found at ${path}`);
          return true;
        }
      }
    }
    return false;
  } catch {
    return false;
  }
}

if (!checkUvInstallation()) {
  console.log('❌ uv package manager not found!');
  console.log('');
  console.log('📋 Please install uv first:');
  
  if (process.platform === 'win32') {
    console.log('Windows (PowerShell):');
    console.log('  powershell -c "irm https://astral.sh/uv/install.ps1 | iex"');
  } else {
    console.log('Linux/Mac:');
    console.log('  curl -LsSf https://astral.sh/uv/install.sh | sh');
  }
  
  console.log('');
  console.log('Then run: uv sync');
  console.log('');
  console.log('For more info: https://docs.astral.sh/uv/getting-started/installation/');
  
  // Don't fail the install, just warn
  console.log('⚠️  You can continue, but the MCP server may not work until uv is installed and dependencies are synced.');
} else {
  console.log('✅ System requirements check passed!');
  console.log('');
  console.log('🔧 Next steps after installation:');
  console.log('1. Run: uv sync  (to install Python dependencies)');
  console.log('2. Verify: uv run --project . markitdown --help');
}