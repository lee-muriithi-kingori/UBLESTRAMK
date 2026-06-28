#!/bin/bash
# ==========================================
# UBLESTRAMK - Build Script
# Builds the flashable ZIP package
# Usage: ./build.sh [version]
# ==========================================

set -e

# Configuration
MODULE_ID="UBLESTRAMK"
MODULE_NAME="UBLESTRAMK"
DEFAULT_VERSION="v0.9.0-beta"
VERSION="${1:-$DEFAULT_VERSION}"
VERSION_CODE=900
AUTHOR="lee-muriithi-kingori"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
ZYGISK_SRC="$SCRIPT_DIR/zygisk_src"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo ""
echo "============================================"
echo "  UBLESTRAMK Build System"
echo "============================================"
echo "  Module: $MODULE_NAME"
echo "  Version: $VERSION"
echo "  Author: $AUTHOR"
echo "============================================"
echo ""

# Clean previous build
log_info "Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Check for NDK
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_NDK" ]; then
    log_warn "ANDROID_NDK_HOME not set. Skipping native build."
    log_warn "Set ANDROID_NDK_HOME to build Zygisk libraries."
    SKIP_NATIVE=1
else
    NDK="${ANDROID_NDK_HOME:-$ANDROID_NDK}"
    log_info "Using Android NDK: $NDK"
    SKIP_NATIVE=0
fi

# Build Zygisk native libraries if NDK is available
if [ "$SKIP_NATIVE" -eq 0 ]; then
    log_info "Building Zygisk native libraries..."
    
    cd "$ZYGISK_SRC"
    
    # Build using ndk-build
    if [ -f "$NDK/ndk-build" ]; then
        "$NDK/ndk-build" -C "$ZYGISK_SRC" \
            NDK_PROJECT_PATH="$ZYGISK_SRC" \
            APP_BUILD_SCRIPT="$ZYGISK_SRC/jni/Android.mk" \
            NDK_APPLICATION_MK="$ZYGISK_SRC/jni/Application.mk" \
            NDK_OUT="$BUILD_DIR/obj" \
            NDK_LIBS_OUT="$BUILD_DIR/libs" \
            clean 2>/dev/null || true
            
        "$NDK/ndk-build" -C "$ZYGISK_SRC" \
            NDK_PROJECT_PATH="$ZYGISK_SRC" \
            APP_BUILD_SCRIPT="$ZYGISK_SRC/jni/Android.mk" \
            NDK_APPLICATION_MK="$ZYGISK_SRC/jni/Application.mk" \
            NDK_OUT="$BUILD_DIR/obj" \
            NDK_LIBS_OUT="$BUILD_DIR/libs"
        
        if [ $? -eq 0 ]; then
            log_success "Native libraries built successfully"
        else
            log_error "Native build failed!"
            log_warn "Continuing without Zygisk libraries..."
        fi
    else
        log_warn "ndk-build not found. Skipping native build."
    fi
    
    cd "$SCRIPT_DIR"
else
    log_warn "Skipping native library build (no NDK)"
fi

# Prepare module directory
log_info "Preparing module package..."
MODULE_BUILD="$BUILD_DIR/$MODULE_ID"
mkdir -p "$MODULE_BUILD"

# Copy module files
# Preflight: ensure all required files exist before we try to copy them
REQUIRED_FILES=(
    "module.prop"
    "system.prop"
    "post-fs-data.sh"
    "service.sh"
    "customize.sh"
    "uninstall.sh"
    "action.sh"
    "common_func.sh"
    "target_apps.txt"
    "hide_root.sh"
    "README.md"
    "META-INF/com/google/android/update-binary"
)
for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$f" ]; then
        log_error "Missing required file: $f"
        exit 1
    fi
done

# Copy module files
cp "$SCRIPT_DIR/module.prop" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/system.prop" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/post-fs-data.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/service.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/customize.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/uninstall.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/action.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/common_func.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/target_apps.txt" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/hide_root.sh" "$MODULE_BUILD/"
cp "$SCRIPT_DIR/README.md" "$MODULE_BUILD/"

# Copy META-INF
cp -r "$SCRIPT_DIR/META-INF" "$MODULE_BUILD/"

