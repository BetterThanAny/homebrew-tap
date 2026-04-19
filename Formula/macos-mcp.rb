class MacosMcp < Formula
  desc "MCP server exposing native macOS capabilities (Spotlight, Shortcuts, Calendar, Reminders, screencapture, Vision OCR, browser tabs, Mail) to LLM agents"
  homepage "https://github.com/BetterThanAny/macos-mcp"
  url "https://github.com/BetterThanAny/macos-mcp/releases/download/v0.1.0/macos-mcp-v0.1.0-darwin-arm64.tar.gz"
  sha256 "aa6e6f0809d1a1acea87f181fbe52d84679848cc1cfed5a6219ba57e96602d74"
  version "0.1.0"
  license "MIT"

  depends_on :macos
  depends_on arch: :arm64

  def install
    bin.install "macos-mcp"
  end

  test do
    # The server speaks MCP JSON-RPC over stdio. Send a minimal initialize
    # request and assert the response looks like a JSON-RPC reply.
    init_request = <<~JSON.chomp
      {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"brew-test","version":"1"}}}
    JSON
    response = pipe_output("#{bin}/macos-mcp", init_request, 0)
    assert_match(/"jsonrpc"\s*:\s*"2\.0"/, response)
    assert_match(/"serverInfo"/, response)
  end
end
