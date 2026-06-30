#!/bin/bash
# ==========================================
# UBLESTRAMK - Build Script v1.4.0
# Usage: ./build.sh [version] [--check-only]
# ==========================================
set -euo pipefail

MODULE_ID="UBLESTRAMK"
MODULE_NAME="UBLESTRAMK"
DEFAULT_VERSION="v1.4.0"
VERSION="${1:-$DEFAULT_VERSION}"
VERSION_CODE=1400
CHECK_ONLY=false
[ "${1:-}" = "--check-only" ] || [ "${2:-}" = "--check-only" ] && CHECK_ONLY=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
ZYGISK_SRC="$SCRIPT_DIR/zygisk_src"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ERRORS=0; WARNINGS=0
error() { log_error "$1"; ERRORS=$((ERRORS + 1)); }
warn() { log_warn "$1"; WARNINGS=$((WARNINGS + 1)); }

echo ""
echo "============================================"
echo "  UBLESTRAMK Build System v1.4.0"
echo "  Module: $MODULE_NAME"
echo "  Version: $VERSION"
echo "============================================"
echo ""

validate_required_files() {
    log_info "Validating required files..."
    REQUIRED_FILES=(
        "module.prop" "system.prop" "post-fs-data.sh" "service.sh"
        "customize.sh" "uninstall.sh" "action.sh" "common_func.sh"
        "target_apps.txt" "hide_root.sh" "README.md"
        "keybox.xml" "keybox_updater.sh" "update_service_addon.sh"
    )
    for f in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$f" ]; then error "Missing: $f"
        else
            local size=$(wc -c < "$SCRIPT_DIR/$f" 2>/dev/null || echo 0)
            log_info "  OK: $f (${size}B)"
        fi
    done
    if [ ! -f "$SCRIPT_DIR/META-INF/com/google/android/update-binary" ]; then
        error "Missing META-INF/update-binary"
    fi
}

validate_shell_scripts() {
    log_info "Validating shell syntax..."
    for f in post-fs-data.sh service.sh customize.sh uninstall.sh action.sh common_func.sh hide_root.sh keybox_updater.sh update_service_addon.sh; do
        [ -f "$SCRIPT_DIR/$f" ] && sh -n "$SCRIPT_DIR/$f" 2>/dev/null && log_info "  OK: $f" || error "Syntax error in $f"
    done
}

validate_webroot() {
    log_info "Validating WebUI..."
    if [ ! -d "$SCRIPT_DIR/webroot" ]; then error "Missing webroot/"; return; fi
    if [ ! -f "$SCRIPT_DIR/webroot/index.html" ]; then error "Missing webroot/index.html"
    else
        local size=$(wc -c < "$SCRIPT_DIR/webroot/index.html" 2>/dev/null || echo 0)
        log_info "  OK: webroot/index.html (${size}B)"
    fi
}

validate_module_prop() {
    log_info "Validating module.prop..."
    local id=$(grep "^id=" "$SCRIPT_DIR/module.prop" 2>/dev/null | cut -d'=' -f2 || true)
    local ver=$(grep "^version=" "$SCRIPT_DIR/module.prop" 2>/dev/null | cut -d'=' -f2 || true)
    local vcode=$(grep "^versionCode=" "$SCRIPT_DIR/module.prop" 2>/dev/null | cut -d'=' -f2 || true)
    [ -z "$id" ] && error "Missing id"
    [ -z "$ver" ] && error "Missing version"
    [ -z "$vcode" ] && error "Missing versionCode"
    echo "$id" | grep -qE '\[STABLE\]|\[BETA\]' && warn "Name has [STABLE]/[BETA] tags"
    grep -q "^webroot=" "$SCRIPT_DIR/module.prop" || warn "webroot field missing"
    log_info "  Module: $id $ver (code: $vcode)"
}

validate_keybox() {
    log_info "Validating keybox.xml..."
    grep -q "PLACEHOLDER" "$SCRIPT_DIR/keybox.xml" 2>/dev/null && warn "keybox.xml has PLACEHOLDERs"
    grep -q "<Keybox>" "$SCRIPT_DIR/keybox.xml" 2>/dev/null || error "Missing <Keybox> tag"
    grep -q "<Key" "$SCRIPT_DIR/keybox.xml" 2>/dev/null || error "Missing <Key> elements"
}

validate_system_prop() {
    log_info "Validating system.prop..."
    grep -q "ro.build.selinux=0" "$SCRIPT_DIR/system.prop" 2>/dev/null && warn "ro.build.selinux=0 detected"
}

validate_required_files
validate_shell_scripts
validate_webroot
validate_module_prop
validate_keybox
validate_system_prop

if [ $ERRORS -gt 0 ]; then
    echo ""
    log_error "VALIDATION FAILED: $ERRORS errors, $WARNINGS warnings"
    exit 1
fi

[ $WARNINGS -gt 0 ] && log_warn "$WARNINGS warning(s)"
log_success "All validations passed"

if [ "$CHECK_ONLY" = true ]; then
    log_success "Check-only mode complete"
    exit 0
fi

log_info "Cleaning build..."
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

SKIP_NATIVE=1
if [ -n "${ANDROID_NDK_HOME:-}" ] || [ -n "${ANDROID_NDK:-}" ]; then
    NDK="${ANDROID_NDK_HOME:-$ANDROID_NDK}"
    if [ -f "$NDK/ndk-build" ]; then
        log_info "Using NDK: $NDK"
        SKIP_NATIVE=0
    fi
