#ifndef MM_PERT_H
#define MM_PERT_H

#include "mm_status.h"

typedef struct {
    double a;
    double m;
    double b;
} mm_stage_t;

/* Writes PERT expected time (a+4m+b)/6. Fails MM_ERR_ARG on NULL or
 * a>m, m>b, or a<0. */
mm_status_t mm_pert_expected(double *out_te, mm_stage_t stage);

/* Writes PERT sigma (b-a)/6. Same argument rules as mm_pert_expected. */
mm_status_t mm_pert_sigma(double *out_sigma, mm_stage_t stage);

/* True when a<=m<=b and a>=0. Pure. */
int mm_stage_is_valid(mm_stage_t stage);

#endif /* MM_PERT_H */
