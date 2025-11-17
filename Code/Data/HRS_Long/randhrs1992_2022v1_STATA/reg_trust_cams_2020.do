*----------------------------------------------------------------------
* reg_trust_cams_2020.do
* Cross-sectional OLS of 2020 trust variables on controls
* Runs each trust variable on basic controls (age, education, gender, race)
* Trust variables (LHS): rv557, rv558, rv559, rv560, rv561, rv562, rv563, rv564
* Controls: r15agey_b (quadratic), raedyrs, ragender, race_eth
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_trust_cams_2020.log", replace text

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

* Trust variables (2020) - these are the dependent variables
local trust_vars "rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564"

* Quick overlap diagnostics for sample sizes
quietly count
local N_all = r(N)
di as txt "=== Quick overlap check: trust variables and controls ==="
quietly count if !missing(rv557)
di as txt "  Non-missing rv557: " r(N) " of " `N_all'
quietly count if !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
di as txt "  Non-missing basic controls: " r(N) " of " `N_all'
quietly count if !missing(rv557) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
di as txt "  Non-missing rv557 and basic controls: " r(N) " of " `N_all'
di as txt ""

* ----------------------------------------------------------------------
* Correlation matrix of trust variables
* ----------------------------------------------------------------------
di as txt "=== Computing correlation matrix of trust variables ==="

* Check which trust variables are available
local trust_vars_avail ""
foreach t of local trust_vars {
    capture confirm variable `t'
    if !_rc {
        quietly count if !missing(`t')
        if r(N) > 0 {
            local trust_vars_avail "`trust_vars_avail' `t'"
        }
    }
}

if "`trust_vars_avail'" != "" {
    di as txt "Computing correlations for: `trust_vars_avail'"
    quietly correlate `trust_vars_avail'
    matrix corr_trust = r(C)
    
    * Display in log
    di as txt "Correlation matrix:"
    matrix list corr_trust
    
    * Export to LaTeX
    local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
    local outfile_corr "`tables'/trust_correlation_2020.tex"
    di as txt "Exporting correlation matrix to: `outfile_corr'"
    
    * Create variable labels for correlation table
    local vlab_corr rv557 "rv557" rv558 "rv558" rv559 "rv559" rv560 "rv560" ///
                     rv561 "rv561" rv562 "rv562" rv563 "rv563" rv564 "rv564"
    
    esttab matrix(corr_trust) using "`outfile_corr'", replace ///
        booktabs ///
        compress b(%9.3f) ///
        title("Correlation Matrix of Trust Variables (2020)") ///
        addnote("Pairwise correlations between trust variables rv557-rv564")
}
else {
    di as warn "WARNING: No trust variables available for correlation matrix"
}
di as txt ""

* ----------------------------------------------------------------------
* Setup control variables
* ----------------------------------------------------------------------
di as txt "=== Setting up control variables ==="

* Basic controls: age (quadratic), education, gender, race
local age_quad ""
capture confirm variable r15agey_b
if !_rc {
    local age_quad "c.r15agey_b c.r15agey_b#c.r15agey_b"
    di as txt "Age (quadratic) included"
}

local education_var ""
capture confirm variable raedyrs
if !_rc {
    local education_var "raedyrs"
    di as txt "Education (raedyrs) included"
}

local gender_factor ""
capture confirm variable ragender
if !_rc {
    local gender_factor "i.ragender"
    di as txt "Gender (i.ragender) included"
}

local race_factor ""
capture confirm variable race_eth
if !_rc {
    local race_factor "i.race_eth"
    di as txt "Race/ethnicity (i.race_eth) included"
}
di as txt ""

* Additional controls: married status and log labor income (2020)
local additional_ctrls ""
local income_var ""

* Check for married_2020
capture confirm variable married_2020
if !_rc {
    local additional_ctrls "married_2020"
    di as txt "Married status (married_2020) included"
}

