class AutoSeedbox < Formula
  include Language::Python::Virtualenv
  desc "Watch macOS downloads folder for .torrents, upload them to seedbox, download resulting files."
  homepage "https://github.com/riley-martine/homebrew-auto-seedbox"

  url "/Users/zero/dev/homebrew-auto-seedbox",
    using: :git,
    tag: "main"
  version "2.0.0"
  # url "https://github.com/riley-martine/homebrew-auto-seedbox/archive/refs/tags/v1.0.4.tar.gz"
  # sha256 "c2e2e46b505fb27fbda187ba3afde41344bfae167f19a8ed5ad268e1db265571"
  license "GPL-3.0-only"


  depends_on "jq"
  depends_on "rclone"
  depends_on "nmap"
  # TODO remove rg dependency
  depends_on "ripgrep"
  depends_on "python@3.12"

  head "https://github.com/riley-martine/homebrew-auto-seedbox.git", branch: "main"


  def install
    virtualenv_create(libexec, "python3.12")
    virtualenv_install_with_resources

    libexec.mkpath
    libexec.install "scripts/set_vars.sh"
    libexec.install "scripts/torrent_daemon.sh"

    bin.mkpath
    bin.install "scripts/copy_to_kindle.sh"

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
