// Zygisk API header for UBLESTRAMK
// Based on the Zygisk API standard

#pragma once

#include <jni.h>

#define ZYGISK_API_VERSION 4

namespace zygisk {

struct Api;
struct AppSpecializeArgs;
struct ServerSpecializeArgs;

struct ModuleBase {
    virtual void onLoad(Api *api, JNIEnv *env) {}
    virtual void preAppSpecialize(AppSpecializeArgs *args) {}
    virtual void postAppSpecialize(const AppSpecializeArgs *args) {}
    virtual void preServerSpecialize(ServerSpecializeArgs *args) {}
    virtual void postServerSpecialize(const ServerSpecializeArgs *args) {}
};

enum Option {
    FORCE_DENYLIST_UNMOUNT = 0,
    DLCLOSE_MODULE_LIBRARY = 1,
};

enum StateFlag {
    PROCESS_GRANTED_ROOT = (1u << 0),
    PROCESS_ON_DENYLIST = (1u << 1),
};

struct Api {
    virtual void setOption(Option opt) = 0;
    virtual uint32_t getFlags() = 0;
    virtual void exemptFd(int fd) = 0;
    virtual int  reserveFd() = 0;
    virtual bool pltHookRegister(dev_t dev, inode_t inode, const char *symbol, void *new_func, void **old_func) = 0;
    virtual bool pltHookCommit() = 0;
    virtual int  connectCompanion() = 0;
    virtual void getModuleDir(char *buf, size_t len) = 0;
};

struct AppSpecializeArgs {
    uid_t &uid;
    gid_t &gid;
    jintArray &gids;
    jint &runtime_flags;
    jint &mount_external;
    jstring &se_info;
    jstring &nice_name;
    jstring &instruction_set;
    jstring &app_data_dir;
    jboolean *const is_child_zygote;
    jboolean *const is_top_app;
    jobjectArray *const pkg_data_info_list;
    jobjectArray *const whitelisted_data_info_list;
    jboolean *const mount_data_dirs;
    jboolean *const mount_storage_dirs;
};

struct ServerSpecializeArgs {
    uid_t &uid;
    gid_t &gid;
    jintArray &gids;
    jint &runtime_flags;
    jlong &permitted_capabilities;
    jlong &effective_capabilities;
};

} // namespace zygisk

#define REGISTER_ZYGISK_MODULE(className) \
    extern "C" [[gnu::visibility("default")]] \
    void zygisk_module_entry(zygisk::Api *api, JNIEnv *env) { \
        static className module; \
        module.onLoad(api, env); \
    }

#define REGISTER_ZYGISK_COMPANION(func) \
    extern "C" [[gnu::visibility("default")]] \
    void zygisk_companion_entry(int client_fd) { \
        func(client_fd); \
    }
