*----------------------------------------------------------------------
* reg_inc_trust_2020.do
* Cross-sectional OLS of 2020 income variables on 2020 trust variables
* Runs each income measure on each trust variable, with and without controls
*----------------------------------------------------------------------

clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_inc_trust_2020.log", replace text

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

* Income variables: raw and log versions
local inc_raw "resp_lab_inc resp_tot_inc"

* Create log versions of income variables
di as txt "=== Creating log versions of income variables ==="
foreach v of local inc_raw {
    capture confirm variable `v'
    if !_rc {
        capture drop ln_`v'
        gen double ln_`v' = ln(`v') if `v' > 0 & !missing(`v')
        label var ln_`v' "Log of `v'"
        di as txt "Created ln_`v'"
    }
}

* Define all income variables (raw + log)
local inc_vars "resp_lab_inc resp_tot_inc ln_resp_lab_inc ln_resp_tot_inc"

* Quick overlap diagnostics for sample sizes
quietly count
local N_all = r(N)
di as txt "=== Quick overlap check: resp_lab_inc and rv557 ==="
quietly count if !missing(resp_lab_inc)
di as txt "  Non-missing resp_lab_inc: " r(N) " of " `N_all'
quietly count if !missing(rv557)
di as txt "  Non-missing rv557:        " r(N) " of " `N_all'
quietly count if !missing(resp_lab_inc) & !missing(rv557)
di as txt "  Non-missing both:         " r(N) " of " `N_all'
di as txt ""

* Controls: age, education, employment, marital status, immigration
local ctrl_vars "r15agey_b raedyrs r15inlbrf married_2020 born_us"

* Report which controls are available
di as txt "Controls to include (if present):"
di as txt "  `ctrl_vars'"

* Check which controls are actually present
local ctrl_in ""
local age_quad ""
foreach c of local ctrl_vars {
    capture confirm variable `c'
    if !_rc {
        if "`c'" == "r15agey_b" {
            local age_quad "c.r15agey_b c.r15agey_b#c.r15agey_b"
        }
        else {
            local ctrl_in "`ctrl_in' `c'"
        }
    }
}
di as txt "Controls actually included: `ctrl_in' with age quad if available"

* Loop over trust variables and income measures
di as txt "=== BEGIN REGRESSIONS: INCOME on TRUST (no controls) ==="
foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc {
        di as warn "Skipping trust var (not found): `t'"
        continue
    }
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        di as txt "[RAW] `y' on `t' + `t'^2 (robust)"
        regress `y' c.`t' c.`t'#c.`t' if !missing(`y') & !missing(`t'), vce(robust)
    }
}

di as txt "=== BEGIN REGRESSIONS: INCOME on TRUST (+ controls) ==="
foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc continue
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        di as txt "[RAW+C] `y' on `t' + `t'^2 + age quad + controls (robust)"
        regress `y' c.`t' c.`t'#c.`t' `age_quad' `ctrl_in' if !missing(`y') & !missing(`t'), vce(robust)
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
    quietly count if !missing(resp_lab_inc) & !missing(trust_pca1_z)
    di as txt "Overlap with resp_lab_inc: " r(N)

    di as txt "=== REGRESSIONS: INCOME on trust_pca1_z (no controls) ==="
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        di as txt "[RAW] `y' on trust_pca1_z + trust_pca1_z^2 (robust)"
        regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z if !missing(`y') & !missing(trust_pca1_z), vce(robust)
    }

    di as txt "=== REGRESSIONS: INCOME on trust_pca1_z (+ controls) ==="
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        di as txt "[RAW+C] `y' on trust_pca1_z + trust_pca1_z^2 + age quad + controls (robust)"
        regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z `age_quad' `ctrl_in' if !missing(`y') & !missing(trust_pca1_z), vce(robust)
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed. Review coefficients, SEs, R2, and N above."

log close
