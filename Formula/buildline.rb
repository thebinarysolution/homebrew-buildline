class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.1.1"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.1.1/buildline_0.1.1_darwin_all.tar.gz"
  sha256 "4ab43d8638e5dd0518855ec3b4401ac1927d3ff5c8a1b88112e215c1bfab2a37"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
