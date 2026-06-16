class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.1.0"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.1.0/buildline_0.1.0_darwin_all.tar.gz"
  sha256 "49527034f976dddccf025b99a88ebab2ec061ca1a31e7fbb14aea255a0fc95a7"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
