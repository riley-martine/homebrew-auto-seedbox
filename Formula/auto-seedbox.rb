class AutoSeedbox < Formula
  desc "Watch macOS downloads folder for .torrents, upload them to seedbox, download resulting files."
  homepage "https://github.com/riley-martine/homebrew-auto-seedbox"

  url "https://github.com/riley-martine/homebrew-auto-seedbox/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "a0231d4c01aa0ad6021932f8308214a90d73c0eb6e9b16eb6aba0a6fb34dc84d"
  license "GPL-3.0-only"


  depends_on "jq"
  depends_on "rclone"
  depends_on "libtorrent-rasterbar"
  depends_on "fswatch"
  depends_on "nmap"
  # TODO remove rg dependency
  depends_on "ripgrep"

  head "https://github.com/riley-martine/homebrew-auto-seedbox.git", branch: "main"


  # I'm kind of using this as a replacement for a Makefile
  # It is what it is
  def install
    libexec.mkpath
    libexec.install "scripts/torrent_daemon.sh"
    libexec.install "scripts/torrent_name.py"
    libexec.install "scripts/wait_and_download.sh"
    libexec.install "scripts/copy_to_kindle.sh"
    libexec.install "scripts/get_torrent_epub_files.py"

    (var/"log").mkpath
  end

  service do
    run libexec/"torrent_daemon.sh"
    keep_alive true
    log_path var/"log/auto-seedbox.log"
    error_log_path var/"log/auto-seedbox.log"
    working_dir libexec
  end
end
