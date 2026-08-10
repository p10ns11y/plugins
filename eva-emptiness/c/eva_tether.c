/* eva_tether.c: owns EVA permission tether classification and JSON emit. */

#include <assert.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "eva_tether.h"

enum {
    EVA_TETHER_WORD_MAX_BYTES = 64,
    EVA_TETHER_SCAN_MAX_ITERS = 65536,
    EVA_TETHER_FULL_REASON_MAX_BYTES = 320
};

#define EVA_TETHER_REASON_PREFIX "eva-emptiness tether: "
#define EVA_TETHER_REASON_ALWAYS_APPROVE \
    "refusing always-approve/yolo under EVA tether (auth event horizon)"
#define EVA_TETHER_REASON_FORCE_PUSH "force-push blocked"
#define EVA_TETHER_REASON_GIT_PUSH "git push requires human Ask (auth / remote mutate)"
#define EVA_TETHER_REASON_RESET_HARD "git reset --hard blocked"
#define EVA_TETHER_REASON_RM_ROOT \
    "recursive delete targeting filesystem root blocked"
#define EVA_TETHER_CURSOR_ASK_AGENT \
    "HITL Ask for git push — proceed only after explicit human approval for this remote mutate."
#define EVA_TETHER_CURSOR_DENY_AGENT_PREFIX "Blocked by eva-emptiness tether: "
#define EVA_TETHER_CURSOR_DENY_AGENT_SUFFIX \
    ". Use HITL Ask — do not bypass with yolo/always-approve."

/* Sets a DENY decision with a fixed reason string. */
static void eva_tether_set_deny(eva_tether_decision_t *out, const char *reason);

/* Sets an ASK decision with a fixed reason string. */
static void eva_tether_set_ask(eva_tether_decision_t *out, const char *reason);

/* Sets ALLOW with empty reason. */
static void eva_tether_set_allow(eva_tether_decision_t *out);

/* True when needle appears as a case-sensitive substring of hay. Pure. */
static bool eva_tether_has_substr(const char *hay, const char *needle);

/* True when c ends a shell word for git-token scans. Pure. */
static bool eva_tether_is_word_boundary(unsigned char c);

/* Advances past ASCII whitespace. Bounded. */
static const char *eva_tether_skip_space(const char *p);

/* True when *p starts with token as a whole word. Pure. */
static bool eva_tether_at_word(const char *p, const char *token);

/* True when blob contains trauma always-approve / yolo markers. Pure. */
static bool eva_tether_has_always_approve(const char *blob);

/* True when blob has git push with -f / --force. Pure. */
static bool eva_tether_has_force_push(const char *blob);

/* True when blob has ordinary git push. Pure. */
static bool eva_tether_has_git_push(const char *blob);

/* True when blob has git reset --hard. Pure. */
static bool eva_tether_has_reset_hard(const char *blob);

/* True when blob has rm -r… targeting /. Pure. */
static bool eva_tether_has_rm_root(const char *blob);

/* After "git", skip options until a subcommand or end. Bounded. */
static const char *eva_tether_skip_git_options(const char *p);

/* True when a git push arg list contains force flags. Pure. */
static bool eva_tether_push_args_force(const char *p);

/* True when reset args include --hard. Pure. */
static bool eva_tether_reset_args_hard(const char *args);

/* True when an rm arg list is recursive delete of /. Pure. */
static bool eva_tether_rm_args_target_root(const char *args);

/* True when flags string is recursive (r/R/--recursive). Pure. */
static bool eva_tether_flags_recursive(const char *flags);

/* Copies one shell token into out; advances *pp past it. */
static void eva_tether_take_token(char *out, size_t capacity, const char **pp);

/* Copies src into dst with capacity; always NUL-terminates. */
static eva_tether_status_t eva_tether_copy_cstr(char *dst,
                                                size_t capacity,
                                                const char *src);

/* Joins prefix and reason into out. Truncates to capacity-1. */
static void eva_tether_join_reason(char *out,
                                   size_t capacity,
                                   const char *prefix,
                                   const char *reason);

