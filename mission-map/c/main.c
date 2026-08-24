/* main.c: CLI over PERT, path MC, grad, hazard, and Bayesian PERT update. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mm_bayes_pert.h"
#include "mm_grad.h"
#include "mm_hazard.h"
#include "mm_mc.h"
#include "mm_pert.h"

enum {
    MM_CLI_STAGE_ARGS = 3
};

static int mm_cli_usage(void);
static int mm_cli_pert(int argc, char **argv);
static int mm_cli_mc(int argc, char **argv);
static int mm_cli_grad(int argc, char **argv);
static int mm_cli_hazard(int argc, char **argv);
static int mm_cli_bayes(int argc, char **argv);
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
    if (strcmp(argv[1], "hazard") == 0)
        return mm_cli_hazard(argc - 2, argv + 2);
    if (strcmp(argv[1], "bayes") == 0)
        return mm_cli_bayes(argc - 2, argv + 2);
    return mm_cli_usage();
}

static int mm_cli_usage(void)
{
    fputs("usage: mm-kern pert <a> <m> <b>\n", stderr);
    fputs("       mm-kern mc <a> <m> <b> [a m b ...]\n", stderr);
    fputs("       mm-kern grad <a> <m> <b>\n", stderr);
    fputs("       mm-kern hazard <lambda> <tau> [<blast>]\n", stderr);
    fputs("       mm-kern bayes <a> <m> <b> <t_actual>\n", stderr);
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

static int mm_cli_hazard(int argc, char **argv)
{
    double lambda;
    double tau;
    double blast = 0.0;
    double p = 0.0;
    double edt = 0.0;

    if (argc < 2 || argc > 3)
        return mm_cli_usage();
    lambda = strtod(argv[0], NULL);
    tau = strtod(argv[1], NULL);
    if (argc == 3)
        blast = strtod(argv[2], NULL);
    if (mm_hazard_p_fire(&p, lambda, tau) != MM_OK)
        return 1;
    printf("p_fire=%.6f\n", p);
    if (argc == 3) {
        if (mm_hazard_e_delta_te(&edt, blast, lambda, tau) != MM_OK)
            return 1;
        printf("e_delta_te=%.6f\n", edt);
    }
    return 0;
}

static int mm_cli_bayes(int argc, char **argv)
{
    mm_stage_t prior;
    mm_stage_t out;
    double t_actual;

    if (argc != 4)
        return mm_cli_usage();
    if (mm_cli_parse_stage(&prior, argv) != MM_OK)
        return 1;
    t_actual = strtod(argv[3], NULL);
    if (mm_bayes_pert_observe(prior, t_actual, &out) != MM_OK)
        return 1;
    printf("a=%.6f m=%.6f b=%.6f\n", out.a, out.m, out.b);
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
