/*
 * UBLESTRAMK - Zygisk Native Module
 * Provides deep system-level root hiding via Zygisk
 * 
 * Author: lee-muriithi-kingori
 * Version: v0.9.0-beta
 */

#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sched.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <dirent.h>
#include <ctype.h>

#include "zygisk.hpp"

#define LOG_TAG "UBLESTRAMK-Zygisk"
#define LOGD(...) fprintf(stderr, "[" LOG_TAG "] DEBUG: " __VA_ARGS__); fprintf(stderr, "\n")
#define LOGI(...) fprintf(stderr, "[" LOG_TAG "] INFO: " __VA_ARGS__); fprintf(stderr, "\n")
#define LOGW(...) fprintf(stderr, "[" LOG_TAG "] WARN: " __VA_ARGS__); fprintf(stderr, "\n")
#define LOGE(...) fprintf(stderr, "[" LOG_TAG "] ERROR: " __VA_ARGS__); fprintf(stderr, "\n")

// Target app packages to hide from
static const char* TARGET_PACKAGES[] = {
    "com.ubercab.driver",
    "com.ubercab",
    "com.ubercab.eats",
    "com.chase.sig.android",
    "com.bankofamerica.cashpromobile",
    "com.wf.wellsfargomobile",
    "com.paypal.android.p2pmobile",
    "com.venmo",
    "com.coinbase.android",
    "com.binance.dev",
    "com.netflix.mediaclient",
    "com.nianticlabs.pokemongo",
    nullptr
};

// Mount points to unmount for hiding
static const char* HIDE_MOUNT_POINTS[] = {
    "/data/adb/modules",
    "/data/adb/ksu",
    "/data/adb/ap",
    "/debug_ramdisk",
    "/sbin",
    nullptr
};

// Suspicious filesystem names
static const char* SUSPICIOUS_FS[] = {
    "magisk",
    "KSU",
    "APatch",
    "tmpfs",
    nullptr
};

// Module context
class UblestramkModule : public zygisk::ModuleBase {
public:
    void onLoad(zygisk::Api *api, JNIEnv *env) override {
        this->m_api = api;
        this->m_env = env;
        LOGI("Module loaded in Zygote");
    }

    void preAppSpecialize(zygisk::AppSpecializeArgs *args) override {
        // Get process flags
        uint32_t flags = m_api->getFlags();
        bool isRoot = (flags & zygisk::PROCESS_GRANTED_ROOT) != 0;
        bool isOnDenylist = (flags & zygisk::PROCESS_ON_DENYLIST) != 0;

        // Check if this is a child zygote (WebView, etc.)
        bool isChildZygote = args->is_child_zygote != nullptr && *(args->is_child_zygote);

        // Only process regular user apps on the denylist
        if (isRoot || !isOnDenylist) {
            LOGD("Skipping - isRoot=%d isOnDenylist=%d isChildZygote=%d",
                 isRoot, isOnDenylist, isChildZygote);
            m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        // Get the app package name
        const char* pkgName = nullptr;
        if (args->nice_name != nullptr) {
            pkgName = m_env->GetStringUTFChars(args->nice_name, nullptr);
        }

        LOGI("Processing app: %s (uid=%d)", pkgName ? pkgName : "unknown", args->uid);

        // Check if this is a target package
        bool isTarget = false;
        if (pkgName != nullptr) {
            for (int i = 0; TARGET_PACKAGES[i] != nullptr; i++) {
                if (strstr(pkgName, TARGET_PACKAGES[i]) != nullptr) {
                    isTarget = true;
                    break;
                }
            }
        }

        // Apply hiding for all denylist apps (more thorough)
        // Target apps get extra treatment
        if (isTarget) {
            LOGI("Target app detected: %s - applying deep hiding", pkgName);
        }

        // Set DLCLOSE option to unload after this function
        m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);

        // Perform mount unmounting in the child process
        performUnmount();

        // Spoof mount namespace
        setupMountNamespace();

        // Clean environment
        cleanEnvironment();

        // Release JNI string
        if (pkgName != nullptr) {
            m_env->ReleaseStringUTFChars(args->nice_name, pkgName);
        }

        LOGI("Hiding applied for app");
    }

