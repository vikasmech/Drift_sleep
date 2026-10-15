#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
server="${1:-https://one-tap-sleep-sounds.replit.app}"
case "$server" in
  https://*) ;;
  *) printf '%s\n' "Use a full HTTPS backend URL as the first argument." >&2; exit 1 ;;
esac
command -v python3 >/dev/null || { echo "Python 3 is needed to validate downloaded PCM WAV files." >&2; exit 1; }
mkdir -p DriftSleep/Resources
temporary=""
trap 'if [ -n "$temporary" ]; then rm -f "$temporary"; fi' EXIT
for id in gentle-rain ocean-waves brown-noise pink-noise soft-fan; do
  file="DriftSleep/Resources/loop-v2-$id.wav"
  if [ -f "$file" ]; then
    echo "Already present: $id"
    continue
  fi
  temporary="$file.part"
  echo "Preparing: $id"
  if ! curl --fail --location --proto '=https' --proto-redir '=https' \
    --max-time 120 --retry 2 --silent --show-error \
    "${server%/}/api/audio/loop-v2-$id.wav" -o "$temporary"; then
    echo "Backend does not serve the current loop. Use an updated backend URL, or the Mac ZIP with audio included." >&2
    exit 1
  fi
  python3 - "$temporary" <<'PY'
import sys, wave
with wave.open(sys.argv[1], "rb") as audio:
    duration = audio.getnframes() / audio.getframerate()
    assert audio.getcomptype() == "NONE", "Expected lossless PCM"
    assert audio.getnchannels() == 1 and audio.getsampwidth() == 2, "Expected mono 16-bit PCM"
    assert audio.getframerate() == 32000 and 20 <= duration <= 60, "Unexpected audio format or duration"
PY
  mv "$temporary" "$file"
  temporary=""
done
echo "All five lossless loops are ready. Open DriftSleep.xcodeproj in Xcode."
