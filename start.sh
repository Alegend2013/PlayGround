#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$PROJECT_DIR"
PORT="${PORT:-3000}"
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT > 0 && PORT < 65536 )) || { echo "PORT must be between 1 and 65535." >&2; exit 1; }

# Install project dependencies and run the project's build script when one exists.
if [[ -f package.json ]]; then
  /usr/bin/time -p npm install --no-audit --no-fund
  /usr/bin/time -p npm run build --if-present
fi

# Serve the built static output when the project defines one; otherwise this is
# a static site whose build directory is the project root itself.
if [[ -f dist/index.html ]]; then
  DEPLOY_DIR="$PROJECT_DIR/dist"
elif [[ -f build/index.html ]]; then
  DEPLOY_DIR="$PROJECT_DIR/build"
else
  DEPLOY_DIR="$PROJECT_DIR"
fi
/usr/bin/time -p test -f "$DEPLOY_DIR/index.html"

WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$WEB_DIR"
PROJECT_PATH="$PROJECT_DIR" DEPLOY_PATH="$DEPLOY_DIR" OUTPUT_PATH="$WEB_DIR/deployment-output.json" \
  /usr/bin/time -p node --input-type=module -e '
    import { writeFileSync, renameSync } from "node:fs";
    const output = process.env.OUTPUT_PATH;
    const temporary = `${output}.tmp`;
    writeFileSync(temporary, JSON.stringify({ project: process.env.PROJECT_PATH, directory: process.env.DEPLOY_PATH }) + "\n");
    renameSync(temporary, output);
  '

export PORT
/usr/bin/time -p python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$DEPLOY_DIR"
