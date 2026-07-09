# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.4.4"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.4.4/buildline_0.4.4_darwin_all.tar.gz"
  sha256 "8dd7c415c5a105efbd6fd8230e4eb28321ac99949c9eeb3f25e266c3efec5092"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