/* Extracts first JSON string value for key into out. */
static bool eva_tether_json_string_field(char *out,
                                         size_t capacity,
                                         const char *input,
                                         const char *key);

/* Emits Grok decision JSON or nothing on allow. */
static eva_tether_status_t eva_tether_emit_grok(const eva_tether_decision_t *d);

/* Emits Cursor permission JSON. */
static eva_tether_status_t eva_tether_emit_cursor(const eva_tether_decision_t *d);

/* Prints one JSON string with minimal escapes. */
static void eva_tether_print_json_string(const char *s);

eva_tether_status_t eva_tether_classify(eva_tether_decision_t *out_decision,
                                        eva_tether_mode_t mode,
                                        const char *blob)
{
    if (out_decision == NULL)
        return EVA_TETHER_ERR_ARG;
    if (blob == NULL)
        return EVA_TETHER_ERR_ARG;
    if (mode != EVA_TETHER_MODE_GROK && mode != EVA_TETHER_MODE_CURSOR)
        return EVA_TETHER_ERR_ARG;

    if (eva_tether_has_always_approve(blob)) {
        eva_tether_set_deny(out_decision, EVA_TETHER_REASON_ALWAYS_APPROVE);
        return EVA_TETHER_OK;
    }
    if (eva_tether_has_force_push(blob)) {
        eva_tether_set_deny(out_decision, EVA_TETHER_REASON_FORCE_PUSH);
        return EVA_TETHER_OK;
    }
    if (eva_tether_has_git_push(blob)) {
        if (mode == EVA_TETHER_MODE_CURSOR)
            eva_tether_set_ask(out_decision, EVA_TETHER_REASON_GIT_PUSH);
        else
            eva_tether_set_deny(out_decision, EVA_TETHER_REASON_GIT_PUSH);
        return EVA_TETHER_OK;
    }
    if (eva_tether_has_reset_hard(blob)) {
        eva_tether_set_deny(out_decision, EVA_TETHER_REASON_RESET_HARD);
        return EVA_TETHER_OK;
    }
    if (eva_tether_has_rm_root(blob)) {
        eva_tether_set_deny(out_decision, EVA_TETHER_REASON_RM_ROOT);
        return EVA_TETHER_OK;
    }

    eva_tether_set_allow(out_decision);
    return EVA_TETHER_OK;
}

eva_tether_status_t eva_tether_read_stdin(char *buf, size_t capacity, size_t *out_len)
{
    size_t total = 0;
    size_t n = 0;

    if (buf == NULL || capacity < 2u)
        return EVA_TETHER_ERR_ARG;

    while (total + 1u < capacity) {
        n = fread(buf + total, 1u, capacity - 1u - total, stdin);
        if (n == 0u)
            break;
        total += n;
        if (total >= (size_t)EVA_TETHER_SCAN_MAX_ITERS)
            break;
    }
    if (ferror(stdin))
        return EVA_TETHER_ERR_IO;

    buf[total] = '\0';
    if (out_len != NULL)
        *out_len = total;
    return EVA_TETHER_OK;
}

eva_tether_status_t eva_tether_extract_blob(char *out_blob,
                                            size_t capacity,
                                            const char *input,
                                            eva_tether_mode_t mode)
{
    char field[EVA_TETHER_BLOB_MAX_BYTES];

    if (out_blob == NULL || input == NULL || capacity < 2u)
        return EVA_TETHER_ERR_ARG;

    field[0] = '\0';
    if (mode == EVA_TETHER_MODE_CURSOR) {
        if (eva_tether_json_string_field(field, sizeof field, input, "command"))
            return eva_tether_copy_cstr(out_blob, capacity, field);
    } else {
        if (eva_tether_json_string_field(field, sizeof field, input, "toolInput"))
            return eva_tether_copy_cstr(out_blob, capacity, field);
        if (eva_tether_json_string_field(field, sizeof field, input, "command"))
            return eva_tether_copy_cstr(out_blob, capacity, field);
        if (eva_tether_json_string_field(field, sizeof field, input, "cmd"))
            return eva_tether_copy_cstr(out_blob, capacity, field);
        if (eva_tether_json_string_field(field, sizeof field, input, "script"))
            return eva_tether_copy_cstr(out_blob, capacity, field);
    }

    return eva_tether_copy_cstr(out_blob, capacity, input);
}

