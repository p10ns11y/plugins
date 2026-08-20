#ifndef MM_BAYES_PERT_H
#define MM_BAYES_PERT_H

#include "mm_pert.h"

/* Conjugate-ish PERT update after observing actual completion time.
 * Pulls m toward t_actual and tightens [a,b] when the draw was inside. */
mm_status_t mm_bayes_pert_observe(mm_stage_t prior, double t_actual, mm_stage_t *out);

#endif /* MM_BAYES_PERT_H */
