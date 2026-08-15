#ifndef MM_STATUS_H
#define MM_STATUS_H

enum {
    MM_MAX_STAGES = 32,
    MM_MAX_DRAWS = 4096,
    MM_PERT_WEIGHT_ENDS = 1,
    MM_PERT_WEIGHT_MODE = 4,
    MM_PERT_WEIGHT_SUM = 6
};

typedef enum {
    MM_OK = 0,
    MM_ERR_ARG = -1,
    MM_ERR_RANGE = -2,
    MM_ERR_FULL = -3
} mm_status_t;

#define MM_TRY(expr)                            \
    do {                                        \
        mm_status_t mm_try_s_ = (expr);         \
        if (mm_try_s_ != MM_OK)                 \
            return mm_try_s_;                   \
    } while (0)

#endif /* MM_STATUS_H */
