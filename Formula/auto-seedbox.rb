class AutoSeedbox < Formula
  include Language::Python::Virtualenv
  desc "Watch macOS downloads folder for .torrents, upload them to seedbox, download resulting files."
  homepage "https://github.com/riley-martine/homebrew-auto-seedbox"

  url "/Users/zero/dev/homebrew-auto-seedbox",
    using: :git,
    branch: "main"
  version "2.0.6"
  # url "https://github.com/riley-martine/homebrew-auto-seedbox/archive/refs/tags/v1.0.4.tar.gz"
  # sha256 "c2e2e46b505fb27fbda187ba3afde41344bfae167f19a8ed5ad268e1db265571"
  license "GPL-3.0-only"


  depends_on "jq"
  depends_on "rclone"
  depends_on "nmap"
  # TODO remove rg dependency
  depends_on "ripgrep"
  depends_on "python@3.13"
  depends_on "libtorrent-rasterbar"

  head "https://github.com/riley-martine/homebrew-auto-seedbox.git", branch: "main"

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/73/f7/f14b46d4bcd21092d7d3ccef689615220d8a08fb25e564b65d20738e672e/certifi-2025.6.15.tar.gz"
    sha256 "d747aa5a8b9bbbb1bb8c22bb13e22bd1f18e9796defa16bab421f7f7a317323b"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/e4/33/89c2ced2b67d1c2a61c19c6751aa8902d46ce3dacb23600a283619f5a12d/charset_normalizer-3.4.2.tar.gz"
    sha256 "5baececa9ecba31eff645232d59845c07aa030f0c81ee70184a90d35099a0e63"
  end

  resource "dataclasses-json" do
    url "https://files.pythonhosted.org/packages/64/a4/f71d9cf3a5ac257c993b5ca3f93df5f7fb395c725e7f1e6479d2514173c3/dataclasses_json-0.6.7.tar.gz"
    sha256 "b6b3e528266ea45b9535223bc53ca645f5208833c29229e847b3f26a1cc55fc0"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f1/70/7703c29685631f5a7590aa73f1f1d3fa9a380e654b86af429e0934a32f7d/idna-3.10.tar.gz"
    sha256 "12f65c9b470abda6dc35cf8e63cc574b1c52b11df2c86030af0ac09b01b13ea9"
  end

  resource "macfsevents" do
    url "https://files.pythonhosted.org/packages/f3/80/0d780e46286819558305c3d698f0c700cba2af0b04e86840f528cc302802/MacFSEvents-0.8.4.tar.gz"
    sha256 "bf7283f1d517764ccdc8195b21631dbbac1c506b920bf9a8ea2956b3127651cb"
  end

  resource "marshmallow" do
    url "https://files.pythonhosted.org/packages/ab/5e/5e53d26b42ab75491cda89b871dab9e97c840bf12c63ec58a1919710cd06/marshmallow-3.26.1.tar.gz"
    sha256 "e6d8affb6cb61d39d26402096dc0aee12d5a26d490a121f118d2e81dc0719dc6"
  end

  resource "mypy-extensions" do
    url "https://files.pythonhosted.org/packages/a2/6e/371856a3fb9d31ca8dac321cda606860fa4548858c0cc45d9d1d4ca2628b/mypy_extensions-1.1.0.tar.gz"
    sha256 "52e68efc3284861e772bbcd66823fde5ae21fd2fdb51c62a211403730b916558"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/a1/d4/1fc4078c65507b51b96ca8f8c3ba19e6a61c8253c72794544580a7b6c24d/packaging-25.0.tar.gz"
    sha256 "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f"
  end

  resource "qbittorrent-api" do
    url "https://files.pythonhosted.org/packages/d6/a9/88fce9b8c5e79bac74b0e9624ec8af2da8280dddc87f91298178aafb7759/qbittorrent_api-2024.12.71.tar.gz"
    sha256 "4bb62ac075826d47529de562896bd97fe8527d2f55851ac3611d7b221c4507e2"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/e1/0a/929373653770d8a0d7ea76c37de6e41f11eb07559b103b1c02cafb3f7cf8/requests-2.32.4.tar.gz"
    sha256 "27d0316682c8a29834d3264820024b62a36942083d52caf2f14c0591336d3422"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/d1/bc/51647cd02527e87d05cb083ccc402f93e441606ff1f01739a62c8ad09ba5/typing_extensions-4.14.0.tar.gz"
    sha256 "8676b788e32f02ab42d9e7c61324048ae4c6d844a399eebace3d4979d75ceef4"
  end

  resource "typing-inspect" do
    url "https://files.pythonhosted.org/packages/dc/74/1789779d91f1961fa9438e9a8710cdae6bd138c80d7303996933d117264a/typing_inspect-0.9.0.tar.gz"
    sha256 "b23fc42ff6f6ef6954e4852c1fb512cdd18dbea03134f91f856a95ccc9461f78"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/15/22/9ee70a2574a4f4599c47dd506532914ce044817c7752a79b6a51286319bc/urllib3-2.5.0.tar.gz"
    sha256 "3fc47733c7e419d4bc3f6b3dc2b4f890bb743906a30d56ba4a5bfa4bbff92760"
  end

  resource "watchdog" do
    url "https://files.pythonhosted.org/packages/a2/48/a86139aaeab2db0a2482676f64798d8ac4d2dbb457523f50ab37bf02ce2c/watchdog-5.0.3.tar.gz"
    sha256 "108f42a7f0345042a854d4d0ad0834b741d421330d5f575b81cb27b883500176"
  end

  def install
    virtualenv_create(libexec, "python3.13")

    venv = virtualenv_install_with_resources without: "macfsevents"

    # https://github.com/malthe/macfsevents/issues/49
    resource("macfsevents").stage do
      ENV.append_to_cflags "-Wno-implicit-function-declaration"
      venv.pip_install Pathname.pwd
    end

    (libexec/"bin").mkpath
    (libexec/"bin").install "scripts/set_vars.sh"
    (libexec/"bin").install "scripts/torrent_daemon.sh"
    (libexec/"bin").install "scripts/copy_to_kindle.sh"

    bin.mkpath
    link libexec/"bin/copy_to_kindle.sh", bin/"copy_to_kindle"

    (var/"log").mkpath
  end

  service do
    run libexec/"bin/torrent_daemon.sh"
    keep_alive true
    log_path var/"log/auto-seedbox.log"
    error_log_path var/"log/auto-seedbox.log"
  end
end
