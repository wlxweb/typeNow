#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SVG="$ROOT_DIR/Resources/icon-flat.svg"
OUTPUT_ICNS="$ROOT_DIR/Resources/icon.icns"
TMP_DIR="$(mktemp -d)"
ICONSET_DIR="$TMP_DIR/typeNow.iconset"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -f "$SOURCE_SVG" ]]; then
  echo "Missing source SVG: $SOURCE_SVG" >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "Missing ImageMagick 'magick' command" >&2
  exit 1
fi

mkdir -p "$ICONSET_DIR"

export_png() {
  local points="$1"
  local scale="$2"
  local suffix=""
  local pixels=$((points * scale))
  if [[ "$scale" == "2" ]]; then
    suffix="@2x"
  fi

  magick -background none "$SOURCE_SVG" -resize "${pixels}x${pixels}" "$ICONSET_DIR/icon_${points}x${points}${suffix}.png"
}

for points in 16 32 128 256 512; do
  export_png "$points" 1
  export_png "$points" 2
done

iconutil --convert icns "$ICONSET_DIR" --output "$OUTPUT_ICNS"
echo "Generated $OUTPUT_ICNS"
