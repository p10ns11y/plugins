//! Bindings to C PERT / MC / grad kernels.

use std::os::raw::{c_int, c_uint};

#[repr(C)]
#[derive(Clone, Copy)]
pub struct MmStage {
    pub a: f64,
    pub m: f64,
    pub b: f64,
}

#[repr(C)]
pub struct MmMcSummary {
    pub mean: f64,
    pub p50: f64,
    pub p90: f64,
}

#[repr(C)]
pub struct MmMcCfg {
    pub stages: *const MmStage,
    pub n: usize,
    pub draws: c_uint,
    pub seed: c_uint,
}

extern "C" {
    fn mm_pert_expected(out_te: *mut f64, stage: MmStage) -> c_int;
    fn mm_mc_path(out: *mut MmMcSummary, cfg: *const MmMcCfg) -> c_int;
    fn mm_grad_te_wrt_m(out_dte: *mut f64, stage: MmStage) -> c_int;
    fn mm_hazard_p_fire(out: *mut f64, lambda: f64, tau: f64) -> c_int;
    fn mm_hazard_e_delta_te(out: *mut f64, blast: f64, lambda: f64, tau: f64) -> c_int;
    fn mm_bayes_pert_observe(prior: MmStage, t_actual: f64, out: *mut MmStage) -> c_int;
}

const MM_OK: c_int = 0;

pub fn pert_expected(stage: MmStage) -> Result<f64, c_int> {
    let mut te = 0.0;
    let status = unsafe { mm_pert_expected(&mut te, stage) };
    if status == MM_OK {
        Ok(te)
    } else {
        Err(status)
    }
}

pub fn mc_path(stages: &[MmStage], draws: u32, seed: u32) -> Result<MmMcSummary, c_int> {
    let mut out = MmMcSummary {
        mean: 0.0,
        p50: 0.0,
        p90: 0.0,
    };
    let cfg = MmMcCfg {
        stages: stages.as_ptr(),
        n: stages.len(),
        draws,
        seed,
    };
    let status = unsafe { mm_mc_path(&mut out, &cfg) };
    if status == MM_OK {
        Ok(out)
    } else {
        Err(status)
    }
}

pub fn grad_te_wrt_m(stage: MmStage) -> Result<f64, c_int> {
    let mut dte = 0.0;
    let status = unsafe { mm_grad_te_wrt_m(&mut dte, stage) };
    if status == MM_OK {
        Ok(dte)
    } else {
        Err(status)
    }
}

pub fn hazard_p_fire(lambda: f64, tau: f64) -> Result<f64, c_int> {
    let mut p = 0.0;
    let status = unsafe { mm_hazard_p_fire(&mut p, lambda, tau) };
    if status == MM_OK {
        Ok(p)
    } else {
        Err(status)
    }
}

pub fn hazard_e_delta_te(blast: f64, lambda: f64, tau: f64) -> Result<f64, c_int> {
    let mut edt = 0.0;
    let status = unsafe { mm_hazard_e_delta_te(&mut edt, blast, lambda, tau) };
    if status == MM_OK {
        Ok(edt)
    } else {
        Err(status)
    }
}

pub fn bayes_pert_observe(prior: MmStage, t_actual: f64) -> Result<MmStage, c_int> {
    let mut out = MmStage { a: 0.0, m: 0.0, b: 0.0 };
    let status = unsafe { mm_bayes_pert_observe(prior, t_actual, &mut out) };
    if status == MM_OK {
        Ok(out)
    } else {
        Err(status)
    }
}
