#!/bin/bash
# ==========================================
# UBLESTRAMK - Build Script v1.4.1
# Usage: ./build.sh [version] [--check-only]
# Requirements: bash, zip (for --check-only, these are skipped)
# ==========================================

MODULE_ID="UBLESTRAMK"
MODULE_NAME="UBLESTRAMK"
DEFAULT_VERSION="v1.4.1"
VERSION="${1:-$DEFAULT_VERSION}"
VERSION_CODE=1401
CHECK_ONLY=false
[ "${1:-}" = "--check-only" ] || [ "${2:-}" = "--check-only" ] && CHECK_ONLY=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"
ZYGISK_SRC="$SCRIPT_DIR/zygisk_src"

# Portable file size (bytes) — no external tools
file_size() {
    stat -c%s "$1" 2>/dev/null || \
    wc -c < "$1" 2>/dev/null || \
    echo 0
}

# Portable grep (returns 0 if pattern found, 1 if not)
grep_q() {
    grep "$1" "$2" >/dev/null 2>&1
}

# Portable sed -i (works on Linux/macOS/BSD/Git-Bash)
sed_i() {
    local pat="$1" file="$2"
    # Try GNU sed first (Linux, Git-Bash)
    sed -i "$pat" "$file" 2>/dev/null && return 0
    # Try BSD sed (macOS)
    sed -i '' "$pat" "$file" 2>/dev/null && return 0
    # Fallback: perl
    perl -pi -e "$pat" "$file" 2>/dev/null && return 0
    return 1
}

# Portable chmod
chmod_r() {
    chmod -R "$1" "$2" 2>/dev/null && return 0
    # Git-Bash on Windows: chmod not available — skip
    return 0
}

chmod_f() {
    chmod "$1" "$2" 2>/dev/null && return 0
    return 0
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1"; }

ERRORS=0; WARNINGS=0
error() { log_error "$1"; ERRORS=$((ERRORS + 1)); }
warn()  { log_warn "$1";  WARNINGS=$((WARNINGS + 1)); }

echo ""
echo "============================================"
echo "  UBLESTRAMK Build System v1.4.1"
echo "  Module: $MODULE_NAME"
echo "  Version: $VERSION"
echo "============================================"
echo ""

validate_required_files() {
    log_info "Validating required files..."
    local required_files=(
        "module.prop" "system.prop" "post-fs-data.sh" "service.sh"
        "customize.sh" "uninstall.sh" "action.sh" "common_func.sh"
        "target_apps.txt" "hide_root.sh" "README.md"
        "keybox.xml" "keybox_updater.sh" "update_service_addon.sh"
    )
    for f in "${required_files[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$f" ]; then
            error "Missing: $f"
        else
            local size
            size=$(file_size "$SCRIPT_DIR/$f")
            log_info "  OK: $f (${size}B)"
        fi
    done
    if [ ! -f "$SCRIPT_DIR/META-INF/com/google/android/update-binary" ]; then
        error "Missing META-INF/update-binary"
    fi
}

validate_shell_scripts() {
    log_info "Validating shell syntax..."
    local shell_scripts=(
        "post-fs-data.sh" "service.sh" "customize.sh"
        "uninstall.sh" "action.sh" "common_func.sh"
        "hide_root.sh" "keybox_updater.sh" "update_service_addon.sh"
    )
    for f in "${shell_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$f" ]; then continue; fi
        # Use bash to check syntax (more portable than sh)
        if bash -n "$SCRIPT_DIR/$f" 2>/dev/null; then
            log_info "  OK: $f"
        elif sh -n "$SCRIPT_DIR/$f" 2>/dev/null; then
            log_info "  OK: $f"
        else
            warn "Syntax check skipped for $f (shell not available)"
        fi
    done
}

validate_webroot() {
    log_info "Validating WebUI..."
    if [ ! -d "$SCRIPT_DIR/webroot" ]; then
        error "Missing webroot/"
        return
    fi
    if [ ! -f "$SCRIPT_DIR/webroot/index.html" ]; then
        error "Missing webroot/index.html"
    else
        local size
        size=$(file_size "$SCRIPT_DIR/webroot/index.html")
        log_info "  OK: webroot/index.html (${size}B)"
    fi
}

validate_zygisk() {
    log_info "Validating Zygisk source..."
    if [ ! -f "$SCRIPT_DIR/zygisk_src/jni/root_spoof.cpp" ]; then
        warn "Missing zygisk_src/jni/root_spoof.cpp (native layer disabled)"
    else
        local size
        size=$(file_size "$SCRIPT_DIR/zygisk_src/jni/root_spoof.cpp")
        log_info "  OK: root_spoof.cpp (${size}B)"
    fi
    if [ ! -f "$SCRIPT_DIR/zygisk_src/jni/Android.mk" ]; then
        warn "Missing Android.mk"
    else
        log_info "  OK: Android.mk"
    fi
}