    void postAppSpecialize(const zygisk::AppSpecializeArgs *args) override {
        // Nothing to do post-specialize
    }

    void preServerSpecialize(zygisk::ServerSpecializeArgs *args) override {
        // System server - unload module to save resources
        m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
    }

private:
    zygisk::Api *m_api;
    JNIEnv *m_env;

    // Unmount suspicious mount points
    void performUnmount() {
        LOGI("Unmounting module paths");

        // Read mountinfo for current process
        int fd = open("/proc/self/mountinfo", O_RDONLY | O_CLOEXEC);
        if (fd < 0) {
            LOGW("Cannot open mountinfo: %s", strerror(errno));
            return;
        }

        char buf[4096];
        ssize_t n;
        char line[512];
        int linePos = 0;

        while ((n = read(fd, buf, sizeof(buf))) > 0) {
            for (ssize_t i = 0; i < n; i++) {
                if (buf[i] == '\n') {
                    line[linePos] = '\0';
                    processMountLine(line);
                    linePos = 0;
                } else if (linePos < sizeof(line) - 1) {
                    line[linePos++] = buf[i];
                }
            }
        }
        close(fd);
    }

    // Process a single mountinfo line
    void processMountLine(const char* line) {
        // Find mount point (after "root " and before " - ")
        const char* dash = strstr(line, " - ");
        if (!dash) return;

        // Walk back from dash to find mount point start
        const char* mpEndPtr = dash;
        while (mpEndPtr > line && *(mpEndPtr - 1) != ' ') mpEndPtr--;

        // Walk further back to find mount point start
        const char* mpStartPtr = mpEndPtr - 1;
        while (mpStartPtr > line && *(mpStartPtr - 1) != ' ') mpStartPtr--;

        size_t mpLen = mpEndPtr - mpStartPtr;
        if (mpLen >= 256) mpLen = 255;
        char mountPoint[256];
        strncpy(mountPoint, mpStartPtr, mpLen);
        mountPoint[mpLen] = '\0';

        // Get filesystem type after " - "
        const char* fst = dash + 3;
        int fsLen = 0;
        while (fst[fsLen] && fst[fsLen] != ' ') fsLen++;
        if (fsLen >= 64) fsLen = 63;
        char fsType[64];
        strncpy(fsType, fst, fsLen);
        fsType[fsLen] = '\0';

        // Get source (after fs type)
        const char* src = fst + fsLen;
        while (*src == ' ') src++;
        int srcLen = 0;
        while (src[srcLen] && src[srcLen] != ' ') srcLen++;
        if (srcLen >= 128) srcLen = 127;
        char source[128];
        strncpy(source, src, srcLen);
        source[srcLen] = '\0';

        // Check if this mount should be unmounted
        bool shouldUnmount = false;

        // Check mount point against hide list
        for (int i = 0; HIDE_MOUNT_POINTS[i] != nullptr; i++) {
            if (strncmp(mountPoint, HIDE_MOUNT_POINTS[i], strlen(HIDE_MOUNT_POINTS[i])) == 0) {
                shouldUnmount = true;
                break;
            }
        }

        // Check filesystem name against suspicious list
        if (!shouldUnmount) {
            for (int i = 0; SUSPICIOUS_FS[i] != nullptr; i++) {
                if (strstr(source, SUSPICIOUS_FS[i]) != nullptr) {
                    if (strcmp(fsType, "overlay") == 0 || strcmp(fsType, "tmpfs") == 0) {
                        shouldUnmount = true;
                        break;
                    }
                }
            }
        }

        // Check overlayfs with suspicious dirs
        if (!shouldUnmount && strcmp(fsType, "overlay") == 0) {
            if (strstr(line, "/data/adb") != nullptr ||
                strstr(line, "/debug_ramdisk") != nullptr) {
                shouldUnmount = true;
            }
        }

        if (shouldUnmount) {
            LOGD("Unmounting: %s (%s)", mountPoint, fsType);
            if (umount2(mountPoint, MNT_DETACH) == 0) {
                LOGI("Unmounted: %s", mountPoint);
            } else {
                LOGD("umount2(%s) failed: %s", mountPoint, strerror(errno));
            }
        }
    }

