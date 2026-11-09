#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CAPTURE_URL="${CAPTURE_URL:?Set CAPTURE_URL to the preview URL.}"
CAPTURE_DIR="${CAPTURE_DIR:?Set CAPTURE_DIR to the evidence directory.}"
RUNTIME_DIR="${RUNTIME_DIR:?RUNTIME_DIR must point to the preview runtime.}"

/usr/bin/time -p test -f "$RUNTIME_DIR/scripts/default-capture.mjs"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
CAPTURE_DIR="$(cd "$CAPTURE_DIR" && pwd -P)"
case "$CAPTURE_DIR/" in
  "$PROJECT_DIR/"*) echo "Capture output must be outside the project source tree." >&2; exit 1 ;;
esac
export CAPTURE_URL CAPTURE_DIR
# Strict mode treats browser-rendering errors as defects (exit 1); the runtime
# capture utility maps temporary browser/navigation infrastructure failures to 75.
export CAPTURE_STRICT=1
/usr/bin/time -p node "$RUNTIME_DIR/scripts/default-capture.mjs"
