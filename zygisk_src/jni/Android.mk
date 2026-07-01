# ==========================================
# UBLESTRAMK - Android NDK Build File
# ==========================================
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libublestramk
LOCAL_SRC_FILES := root_spoof.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_CFLAGS := -Wall -Wextra -O2 -fvisibility=hidden
LOCAL_LDFLAGS := -Wl,-z,relro -Wl,-z,now
LOCAL_CONLYFLAGS := -std=c11
LOCAL_NDK_VERSION := 25.2.9519653
LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := both
LOCAL_ARCH_VARIANTS := arm64-v8a armeabi-v7a x86 x86_64

# Link against zygisk library
LOCAL_SHARED_LIBRARIES := liblog libandroid
LOCAL_STATIC_LIBRARIES := libzygisk

include $(BUILD_SHARED_LIBRARY)

# Include zygisk headers path
$(call import-add-path, $(LOCAL_PATH)/../prebuilt)
$(call import-module, zygisk)
