# ==========================================
# UBLESTRAMK - Android NDK Build File
# ==========================================
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libublestramk
# main.cpp = Zygisk module entry point (REGISTER_ZYGISK_MODULE)
# keybox_hook.cpp = Keystore/KeyMint attestation hooks
# root_spoof.cpp = /proc/self/status and mount hiding
LOCAL_SRC_FILES := main.cpp keybox_hook.cpp root_spoof.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)
LOCAL_CPPFLAGS := -std=c++17 -fno-rtti -fno-exceptions
LOCAL_CFLAGS := -Wall -Wextra -O2 -fvisibility=hidden
LOCAL_LDFLAGS := -Wl,-z,relro -Wl,-z,now
LOCAL_MODULE_TAGS := optional

# Link liblog (for __android_log_print in .cpp files)
# libandroid (for JNI)
# libzygisk (Zygisk module stub, injected by Riru/Zygisk at runtime)
LOCAL_SHARED_LIBRARIES := liblog libandroid
LOCAL_STATIC_LIBRARIES := libzygisk

include $(BUILD_SHARED_LIBRARY)

# Point to the prebuilt zygisk stub library
$(call import-add-path, $(LOCAL_PATH)/../prebuilt)
$(call import-module, zygisk)
