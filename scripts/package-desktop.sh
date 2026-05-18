#!/usr/bin/env bash
set -euo pipefail

LOVE_VERSION="${LOVE_VERSION:-11.5}"
GAME_NAME="${GAME_NAME:-ShadowDuet}"
GAME_TITLE="${GAME_TITLE:-Shadow Duet}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/desktop"
GAME_SRC="$BUILD_DIR/game-src"
DIST_DIR="$ROOT_DIR/dist"
CACHE_DIR="$BUILD_DIR/cache"
LOVE_FILE="$DIST_DIR/$GAME_NAME.love"

mkdir -p "$DIST_DIR" "$CACHE_DIR"
rm -rf "$GAME_SRC" "$DIST_DIR"/*
mkdir -p "$GAME_SRC"

cp "$ROOT_DIR/conf.lua" "$ROOT_DIR/main.lua" "$ROOT_DIR/levels.lua" "$GAME_SRC/"
cp -R "$ROOT_DIR/assets" "$GAME_SRC/assets"

(
  cd "$GAME_SRC"
  python3 - "$LOVE_FILE" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
out = Path(sys.argv[1])
with ZipFile(out, 'w', ZIP_DEFLATED) as z:
    for p in sorted(Path('.').rglob('*')):
        if p.is_file():
            z.write(p, p.as_posix())
PY
)

base_url="https://github.com/love2d/love/releases/download/$LOVE_VERSION"

fetch() {
  local name="$1"
  local out="$CACHE_DIR/$name"
  if [[ ! -s "$out" ]]; then
    curl -L --fail --retry 3 --retry-delay 2 -o "$out" "$base_url/$name"
  fi
  printf '%s\n' "$out"
}

# Windows x64 fused executable bundle.
win_zip="$(fetch "love-$LOVE_VERSION-win64.zip")"
win_dir="$BUILD_DIR/win64"
rm -rf "$win_dir"
mkdir -p "$win_dir"
python3 - "$win_zip" "$win_dir" <<'PY'
from zipfile import ZipFile
import sys
with ZipFile(sys.argv[1]) as z:
    z.extractall(sys.argv[2])
PY
win_runtime="$(find "$win_dir" -maxdepth 1 -type d -name "love-*win64" | head -n 1)"
win_out="$BUILD_DIR/$GAME_NAME-windows-x64"
rm -rf "$win_out"
mkdir -p "$win_out"
cat "$win_runtime/love.exe" "$LOVE_FILE" > "$win_out/$GAME_NAME.exe"
find "$win_runtime" -maxdepth 1 -type f ! -name 'love.exe' -exec cp {} "$win_out/" \;
printf '%s\n' "Run $GAME_NAME.exe" > "$win_out/README.txt"
(
  cd "$BUILD_DIR"
  python3 - "$DIST_DIR/$GAME_NAME-windows-x64.zip" "$GAME_NAME-windows-x64" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
out, root = Path(sys.argv[1]), Path(sys.argv[2])
with ZipFile(out, 'w', ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file():
            z.write(p, p.relative_to(root.parent))
PY
)

# macOS app bundle with game.love embedded.
mac_zip="$(fetch "love-$LOVE_VERSION-macos.zip")"
mac_dir="$BUILD_DIR/macos"
rm -rf "$mac_dir"
mkdir -p "$mac_dir"
python3 - "$mac_zip" "$mac_dir" <<'PY'
from zipfile import ZipFile
import sys
with ZipFile(sys.argv[1]) as z:
    z.extractall(sys.argv[2])
PY
mac_app_src="$(find "$mac_dir" -maxdepth 2 -name 'love.app' -type d | head -n 1)"
mac_out_dir="$BUILD_DIR/$GAME_NAME-macos"
rm -rf "$mac_out_dir"
mkdir -p "$mac_out_dir"
cp -R "$mac_app_src" "$mac_out_dir/$GAME_TITLE.app"
cp "$LOVE_FILE" "$mac_out_dir/$GAME_TITLE.app/Contents/Resources/game.love"
python3 - "$mac_out_dir/$GAME_TITLE.app/Contents/Info.plist" "$GAME_TITLE" "$GAME_NAME" <<'PY'
import plistlib, sys
path, title, ident = sys.argv[1:4]
with open(path, 'rb') as f:
    data = plistlib.load(f)
data['CFBundleName'] = title
data['CFBundleDisplayName'] = title
data['CFBundleIdentifier'] = f'io.github.awsl233777.{ident.lower()}'
with open(path, 'wb') as f:
    plistlib.dump(data, f)
PY
(
  cd "$BUILD_DIR"
  python3 - "$DIST_DIR/$GAME_NAME-macos.zip" "$GAME_NAME-macos" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
out, root = Path(sys.argv[1]), Path(sys.argv[2])
with ZipFile(out, 'w', ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file():
            z.write(p, p.relative_to(root.parent))
PY
)

# Linux x86_64 bundle with official AppImage runtime and launcher.
linux_appimage="$(fetch "love-$LOVE_VERSION-x86_64.AppImage")"
linux_out="$BUILD_DIR/$GAME_NAME-linux-x86_64"
rm -rf "$linux_out"
mkdir -p "$linux_out"
cp "$linux_appimage" "$linux_out/love-$LOVE_VERSION-x86_64.AppImage"
chmod +x "$linux_out/love-$LOVE_VERSION-x86_64.AppImage"
cp "$LOVE_FILE" "$linux_out/$GAME_NAME.love"
cat > "$linux_out/run.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "\$(dirname "\$0")"
./love-$LOVE_VERSION-x86_64.AppImage ./$GAME_NAME.love
EOF
chmod +x "$linux_out/run.sh"
cat > "$linux_out/README.txt" <<EOF
Run ./run.sh on Linux x86_64.
If AppImage/FUSE is unavailable, install Love2D $LOVE_VERSION and run: love $GAME_NAME.love
EOF
(
  cd "$BUILD_DIR"
  tar -czf "$DIST_DIR/$GAME_NAME-linux-x86_64.tar.gz" "$GAME_NAME-linux-x86_64"
)

ls -lh "$DIST_DIR"
