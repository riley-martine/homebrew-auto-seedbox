class AutoSeedbox < Formula
  desc "Watch MacOS downloads folder for .torrents, upload them to seedbox, download resulting files."
  homepage "https://github.com/riley-martine/homebrew-auto-seedbox"

  # TODO do we need version?
  # version "v0.0.1"
  url "https://github.com/riley-martine/homebrew-auto-seedbox/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "20f32f22de814b4cbc3cba1ed4eeab03a66ab51aeaf80faeafd9fb9a7d339b56"
  license "GPL-3.0-only"


  depends_on "jq"
  depends_on "rclone"
  depends_on "libtorrent-rasterbar"
  depends_on "fswatch"
  depends_on "nmap"
  # TODO remove rg dependency
  depends_on "ripgrep"

  head "https://github.com/riley-martine/homebrew-auto-seedbox.git", branch: "main"

  # TODO delete this once done
  revision 3

  # I'm kind of using this as a replacement for a Makefile
  # It is what it is
  def install
    libexec.mkpath
    libexec.install "auto_download/torrent_daemon.sh"
    libexec.install "auto_download/torrent_name.py"
    libexec.install "auto_download/wait_and_download.sh"
    libexec.install "auto_kindle/copy_to_kindle.sh"
    libexec.install "auto_kindle/get_torrent_epub_files.py"

    (var/"log").mkpath
    system "mkdir -p \"$HOME/.config/auto-seedbox\""
  end

  service do
    run libexec/"torrent_daemon.sh"
    keep_alive true
    log_path var/"log/auto-seedbox.log"
    error_log_path var/"log/auto-seedbox.log"
    working_dir libexec
  end

  test do
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
