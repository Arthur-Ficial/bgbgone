#!/usr/bin/env bash
# Update the Arthur-Ficial/homebrew-tap formula for bgbgone to a new
# version + sha256, in-place via the GitHub Contents API. Used by
# `make deploy`.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <version> <sha256>" >&2
    exit 2
fi

version="$1"
sha="$2"
tap_repo="Arthur-Ficial/homebrew-tap"
formula_path="Formula/bgbgone.rb"

echo "homebrew-tap: bumping bgbgone -> v${version} (sha256 ${sha})"

current_sha=$(gh api "/repos/${tap_repo}/contents/${formula_path}" -q .sha)

tmpformula=$(mktemp)
cat > "$tmpformula" <<EOF
class Bgbgone < Formula
  desc "On-device Apple Vision background remover for macOS"
  homepage "https://github.com/Arthur-Ficial/bgbgone"
  url "https://github.com/Arthur-Ficial/bgbgone/releases/download/v${version}/bgbgone-${version}-arm64-macos.tar.gz"
  sha256 "${sha}"
  license "MIT"

  def install
    odie "bgbgone requires Apple Silicon." unless Hardware::CPU.arm?

    bin.install "bgbgone"
  end

  def caveats
    <<~EOS
      bgbgone runs entirely on-device using Apples Vision framework.
      No API keys, no network, no accounts. No GUI side-effects - every
      invocation is silent and scriptable.

      Verify with:
        bgbgone --version
        bgbgone --check
        bgbgone /path/to/photo.jpg -o cutout.png

      To use a generated or hand-painted background, save it as a PNG / JPG
      and compose with --bg image:<path>.
    EOS
  end

  test do
    assert_match "bgbgone v", shell_output("#{bin}/bgbgone --version")
    assert_match "USAGE:", shell_output("#{bin}/bgbgone --help")
    assert_match "capability report", shell_output("#{bin}/bgbgone --check")
  end
end
EOF
new_content=$(cat "$tmpformula")
rm -f "$tmpformula"

b64=$(printf '%s' "$new_content" | base64)

gh api --method PUT "/repos/${tap_repo}/contents/${formula_path}" \
    -f message="bgbgone: bump to v${version}" \
    -f content="${b64}" \
    -f sha="${current_sha}" \
    -q '"homebrew-tap: commit " + .commit.sha[0:8] + " -> " + .commit.html_url'