* Check for income variable and create log version
* Priority: resp_lab_inc_2020 (constructed from R15/2020 wave components)
* Note: Using ln(var + 1) convention to handle zeros
capture confirm variable resp_lab_inc_2020
if !_rc {
    capture drop ln_resp_lab_inc_2020
    gen double ln_resp_lab_inc_2020 = ln(resp_lab_inc_2020 + 1)
    label var ln_resp_lab_inc_2020 "log(resp_lab_inc + 1) - 2020 wave"
    local income_var "ln_resp_lab_inc_2020"
    di as txt "Log labor income (ln_resp_lab_inc_2020) created from resp_lab_inc_2020 (2020 wave data, using +1)"
}
else {
    * Fallback: check for resp_lab_inc (no suffix)
    capture confirm variable resp_lab_inc
    if !_rc {
        capture drop ln_resp_lab_inc
        gen double ln_resp_lab_inc = ln(resp_lab_inc + 1)
        label var ln_resp_lab_inc "log(resp_lab_inc + 1)"
        local income_var "ln_resp_lab_inc"
        di as txt "Log labor income (ln_resp_lab_inc) created from resp_lab_inc (using +1)"
    }
}

* Add income variable to additional_ctrls if created
if "`income_var'" != "" {
    if "`additional_ctrls'" != "" {
        local additional_ctrls "`additional_ctrls' `income_var'"
    }
    else {
        local additional_ctrls "`income_var'"
    }
}

if "`additional_ctrls'" != "" {
    di as txt "Additional controls included: `additional_ctrls'"
}
di as txt ""

* Create pension wealth variables (2020)
* Pension total from defined contribution balances
capture drop pension_total_2020
egen double pension_total_2020 = rowtotal(r15dcbal1 r15dcbal2 r15dcbal3 r15dcbal4)
label var pension_total_2020 "Total pension wealth (sum of r15dcbal1-4) - 2020 wave"

capture drop ln_pension_total_2020
gen double ln_pension_total_2020 = ln(pension_total_2020 + 1)
label var ln_pension_total_2020 "log(pension_total + 1) - 2020 wave"

di as txt "Pension wealth variables created: pension_total_2020, ln_pension_total_2020"
di as txt ""

* CAMS 2021 controls (conditionally include those present) — Spec 2 RHS
local cams_ctrls ""
foreach v in cams_showaffect_2021 cams_helpothers_2021 cams_volunteer_2021 cams_religattend_2021 cams_meetings_2021 {
    capture confirm variable `v'
    if !_rc local cams_ctrls "`cams_ctrls' `v'"
}
if "`cams_ctrls'" != "" {
    di as txt "CAMS controls included: `cams_ctrls'"
}

* Spec 3 controls: additional_ctrls + r15lbagr
local spec3_ctrls ""
capture confirm variable r15lbagr
if !_rc {
    if "`additional_ctrls'" != "" {
        local spec3_ctrls "`additional_ctrls' r15lbagr"
    }
    else {
        local spec3_ctrls "r15lbagr"
    }
    di as txt "Spec 3 control (r15lbagr) found and will be included"
}
else {
    * If r15lbagr doesn't exist, spec3_ctrls = additional_ctrls (same as spec 1)
    local spec3_ctrls "`additional_ctrls'"
    di as warn "WARNING: r15lbagr not found; spec 3 will be same as spec 1"
}
if "`spec3_ctrls'" != "" {
    di as txt "Spec 3 controls: `spec3_ctrls'"
}

* Spec 4 controls: additional_ctrls + r15inlbrf + h15aira + r15cesd + r15conde
local spec4_ctrls ""
if "`additional_ctrls'" != "" {
    local spec4_ctrls "`additional_ctrls' r15inlbrf h15aira r15cesd r15conde"
}
else {
    local spec4_ctrls "r15inlbrf h15aira r15cesd r15conde"
}

di as txt ""

