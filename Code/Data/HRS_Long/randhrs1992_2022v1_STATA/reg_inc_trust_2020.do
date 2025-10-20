*----------------------------------------------------------------------
* reg_inc_trust_2020.do
* Cross-sectional OLS of 2020 income measures on 2020 trust variables
* Runs each income measure on each trust variable, with and without controls
* Income: resp_lab_inc, resp_tot_inc, and their logs (created here)
* Controls: r15agey_b, raedyrs, r15inlbrf, married_2020, born_us
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_inc_trust_2020.log", replace text

set more off

* Ensure estout is available for table export
capture which esttab
if _rc {
	ssc install estout, replace
}

* Master dataset with all computed variables
local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}
use "`master'", clear
di as txt "Using master file: `master'"

di as txt ""
* Trust variables (2020)
local trust_vars "rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564"

* Income variables: log versions only
local inc_raw "resp_lab_inc resp_tot_inc"

di as txt "=== Creating log versions of income variables ==="
foreach v of local inc_raw {
    capture confirm variable `v'
    if !_rc {
        local lnname = substr("ln_`v'", 1, .)
        capture drop ln_`v'
        gen double ln_`v' = ln(`v') if `v' > 0
        label var ln_`v' "log(`v')"
    }
}

* Define income variables (log only)
local inc_vars "ln_resp_lab_inc ln_resp_tot_inc"

* Quick overlap diagnostics for sample sizes
quietly count
local N_all = r(N)

di as txt "=== Quick overlap check: ln_resp_lab_inc and rv557 ==="
quietly count if !missing(ln_resp_lab_inc)
di as txt "  Non-missing ln_resp_lab_inc: " r(N) " of " `N_all'
quietly count if !missing(rv557)
di as txt "  Non-missing rv557:        " r(N) " of " `N_all'
quietly count if !missing(ln_resp_lab_inc) & !missing(rv557)
di as txt "  Non-missing both:         " r(N) " of " `N_all'

di as txt ""

* Controls: age, education, employment, marital status, immigration
local ctrl_vars "r15agey_b raedyrs r15inlbrf married_2020 born_us"

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

di as txt ""
* ----------------------------------------------------------------------
* Collect and export: one LaTeX table per trust variable (8 columns: 4 raw + 4 +controls)
* ----------------------------------------------------------------------
foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc {
        di as warn "Skipping trust var (not found): `t'"
        continue
    }

    eststo clear
    local models_raw ""
    local models_ctl ""

    * Raw (no controls)
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        local mname = "`t'_raw_`y'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' if !missing(`y') & !missing(`t'), vce(robust)
        local models_raw "`models_raw' `mname'"
    }

    * With controls
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        local mname = "`t'_ctl_`y'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' `age_quad' `ctrl_in' if !missing(`y') & !missing(`t'), vce(robust)
        local models_ctl "`models_ctl' `mname'"
    }

    * Export table for this trust variable -> Paper/Tables
    local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
    local outfile "`tables'/trust_income_`t'.tex"
    di as txt "Exporting LaTeX table: `outfile'"
    if "`models_raw'`models_ctl'" != "" {
        * Short, human column titles for 4 models (log income only)
        local mt "log Lab" "log Tot" "log Lab" "log Tot"
        
        * Short row names (LaTeX-safe)
        local vlab `t'         "Trust"
        local vlab2 c.`t'#c.`t' "Trust\$^{2}\$"
        local vlab3 r15agey_b    "Age"
        local vlab4 c.r15agey_b#c.r15agey_b "Age\$^{2}\$"
        local vlab5 raedyrs      "Years of education"
        local vlab6 r15inlbrf    "In labor force"
        local vlab7 married_2020 "Married"
        local vlab8 born_us      "Born in U.S."
        
        esttab `models_raw' `models_ctl' using "`outfile'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            mtitles("log Lab" "log Tot" "log Lab" "log Tot") ///
            posthead("& \multicolumn{2}{c}{No controls} & \multicolumn{2}{c}{With controls} \\\\ \cmidrule(lr){2-3}\cmidrule(lr){4-5}") ///
            varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Log Income (2020) on Trust `t'") ///
            addnote("Robust SEs in parentheses; Age entered quadratically when available." "Controls (when included): raedyrs, in labor force, married, born in U.S.")
    }
    else {
        di as warn "No models estimated for trust var `t'; skipping export."
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

    eststo clear
    local models_pca_raw ""
    local models_pca_ctl ""

    * RAW
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        local mname = "pca_raw_`y'"
        eststo `mname': regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z if !missing(`y') & !missing(trust_pca1_z), vce(robust)
        local models_pca_raw "`models_pca_raw' `mname'"
    }

    * With controls
    foreach y of local inc_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        local mname = "pca_ctl_`y'"
        eststo `mname': regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z `age_quad' `ctrl_in' if !missing(`y') & !missing(trust_pca1_z), vce(robust)
        local models_pca_ctl "`models_pca_ctl' `mname'"
    }

    * Export PCA table -> Paper/Tables
    local outfile_pca "`tables'/trust_income_pca.tex"
    di as txt "Exporting LaTeX table: `outfile_pca'"
    if "`models_pca_raw'`models_pca_ctl'" != "" {
        local pc1_str : display %6.3f pc1_prop
        
        * Short, human column titles for 4 models (log income only)
        local mt "log Lab" "log Tot" "log Lab" "log Tot"
        
        * Short row names (LaTeX-safe)
        local vlab trust_pca1_z         "Trust PC1"
        local vlab2 c.trust_pca1_z#c.trust_pca1_z "Trust PC1\$^{2}\$"
        local vlab3 r15agey_b    "Age"
        local vlab4 c.r15agey_b#c.r15agey_b "Age\$^{2}\$"
        local vlab5 raedyrs      "Years of education"
        local vlab6 r15inlbrf    "In labor force"
        local vlab7 married_2020 "Married"
        local vlab8 born_us      "Born in U.S."
        
        esttab `models_pca_raw' `models_pca_ctl' using "`outfile_pca'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            mtitles("log Lab" "log Tot" "log Lab" "log Tot") ///
            posthead("& \multicolumn{2}{c}{No controls} & \multicolumn{2}{c}{With controls} \\\\ \cmidrule(lr){2-3}\cmidrule(lr){4-5}") ///
            varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Log Income (2020) on Trust PC1") ///
            addnote("Robust SEs in parentheses; Age entered quadratically when available." "Controls (when included): raedyrs, in labor force, married, born in U.S." "PC1 variance prop = `pc1_str'")
    }
    else {
        di as warn "No PCA models estimated; skipping export."
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed and tables exported."

log close
