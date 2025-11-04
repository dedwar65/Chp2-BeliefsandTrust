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

* CAMS 2021 controls (conditionally include those present) — Spec 2 RHS
local cams_ctrls ""
foreach v in cams_showaffect_2021 cams_helpothers_2021 cams_volunteer_2021 cams_religattend_2021 cams_meetings_2021 {
    capture confirm variable `v'
    if !_rc local cams_ctrls "`cams_ctrls' `v'"
}
if "`cams_ctrls'" != "" {
    di as txt "CAMS controls included: `cams_ctrls'"
}

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
    quietly count if !missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
    if r(N) > 0 {
        eststo `t'_spec1: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' ///
            if !missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)
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
    
    esttab `t'_spec1 using "`outfile'", replace ///
        booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
        compress b(%9.3f) se(%9.3f) ///
        varlabels(`vlab1' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7') ///
        stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
        title("Trust `t' on Controls") ///
        addnote("Robust SEs in parentheses; Age entered quadratically.")

    * Spec 2: add CAMS controls on RHS (export separate table)
    if "`cams_ctrls'" != "" {
        quietly count if !missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
        if r(N) > 0 {
            eststo `t'_spec2: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `cams_ctrls' ///
                if !missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)

            local outfile2 "`tables'/trust_cams_`t'_spec2.tex"
            di as txt "Exporting LaTeX table (spec 2): `outfile2'"
            esttab `t'_spec2 using "`outfile2'", replace ///
                booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
                compress b(%9.3f) se(%9.3f) ///
                varlabels(`vlab1' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7') ///
                stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                title("Trust `t' on Controls + CAMS (Spec 2)") ///
                addnote("Robust SEs in parentheses; Age entered quadratically; adds CAMS controls.")
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

    * Basic controls only
    quietly count if !missing(trust_pca1_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
    if r(N) > 0 {
        eststo pca_spec1: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' ///
            if !missing(trust_pca1_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)
    }

    * Spec 2 for PC1: add CAMS controls if available
    if "`cams_ctrls'" != "" {
        quietly count if !missing(trust_pca1_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
        if r(N) > 0 {
            eststo pca_spec2: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `cams_ctrls' ///
                if !missing(trust_pca1_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)
        }
    }

    * Same regression for PC2 if available
    quietly count if !missing(trust_pca2_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
    if r(N) > 0 {
        eststo pca2_spec1: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' ///
            if !missing(trust_pca2_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)
    }

    * Spec 2 for PC2: add CAMS controls if available
    if "`cams_ctrls'" != "" {
        quietly count if !missing(trust_pca2_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)
        if r(N) > 0 {
            eststo pca2_spec2: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `cams_ctrls' ///
                if !missing(trust_pca2_z) & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender), vce(robust)
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
    
    esttab pca_spec1 using "`outfile_pca'", replace ///
        booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
        compress b(%9.3f) se(%9.3f) ///
        varlabels(`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
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
            varlabels(`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
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
            varlabels(`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
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
            varlabels(`vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls + CAMS (Spec 2)") ///
            addnote(`note_lines')
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed and tables exported."

log close

