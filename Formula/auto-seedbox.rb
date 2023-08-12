class AutoSeedbox < Formula
  desc "Watch macOS downloads folder for .torrents, upload them to seedbox, download resulting files."
  homepage "https://github.com/riley-martine/homebrew-auto-seedbox"

  url "https://github.com/riley-martine/homebrew-auto-seedbox/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "686f4b73a7f55064b8f9031dadaaa2dc7b9e0942c0ce6e7faac1bcf4317d6465"
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
    libexec.install "scripts/set_vars.sh"
    libexec.install "scripts/get_download_target.py"

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
