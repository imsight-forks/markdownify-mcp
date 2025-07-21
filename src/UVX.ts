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
  uvxPath: string;

  constructor(uvxPath: string) {
    this.uvxPath = uvxPath;
  }

  get path() {
    return this.uvxPath;
  }

  static async setup() {
    // Try to find uvx using proper platform-specific paths
    const possiblePaths: string[] = [];
    const homeDir = os.homedir();
    const uvxExecutable = process.platform === 'win32' ? 'uvx.exe' : 'uvx';
    
    // Standard user installation locations using env-paths for cross-platform directories
    if (process.platform === 'win32') {
      // Windows-specific locations
      possiblePaths.push(
        path.join(homeDir, '.local', 'bin', uvxExecutable),
        path.join(paths.data, 'bin', uvxExecutable), // Application data directory
        path.join(process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming'), 'Python', 'Scripts', uvxExecutable),
        path.join(process.env.LOCALAPPDATA || path.join(homeDir, 'AppData', 'Local'), 'Programs', 'Python', 'Scripts', uvxExecutable)
      );
    } else {
      // Unix-like systems (Linux, macOS)
      possiblePaths.push(
        path.join(homeDir, '.local', 'bin', uvxExecutable),
        path.join(paths.data, 'bin', uvxExecutable), // Application data directory
        upath.join('/usr/local/bin', uvxExecutable),
        upath.join('/usr/bin', uvxExecutable),
        upath.join('/opt/homebrew/bin', uvxExecutable) // Homebrew on Apple Silicon
      );
    }
    
    // Add system PATH as last resort
    possiblePaths.push(uvxExecutable);

    // First try using 'uvx' from PATH
    try {
      const whichCommand = process.platform === 'win32' ? `where ${uvxExecutable}` : `which ${uvxExecutable}`;
      const { stdout: uvxPath, stderr } = await execAsync(whichCommand);
      
      if (!stderr && uvxPath.trim()) {
        const foundPath = uvxPath.trim().split('\n')[0];
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

    throw new Error(
      "uvx not found. Please ensure uv is installed and uvx is in your PATH, or set UV_PATH environment variable.",
    );
  }

  async installDeps() {
    // This is a hack to make sure that markitdown is installed before it's called in the OCRProcessor
    try {
      const normalizedPath = upath.normalize(this.uvxPath);
      const quotedPath = normalizedPath.includes(' ') ? `"${normalizedPath}"` : normalizedPath;
      await execAsync(`${quotedPath} markitdown example.pdf`);
    } catch {
      console.log("UVX markitdown should be ready now");
    }
  }
}
