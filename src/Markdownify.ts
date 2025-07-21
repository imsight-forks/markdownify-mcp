import { exec } from "child_process";
import { promisify } from "util";
import path from "path";
import fs from "fs";
import os from "os";
import { fileURLToPath } from "url";
import envPaths from "env-paths";
import upath from "upath";

const execAsync = promisify(exec);
const paths = envPaths('markdownify-mcp');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Constants for download limits and timeouts
const WARNING_FILE_SIZE = 50 * 1024 * 1024; // 50MB - warn but don't block
const DOWNLOAD_TIMEOUT = 30000; // 30 second timeout

export type MarkdownResult = {
  path: string;
  text: string;
};

export class Markdownify {
  private static isUrl(input: string): boolean {
    try {
      new URL(input);
      return input.startsWith('http://') || input.startsWith('https://');
    } catch {
      return false;
    }
  }

  private static getFileExtensionFromUrl(url: string): string | null {
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const extension = path.extname(pathname).toLowerCase().slice(1);
      
      // Return recognized extensions, default to null for unknown
      if (['pdf', 'docx', 'xlsx', 'pptx', 'jpg', 'jpeg', 'png', 'gif', 'mp3', 'wav', 'mp4'].includes(extension)) {
        return extension;
      }
      return null;
    } catch {
      return null;
    }
  }

  private static async downloadToTempFile(url: string): Promise<string> {
    // Validate URL
    if (!this.isUrl(url)) {
      throw new Error("Invalid URL provided");
    }

    const parsedUrl = new URL(url);
    if (!["http:", "https:"].includes(parsedUrl.protocol)) {
      throw new Error("Only HTTP and HTTPS protocols are allowed");
    }

    // Create secure temporary directory
    const tempDir = await fs.promises.mkdtemp(
      path.join(await fs.promises.realpath(os.tmpdir()), 'markdownify-')
    );

    try {
      // Determine file extension from URL
      const extension = this.getFileExtensionFromUrl(url) || 'bin';
      const tempFilePath = path.join(tempDir, `download.${extension}`);

      // Download with timeout and size limit
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), DOWNLOAD_TIMEOUT);

      try {
        const response = await fetch(url, { 
          signal: controller.signal 
        });
        clearTimeout(timeoutId);

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        // Check content length if provided - warn for large files
        const contentLength = response.headers.get('content-length');
        if (contentLength && parseInt(contentLength) > WARNING_FILE_SIZE) {
          console.warn(`Warning: Large file detected: ${Math.round(parseInt(contentLength) / 1024 / 1024)}MB. This may take longer to process.`);
        }

        const arrayBuffer = await response.arrayBuffer();
        
        // Warn for actual size if large
        if (arrayBuffer.byteLength > WARNING_FILE_SIZE) {
          console.warn(`Warning: Large file processed: ${Math.round(arrayBuffer.byteLength / 1024 / 1024)}MB.`);
        }

        await fs.promises.writeFile(tempFilePath, Buffer.from(arrayBuffer));
        return tempFilePath;
      } catch (error) {
        clearTimeout(timeoutId);
        // Clean up temp directory on download failure
        await fs.promises.rm(tempDir, { recursive: true, force: true }).catch(() => {});
        throw error;
      }
    } catch (error) {
      // Clean up temp directory on any failure
      await fs.promises.rm(tempDir, { recursive: true, force: true }).catch(() => {});
      throw error;
    }
  }

  private static async _markitdown(
    filePath: string,
    projectRoot: string,
    uvPath: string,
  ): Promise<string> {
    // Expand home directory and normalize paths using upath for consistency
    const expandedUvPath = this.expandHome(uvPath);
    const normalizedUvPath = upath.normalize(expandedUvPath);
    const normalizedProjectRoot = upath.normalize(projectRoot);
    // Don't normalize URLs - only normalize actual file paths
    const normalizedFilePath = this.isUrl(filePath) ? filePath : upath.normalize(filePath);
    
    // Properly quote paths for Windows (upath handles path separators consistently)
    const quotedUvPath = normalizedUvPath.includes(' ') ? `"${normalizedUvPath}"` : normalizedUvPath;
    const quotedProjectRoot = normalizedProjectRoot.includes(' ') ? `"${normalizedProjectRoot}"` : normalizedProjectRoot;
    const quotedFilePath = normalizedFilePath.includes(' ') ? `"${normalizedFilePath}"` : normalizedFilePath;
    
    // Use 'uv run --project' which properly sets up the virtual environment
    const command = `${quotedUvPath} run --project ${quotedProjectRoot} markitdown ${quotedFilePath}`;
    
    // Set up environment for proper encoding on Windows
    const env = { 
      ...process.env,
      // Force UTF-8 encoding on Windows to avoid Unicode issues
      ...(process.platform === 'win32' ? { PYTHONIOENCODING: 'utf-8' } : {})
    };
    
    const { stdout, stderr } = await execAsync(command, { env });

    if (stderr) {
      throw new Error(`Error executing command: ${stderr}`);
    }

    return stdout;
  }

  private static async saveToTempFile(content: string | Buffer, suggestedExtension?: string | null): Promise<string> {
    let outputExtension = "md";
    if (suggestedExtension != null) {
      outputExtension = suggestedExtension;
    }

    const tempOutputPath = upath.join(
      os.tmpdir(),
      `markdown_output_${Date.now()}.${outputExtension}`,
    );
    fs.writeFileSync(tempOutputPath, content);
    return tempOutputPath;
  }

  private static normalizePath(p: string): string {
    return upath.normalize(p);
  }
  
  private static expandHome(filepath: string): string {
    if (filepath.startsWith('~/') || filepath === '~') {
      return upath.join(os.homedir(), filepath.slice(1));
    }
    // Handle Windows-style home expansion using upath for consistency
    if (process.platform === 'win32' && filepath.startsWith('~\\')) {
      return upath.join(os.homedir(), filepath.slice(2));
    }
    return upath.normalize(filepath);
  }

  private static getDefaultUvPath(): string {
    const homeDir = os.homedir();
    const uvExecutable = process.platform === 'win32' ? 'uv.exe' : 'uv';
    
    // Try multiple standard locations using env-paths for platform-specific directories
    const possiblePaths = [
      path.join(homeDir, '.local', 'bin', uvExecutable),
      path.join(paths.data, 'bin', uvExecutable), // Application data directory
    ];
    
    if (process.platform === 'win32') {
      possiblePaths.push(
        path.join(process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming'), 'Python', 'Scripts', uvExecutable),
        path.join(process.env.LOCALAPPDATA || path.join(homeDir, 'AppData', 'Local'), 'Programs', 'Python', 'Scripts', uvExecutable)
      );
    } else {
      possiblePaths.push(
        upath.join('/usr/local/bin', uvExecutable),
        upath.join('/usr/bin', uvExecutable)
      );
    }
    
    // Check if any of these paths exist and return the first one found
    for (const possiblePath of possiblePaths) {
      try {
        const normalizedPath = upath.normalize(possiblePath);
        if (fs.existsSync(normalizedPath)) {
          return normalizedPath;
        }
      } catch {
        // Continue checking other paths
      }
    }
    
    // If none found, return the first standard location (user's .local/bin)
    return upath.normalize(possiblePaths[0]);
  }

  static async toMarkdown({
    filePath,
    url,
    projectRoot = upath.resolve(__dirname, ".."),
    uvPath = Markdownify.getDefaultUvPath(),
  }: {
    filePath?: string;
    url?: string;
    projectRoot?: string;
    uvPath?: string;
  }): Promise<MarkdownResult> {
    try {
      let inputPath: string;
      let isTemporary = false;
      let tempDirToCleanup: string | null = null;

      if (url) {
        const response = await fetch(url);

        let extension = null;

        if (url.endsWith(".pdf")) {
          extension = "pdf";
        } else {
          // Default to html for webpages so markitdown can process them
          extension = "html";
        }

        const arrayBuffer = await response.arrayBuffer();
        const content = Buffer.from(arrayBuffer);

        inputPath = await this.saveToTempFile(content, extension);
        isTemporary = true;
      } else if (filePath) {
        // Check if filePath is actually a URL
        if (this.isUrl(filePath)) {
          inputPath = await this.downloadToTempFile(filePath);
          isTemporary = true;
          // Store temp directory path for cleanup (downloadToTempFile creates a directory)
          tempDirToCleanup = path.dirname(inputPath);
        } else {
          inputPath = filePath;
        }
      } else {
        throw new Error("Either filePath or url must be provided");
      }

      const text = await this._markitdown(inputPath, projectRoot, uvPath);
      const outputPath = await this.saveToTempFile(text);

      // Clean up temporary files/directories
      if (isTemporary) {
        try {
          if (tempDirToCleanup) {
            // Clean up entire temp directory (for downloaded files)
            await fs.promises.rm(tempDirToCleanup, { recursive: true, force: true });
          } else {
            // Clean up single temp file (for old method)
            fs.unlinkSync(inputPath);
          }
        } catch (cleanupError) {
          // Log cleanup error but don't fail the operation
          console.warn('Failed to cleanup temporary files:', cleanupError);
        }
      }

      return { path: outputPath, text };
    } catch (e: unknown) {
      if (e instanceof Error) {
        throw new Error(`Error processing to Markdown: ${e.message}`);
      } else {
        throw new Error("Error processing to Markdown: Unknown error occurred");
      }
    }
  }

  static async get({
    filePath,
  }: {
    filePath: string;
  }): Promise<MarkdownResult> {
    // Check file type is *.md or *.markdown
    const normPath = this.normalizePath(upath.resolve(this.expandHome(filePath)));
    const markdownExt = [".md", ".markdown"];
    if (!markdownExt.includes(upath.extname(normPath))){
      throw new Error("Required file is not a Markdown file.");
    }

    if (process.env?.MD_SHARE_DIR) {
      const allowedShareDir = this.normalizePath(upath.resolve(this.expandHome(process.env.MD_SHARE_DIR)));
      if (!normPath.startsWith(allowedShareDir)) {
        throw new Error(`Only files in ${allowedShareDir} are allowed.`);
      }
    }

    if (!fs.existsSync(filePath)) {
      throw new Error("File does not exist");
    }

    const text = await fs.promises.readFile(filePath, "utf-8");

    return {
      path: filePath,
      text: text,
    };
  }
}