eva_tether_status_t eva_tether_emit(eva_tether_mode_t mode,
                                    const eva_tether_decision_t *decision)
{
    if (decision == NULL)
        return EVA_TETHER_ERR_ARG;
    if (mode == EVA_TETHER_MODE_GROK)
        return eva_tether_emit_grok(decision);
    if (mode == EVA_TETHER_MODE_CURSOR)
        return eva_tether_emit_cursor(decision);
    return EVA_TETHER_ERR_ARG;
}

eva_tether_status_t eva_tether_parse_mode(eva_tether_mode_t *out_mode,
                                          int argc,
                                          char **argv)
{
    int i = 0;

    if (out_mode == NULL || argv == NULL)
        return EVA_TETHER_ERR_ARG;

    *out_mode = EVA_TETHER_MODE_GROK;
    for (i = 1; i < argc; i++) {
        const char *arg = argv[i];

        if (arg == NULL)
            return EVA_TETHER_ERR_ARG;
        if (strcmp(arg, "--mode=grok") == 0) {
            *out_mode = EVA_TETHER_MODE_GROK;
            continue;
        }
        if (strcmp(arg, "--mode=cursor") == 0) {
            *out_mode = EVA_TETHER_MODE_CURSOR;
            continue;
        }
        if (strcmp(arg, "--mode") == 0) {
            if (i + 1 >= argc)
                return EVA_TETHER_ERR_ARG;
            i++;
            arg = argv[i];
            if (arg == NULL)
                return EVA_TETHER_ERR_ARG;
            if (strcmp(arg, "grok") == 0) {
                *out_mode = EVA_TETHER_MODE_GROK;
                continue;
            }
            if (strcmp(arg, "cursor") == 0) {
                *out_mode = EVA_TETHER_MODE_CURSOR;
                continue;
            }
            return EVA_TETHER_ERR_ARG;
        }
        return EVA_TETHER_ERR_ARG;
    }
    return EVA_TETHER_OK;
}

static void eva_tether_set_deny(eva_tether_decision_t *out, const char *reason)
{
    assert(out != NULL);
    assert(reason != NULL);
    out->verdict = EVA_TETHER_VERDICT_DENY;
    (void)eva_tether_copy_cstr(out->reason, sizeof out->reason, reason);
}

static void eva_tether_set_ask(eva_tether_decision_t *out, const char *reason)
{
    assert(out != NULL);
    assert(reason != NULL);
    out->verdict = EVA_TETHER_VERDICT_ASK;
    (void)eva_tether_copy_cstr(out->reason, sizeof out->reason, reason);
}

static void eva_tether_set_allow(eva_tether_decision_t *out)
{
    assert(out != NULL);
    out->verdict = EVA_TETHER_VERDICT_ALLOW;
    out->reason[0] = '\0';
}

static bool eva_tether_has_substr(const char *hay, const char *needle)
{
    assert(hay != NULL);
    assert(needle != NULL);
    return strstr(hay, needle) != NULL;
}

static bool eva_tether_is_word_boundary(unsigned char c)
{
    if (c == '\0')
        return true;
    if (isspace(c))
        return true;
    if (c == ';' || c == '|' || c == '&' || c == '(' || c == ')' || c == '<' || c == '>')
        return true;
    return false;
}

static const char *eva_tether_skip_space(const char *p)
{
    size_t guard = 0;

    assert(p != NULL);
    while (*p != '\0' && isspace((unsigned char)*p)
           && guard < (size_t)EVA_TETHER_SCAN_MAX_ITERS) {
        p++;
        guard++;
    }
    return p;
}

static bool eva_tether_at_word(const char *p, const char *token)
{
    size_t len = 0;

    assert(p != NULL);
    assert(token != NULL);
    len = strlen(token);
    if (len == 0u || len > (size_t)EVA_TETHER_WORD_MAX_BYTES)
        return false;
    if (strncmp(p, token, len) != 0)
        return false;
    return eva_tether_is_word_boundary((unsigned char)p[len]);
}

