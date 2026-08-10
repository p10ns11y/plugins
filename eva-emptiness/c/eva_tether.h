#ifndef EVA_TETHER_H
#define EVA_TETHER_H

#include <stddef.h>

enum {
    EVA_TETHER_INPUT_MAX_BYTES = 65536,
    EVA_TETHER_REASON_MAX_BYTES = 256,
    EVA_TETHER_BLOB_MAX_BYTES = 65536
};

typedef enum {
    EVA_TETHER_OK = 0,
    EVA_TETHER_ERR_ARG = -1,
    EVA_TETHER_ERR_IO = -2,
    EVA_TETHER_ERR_OVERFLOW = -3
} eva_tether_status_t;

typedef enum {
    EVA_TETHER_MODE_GROK = 0,
    EVA_TETHER_MODE_CURSOR = 1
} eva_tether_mode_t;

typedef enum {
    EVA_TETHER_VERDICT_ALLOW = 0,
    EVA_TETHER_VERDICT_ASK = 1,
    EVA_TETHER_VERDICT_DENY = 2
} eva_tether_verdict_t;

typedef struct {
    eva_tether_verdict_t verdict;
    char reason[EVA_TETHER_REASON_MAX_BYTES];
} eva_tether_decision_t;

/* Classifies a command/blob under EVA trauma rules. Writes decision.
 * Fails with EVA_TETHER_ERR_ARG on a NULL pointer. */
eva_tether_status_t eva_tether_classify(eva_tether_decision_t *out_decision,
                                        eva_tether_mode_t mode,
                                        const char *blob);

/* Reads stdin into buf (NUL-terminated). Caps at capacity-1 bytes.
 * Fails with EVA_TETHER_ERR_ARG or EVA_TETHER_ERR_IO. */
eva_tether_status_t eva_tether_read_stdin(char *buf, size_t capacity, size_t *out_len);

/* Extracts a command-like substring from hook JSON into out_blob.
 * On failure to parse, copies input as the blob (fail-open scan). */
eva_tether_status_t eva_tether_extract_blob(char *out_blob,
                                            size_t capacity,
                                            const char *input,
                                            eva_tether_mode_t mode);

/* Prints mode-specific JSON (or empty for Grok allow) to stdout. */
eva_tether_status_t eva_tether_emit(eva_tether_mode_t mode,
                                    const eva_tether_decision_t *decision);

/* Parses --mode=grok|cursor. Fails with EVA_TETHER_ERR_ARG on bad args. */
eva_tether_status_t eva_tether_parse_mode(eva_tether_mode_t *out_mode,
                                          int argc,
                                          char **argv);

#endif /* EVA_TETHER_H */
