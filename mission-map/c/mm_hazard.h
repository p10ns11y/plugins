#ifndef MM_HAZARD_H
#define MM_HAZARD_H

#include "mm_status.h"

/* P(fire by tau) = 1 - exp(-lambda * tau). lambda = events per time unit. */
mm_status_t mm_hazard_p_fire(double *out, double lambda, double tau);

/* Expected weeks added: blast * P(fire by tau). */
mm_status_t mm_hazard_e_delta_te(double *out, double blast, double lambda, double tau);

#endif /* MM_HAZARD_H */