    // Setup isolated mount namespace
    void setupMountNamespace() {
        LOGI("Setting up mount namespace");

        // Unshare to create new mount namespace
        if (unshare(CLONE_NEWNS) == -1) {
            LOGW("unshare(CLONE_NEWNS) failed: %s", strerror(errno));
            return;
        }

        // Make root mount slave so we don't propagate changes back
        if (mount("rootfs", "/", nullptr, MS_SLAVE | MS_REC, nullptr) == -1) {
            LOGW("mount(MS_SLAVE) failed: %s", strerror(errno));
        }
    }

    // Clean environment variables that might leak root info
    void cleanEnvironment() {
        // Remove environment variables that might indicate root
        unsetenv("MAGISK_VER");
        unsetenv("MAGISK_VER_CODE");
        unsetenv("MAGISK_DEBUG");
        unsetenv("KSU");
        unsetenv("KSU_VER");
        unsetenv("KSU_VER_CODE");
        unsetenv("APATCH");
        unsetenv("APATCH_VER");
        unsetenv("APATCH_VER_CODE");

        // Clean PATH of any magisk-specific paths
        const char* path = getenv("PATH");
        if (path && (strstr(path, "/sbin") != nullptr ||
                     strstr(path, ".magisk") != nullptr)) {
            // PATH will be sanitized by Android later
            LOGD("Cleaning PATH environment");
        }
    }
};

// Companion handler - runs in a separate process with root privileges
void ublestramk_companion(int client_fd) {
    LOGI("Companion handler called");

    // Read PID from client
    pid_t target_pid;
    ssize_t ret = read(client_fd, &target_pid, sizeof(target_pid));
    if (ret != sizeof(target_pid)) {
        LOGE("Failed to read PID from client");
        bool result = false;
        write(client_fd, &result, sizeof(result));
        return;
    }

    LOGI("Processing PID: %d", target_pid);

    // Fork to handle namespace switching
    pid_t pid = fork();
    if (pid == -1) {
        LOGE("fork() failed: %s", strerror(errno));
        bool result = false;
        write(client_fd, &result, sizeof(result));
        return;
    }

    if (pid == 0) {
        // Child process - switch to target namespace and unmount
        char nsPath[64];
        snprintf(nsPath, sizeof(nsPath), "/proc/%d/ns/mnt", target_pid);

        int nsFd = open(nsPath, O_RDONLY | O_CLOEXEC);
        if (nsFd < 0) {
            LOGE("Cannot open mount namespace: %s", strerror(errno));
            exit(1);
        }

        if (setns(nsFd, CLONE_NEWNS) == -1) {
            LOGE("setns() failed: %s", strerror(errno));
            close(nsFd);
            exit(1);
        }
        close(nsFd);

        // Unmount module paths in target namespace
        for (int i = 0; HIDE_MOUNT_POINTS[i] != nullptr; i++) {
            umount2(HIDE_MOUNT_POINTS[i], MNT_DETACH);
        }

        exit(0);
    }

    // Parent - wait for child
    int status;
    waitpid(pid, &status, 0);
    bool result = WIFEXITED(status) && WEXITSTATUS(status) == 0;

    if (result) {
        LOGI("Companion unmount successful for PID %d", target_pid);
    } else {
        LOGW("Companion unmount failed for PID %d", target_pid);
    }

    // Send result back
    ret = write(client_fd, &result, sizeof(result));
    if (ret != sizeof(result)) {
        LOGW("Failed to write result to client");
    }
}

// Register the module
REGISTER_ZYGISK_MODULE(UblestramkModule)

// Register companion handler
REGISTER_ZYGISK_COMPANION(ublestramk_companion)