static bool eva_tether_has_always_approve(const char *blob)
{
    assert(blob != NULL);
    if (eva_tether_has_substr(blob, "--always-approve"))
        return true;
    if (eva_tether_has_substr(blob, "--yolo"))
        return true;
    if (eva_tether_has_substr(blob, "permission_mode=always-approve"))
        return true;
    if (eva_tether_has_substr(blob, "permission_mode=\"always-approve\""))
        return true;
    return false;
}

static const char *eva_tether_skip_git_options(const char *p)
{
    size_t guard = 0;

    assert(p != NULL);
    p = eva_tether_skip_space(p);
    while (*p == '-' && guard < 32u) {
        while (*p != '\0' && !isspace((unsigned char)*p)
               && !eva_tether_is_word_boundary((unsigned char)*p))
            p++;
        p = eva_tether_skip_space(p);
        guard++;
    }
    return p;
}

static bool eva_tether_push_args_force(const char *p)
{
    size_t guard = 0;

    assert(p != NULL);
    p = eva_tether_skip_space(p);
    while (*p != '\0' && guard < 64u) {
        if (*p == ';' || *p == '|')
            return false;
        if (*p == '&' && p[1] == '&')
            return false;
        if (eva_tether_at_word(p, "-f") || eva_tether_at_word(p, "--force")
            || eva_tether_at_word(p, "--force-with-lease"))
            return true;
        while (*p != '\0' && !isspace((unsigned char)*p) && *p != ';' && *p != '|'
               && *p != '&')
            p++;
        p = eva_tether_skip_space(p);
        guard++;
    }
    return false;
}

static bool eva_tether_has_force_push(const char *blob)
{
    const char *p = blob;
    size_t guard = 0;

    assert(blob != NULL);
    while (*p != '\0' && guard < (size_t)EVA_TETHER_SCAN_MAX_ITERS) {
        if (eva_tether_at_word(p, "git")) {
            const char *q = eva_tether_skip_git_options(p + 3);

            if (eva_tether_at_word(q, "push") && eva_tether_push_args_force(q + 4))
                return true;
        }
        p++;
        guard++;
    }
    return false;
}

static bool eva_tether_has_git_push(const char *blob)
{
    const char *p = blob;
    size_t guard = 0;

    assert(blob != NULL);
    while (*p != '\0' && guard < (size_t)EVA_TETHER_SCAN_MAX_ITERS) {
        if (eva_tether_at_word(p, "git")) {
            const char *q = eva_tether_skip_git_options(p + 3);

            if (eva_tether_at_word(q, "push"))
                return true;
        }
        p++;
        guard++;
    }
    return false;
}

static bool eva_tether_reset_args_hard(const char *args)
{
    const char *r = args;
    size_t arg_guard = 0;

    assert(args != NULL);
    r = eva_tether_skip_space(r);
    while (*r != '\0' && arg_guard < 32u) {
        if (*r == ';' || *r == '|')
            return false;
        if (eva_tether_at_word(r, "--hard"))
            return true;
        while (*r != '\0' && !isspace((unsigned char)*r) && *r != ';' && *r != '|')
            r++;
        r = eva_tether_skip_space(r);
        arg_guard++;
    }
    return false;
}

static bool eva_tether_has_reset_hard(const char *blob)
{
    const char *p = blob;
    size_t guard = 0;

    assert(blob != NULL);
    while (*p != '\0' && guard < (size_t)EVA_TETHER_SCAN_MAX_ITERS) {
        if (eva_tether_at_word(p, "git")) {
            const char *q = eva_tether_skip_git_options(p + 3);

            if (eva_tether_at_word(q, "reset") && eva_tether_reset_args_hard(q + 5))
                return true;
        }
        p++;
        guard++;
    }
    return false;
}

