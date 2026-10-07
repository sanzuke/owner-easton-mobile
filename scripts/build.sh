#!/usr/bin/env bash
# Build dengan nomor build otomatis naik (menit sejak 1 Jan 2026 UTC) -> android versionCode / iOS CFBundleVersion.
# Pemakaian:  scripts/build.sh [apk|appbundle|ios] [argumen flutter lain...]
#   contoh:   scripts/build.sh apk --debug
#             scripts/build.sh appbundle --release
# Nama versi (1.0.0) tetap dari `version:` di pubspec.yaml; hanya angka build yang diganti.
set -euo pipefail
cd "$(dirname "$0")/.."
TARGET="${1:-apk}"; shift || true
BUILD_NUMBER=$(( ($(date -u +%s) - 1767225600) / 60 ))
echo "Nomor build: ${BUILD_NUMBER}"
flutter build "$TARGET" --build-number="$BUILD_NUMBER" "$@"
