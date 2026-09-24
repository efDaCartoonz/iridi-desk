#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-1.0.1}"
TARGET_ARCH="${2:-universal}" # arm64, x86_64, or universal

echo "=========================================="
echo " Building iRidiDesk for macOS"
echo " Version: $VERSION"
echo " Target Architecture: $TARGET_ARCH"
echo "=========================================="

cd "$PROJECT_ROOT"

# 1. Check .env file
ENV_FILE="$PROJECT_ROOT/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: Local .env file not found at $ENV_FILE"
    echo "Create .env from .env.example before building."
    exit 1
fi

export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# Load .env variables
while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Trim whitespace and skip comments/empty lines
    key="$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ -z "$key" || "$key" =~ ^# ]]; then
        continue
    fi
    value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ "$key" =~ ^IRIDI_ ]]; then
        export "$key=$value"
    fi
done < "$ENV_FILE"

if [[ -z "${IRIDI_RENDEZVOUS_SERVER:-}" || -z "${IRIDI_RELAY_SERVER:-}" || -z "${IRIDI_PUB_KEY:-}" ]]; then
    echo "ERROR: IRIDI_RENDEZVOUS_SERVER, IRIDI_RELAY_SERVER, and IRIDI_PUB_KEY must be set in .env"
    exit 1
fi

# 2. Check toolchains
if ! command -v cargo &>/dev/null; then
    echo "ERROR: cargo not found in PATH. Make sure Rust toolchain is installed."
    exit 1
fi

# Locate VCPKG_ROOT
if [[ -z "${VCPKG_ROOT:-}" ]]; then
    if [[ -d "$HOME/vcpkg" ]]; then
        export VCPKG_ROOT="$HOME/vcpkg"
    elif [[ -d "/Users/admin/vcpkg" ]]; then
        export VCPKG_ROOT="/Users/admin/vcpkg"
    elif [[ -d "/opt/vcpkg" ]]; then
        export VCPKG_ROOT="/opt/vcpkg"
    fi
fi

if [[ -z "${VCPKG_ROOT:-}" || ! -d "$VCPKG_ROOT" ]]; then
    echo "ERROR: VCPKG_ROOT not found. Please set VCPKG_ROOT or install vcpkg."
    exit 1
fi

export VCPKG_ROOT

# 3. Generate inline sciter UI
echo "==> Generating inline Sciter UI..."
python3 res/inline-sciter.py

# 4. Generate macOS ICNS icon if missing
if [[ ! -f "$PROJECT_ROOT/res/iRidiDesk.icns" ]]; then
    echo "==> Generating macOS icon..."
    if [[ -f "$PROJECT_ROOT/res/iridi/favicon.ico" ]]; then
        TMP_ICONSET="/tmp/iRidiDesk_$$.iconset"
        TMP_PNG="/tmp/iridi_base_$$.png"
        mkdir -p "$TMP_ICONSET"
        sips -s format png "$PROJECT_ROOT/res/iridi/favicon.ico" --out "$TMP_PNG" >/dev/null
        sips -z 16 16     "$TMP_PNG" --out "$TMP_ICONSET/icon_16x16.png" >/dev/null
        sips -z 32 32     "$TMP_PNG" --out "$TMP_ICONSET/icon_16x16@2x.png" >/dev/null
        sips -z 32 32     "$TMP_PNG" --out "$TMP_ICONSET/icon_32x32.png" >/dev/null
        sips -z 64 64     "$TMP_PNG" --out "$TMP_ICONSET/icon_32x32@2x.png" >/dev/null
        sips -z 128 128   "$TMP_PNG" --out "$TMP_ICONSET/icon_128x128.png" >/dev/null
        sips -z 256 256   "$TMP_PNG" --out "$TMP_ICONSET/icon_128x128@2x.png" >/dev/null
        sips -z 256 256   "$TMP_PNG" --out "$TMP_ICONSET/icon_256x256.png" >/dev/null
        sips -z 512 512   "$TMP_PNG" --out "$TMP_ICONSET/icon_256x256@2x.png" >/dev/null
        sips -z 512 512   "$TMP_PNG" --out "$TMP_ICONSET/icon_512x512.png" >/dev/null
        sips -z 1024 1024 "$TMP_PNG" --out "$TMP_ICONSET/icon_512x512@2x.png" >/dev/null
        iconutil -c icns "$TMP_ICONSET" -o "$PROJECT_ROOT/res/iRidiDesk.icns"
        rm -rf "$TMP_ICONSET" "$TMP_PNG"
    fi
fi

# Ensure universal libsciter.dylib exists
if [[ ! -f "$PROJECT_ROOT/libsciter.dylib" && -f "$PROJECT_ROOT/res/libsciter.dylib" ]]; then
    cp "$PROJECT_ROOT/res/libsciter.dylib" "$PROJECT_ROOT/libsciter.dylib"
fi

build_target() {
    local arch="$1"
    local rust_target="$2"
    echo "==> Compiling for $arch ($rust_target)..."
    # The app bundle needs both the UI executable and the service helper.
    MACOSX_DEPLOYMENT_TARGET=10.14 cargo build --release --bins --target "$rust_target" --features inline
}