static bool eva_tether_flags_recursive(const char *flags)
{
    size_t i = 0;

    assert(flags != NULL);
    if (eva_tether_has_substr(flags, "--recursive"))
        return true;
    if (flags[0] != '-')
        return false;
    for (i = 1; flags[i] != '\0' && i < (size_t)EVA_TETHER_WORD_MAX_BYTES; i++) {
        if (flags[i] == '-')
            break;
        if (flags[i] == 'r' || flags[i] == 'R')
            return true;
    }
    return false;
}

static void eva_tether_take_token(char *out, size_t capacity, const char **pp)
{
    const char *q = NULL;
    size_t flen = 0;

    assert(out != NULL);
    assert(pp != NULL);
    assert(*pp != NULL);
    assert(capacity >= 1u);
    q = *pp;
    while (q[flen] != '\0' && !isspace((unsigned char)q[flen]) && q[flen] != ';'
           && flen + 1u < capacity)
        flen++;
    memcpy(out, q, flen);
    out[flen] = '\0';
    *pp = q + flen;
}

static bool eva_tether_rm_args_target_root(const char *args)
{
    const char *q = args;
    bool recursive = false;
    size_t arg_guard = 0;
    char token[EVA_TETHER_WORD_MAX_BYTES];

    assert(args != NULL);
    q = eva_tether_skip_space(q);
    while (*q != '\0' && arg_guard < 32u) {
        if (*q == ';' || *q == '|')
            return false;
        if (*q == '-') {
            eva_tether_take_token(token, sizeof token, &q);
            if (eva_tether_flags_recursive(token))
                recursive = true;
            q = eva_tether_skip_space(q);
            arg_guard++;
            continue;
        }
        if (recursive && (eva_tether_at_word(q, "/") || eva_tether_at_word(q, "/*")))
            return true;
        while (*q != '\0' && !isspace((unsigned char)*q) && *q != ';')
            q++;
        q = eva_tether_skip_space(q);
        arg_guard++;
    }
    return false;
}

static bool eva_tether_has_rm_root(const char *blob)
{
    const char *p = blob;
    size_t guard = 0;

    assert(blob != NULL);
    while (*p != '\0' && guard < (size_t)EVA_TETHER_SCAN_MAX_ITERS) {
        if (eva_tether_at_word(p, "rm")
            && eva_tether_rm_args_target_root(eva_tether_skip_space(p + 2)))
            return true;
        p++;
        guard++;
    }
    return false;
}

static eva_tether_status_t eva_tether_copy_cstr(char *dst,
                                                size_t capacity,
                                                const char *src)
{
    size_t i = 0;

    if (dst == NULL || src == NULL || capacity < 1u)
        return EVA_TETHER_ERR_ARG;
    for (i = 0; i + 1u < capacity && src[i] != '\0'; i++)
        dst[i] = src[i];
    dst[i] = '\0';
    if (src[i] != '\0')
        return EVA_TETHER_ERR_OVERFLOW;
    return EVA_TETHER_OK;
}

static void eva_tether_join_reason(char *out,
                                   size_t capacity,
                                   const char *prefix,
                                   const char *reason)
{
    size_t n = 0;
    size_t i = 0;

    assert(out != NULL);
    assert(prefix != NULL);
    assert(reason != NULL);
    assert(capacity >= 1u);

    for (i = 0; prefix[i] != '\0' && n + 1u < capacity; i++)
        out[n++] = prefix[i];
    for (i = 0; reason[i] != '\0' && n + 1u < capacity; i++)
        out[n++] = reason[i];
    out[n] = '\0';
}