* ----------------------------------------------------------------------
* Individual trust variable regressions
* ----------------------------------------------------------------------
di as txt "=== Running individual trust variable regressions ==="

local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"

foreach t of local trust_vars {
    capture confirm variable `t'
    if _rc {
        di as warn "Skipping trust var (not found): `t'"
        continue
    }

    * Check sample size
    quietly count if !missing(`t')
    if r(N)==0 {
        di as warn "Skipping trust var (no non-missing): `t'"
        continue
    }

    eststo clear

    * Basic controls only
    * Build condition for sample size check
    local spec1_cond "!missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)"
    if "`additional_ctrls'" != "" {
        foreach v of local additional_ctrls {
            local spec1_cond "`spec1_cond' & !missing(`v')"
        }
    }
    quietly count if `spec1_cond'
    if r(N) > 0 {
        eststo `t'_spec1: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' ///
            if `spec1_cond', vce(robust)
    }

    * Export table for this trust variable
    local outfile "`tables'/trust_cams_`t'.tex"
    di as txt "Exporting LaTeX table: `outfile'"
    
    * Variable labels (LaTeX-safe)
    local vlab1 r15agey_b    "Age"
    local vlab2 c.r15agey_b#c.r15agey_b "Age\$^{2}\$"
    local vlab3 raedyrs      "Years of education"
    local vlab4 ragender     "Female"
    local vlab5 2.race_eth   "NH Black"
    local vlab6 3.race_eth   "Hispanic"
    local vlab7 4.race_eth   "NH Other"
    * Add labels for additional controls if present
    if "`additional_ctrls'" != "" {
        local vlab_idx = 8
        foreach v of local additional_ctrls {
            if "`v'" == "married_2020" {
                local vlab`vlab_idx' married_2020 "Married"
            }
            else if "`v'" == "ln_resp_lab_inc_2020" {
                local vlab`vlab_idx' ln_resp_lab_inc_2020 "Log labor income"
            }
            else if "`v'" == "ln_resp_lab_inc" {
                local vlab`vlab_idx' ln_resp_lab_inc "Log labor income"
            }
            local vlab_idx = `vlab_idx' + 1
        }
        * Build varlabels string with all labels
        local vlab_all "`vlab1' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7'"
        forvalues i = 8/`=`vlab_idx'-1' {
            local vlab_all "`vlab_all' `vlab`i''"
        }
        * Add r15lbagr label if present (for spec 3)
        capture confirm variable r15lbagr
        if !_rc {
            local vlab`vlab_idx' r15lbagr "r15lbagr"
            local vlab_all "`vlab_all' `vlab`vlab_idx''"
            local vlab_idx = `vlab_idx' + 1
        }
        * Add spec 4 variable labels
        local vlab`vlab_idx' r15inlbrf "In labor force"
        local vlab_all "`vlab_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' h15aira "h15aira"
        local vlab_all "`vlab_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' r15cesd "r15cesd"
        local vlab_all "`vlab_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' r15conde "r15conde"
        local vlab_all "`vlab_all' `vlab`vlab_idx''"
    }
    else {
        local vlab_all "`vlab1' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7'"
        * Add r15lbagr label if present (for spec 3)
        capture confirm variable r15lbagr
        if !_rc {
            local vlab8 r15lbagr "r15lbagr"
            local vlab_all "`vlab_all' `vlab8'"
        }
        * Add spec 4 variable labels
        local vlab9 r15inlbrf "In labor force"
        local vlab_all "`vlab_all' `vlab9'"
        local vlab10 h15aira "h15aira"
        local vlab_all "`vlab_all' `vlab10'"
        local vlab11 r15cesd "r15cesd"
        local vlab_all "`vlab_all' `vlab11'"
        local vlab12 r15conde "r15conde"
        local vlab_all "`vlab_all' `vlab12'"
    }
    
    * Build addnote text
    local addnote_text "Robust SEs in parentheses; Age entered quadratically."
    if "`additional_ctrls'" != "" {
        local addnote_text "`addnote_text' Includes married status and log labor income (2020)."
    }
    
    esttab `t'_spec1 using "`outfile'", replace ///
        booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
        compress b(%9.3f) se(%9.3f) ///
        varlabels(`vlab_all') ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("Trust `t' on Controls") ///
        addnote("`addnote_text'")

    * Spec 2: add CAMS controls on RHS (export separate table)
    if "`cams_ctrls'" != "" {
        * Build condition for sample size check (same as spec1)
        local spec2_cond "`spec1_cond'"
        quietly count if `spec2_cond'
        if r(N) > 0 {
            eststo `t'_spec2: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' `cams_ctrls' ///
                if `spec2_cond', vce(robust)

            local outfile2 "`tables'/trust_cams_`t'_spec2.tex"
            di as txt "Exporting LaTeX table (spec 2): `outfile2'"
            * Build addnote for spec 2
            local addnote_text2 "Robust SEs in parentheses; Age entered quadratically; adds CAMS controls."
            if "`additional_ctrls'" != "" {
                local addnote_text2 "`addnote_text2' Includes married status and log labor income (2020)."
            }
            esttab `t'_spec2 using "`outfile2'", replace ///
                booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
                compress b(%9.3f) se(%9.3f) ///
                varlabels(`vlab_all') ///
                stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                title("Trust `t' on Controls + CAMS (Spec 2)") ///
                addnote("`addnote_text2'")
        }
    }

    * Spec 3: add r15lbagr control (export separate table)
    if "`spec3_ctrls'" != "" {
        * Build condition for sample size check (same as spec1_cond but also check r15lbagr)
        local spec3_cond "`spec1_cond'"
        capture confirm variable r15lbagr
        if !_rc {
            local spec3_cond "`spec3_cond' & !missing(r15lbagr)"
        }
        quietly count if `spec3_cond'
        if r(N) > 0 {
            eststo `t'_spec3: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `spec3_ctrls' ///
                if `spec3_cond', vce(robust)

            local outfile3 "`tables'/trust_cams_`t'_spec3.tex"
            di as txt "Exporting LaTeX table (spec 3): `outfile3'"
            * Build addnote for spec 3
            local addnote_text3 "Robust SEs in parentheses; Age entered quadratically; adds r15lbagr control."
            if "`additional_ctrls'" != "" {
                local addnote_text3 "`addnote_text3' Includes married status and log labor income (2020)."
            }
            esttab `t'_spec3 using "`outfile3'", replace ///
                booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
                compress b(%9.3f) se(%9.3f) ///
                varlabels(`vlab_all') ///
                stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                title("Trust `t' on Controls + r15lbagr (Spec 3)") ///
                addnote("`addnote_text3'")
        }
    }

    * Spec 4: add r15inlbrf + h15aira + r15cesd + r15conde (export separate table)
    if "`spec4_ctrls'" != "" {
        * Build condition for sample size check (spec1_cond + all spec4 variables)
        local spec4_cond "`spec1_cond' & !missing(r15inlbrf) & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde)"
        quietly count if `spec4_cond'
        if r(N) > 0 {
            eststo `t'_spec4: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `spec4_ctrls' ///
                if `spec4_cond', vce(robust)

            local outfile4 "`tables'/trust_cams_`t'_spec4.tex"
            di as txt "Exporting LaTeX table (spec 4): `outfile4'"
            * Build addnote for spec 4
            local addnote_text4 "Robust SEs in parentheses; Age entered quadratically; adds labor force, h15aira, r15cesd, r15conde."
            if "`additional_ctrls'" != "" {
                local addnote_text4 "`addnote_text4' Includes married status and log labor income (2020)."
            }
            esttab `t'_spec4 using "`outfile4'", replace ///
                booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
                compress b(%9.3f) se(%9.3f) ///
                varlabels(`vlab_all') ///
                stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                title("Trust `t' on Controls + Extended (Spec 4)") ///
                addnote("`addnote_text4'")
        }
    }
}

* ----------------------------------------------------------------------
* PCA of trust variables and regressions using PC1
* ----------------------------------------------------------------------
di as txt "=== PCA on trust variables (rv557-rv564) ==="

capture drop trust_pca1 trust_pca1_z trust_pca2 trust_pca2_z
capture noisily pca rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564, components(2)

if _rc==0 {
    * Proportion of variance explained by PC1 and PC2 (display only)
    capture matrix M = e(Prop)
    if _rc==0 {
        scalar pc1_prop = M[1,1]
        di as txt "PC1 variance proportion: " %6.3f pc1_prop
        capture scalar pc2_prop = M[1,2]
        if !_rc di as txt "PC2 variance proportion: " %6.3f pc2_prop
    }
    * Predict PC1 and PC2 scores and standardize
    predict double trust_pca1 trust_pca2 if e(sample), score
    egen double trust_pca1_z = std(trust_pca1)
    quietly count if !missing(trust_pca1_z)
    di as txt "Non-missing trust_pca1_z: " r(N)
    egen double trust_pca2_z = std(trust_pca2)
    quietly count if !missing(trust_pca2_z)
    di as txt "Non-missing trust_pca2_z: " r(N)

    eststo clear

    * Build condition for sample size checks (same for all PCA regressions)
    local pca_cond "!missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)"
    if "`additional_ctrls'" != "" {
        foreach v of local additional_ctrls {
            local pca_cond "`pca_cond' & !missing(`v')"
        }
    }

    * Basic controls only - PC1
    quietly count if !missing(trust_pca1_z) & `pca_cond'
    if r(N) > 0 {
        eststo pca_spec1: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' ///
            if !missing(trust_pca1_z) & `pca_cond', vce(robust)
    }

    * Spec 2 for PC1: add CAMS controls if available
    if "`cams_ctrls'" != "" {
        quietly count if !missing(trust_pca1_z) & `pca_cond'
        if r(N) > 0 {
            eststo pca_spec2: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' `cams_ctrls' ///
                if !missing(trust_pca1_z) & `pca_cond', vce(robust)
        }
    }

    * Same regression for PC2 if available - spec1
    quietly count if !missing(trust_pca2_z) & `pca_cond'
    if r(N) > 0 {
        eststo pca2_spec1: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' ///
            if !missing(trust_pca2_z) & `pca_cond', vce(robust)
    }

    * Spec 2 for PC2: add CAMS controls if available
    if "`cams_ctrls'" != "" {
        quietly count if !missing(trust_pca2_z) & `pca_cond'
        if r(N) > 0 {
            eststo pca2_spec2: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `additional_ctrls' `cams_ctrls' ///
                if !missing(trust_pca2_z) & `pca_cond', vce(robust)
        }
    }

    * Spec 3 for PC1: add r15lbagr control if available
    if "`spec3_ctrls'" != "" {
        * Build condition for spec 3 (pca_cond + r15lbagr check)
        local pca_spec3_cond "`pca_cond'"
        capture confirm variable r15lbagr
        if !_rc {
            local pca_spec3_cond "`pca_spec3_cond' & !missing(r15lbagr)"
        }
        quietly count if !missing(trust_pca1_z) & `pca_spec3_cond'
        if r(N) > 0 {
            eststo pca_spec3: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `spec3_ctrls' ///
                if !missing(trust_pca1_z) & `pca_spec3_cond', vce(robust)
        }
    }

    * Spec 3 for PC2: add r15lbagr control if available
    if "`spec3_ctrls'" != "" {
        * Build condition for spec 3 (pca_cond + r15lbagr check)
        local pca_spec3_cond "`pca_cond'"
        capture confirm variable r15lbagr
        if !_rc {
            local pca_spec3_cond "`pca_spec3_cond' & !missing(r15lbagr)"
        }
        quietly count if !missing(trust_pca2_z) & `pca_spec3_cond'
        if r(N) > 0 {
            eststo pca2_spec3: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `spec3_ctrls' ///
                if !missing(trust_pca2_z) & `pca_spec3_cond', vce(robust)
        }
    }

    * Spec 4 for PC1: add r15inlbrf + h15aira + r15cesd + r15conde
    if "`spec4_ctrls'" != "" {
        * Build condition for spec 4 (pca_cond + all spec4 variables)
        local pca_spec4_cond "`pca_cond' & !missing(r15inlbrf) & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde)"
        quietly count if !missing(trust_pca1_z) & `pca_spec4_cond'
        if r(N) > 0 {
            eststo pca_spec4: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `spec4_ctrls' ///
                if !missing(trust_pca1_z) & `pca_spec4_cond', vce(robust)
        }
    }

    * Spec 4 for PC2: add r15inlbrf + h15aira + r15cesd + r15conde
    if "`spec4_ctrls'" != "" {
        * Build condition for spec 4 (pca_cond + all spec4 variables)
        local pca_spec4_cond "`pca_cond' & !missing(r15inlbrf) & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde)"
        quietly count if !missing(trust_pca2_z) & `pca_spec4_cond'
        if r(N) > 0 {
            eststo pca2_spec4: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `spec4_ctrls' ///
                if !missing(trust_pca2_z) & `pca_spec4_cond', vce(robust)
        }
    }

    * Export PCA table
    local outfile_pca "`tables'/trust_cams_pca.tex"
    di as txt "Exporting LaTeX table: `outfile_pca'"
    
    * Check if PC1 proportion was computed
    capture scalar pc1_prop
    local pc1_str ""
    if !_rc {
        local pc1_str : display %6.3f pc1_prop
    }
    * Optionally include PC2 proportion in note if available
    capture scalar pc2_prop
    local pc2_str ""
    if !_rc {
        local pc2_str : display %6.3f pc2_prop
    }
    
    * Build addnote string
    local note_lines "Robust SEs in parentheses; Age entered quadratically."
    if "`additional_ctrls'" != "" {
        local note_lines "`note_lines'" "Includes married status and log labor income (2020)."
    }
    if "`pc1_str'" != "" {
        local note_lines "`note_lines'" "PC1 variance prop = `pc1_str'."
    }
    if "`pc2_str'" != "" {
        local note_lines "`note_lines'" " PC2 variance prop = `pc2_str'."
    }
    
    * Variable labels
    local vlab1 trust_pca1_z "Trust PC1"
    local vlab2 r15agey_b    "Age"
    local vlab3 c.r15agey_b#c.r15agey_b "Age\$^{2}\$"
    local vlab4 raedyrs      "Years of education"
    local vlab5 ragender     "Female"
    local vlab6 2.race_eth   "NH Black"
    local vlab7 3.race_eth   "Hispanic"
    local vlab8 4.race_eth   "NH Other"
    * Add labels for additional controls if present
    if "`additional_ctrls'" != "" {
        local vlab_idx = 9
        foreach v of local additional_ctrls {
            if "`v'" == "married_2020" {
                local vlab`vlab_idx' married_2020 "Married"
            }
            else if "`v'" == "ln_resp_lab_inc_2020" {
                local vlab`vlab_idx' ln_resp_lab_inc_2020 "Log labor income"
            }
            else if "`v'" == "ln_resp_lab_inc" {
                local vlab`vlab_idx' ln_resp_lab_inc "Log labor income"
            }
            local vlab_idx = `vlab_idx' + 1
        }
        * Build varlabels string with all labels
        local vlab_pca_all "`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8'"
        forvalues i = 9/`=`vlab_idx'-1' {
            local vlab_pca_all "`vlab_pca_all' `vlab`i''"
        }
        * Add r15lbagr label if present (for spec 3)
        capture confirm variable r15lbagr
        if !_rc {
            local vlab`vlab_idx' r15lbagr "r15lbagr"
            local vlab_pca_all "`vlab_pca_all' `vlab`vlab_idx''"
            local vlab_idx = `vlab_idx' + 1
        }
        * Add spec 4 variable labels
        local vlab`vlab_idx' r15inlbrf "In labor force"
        local vlab_pca_all "`vlab_pca_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' h15aira "h15aira"
        local vlab_pca_all "`vlab_pca_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' r15cesd "r15cesd"
        local vlab_pca_all "`vlab_pca_all' `vlab`vlab_idx''"
        local vlab_idx = `vlab_idx' + 1
        local vlab`vlab_idx' r15conde "r15conde"
        local vlab_pca_all "`vlab_pca_all' `vlab`vlab_idx''"
    }
    else {
        local vlab_pca_all "`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8'"
        * Add r15lbagr label if present (for spec 3)
        capture confirm variable r15lbagr
        if !_rc {
            local vlab9 r15lbagr "r15lbagr"
            local vlab_pca_all "`vlab_pca_all' `vlab9'"
        }
        * Add spec 4 variable labels
        local vlab10 r15inlbrf "In labor force"
        local vlab_pca_all "`vlab_pca_all' `vlab10'"
        local vlab11 h15aira "h15aira"
        local vlab_pca_all "`vlab_pca_all' `vlab11'"
        local vlab12 r15cesd "r15cesd"
        local vlab_pca_all "`vlab_pca_all' `vlab12'"
        local vlab13 r15conde "r15conde"
        local vlab_pca_all "`vlab_pca_all' `vlab13'"
    }
    
    esttab pca_spec1 using "`outfile_pca'", replace ///
        booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
        compress b(%9.3f) se(%9.3f) ///
        varlabels(`vlab_pca_all') ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("Trust PC1 on Controls") ///
        addnote(`note_lines')

    * Export PC1 spec 2 table if estimated
    capture estimates dir
    local has_pca1s2 = strpos(r(names), "pca_spec2")
    if `has_pca1s2' > 0 {
        local outfile_pca1s2 "`tables'/trust_cams_pca_spec2.tex"
        di as txt "Exporting LaTeX table: `outfile_pca1s2'"
        esttab pca_spec2 using "`outfile_pca1s2'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC1 on Controls + CAMS (Spec 2)") ///
            addnote(`note_lines')
    }

    * Export PC2 regression table if estimated
    capture estimates dir
    local has_pca2 = strpos(r(names), "pca2_spec1")
    if `has_pca2' > 0 {
        local outfile_pca2 "`tables'/trust_cams_pca2.tex"
        di as txt "Exporting LaTeX table: `outfile_pca2'"
        esttab pca2_spec1 using "`outfile_pca2'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls") ///
            addnote(`note_lines')
    }

    * Export PC2 spec 2 table if estimated
    capture estimates dir
    local has_pca2s2 = strpos(r(names), "pca2_spec2")
    if `has_pca2s2' > 0 {
        local outfile_pca2s2 "`tables'/trust_cams_pca2_spec2.tex"
        di as txt "Exporting LaTeX table: `outfile_pca2s2'"
        esttab pca2_spec2 using "`outfile_pca2s2'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls + CAMS (Spec 2)") ///
            addnote(`note_lines')
    }

    * Export PC1 spec 3 table if estimated
    capture estimates dir
    local has_pca1s3 = strpos(r(names), "pca_spec3")
    if `has_pca1s3' > 0 {
        local outfile_pca1s3 "`tables'/trust_cams_pca_spec3.tex"
        di as txt "Exporting LaTeX table: `outfile_pca1s3'"
        * Build addnote for spec 3
        local note_lines_s3 "Robust SEs in parentheses; Age entered quadratically; adds r15lbagr control."
        if "`additional_ctrls'" != "" {
            local note_lines_s3 "`note_lines_s3'" "Includes married status and log labor income (2020)."
        }
        if "`pc1_str'" != "" {
            local note_lines_s3 "`note_lines_s3'" "PC1 variance prop = `pc1_str'."
        }
        if "`pc2_str'" != "" {
            local note_lines_s3 "`note_lines_s3'" " PC2 variance prop = `pc2_str'."
        }
        esttab pca_spec3 using "`outfile_pca1s3'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC1 on Controls + r15lbagr (Spec 3)") ///
            addnote(`note_lines_s3')
    }

    * Export PC2 spec 3 table if estimated
    capture estimates dir
    local has_pca2s3 = strpos(r(names), "pca2_spec3")
    if `has_pca2s3' > 0 {
        local outfile_pca2s3 "`tables'/trust_cams_pca2_spec3.tex"
        di as txt "Exporting LaTeX table: `outfile_pca2s3'"
        * Build addnote for spec 3
        local note_lines_s3 "Robust SEs in parentheses; Age entered quadratically; adds r15lbagr control."
        if "`additional_ctrls'" != "" {
            local note_lines_s3 "`note_lines_s3'" "Includes married status and log labor income (2020)."
        }
        if "`pc1_str'" != "" {
            local note_lines_s3 "`note_lines_s3'" "PC1 variance prop = `pc1_str'."
        }
        if "`pc2_str'" != "" {
            local note_lines_s3 "`note_lines_s3'" " PC2 variance prop = `pc2_str'."
        }
        esttab pca2_spec3 using "`outfile_pca2s3'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls + r15lbagr (Spec 3)") ///
            addnote(`note_lines_s3')
    }

    * Export PC1 spec 4 table if estimated
    capture estimates dir
    local has_pca1s4 = strpos(r(names), "pca_spec4")
    if `has_pca1s4' > 0 {
        local outfile_pca1s4 "`tables'/trust_cams_pca_spec4.tex"
        di as txt "Exporting LaTeX table: `outfile_pca1s4'"
        * Build addnote for spec 4
        local note_lines_s4 "Robust SEs in parentheses; Age entered quadratically; adds labor force, h15aira, r15cesd, r15conde."
        if "`additional_ctrls'" != "" {
            local note_lines_s4 "`note_lines_s4'" "Includes married status and log labor income (2020)."
        }
        if "`pc1_str'" != "" {
            local note_lines_s4 "`note_lines_s4'" "PC1 variance prop = `pc1_str'."
        }
        if "`pc2_str'" != "" {
            local note_lines_s4 "`note_lines_s4'" " PC2 variance prop = `pc2_str'."
        }
        esttab pca_spec4 using "`outfile_pca1s4'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC1 on Controls + Extended (Spec 4)") ///
            addnote(`note_lines_s4')
    }

    * Export PC2 spec 4 table if estimated
    capture estimates dir
    local has_pca2s4 = strpos(r(names), "pca2_spec4")
    if `has_pca2s4' > 0 {
        local outfile_pca2s4 "`tables'/trust_cams_pca2_spec4.tex"
        di as txt "Exporting LaTeX table: `outfile_pca2s4'"
        * Build addnote for spec 4
        local note_lines_s4 "Robust SEs in parentheses; Age entered quadratically; adds labor force, h15aira, r15cesd, r15conde."
        if "`additional_ctrls'" != "" {
            local note_lines_s4 "`note_lines_s4'" "Includes married status and log labor income (2020)."
        }
        if "`pc1_str'" != "" {
            local note_lines_s4 "`note_lines_s4'" "PC1 variance prop = `pc1_str'."
        }
        if "`pc2_str'" != "" {
            local note_lines_s4 "`note_lines_s4'" " PC2 variance prop = `pc2_str'."
        }
        esttab pca2_spec4 using "`outfile_pca2s4'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls + Extended (Spec 4)") ///
            addnote(`note_lines_s4')
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed and tables exported."

log close