# Update version in module.prop
sed -i "s/^version=.*/version=$VERSION/" "$MODULE_BUILD/module.prop"
sed -i "s/^versionCode=.*/versionCode=$VERSION_CODE/" "$MODULE_BUILD/module.prop"

# Copy Zygisk libraries if built
if [ -d "$BUILD_DIR/libs" ]; then
    log_info "Including Zygisk libraries..."
    mkdir -p "$MODULE_BUILD/zygisk"
    
    for abi in arm64-v8a armeabi-v7a x86 x86_64; do
        if [ -f "$BUILD_DIR/libs/$abi/libublestramk.so" ]; then
            # Rename to standard Zygisk library name
            cp "$BUILD_DIR/libs/$abi/libublestramk.so" "$MODULE_BUILD/zygisk/$abi.so"
            log_info "  Added Zygisk library: $abi"
        fi
    done
else
    log_warn "No Zygisk libraries found (NDK build skipped or failed)"
    log_warn "Module will work in shell-only mode"
fi

# Set proper permissions
chmod -R 755 "$MODULE_BUILD"
chmod 644 "$MODULE_BUILD/module.prop"
chmod 644 "$MODULE_BUILD/system.prop"
chmod 644 "$MODULE_BUILD/common_func.sh"
chmod 644 "$MODULE_BUILD/target_apps.txt"
chmod 644 "$MODULE_BUILD/README.md"

# Make scripts executable
chmod 755 "$MODULE_BUILD/post-fs-data.sh"
chmod 755 "$MODULE_BUILD/service.sh"
chmod 755 "$MODULE_BUILD/customize.sh"
chmod 755 "$MODULE_BUILD/uninstall.sh"
chmod 755 "$MODULE_BUILD/action.sh"
chmod 755 "$MODULE_BUILD/hide_root.sh"
chmod 755 "$MODULE_BUILD/META-INF/com/google/android/update-binary"

# Create flashable ZIP
ZIP_NAME="${MODULE_NAME}-${VERSION}.zip"
log_info "Creating flashable ZIP: $ZIP_NAME..."

cd "$MODULE_BUILD"
zip -r "$OUTPUT_DIR/$ZIP_NAME" . \
    -x "*.git*" \
    -x "*.DS_Store" \
    -x "*__MACOSX*" \
    -x "*.swp" \
    -x "*.swo"

cd "$SCRIPT_DIR"

# Calculate checksums
if command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
    echo "$SHA256  $ZIP_NAME" > "$OUTPUT_DIR/$ZIP_NAME.sha256"
    log_info "SHA256: $SHA256"
elif command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
    echo "$SHA256  $ZIP_NAME" > "$OUTPUT_DIR/$ZIP_NAME.sha256"
    log_info "SHA256: $SHA256"
fi

# Get file size
FILESIZE=$(du -h "$OUTPUT_DIR/$ZIP_NAME" | cut -f1)

# Generate update.json for Magisk/KernelSU
log_info "Generating update.json..."
cat > "$OUTPUT_DIR/update.json" <<EOF
{
    "version": "$VERSION",
    "versionCode": $VERSION_CODE,
    "zipUrl": "https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases/download/$VERSION/$ZIP_NAME",
    "changelog": "https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases/tag/$VERSION"
}
EOF

# Build summary
echo ""
echo "============================================"
echo "  BUILD COMPLETE"
echo "============================================"
echo "  Module: $MODULE_NAME"
echo "  Version: $VERSION"
echo "  File: $ZIP_NAME"
echo "  Size: $FILESIZE"
echo "  Output: $OUTPUT_DIR/"
echo ""
echo "  Files:"
ls -la "$OUTPUT_DIR/"
echo ""
echo "============================================"
echo "  INSTALL INSTRUCTIONS:"
echo "============================================"
echo "  1. Push to device: adb push $OUTPUT_DIR/$ZIP_NAME /sdcard/Download/"
echo "  2. Install via Magisk/KernelSU Manager"
echo "  3. Reboot device"
echo "  4. Add apps to DenyList/Unmount modules"
echo "  5. Clear target app data"
echo "============================================"
echo ""

log_success "Build completed successfully!"
