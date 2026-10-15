#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo "Run this script on macOS with full Xcode 16 or later selected." >&2
  exit 1
fi
destination="${1:-generic/platform=iOS Simulator}"
xcodebuild -project DriftSleep.xcodeproj -scheme DriftSleep \
  -configuration Debug -destination "$destination" \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
if [ "$destination" != "generic/platform=iOS Simulator" ]; then
  xcodebuild -project DriftSleep.xcodeproj -scheme DriftSleep \
    -configuration Debug -destination "$destination" \
    -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
else
  echo "Build complete. To run tests, pass a concrete simulator destination:"
  echo "bash scripts/validate-mac.sh 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID'"
fi