case "$TARGET_ARCH" in
    arm64|aarch64)
        build_target "arm64" "aarch64-apple-darwin"
        ARCHS=("arm64")
        ;;
    x86_64|x64|intel)
        build_target "x86_64" "x86_64-apple-darwin"
        ARCHS=("x86_64")
        ;;
    universal|all)
        build_target "arm64" "aarch64-apple-darwin"
        build_target "x86_64" "x86_64-apple-darwin"
        ARCHS=("arm64" "x86_64" "universal")
        ;;
    *)
        echo "ERROR: Unknown target architecture $TARGET_ARCH"
        exit 1
        ;;
esac

DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

for ARCH in "${ARCHS[@]}"; do
    echo "==> Packaging bundle for $ARCH..."
    PKG_NAME="iRidiDesk-$VERSION-macos-$ARCH"
    PKG_DIR="$DIST_DIR/$PKG_NAME"
    APP_DIR="$PKG_DIR/iRidiDesk.app"

    rm -rf "$PKG_DIR"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Generate Info.plist and PkgInfo
    sed -e "s/VERSION_PLACEHOLDER/$VERSION/g" "$PROJECT_ROOT/res/Info.plist" > "$APP_DIR/Contents/Info.plist"
    echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

    # Copy icons
    if [[ -f "$PROJECT_ROOT/res/iRidiDesk.icns" ]]; then
        cp "$PROJECT_ROOT/res/iRidiDesk.icns" "$APP_DIR/Contents/Resources/iRidiDesk.icns"
    fi

    # Copy libsciter.dylib
    cp "$PROJECT_ROOT/res/libsciter.dylib" "$APP_DIR/Contents/MacOS/libsciter.dylib"

    # Copy binaries
    if [[ "$ARCH" == "arm64" ]]; then
        cp "$PROJECT_ROOT/target/aarch64-apple-darwin/release/rustdesk" "$APP_DIR/Contents/MacOS/iRidiDesk"
        cp "$PROJECT_ROOT/target/aarch64-apple-darwin/release/service" "$APP_DIR/Contents/MacOS/service"
    elif [[ "$ARCH" == "x86_64" ]]; then
        cp "$PROJECT_ROOT/target/x86_64-apple-darwin/release/rustdesk" "$APP_DIR/Contents/MacOS/iRidiDesk"
        cp "$PROJECT_ROOT/target/x86_64-apple-darwin/release/service" "$APP_DIR/Contents/MacOS/service"
    elif [[ "$ARCH" == "universal" ]]; then
        echo "==> Creating Universal binary via lipo..."
        lipo -create \
            "$PROJECT_ROOT/target/aarch64-apple-darwin/release/rustdesk" \
            "$PROJECT_ROOT/target/x86_64-apple-darwin/release/rustdesk" \
            -output "$APP_DIR/Contents/MacOS/iRidiDesk"
        lipo -create \
            "$PROJECT_ROOT/target/aarch64-apple-darwin/release/service" \
            "$PROJECT_ROOT/target/x86_64-apple-darwin/release/service" \
            -output "$APP_DIR/Contents/MacOS/service"
    fi

    chmod +x "$APP_DIR/Contents/MacOS/iRidiDesk"
    chmod +x "$APP_DIR/Contents/MacOS/service"

    # Strip symbols
    strip "$APP_DIR/Contents/MacOS/iRidiDesk" || true
    strip "$APP_DIR/Contents/MacOS/service" || true

    # Ad-hoc code signing for local macOS compatibility
    echo "==> Codesigning bundle..."
    codesign --force --options runtime -s - "$APP_DIR/Contents/MacOS/libsciter.dylib" || true
    codesign --force --options runtime --entitlements "$PROJECT_ROOT/res/iRidiDesk.entitlements" -s - "$APP_DIR/Contents/MacOS/service" || true
    codesign --force --options runtime --entitlements "$PROJECT_ROOT/res/iRidiDesk.entitlements" -s - "$APP_DIR/Contents/MacOS/iRidiDesk" || true
    codesign --force --options runtime --entitlements "$PROJECT_ROOT/res/iRidiDesk.entitlements" -s - "$APP_DIR" || true

    # Create ZIP archive
    ZIP_PATH="$DIST_DIR/$PKG_NAME.zip"
    rm -f "$ZIP_PATH"
    (cd "$PKG_DIR" && zip -r -q "$ZIP_PATH" "iRidiDesk.app")
    echo "Created ZIP archive: $ZIP_PATH"

    # Create DMG disk image
    DMG_PATH="$DIST_DIR/$PKG_NAME.dmg"
    rm -f "$DMG_PATH"

    DMG_TMP="$DIST_DIR/dmg_tmp_$ARCH"
    rm -rf "$DMG_TMP"
    mkdir -p "$DMG_TMP"
    cp -R "$APP_DIR" "$DMG_TMP/"
    ln -s /Applications "$DMG_TMP/Applications"

    hdiutil create -volname "iRidiDesk" -srcfolder "$DMG_TMP" -ov -format UDZO "$DMG_PATH" >/dev/null
    rm -rf "$DMG_TMP"
    echo "Created DMG disk image: $DMG_PATH"
done

echo "=========================================="
echo " BUILD COMPLETE!"
echo " Output files are located in dist/:"
ls -lh "$DIST_DIR"/*.zip "$DIST_DIR"/*.dmg
echo "=========================================="
