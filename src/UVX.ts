import { exec } from "child_process";
import { promisify } from "util";
import fs from "fs";
import path from "path";
import os from "os";
import envPaths from "env-paths";
import upath from "upath";
const execAsync = promisify(exec);

const paths = envPaths('markdownify-mcp');

export default class UVX {
  uvPath: string;

  constructor(uvPath: string) {
    this.uvPath = uvPath;
  }

  get path() {
    return this.uvPath;
  }

  static async setup() {
    // Try to find uv using proper platform-specific paths
    const possiblePaths: string[] = [];
    const homeDir = os.homedir();
    const uvExecutable = process.platform === 'win32' ? 'uv.exe' : 'uv';
    
    // Standard user installation locations
    if (process.platform === 'win32') {
      // Windows-specific locations
      possiblePaths.push(
        path.join(homeDir, '.local', 'bin', uvExecutable),
        path.join(paths.data, 'bin', uvExecutable),
        path.join(process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming'), 'Python', 'Scripts', uvExecutable),
        path.join(process.env.LOCALAPPDATA || path.join(homeDir, 'AppData', 'Local'), 'Programs', 'Python', 'Scripts', uvExecutable)
      );
    } else {
      // Unix-like systems (Linux, macOS)
      possiblePaths.push(
        path.join(homeDir, '.local', 'bin', uvExecutable),
        path.join(paths.data, 'bin', uvExecutable),
        upath.join('/usr/local/bin', uvExecutable),
        upath.join('/usr/bin', uvExecutable),
        upath.join('/opt/homebrew/bin', uvExecutable) // Homebrew on Apple Silicon
      );
    }

    // First try using 'uv' from PATH
    try {
      const whichCommand = process.platform === 'win32' ? `where ${uvExecutable}` : `which ${uvExecutable}`;
      const { stdout: uvPath, stderr } = await execAsync(whichCommand);
      
      if (!stderr && uvPath.trim()) {
        const foundPath = uvPath.trim().split('\n')[0];
        return new UVX(upath.normalize(foundPath));
      }
    } catch {
      // Fall through to manual path checking
    }

    // If not in PATH, try common installation locations
    for (const possiblePath of possiblePaths) {
      try {
        const normalizedPath = upath.normalize(possiblePath);
        if (fs.existsSync(normalizedPath)) {
          return new UVX(normalizedPath);
        }
      } catch {
        // Continue checking other paths
      }
    }

    // Provide helpful error message with installation instructions
    const installInstructions = process.platform === 'win32' 
      ? 'Windows (PowerShell):\n  powershell -c "irm https://astral.sh/uv/install.ps1 | iex"'
      : 'Linux/Mac:\n  curl -LsSf https://astral.sh/uv/install.sh | sh';
    
    throw new Error(
      `uv package manager not found!\n\n` +
      `Please install uv first:\n${installInstructions}\n\n` +
      `After installation, run:\n` +
      `  uv sync  (to install Python dependencies)\n` +
      `  uv run --project . markitdown --help  (to verify)\n\n` +
      `For more info: https://docs.astral.sh/uv/getting-started/installation/`
    );
  }

  // Remove automatic dependency installation - let users handle this themselves
  async checkDeps(projectRoot: string): Promise<boolean> {
    try {
      const normalizedPath = upath.normalize(this.uvPath);
      const quotedPath = normalizedPath.includes(' ') ? `"${normalizedPath}"` : normalizedPath;
      const quotedProjectRoot = projectRoot.includes(' ') ? `"${projectRoot}"` : projectRoot;
      
      // Test if markitdown is available without trying to install
      await execAsync(`${quotedPath} run --project ${quotedProjectRoot} markitdown --help`);
      return true;
    } catch (error: any) {
      const errorMessage = error.message || error.toString();
      if (errorMessage.includes('ModuleNotFoundError')) {
        throw new Error(
          `Python dependencies not found!\n\n` +
          `Please run the following commands:\n` +
          `  cd ${projectRoot}\n` +
          `  uv sync\n\n` +
          `This will install the required Python packages including markitdown.`
        );
      }
      throw error;
    }
  }
}
