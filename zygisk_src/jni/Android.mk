# UBLESTRAMK Zygisk Module - Android Makefile
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    := ublestramk
LOCAL_SRC_FILES := main.cpp keybox_hook.cpp
LOCAL_CFLAGS    := -O2 -fvisibility=hidden -fvisibility-inlines-hidden \
                   -fno-exceptions -fno-rtti -fno-stack-protector \
                   -DANDROID -DNDEBUG
LOCAL_CPPFLAGS  := -std=c++17
LOCAL_LDLIBS    := -llog
LOCAL_LDFLAGS   := -Wl,--exclude-libs,ALL

# Build as shared library for Zygisk
include $(BUILD_SHARED_LIBRARY)
