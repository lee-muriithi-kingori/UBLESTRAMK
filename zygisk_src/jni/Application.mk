# ==========================================
# UBLESTRAMK - Application Makefile
# ==========================================
APP_PLATFORM := android-24
APP_ABI := arm64-v8a armeabi-v7a x86 x86_64
APP_CFLAGS := -Wall -Wextra -Wno-unused-parameter
APP_CPPFLAGS := -std=c++17 -fno-rtti -fno-exceptions
APP_LDFLAGS := -Wl,--gc-sections -Wl,-z,relro -Wl,-z,now
APP_SHORT_COMMANDS := true
NDK_TOOLCHAIN_VERSION := clang

# Zygisk modules require no special permissions
APP_MKFLAGS :=

# Required for Zygisk
MY_APP_ABI := $(APP_ABI)
