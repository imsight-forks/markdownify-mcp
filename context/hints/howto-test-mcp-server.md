# How to Test MCP Server During Development

This guide explains how to start up and test the MCP server during development using Node.js tools, without loading the MCP servers into an IDE like VS Code.

## Starting the MCP Server

### 1. Build and Start the Server

First, you need to build the TypeScript code and start the server:

```bash
# Build the project
npm run build

# Start the server
npm start
```

Or for development with auto-rebuilding:
```bash
# Watch mode for development
npm run dev
```

### 2. Test Using MCP Inspector (Recommended)

The **MCP Inspector** is the official testing tool for MCP servers. It's a visual tool that runs in your browser and allows you to test your server without needing an IDE integration.

Install and run the MCP Inspector to test your server:

```bash
# Install the MCP Inspector globally
npm install -g @modelcontextprotocol/inspector

# Test your local server (after building)
npx @modelcontextprotocol/inspector node dist/index.js
```

This will:
- Start the MCP Inspector UI (usually on port 6274)
- Connect to your server via stdio transport
- Provide a web interface to test all your tools

### 3. Alternative: Direct CLI Testing

You can also test specific tools directly using the inspector's CLI mode:

```bash
# List all available tools
npx @modelcontextprotocol/inspector --cli node dist/index.js --method tools/list

# Test a specific tool (replace with your actual tool name)
npx @modelcontextprotocol/inspector --cli node dist/index.js --method tools/call --tool-name pdf-to-markdown --tool-arg filepath="/path/to/test.pdf"
```

## Development Workflow

Here's the recommended development workflow:

1. **Development Mode**: Run `npm run dev` to watch for TypeScript changes
2. **Testing**: In another terminal, use the MCP Inspector to test your server
3. **Debugging**: Check the inspector's console and your server's stderr output for logs

### Example Test Setup

You could create a simple test script to verify your server works:

```bash
# Create a test directory
mkdir -p test-files

# Test with the inspector
npx @modelcontextprotocol/inspector node dist/index.js
```

## Key Points for This Project

Based on the codebase:

- The server uses **stdio transport** (StdioServerTransport)
- The entry point is `dist/index.js` after building
- The server exposes tools for converting various formats to markdown (PDF, DOCX, images, etc.)
- The server requires Python dependencies (uv) which should be handled by the setup scripts

## Debugging Tips

1. **Server Logs**: The server logs to stderr, which the inspector will capture
2. **Environment**: Make sure `PYTHONUTF8=1` is set (the code does this automatically)
3. **Dependencies**: Ensure Python and uv are properly installed via the setup scripts

## Why Use MCP Inspector?

The MCP Inspector is the best tool for development testing as it provides:
- Visual interface for testing tools
- Real-time connection status
- Tool argument testing
- Response inspection
- Export configurations for later use in IDEs

This approach gives you a complete testing environment without needing to configure MCP servers in VS Code or other IDEs during development.

## Additional Resources

- [MCP Inspector Documentation](https://modelcontextprotocol.io/docs/tools/inspector)
- [MCP Inspector GitHub Repository](https://github.com/modelcontextprotocol/inspector)
- [MCP Server Development Guide](https://modelcontextprotocol.io/quickstart/server)