fi

if [ "$SKIP_NATIVE" -eq 0 ]; then
    log_info "Building Zygisk..."
    cd "$ZYGISK_SRC"
    "$NDK/ndk-build" -C "$ZYGISK_SRC" clean 2>/dev/null || true
    if "$NDK/ndk-build" -C "$ZYGISK_SRC" \
        NDK_PROJECT_PATH="$ZYGISK_SRC" \
        APP_BUILD_SCRIPT="$ZYGISK_SRC/jni/Android.mk" \
        NDK_APPLICATION_MK="$ZYGISK_SRC/jni/Application.mk" \
        NDK_OUT="$BUILD_DIR/obj" \
        NDK_LIBS_OUT="$BUILD_DIR/libs"; then
        log_success "Native build OK"
    else
        log_warn "Native build failed"
    fi
    cd "$SCRIPT_DIR"
fi

MODULE_BUILD="$BUILD_DIR/$MODULE_ID"
mkdir -p "$MODULE_BUILD"

cp "$SCRIPT_DIR/module.prop" "$SCRIPT_DIR/system.prop" "$SCRIPT_DIR/post-fs-data.sh" \
   "$SCRIPT_DIR/service.sh" "$SCRIPT_DIR/customize.sh" "$SCRIPT_DIR/uninstall.sh" \
   "$SCRIPT_DIR/action.sh" "$SCRIPT_DIR/common_func.sh" "$SCRIPT_DIR/target_apps.txt" \
   "$SCRIPT_DIR/hide_root.sh" "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/keybox.xml" \
   "$SCRIPT_DIR/keybox_updater.sh" "$SCRIPT_DIR/update_service_addon.sh" "$MODULE_BUILD/"

cp -r "$SCRIPT_DIR/META-INF" "$MODULE_BUILD/"
cp -r "$SCRIPT_DIR/webroot" "$MODULE_BUILD/"

sed -i "s/^version=.*/version=$VERSION/" "$MODULE_BUILD/module.prop"
sed -i "s/^versionCode=.*/versionCode=$VERSION_CODE/" "$MODULE_BUILD/module.prop"

if [ -d "$BUILD_DIR/libs" ]; then
    mkdir -p "$MODULE_BUILD/zygisk"
    for abi in arm64-v8a armeabi-v7a x86 x86_64; do
        [ -f "$BUILD_DIR/libs/$abi/libublestramk.so" ] && \
            cp "$BUILD_DIR/libs/$abi/libublestramk.so" "$MODULE_BUILD/zygisk/$abi.so"
    done
fi

chmod -R 755 "$MODULE_BUILD"
chmod 644 "$MODULE_BUILD/module.prop" "$MODULE_BUILD/system.prop" "$MODULE_BUILD/common_func.sh" \
    "$MODULE_BUILD/target_apps.txt" "$MODULE_BUILD/README.md" "$MODULE_BUILD/keybox.xml" \
    "$MODULE_BUILD/update_service_addon.sh"
chmod 755 "$MODULE_BUILD/post-fs-data.sh" "$MODULE_BUILD/service.sh" "$MODULE_BUILD/customize.sh" \
    "$MODULE_BUILD/uninstall.sh" "$MODULE_BUILD/action.sh" "$MODULE_BUILD/hide_root.sh" \
    "$MODULE_BUILD/keybox_updater.sh"
chmod -R 755 "$MODULE_BUILD/webroot"
find "$MODULE_BUILD/webroot" -type f -exec chmod 644 {} \;

ZIP_NAME="${MODULE_NAME}-${VERSION}.zip"
log_info "Creating $ZIP_NAME..."
cd "$MODULE_BUILD"
zip -r "$OUTPUT_DIR/$ZIP_NAME" . -x "*.git*" "*.DS_Store" "*__MACOSX*" "*.swp" "*.tmp.*"
cd "$SCRIPT_DIR"

if command -v sha256sum &>/dev/null; then
    SHA256=$(sha256sum "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
    echo "$SHA256  $ZIP_NAME" > "$OUTPUT_DIR/$ZIP_NAME.sha256"
elif command -v shasum &>/dev/null; then
    SHA256=$(shasum -a 256 "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
    echo "$SHA256  $ZIP_NAME" > "$OUTPUT_DIR/$ZIP_NAME.sha256"
fi

FILESIZE=$(du -h "$OUTPUT_DIR/$ZIP_NAME" | cut -f1)
cat > "$OUTPUT_DIR/update.json" <<EOF
{
    "version": "$VERSION",
    "versionCode": $VERSION_CODE,
    "zipUrl": "https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases/download/$VERSION/$ZIP_NAME",
    "changelog": "https://github.com/lee-muriithi-kingori/UBLESTRAMK/releases/tag/$VERSION",
    "passmark": 99.9,
    "tag": "beta"
}
EOF

echo ""
echo "============================================"
echo "  BUILD COMPLETE"
echo "  Version: $VERSION (code: $VERSION_CODE)"
echo "  Size: $FILESIZE"
echo "  SHA256: ${SHA256:-N/A}"
echo "  Output: $OUTPUT_DIR/"
echo "============================================"
log_success "Done!"
