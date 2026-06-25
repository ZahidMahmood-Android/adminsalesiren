#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LOG_FILE="docs/release-management.md"
DATE="$(date +%Y-%m-%d)"
VERSION="$(awk '/^version:/{print $2; exit}' pubspec.yaml)"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Missing $LOG_FILE. Create it using the template in docs/BUILD_AND_RUN.md." >&2
  exit 1
fi

if ! grep -q "## ${DATE}" "$LOG_FILE"; then
  echo "Add a '## ${DATE}' section to $LOG_FILE before building a web release." >&2
  echo "Include version (${VERSION}), deploy target, and a short summary." >&2
  exit 1
fi

echo "Release log OK (${DATE}). Building admin panel web release ${VERSION}..."
flutter build web --release "$@"
echo "Done. Output: build/web/ — deploy artifacts only; do not commit build/."
