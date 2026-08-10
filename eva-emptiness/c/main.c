/* main.c: CLI entry for eva-tether — stdin in, decision JSON out. */

#include <stdio.h>
#include <stdlib.h>

#include "eva_tether.h"

/* Fail-open: print nothing (Grok) or Cursor allow, then exit 0. */
static void eva_tether_fail_open(eva_tether_mode_t mode)
{
    if (mode == EVA_TETHER_MODE_CURSOR)
        fputs("{\"permission\":\"allow\"}\n", stdout);
    exit(0);
}

int main(int argc, char **argv)
{
    eva_tether_mode_t mode = EVA_TETHER_MODE_GROK;
    eva_tether_status_t status = EVA_TETHER_OK;
    eva_tether_decision_t decision = {
        .verdict = EVA_TETHER_VERDICT_ALLOW,
        .reason = {0}
    };
    char input[EVA_TETHER_INPUT_MAX_BYTES];
    char blob[EVA_TETHER_BLOB_MAX_BYTES];
    size_t input_len = 0;

    status = eva_tether_parse_mode(&mode, argc, argv);
    if (status != EVA_TETHER_OK) {
        fputs("usage: eva-tether [--mode=grok|cursor]\n", stderr);
        /* Fail-open for hooks: bad CLI should not brick the agent. */
        eva_tether_fail_open(EVA_TETHER_MODE_GROK);
    }

    status = eva_tether_read_stdin(input, sizeof input, &input_len);
    if (status != EVA_TETHER_OK)
        eva_tether_fail_open(mode);

    status = eva_tether_extract_blob(blob, sizeof blob, input, mode);
    if (status != EVA_TETHER_OK)
        eva_tether_fail_open(mode);

    status = eva_tether_classify(&decision, mode, blob);
    if (status != EVA_TETHER_OK)
        eva_tether_fail_open(mode);

    status = eva_tether_emit(mode, &decision);
    if (status != EVA_TETHER_OK)
        eva_tether_fail_open(mode);

    return 0;
}
