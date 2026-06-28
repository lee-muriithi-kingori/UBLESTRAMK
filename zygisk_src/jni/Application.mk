# UBLESTRAMK Zygisk Module - Application Makefile
APP_ABI := arm64-v8a armeabi-v7a x86 x86_64
APP_PLATFORM := android-26
APP_STL := none
APP_CPPFLAGS := -std=c++17 -fno-exceptions -fno-rtti
APP_CFLAGS := -fvisibility=hidden -fvisibility-inlines-hidden
APP_THIN_ARCHIVE := true
APP_LDFLAGS := -Wl,--exclude-libs,ALL