static bool eva_tether_json_string_field(char *out,
                                         size_t capacity,
                                         const char *input,
                                         const char *key)
{
    char pattern[EVA_TETHER_WORD_MAX_BYTES + 8u];
    const char *hit = NULL;
    const char *p = NULL;
    size_t oi = 0;
    size_t key_len = 0;

    assert(out != NULL);
    assert(input != NULL);
    assert(key != NULL);
    if (capacity < 2u)
        return false;

    key_len = strlen(key);
    if (key_len == 0u || key_len + 4u >= sizeof pattern)
        return false;

    pattern[0] = '"';
    memcpy(pattern + 1u, key, key_len);
    pattern[1u + key_len] = '"';
    pattern[2u + key_len] = '\0';

    hit = strstr(input, pattern);
    if (hit == NULL)
        return false;
    p = hit + 2u + key_len;
    p = eva_tether_skip_space(p);
    if (*p != ':')
        return false;
    p++;
    p = eva_tether_skip_space(p);
    if (*p != '"')
        return false;
    p++;

    out[0] = '\0';
    while (*p != '\0' && *p != '"' && oi + 1u < capacity) {
        if (*p == '\\' && p[1] != '\0') {
            p++;
            out[oi++] = *p++;
            continue;
        }
        out[oi++] = *p++;
    }
    out[oi] = '\0';
    return oi > 0u;
}

static void eva_tether_print_json_string(const char *s)
{
    size_t i = 0;

    assert(s != NULL);
    putchar('"');
    for (i = 0; s[i] != '\0' && i < (size_t)EVA_TETHER_FULL_REASON_MAX_BYTES; i++) {
        unsigned char c = (unsigned char)s[i];

        if (c == '"' || c == '\\') {
            putchar('\\');
            putchar((char)c);
        } else if (c == '\n') {
            fputs("\\n", stdout);
        } else if (c == '\r') {
            fputs("\\r", stdout);
        } else if (c >= 0x20u) {
            putchar((char)c);
        }
    }
    putchar('"');
}

static eva_tether_status_t eva_tether_emit_grok(const eva_tether_decision_t *d)
{
    char full[EVA_TETHER_FULL_REASON_MAX_BYTES];

    assert(d != NULL);
    if (d->verdict == EVA_TETHER_VERDICT_ALLOW)
        return EVA_TETHER_OK;

    eva_tether_join_reason(full, sizeof full, EVA_TETHER_REASON_PREFIX, d->reason);
    fputs("{\"decision\":\"deny\",\"reason\":", stdout);
    eva_tether_print_json_string(full);
    fputs("}\n", stdout);
    return EVA_TETHER_OK;
}

static eva_tether_status_t eva_tether_emit_cursor(const eva_tether_decision_t *d)
{
    char full[EVA_TETHER_FULL_REASON_MAX_BYTES];
    char agent[EVA_TETHER_FULL_REASON_MAX_BYTES];

    assert(d != NULL);
    if (d->verdict == EVA_TETHER_VERDICT_ALLOW) {
        fputs("{\"permission\":\"allow\"}\n", stdout);
        return EVA_TETHER_OK;
    }

    eva_tether_join_reason(full, sizeof full, EVA_TETHER_REASON_PREFIX, d->reason);

    if (d->verdict == EVA_TETHER_VERDICT_ASK) {
        fputs("{\"permission\":\"ask\",\"user_message\":", stdout);
        eva_tether_print_json_string(full);
        fputs(",\"agent_message\":", stdout);
        eva_tether_print_json_string(EVA_TETHER_CURSOR_ASK_AGENT);
        fputs("}\n", stdout);
        return EVA_TETHER_OK;
    }

    eva_tether_join_reason(agent,
                           sizeof agent,
                           EVA_TETHER_CURSOR_DENY_AGENT_PREFIX,
                           d->reason);
    {
        char agent_full[EVA_TETHER_FULL_REASON_MAX_BYTES];
        size_t n = 0;
        size_t i = 0;
        const char *suffix = EVA_TETHER_CURSOR_DENY_AGENT_SUFFIX;

        for (i = 0; agent[i] != '\0' && n + 1u < sizeof agent_full; i++)
            agent_full[n++] = agent[i];
        for (i = 0; suffix[i] != '\0' && n + 1u < sizeof agent_full; i++)
            agent_full[n++] = suffix[i];
        agent_full[n] = '\0';

        fputs("{\"permission\":\"deny\",\"user_message\":", stdout);
        eva_tether_print_json_string(full);
        fputs(",\"agent_message\":", stdout);
        eva_tether_print_json_string(agent_full);
        fputs("}\n", stdout);
    }
    return EVA_TETHER_OK;
}
