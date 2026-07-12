#!/usr/bin/env bash
# Installs a per-user GitHub Actions runner for this repository on macOS.
# Run it once as the same macOS user who authenticated Codex.
set -euo pipefail

repository="${1:-rudranaik/giffer}"
runner_home="${RUNNER_HOME:-$HOME/.local/share/actions-runner-giffer}"
runner_name="${RUNNER_NAME:-$(scutil --get ComputerName | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-codex-giffer}"
uid="$(id -u)"
plist="$HOME/Library/LaunchAgents/com.github.${repository//\//-}.codex-runner.plist"

case "$(uname -m)" in
  arm64) platform="osx-arm64" ;;
  x86_64) platform="osx-x64" ;;
  *) echo "Unsupported macOS architecture: $(uname -m)" >&2; exit 1 ;;
esac

for command in gh curl tar shasum launchctl; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Missing required command: $command" >&2
    exit 1
  }
done

if ! codex login status >/dev/null 2>&1; then
  echo "Authenticate Codex first by running: codex login" >&2
  exit 1
fi

mkdir -p "$runner_home" "$HOME/Library/LaunchAgents"

if [[ ! -x "$runner_home/config.sh" ]]; then
  asset="$(gh api repos/actions/runner/releases/latest --jq ".assets[] | select(.name | test(\"^actions-runner-${platform}-[0-9].*\\\\.tar\\\\.gz$\")) | .name")"
  asset_url="$(gh api repos/actions/runner/releases/latest --jq ".assets[] | select(.name == \"${asset}\") | .browser_download_url")"
  digest="$(gh api repos/actions/runner/releases/latest --jq ".assets[] | select(.name == \"${asset}\") | .digest" | sed 's/^sha256://')"

  if [[ -z "$asset_url" || -z "$digest" ]]; then
    echo "Could not find a verified runner release for ${platform}." >&2
    exit 1
  fi

  archive="$runner_home/$asset"
  curl --fail --location --show-error --silent "$asset_url" --output "$archive"
  printf '%s  %s\n' "$digest" "$archive" | shasum -a 256 --check --status
  tar xzf "$archive" -C "$runner_home"
  rm -f "$archive"
fi

registration_token="$(gh api --method POST "repos/${repository}/actions/runners/registration-token" --jq .token)"
"$runner_home/config.sh" \
  --unattended \
  --replace \
  --url "https://github.com/${repository}" \
  --token "$registration_token" \
  --name "$runner_name" \
  --labels "codex,giffer" \
  --work "_work"

cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.github.${repository//\//-}.codex-runner</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>${runner_home}/run.sh</string></array>
  <key>WorkingDirectory</key><string>${runner_home}</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF

launchctl bootout "gui/${uid}" "$plist" 2>/dev/null || true
launchctl bootstrap "gui/${uid}" "$plist"
launchctl kickstart -k "gui/${uid}/com.github.${repository//\//-}.codex-runner"

echo "Runner '${runner_name}' is installed and running for ${repository}."