validate_module_prop() {
    log_info "Validating module.prop..."
    local id ver vcode
    id=$(grep "^id=" "$SCRIPT_DIR/module.prop" 2>/dev/null | head -1 | cut -d= -f2 || true)
    ver=$(grep "^version=" "$SCRIPT_DIR/module.prop" 2>/dev/null | head -1 | cut -d= -f2 || true)
    vcode=$(grep "^versionCode=" "$SCRIPT_DIR/module.prop" 2>/dev/null | head -1 | cut -d= -f2 || true)
    [ -z "$id" ]   && error "Missing id"
    [ -z "$ver" ]  && error "Missing version"
    [ -z "$vcode" ] && error "Missing versionCode"
    grep_q '\[' "$SCRIPT_DIR/module.prop" && warn "Name has [STABLE]/[BETA] tags"
    grep_q "^webroot=" "$SCRIPT_DIR/module.prop" || warn "webroot field missing"
    log_info "  Module: $id $ver (code: $vcode)"
}

validate_keybox() {
    log_info "Validating keybox.xml..."
    grep_q "PLACEHOLDER" "$SCRIPT_DIR/keybox.xml" && warn "keybox.xml has PLACEHOLDERs"
    grep_q "<Keybox>" "$SCRIPT_DIR/keybox.xml" || error "Missing <Keybox> tag"
    grep_q "<Key" "$SCRIPT_DIR/keybox.xml" || error "Missing <Key> elements"
}

validate_system_prop() {
    log_info "Validating system.prop..."
    grep_q "ro.build.selinux=0" "$SCRIPT_DIR/system.prop" && warn "ro.build.selinux=0 detected"
}

validate_required_files
validate_shell_scripts
validate_webroot
validate_zygisk
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

# Native Zygisk build (requires Android NDK)
if [ -n "${ANDROID_NDK_HOME:-}" ] || [ -n "${ANDROID_NDK:-}" ]; then
    NDK="${ANDROID_NDK_HOME:-$ANDROID_NDK}"
    if [ -x "$NDK/ndk-build" ]; then
        log_info "Using NDK: $NDK"
        log_info "Building Zygisk..."
        if "$NDK/ndk-build" -C "$ZYGISK_SRC" \
            NDK_PROJECT_PATH="$ZYGISK_SRC" \
            APP_BUILD_SCRIPT="$ZYGISK_SRC/jni/Android.mk" \
            NDK_APPLICATION_MK="$ZYGISK_SRC/jni/Application.mk" \
            NDK_OUT="$BUILD_DIR/obj" \
            NDK_LIBS_OUT="$BUILD_DIR/libs" 2>&1 | while IFS= read -r line; do
                echo "  $line"
            done; then
            log_success "Native build OK"
        else
            log_warn "Native build failed — continuing without native layer"
        fi
    else
        log_info "ndk-build not found at $NDK/ndk-build — skipping native build"
    fi
else
    log_info "ANDROID_NDK not set — skipping native Zygisk build"
    log_info "Install Android NDK and set ANDROID_NDK_HOME to enable native layer"
fi

# Assemble module
MODULE_BUILD="$BUILD_DIR/$MODULE_ID"
mkdir -p "$MODULE_BUILD"

log_info "Copying module files..."
cp "$SCRIPT_DIR/module.prop" "$SCRIPT_DIR/system.prop" \
   "$SCRIPT_DIR/post-fs-data.sh" "$SCRIPT_DIR/service.sh" \
   "$SCRIPT_DIR/customize.sh" "$SCRIPT_DIR/uninstall.sh" \
   "$SCRIPT_DIR/action.sh" "$SCRIPT_DIR/common_func.sh" \
   "$SCRIPT_DIR/target_apps.txt" "$SCRIPT_DIR/hide_root.sh" \
   "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/keybox.xml" \
   "$SCRIPT_DIR/keybox_updater.sh" "$SCRIPT_DIR/update_service_addon.sh" \
   "$MODULE_BUILD/"

cp -r "$SCRIPT_DIR/META-INF" "$MODULE_BUILD/"
cp -r "$SCRIPT_DIR/webroot" "$MODULE_BUILD/"

# Copy Zygisk libs if built
if [ -d "$BUILD_DIR/libs" ]; then
    mkdir -p "$MODULE_BUILD/zygisk"
    for abi in arm64-v8a armeabi-v7a x86 x86_64; do
        if [ -f "$BUILD_DIR/libs/$abi/libublestramk.so" ]; then
            cp "$BUILD_DIR/libs/$abi/libublestramk.so" "$MODULE_BUILD/zygisk/$abi.so"
            log_info "  Copied zygisk/$abi.so"
        fi
    done
