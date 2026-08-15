/* main.c: CLI over PERT, path MC, and d(te)/d(m). */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mm_grad.h"
#include "mm_mc.h"
#include "mm_pert.h"

enum {
    MM_CLI_STAGE_ARGS = 3
};

static int mm_cli_usage(void);
static int mm_cli_pert(int argc, char **argv);
static int mm_cli_mc(int argc, char **argv);
static int mm_cli_grad(int argc, char **argv);
static mm_status_t mm_cli_parse_stage(mm_stage_t *out, char **argv);

int main(int argc, char **argv)
{
    if (argc < 2)
        return mm_cli_usage();
    if (strcmp(argv[1], "pert") == 0)
        return mm_cli_pert(argc - 2, argv + 2);
    if (strcmp(argv[1], "mc") == 0)
        return mm_cli_mc(argc - 2, argv + 2);
    if (strcmp(argv[1], "grad") == 0)
        return mm_cli_grad(argc - 2, argv + 2);
    return mm_cli_usage();
}

static int mm_cli_usage(void)
{
    fputs("usage: mm-kern pert <a> <m> <b>\n", stderr);
    fputs("       mm-kern mc <a> <m> <b> [a m b ...]\n", stderr);
    fputs("       mm-kern grad <a> <m> <b>\n", stderr);
    return 2;
}

static int mm_cli_pert(int argc, char **argv)
{
    mm_stage_t stage;
    double te = 0.0;
    double sigma = 0.0;

    if (argc != MM_CLI_STAGE_ARGS)
        return mm_cli_usage();
    if (mm_cli_parse_stage(&stage, argv) != MM_OK)
        return 1;
    if (mm_pert_expected(&te, stage) != MM_OK)
        return 1;
    if (mm_pert_sigma(&sigma, stage) != MM_OK)
        return 1;
    printf("te=%.6f sigma=%.6f\n", te, sigma);
    return 0;
}

static int mm_cli_mc(int argc, char **argv)
{
    mm_stage_t stages[MM_MAX_STAGES];
    mm_mc_cfg_t cfg;
    mm_mc_summary_t sum;
    int i;
    size_t n = 0;

    if (argc < MM_CLI_STAGE_ARGS || (argc % MM_CLI_STAGE_ARGS) != 0)
        return mm_cli_usage();
    n = (size_t)argc / (size_t)MM_CLI_STAGE_ARGS;
    if (n > (size_t)MM_MAX_STAGES)
        return 1;
    for (i = 0; i < (int)n; i++) {
        if (mm_cli_parse_stage(&stages[i], argv + i * MM_CLI_STAGE_ARGS) != MM_OK)
            return 1;
    }
    cfg.stages = stages;
    cfg.n = n;
    cfg.draws = 1024;
    cfg.seed = 1;
    if (mm_mc_path(&sum, &cfg) != MM_OK)
        return 1;
    printf("mean=%.6f p50=%.6f p90=%.6f\n", sum.mean, sum.p50, sum.p90);
    return 0;
}

static int mm_cli_grad(int argc, char **argv)
{
    mm_stage_t stage;
    double dte = 0.0;

    if (argc != MM_CLI_STAGE_ARGS)
        return mm_cli_usage();
    if (mm_cli_parse_stage(&stage, argv) != MM_OK)
        return 1;
    if (mm_grad_te_wrt_m(&dte, stage) != MM_OK)
        return 1;
    printf("dte_dm=%.6f\n", dte);
    return 0;
}

static mm_status_t mm_cli_parse_stage(mm_stage_t *out, char **argv)
{
    if (out == NULL || argv == NULL)
        return MM_ERR_ARG;
    out->a = strtod(argv[0], NULL);
    out->m = strtod(argv[1], NULL);
    out->b = strtod(argv[2], NULL);
    if (!mm_stage_is_valid(*out))
        return MM_ERR_ARG;
    return MM_OK;
}
