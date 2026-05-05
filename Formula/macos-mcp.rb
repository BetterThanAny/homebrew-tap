class MacosMcp < Formula
  desc "Expose native macOS capabilities to LLM agents over MCP stdio"
  homepage "https://github.com/BetterThanAny/macos-mcp"
  url "https://github.com/BetterThanAny/macos-mcp/releases/download/v0.1.0/macos-mcp-v0.1.0-darwin-arm64.tar.gz"
  version "0.1.0"
  sha256 "aa6e6f0809d1a1acea87f181fbe52d84679848cc1cfed5a6219ba57e96602d74"
  license "MIT"

  depends_on arch: :arm64
  depends_on :macos

  def install
    bin.install "macos-mcp"
  end

  test do
    require "io/wait"
    require "open3"
    init = <<~JSON.chomp + "\n"
      {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"brew-test","version":"1"}}}
    JSON

    response = +""
    Open3.popen3(bin/"macos-mcp") do |stdin, stdout, _stderr, wait_thr|
      stdin.write(init)
      stdin.close

      deadline = Time.now + 5
      loop do
        remaining = deadline - Time.now
        break if remaining <= 0

        break unless stdout.wait_readable(remaining)

        begin
          response << stdout.read_nonblock(4096)
          break if response.match?(/"jsonrpc"\s*:\s*"2\.0"/) && response.include?('"serverInfo"')
        rescue IO::WaitReadable
          next
        rescue EOFError
          break
        end
      end
    ensure
      begin
        stdin.close unless stdin.closed?
      rescue IOError
        nil
      end

      unless wait_thr.join(0)
        begin
          Process.kill("TERM", wait_thr.pid)
        rescue Errno::ESRCH
          nil
        end
        wait_thr.join(1)
      end

      unless wait_thr.join(0)
        begin
          Process.kill("KILL", wait_thr.pid)
        rescue Errno::ESRCH
          nil
        end
        wait_thr.join
      end
    end
    assert_match(/"jsonrpc"\s*:\s*"2\.0"/, response.to_s)
    assert_match(/"serverInfo"/, response.to_s)
  end
end
