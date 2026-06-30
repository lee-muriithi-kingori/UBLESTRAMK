/*
 * UBLESTRAMK - Keybox/Keystore Hook Interface
 * Handles hardware attestation and keybox spoofing
 * 
 * Version: v1.0.0
 */

#ifndef KEYBOX_HOOK_H
#define KEYBOX_HOOK_H

#include <jni.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Keybox attestation result codes */
#define KEYBOX_RESULT_OK        0
#define KEYBOX_RESULT_ERROR     -1
#define KEYBOX_RESULT_BLOCKED   -2

/* Supported attestation key algorithms */
#define KEYBOX_ALG_RSA_2048     1
#define KEYBOX_ALG_RSA_4096     2
#define KEYBOX_ALG_EC_P256      3
#define KEYBOX_ALG_EC_P384      4
#define KEYBOX_ALG_EC_P521      5

/* KeyMint security levels */
#define KEYMINT_SECURITY_SW         0
#define KEYMINT_SECURITY_TEE        1
#define KEYMINT_SECURITY_STRONGBOX  2

/* Attestation certificate chain entry */
struct cert_entry {
    const uint8_t* data;
    size_t len;
};

/* Keybox configuration for a device model */
struct keybox_config {
    const char* device_brand;
    const char* device_manufacturer;
    const char* device_product;
    const char* device_model;
    const char* device_board;
    int security_level;      /* TEE or StrongBox */
    int key_algorithm;       /* RSA or EC */
    const char* keybox_xml_path;  /* Path to keybox XML if available */
};

/* Initialize keybox hooking subsystem */
int keybox_init(JNIEnv* env);

/* Shutdown keybox hooking */
void keybox_cleanup(JNIEnv* env);

/* Hook KeyStore/keymint operations for a target process */
int keybox_hook_process(JNIEnv* env, const char* package_name, jint uid);

/* Check if an app is requesting attestation */
bool keybox_is_attestation_request(JNIEnv* env, jclass clazz, jmethodID method);

/* Generate spoofed attestation response */
jobject keybox_spoof_attestation(JNIEnv* env, jobject key_store, int algorithm, int security_level);

/* Get the active keybox config for current device */
const struct keybox_config* keybox_get_active_config(void);

/* Set which security level to spoof (TEE=1, StrongBox=2) */
void keybox_set_spoofed_security_level(int level);

/* Validate a real keybox XML file exists and is readable */
bool keybox_validate_xml(const char* path);

/* Block key attestation entirely (return error to app) */
jobject keybox_block_attestation(JNIEnv* env);

/* Get certificate chain for spoofed attestation */
int keybox_get_cert_chain(struct cert_entry** chain, size_t* count);

/* Free certificate chain */
void keybox_free_cert_chain(struct cert_entry* chain, size_t count);

#ifdef __cplusplus
}
#endif

#endif /* KEYBOX_HOOK_H */
