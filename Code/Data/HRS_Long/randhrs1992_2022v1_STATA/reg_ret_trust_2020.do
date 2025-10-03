*----------------------------------------------------------------------
* reg_ret_trust_2020.do
* Cross-sectional OLS of 2022 returns on 2020 trust variables (Longitudinal dataset)
* Runs each return measure on each trust variable, with and without controls
* Returns: r_annual_2022, r_annual_2022_trim, r_annual_2022_excl_res, r_annual_2022_excl_res_trim
* Controls: r15agey_b, raedyrs, r15inlbrf, married_2020, born_us, wealth deciles (wealth_d2..wealth_d10 if present)
*----------------------------------------------------------------------

clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_ret_trust_2020.log", replace text

set more off

* Master dataset with all computed variables
local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}
use "`master'", clear
di as txt "Using master file: `master'"

* Trust variables (2020)
local trust_vars "rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564"

* Return variables: annual and trimmed (with and without residential)
local ret_vars "r_annual_2022 r_annual_2022_trim r_annual_2022_excl_res r_annual_2022_excl_res_trim"

* Quick overlap diagnostics for sample sizes
quietly count
local N_all = r(N)
di as txt "=== Quick overlap check: r_annual_2022 and rv557 ==="
quietly count if !missing(r_annual_2022)
di as txt "  Non-missing r_annual_2022: " r(N) " of " `N_all'
quietly count if !missing(rv557)
di as txt "  Non-missing rv557:          " r(N) " of " `N_all'
quietly count if !missing(r_annual_2022) & !missing(rv557)
di as txt "  Non-missing both:           " r(N) " of " `N_all'
di as txt ""

* Controls
local ctrl_core "r15agey_b raedyrs r15inlbrf married_2020 born_us"
local ctrl_deciles ""
forvalues d = 2/10 {
    capture confirm variable wealth_d`d'
    if !_rc local ctrl_deciles "`ctrl_deciles' wealth_d`d'"
}
local ctrl_vars "`ctrl_core' `ctrl_deciles'"

* Report which controls are available
di as txt "Controls to include (if present):"
di as txt "  `ctrl_vars'"

* No helper program; rely on Stata's regression output

* Loop over trust variables and returns
di as txt "=== BEGIN REGRESSIONS: RETURNS on TRUST (no controls) ==="
foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc {
        di as warn "Skipping trust var (not found): `t'"
        continue
    }
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        di as txt "[RAW] `y' on `t' + `t'^2 (robust)"
        regress `y' c.`t' c.`t'#c.`t' if !missing(`y') & !missing(`t'), vce(robust)
    }
}

di as txt "=== BEGIN REGRESSIONS: RETURNS on TRUST (+ controls) ==="
* Build controls actually present
local ctrl_in ""
foreach c of local ctrl_vars {
    capture confirm variable `c'
    if !_rc local ctrl_in "`ctrl_in' `c'"
}
di as txt "Controls included: `ctrl_in'"

foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc continue
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        di as txt "[RAW+C] `y' on `t' + `t'^2 with controls (robust)"
        regress `y' c.`t' c.`t'#c.`t' `ctrl_in' if !missing(`y') & !missing(`t'), vce(robust)
    }
}

* ----------------------------------------------------------------------
* PCA of trust variables (rv557-rv564) and regressions using PC1
* ----------------------------------------------------------------------
di as txt "=== PCA on trust variables (rv557-rv564) ==="
capture drop trust_pca1 trust_pca1_z
capture noisily pca rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564, components(1)
if _rc==0 {
    * Proportion of variance explained by PC1 (display only)
    capture matrix M = e(Prop)
    if _rc==0 {
        scalar pc1_prop = M[1,1]
        di as txt "PC1 variance proportion: " %6.3f pc1_prop
    }
    predict double trust_pca1 if e(sample), score
    egen double trust_pca1_z = std(trust_pca1)
    quietly count if !missing(trust_pca1_z)
    di as txt "Non-missing trust_pca1_z: " r(N)
    quietly count if !missing(r_annual_2022) & !missing(trust_pca1_z)
    di as txt "Overlap with r_annual_2022: " r(N)

    di as txt "=== REGRESSIONS: RETURNS on trust_pca1_z (no controls) ==="
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        di as txt "[RAW] `y' on trust_pca1_z + trust_pca1_z^2 (robust)"
        regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z if !missing(`y') & !missing(trust_pca1_z), vce(robust)
    }

    di as txt "=== REGRESSIONS: RETURNS on trust_pca1_z (+ controls) ==="
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        di as txt "[RAW+C] `y' on trust_pca1_z + trust_pca1_z^2 with controls (robust)"
        regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z `ctrl_in' if !missing(`y') & !missing(trust_pca1_z), vce(robust)
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed. Review coefficients, SEs, R2, and N above."

log close

