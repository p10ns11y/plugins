/* mm_hazard.c: Risk signpost survival math. */

#include <math.h>
#include <stddef.h>

#include "mm_hazard.h"

mm_status_t mm_hazard_p_fire(double *out, double lambda, double tau)
{
    if (out == NULL)
        return MM_ERR_ARG;
    if (lambda < 0.0 || tau < 0.0)
        return MM_ERR_ARG;
    *out = 1.0 - exp(-lambda * tau);
    return MM_OK;
}

mm_status_t mm_hazard_e_delta_te(double *out, double blast, double lambda, double tau)
{
    double p = 0.0;

    MM_TRY(mm_hazard_p_fire(&p, lambda, tau));
    if (blast < 0.0)
        return MM_ERR_ARG;
    *out = blast * p;
    return MM_OK;
}