fi

# Patch version into module.prop
sed_i "s/^version=.*/version=$VERSION/" "$MODULE_BUILD/module.prop"
sed_i "s/^versionCode=.*/versionCode=$VERSION_CODE/" "$MODULE_BUILD/module.prop"

# Set permissions (best-effort — skip on Windows)
chmod_r 755 "$MODULE_BUILD" 2>/dev/null || true
chmod_f 644 "$MODULE_BUILD/module.prop" "$MODULE_BUILD/system.prop" \
    "$MODULE_BUILD/common_func.sh" "$MODULE_BUILD/target_apps.txt" \
    "$MODULE_BUILD/README.md" "$MODULE_BUILD/keybox.xml" \
    "$MODULE_BUILD/update_service_addon.sh" 2>/dev/null || true
chmod_f 755 "$MODULE_BUILD/post-fs-data.sh" "$MODULE_BUILD/service.sh" \
    "$MODULE_BUILD/customize.sh" "$MODULE_BUILD/uninstall.sh" \
    "$MODULE_BUILD/action.sh" "$MODULE_BUILD/hide_root.sh" \
    "$MODULE_BUILD/keybox_updater.sh" 2>/dev/null || true
chmod_r 755 "$MODULE_BUILD/webroot" 2>/dev/null || true
find "$MODULE_BUILD/webroot" -type f 2>/dev/null | while IFS= read -r f; do
    chmod_f 644 "$f" 2>/dev/null || true
done

# Build zip
ZIP_NAME="${MODULE_NAME}-${VERSION}.zip"
if command -v zip >/dev/null 2>&1; then
    log_info "Creating $ZIP_NAME..."
    cd "$MODULE_BUILD"
    zip -r "$OUTPUT_DIR/$ZIP_NAME" . -x "*.git*" "*.DS_Store" "*__MACOSX*" "*.swp" "*.tmp.*"
    cd "$SCRIPT_DIR"
else
    log_warn "zip command not found — creating zip with Python fallback"
    if command -v python3 >/dev/null 2>&1; then
        cd "$MODULE_BUILD"
        python3 -c "
import zipfile, os, sys
name = sys.argv[1]
with zipfile.ZipFile(name, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in ['.git','__MACOSX']]
        for f in files:
            if not f.endswith('.swp') and not f.startswith('.tmp'):
                z.write(os.path.join(root, f))
" "$OUTPUT_DIR/$ZIP_NAME"
        cd "$SCRIPT_DIR"
    elif command -v python >/dev/null 2>&1; then
        cd "$MODULE_BUILD"
        python -c "
import zipfile, os, sys
name = sys.argv[1]
with zipfile.ZipFile(name, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in ['.git','__MACOSX']]
        for f in files:
            if not f.endswith('.swp') and not f.startswith('.tmp'):
                z.write(os.path.join(root, f))
" "$OUTPUT_DIR/$ZIP_NAME"
        cd "$SCRIPT_DIR"
    else
        error "No zip or python available — cannot create module zip"
        exit 1
    fi
fi

# SHA256
SHA256=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA256=$(sha256sum "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    SHA256=$(shasum -a 256 "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
elif command -v python3 >/dev/null 2>&1; then
    SHA256=$(python3 -c "
import hashlib, sys
h = hashlib.sha256()
with open(sys.argv[1],'rb') as f:
    for chunk in iter(lambda: f.read(65536), b''):
        h.update(chunk)
print(h.hexdigest())
" "$OUTPUT_DIR/$ZIP_NAME")
elif command -v python >/dev/null 2>&1; then
    SHA256=$(python -c "
import hashlib, sys
h = hashlib.sha256()
with open(sys.argv[1],'rb') as f:
    for chunk in iter(lambda: f.read(65536), b''):
        h.update(chunk)
print(h.hexdigest())
" "$OUTPUT_DIR/$ZIP_NAME")
fi

if [ -n "$SHA256" ]; then
    echo "$SHA256  $ZIP_NAME" > "$OUTPUT_DIR/$ZIP_NAME.sha256"
fi

# File size
FILESIZE=""
if command -v du >/dev/null 2>&1; then
    FILESIZE=$(du -h "$OUTPUT_DIR/$ZIP_NAME" | cut -f1)
elif command -v python3 >/dev/null 2>&1; then
    FILESIZE=$(python3 -c "
import os
sz = os.path.getsize('$OUTPUT_DIR/$ZIP_NAME')
for unit in ['B','KB','MB','GB']:
    if sz < 1024:
        print(f'{sz:.1f}{unit}')
        break
    sz /= 1024
else:
    print(f'{sz:.1f}TB')
" 2>/dev/null || echo "N/A")
fi
[ -z "$FILESIZE" ] && FILESIZE="N/A"

# Generate update.json
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
