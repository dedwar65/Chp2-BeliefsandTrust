*----------------------------------------------------------------------
* reg_explain_trust.do
* Cross-sectional OLS of 2020 trust variables on controls (Spec 5)
* Runs each trust variable on basic controls (age, education, gender, race) + extended controls
* Trust variables (LHS): rv557, rv558, rv559, rv560, rv561, rv562, rv563, rv564
* Controls: r15agey_b (quadratic), raedyrs, ragender, race_eth, married_2020, h15aira, r15cesd, r15conde, r15govmr, r15govmd, r15lifein, r15beqany, r15mdiv, r15mwid
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_explain_trust.log", replace text

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

* Additional controls: married status
local additional_ctrls ""

* Check for married_2020
capture confirm variable married_2020
if !_rc {
    local additional_ctrls "married_2020"
    di as txt "Married status (married_2020) included"
}

if "`additional_ctrls'" != "" {
    di as txt "Additional controls included: `additional_ctrls'"
}
di as txt ""

* Spec 5 controls: additional_ctrls + h15aira + r15cesd + r15conde + r15govmr + r15govmd + r15lifein + r15beqany + r15mdiv + r15mwid
local spec5_ctrls ""
if "`additional_ctrls'" != "" {
    local spec5_ctrls "`additional_ctrls' h15aira r15cesd r15conde r15govmr r15govmd r15lifein r15beqany r15mdiv r15mwid"
}
else {
    local spec5_ctrls "h15aira r15cesd r15conde r15govmr r15govmd r15lifein r15beqany r15mdiv r15mwid"
}

if "`spec5_ctrls'" != "" {
    di as txt "Spec 5 controls: `spec5_ctrls'"
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

    * Spec 5: add h15aira + r15cesd + r15conde + r15govmr + r15govmd + r15lifein + r15beqany + r15mdiv + r15mwid (export separate table)
    if "`spec5_ctrls'" != "" {
        * Build condition for sample size check (basic controls + all spec5 variables)
        local spec5_cond "!missing(`t') & !missing(r15agey_b) & !missing(raedyrs) & !missing(ragender)"
        if "`additional_ctrls'" != "" {
            foreach v of local additional_ctrls {
                local spec5_cond "`spec5_cond' & !missing(`v')"
            }
        }
        local spec5_cond "`spec5_cond' & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde) & !missing(r15govmr) & !missing(r15govmd) & !missing(r15lifein) & !missing(r15beqany) & !missing(r15mdiv) & !missing(r15mwid)"
        quietly count if `spec5_cond'
        if r(N) > 0 {
            eststo `t'_spec5: regress `t' `age_quad' `education_var' `gender_factor' `race_factor' `spec5_ctrls' ///
                if `spec5_cond', vce(robust)

            local outfile5 "`tables'/trust_`t'_spec5.tex"
            di as txt "Exporting LaTeX table (spec 5): `outfile5'"
            
            * Create trust variable label for title
            local trust_title ""
            if "`t'" == "rv557" local trust_title "Trust in others - 557"
            else if "`t'" == "rv558" local trust_title "Trust in Social Security - 558"
            else if "`t'" == "rv559" local trust_title "Trust in Medicare/Medicaid - 559"
            else if "`t'" == "rv560" local trust_title "Trust in Banks - 560"
            else if "`t'" == "rv561" local trust_title "Trust in Financial Advisors - 561"
            else if "`t'" == "rv562" local trust_title "Trust in Mutual Funds - 562"
            else if "`t'" == "rv563" local trust_title "Trust in Insurance Companies - 563"
            else if "`t'" == "rv564" local trust_title "Trust in Mass Media - 564"
            else local trust_title "Trust `t'"
            
            * Variable labels (LaTeX-safe)
            local vlab_all ///
                r15agey_b "Age" ///
                c.r15agey_b#c.r15agey_b "Age$^{2}$" ///
                raedyrs "Years of education" ///
                2.ragender "Female" ///
                2.race_eth "NH Black" ///
                3.race_eth "Hispanic" ///
                4.race_eth "NH Other"
            if "`additional_ctrls'" != "" {
                foreach v of local additional_ctrls {
                    if "`v'" == "married_2020" {
                        local vlab_all `"`vlab_all' married_2020 "Married""'
                    }
                }
            }
            local vlab_all `"`vlab_all' h15aira "IRA wealth" r15cesd "Depression" r15conde "Health conditions" r15govmr "Covered by Medicare" r15govmd "Covered by Medicaid" r15lifein "Has life insurance" r15beqany "Prob. of leaving any bequest" r15mdiv "Number of reported divorces" r15mwid "Number of reported times being widowed""'
            
            * Build addnote for spec 5
            local addnote_text5 "Robust SEs in parentheses"
            esttab `t'_spec5 using "`outfile5'", replace ///
                booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
                compress b(%9.3f) se(%9.3f) ///
                varlabels(`vlab_all') ///
                drop(1.ragender 1.race_eth) ///
                stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
                title("`trust_title' on Controls + Extended (Spec 5)") ///
                addnote("`addnote_text5'")
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

    * Spec 5 for PC1: add h15aira + r15cesd + r15conde + r15govmr + r15govmd + r15lifein + r15beqany + r15mdiv + r15mwid
    if "`spec5_ctrls'" != "" {
        * Build condition for spec 5 (pca_cond + all spec5 variables)
        local pca_spec5_cond "`pca_cond' & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde) & !missing(r15govmr) & !missing(r15govmd) & !missing(r15lifein) & !missing(r15beqany) & !missing(r15mdiv) & !missing(r15mwid)"
        quietly count if !missing(trust_pca1_z) & `pca_spec5_cond'
        if r(N) > 0 {
            eststo pca_spec5: regress trust_pca1_z `age_quad' `education_var' `gender_factor' `race_factor' `spec5_ctrls' ///
                if !missing(trust_pca1_z) & `pca_spec5_cond', vce(robust)
        }
    }

    * Spec 5 for PC2: add h15aira + r15cesd + r15conde + r15govmr + r15govmd + r15lifein + r15beqany + r15mdiv + r15mwid
    if "`spec5_ctrls'" != "" {
        * Build condition for spec 5 (pca_cond + all spec5 variables)
        local pca_spec5_cond "`pca_cond' & !missing(h15aira) & !missing(r15cesd) & !missing(r15conde) & !missing(r15govmr) & !missing(r15govmd) & !missing(r15lifein) & !missing(r15beqany) & !missing(r15mdiv) & !missing(r15mwid)"
        quietly count if !missing(trust_pca2_z) & `pca_spec5_cond'
        if r(N) > 0 {
            eststo pca2_spec5: regress trust_pca2_z `age_quad' `education_var' `gender_factor' `race_factor' `spec5_ctrls' ///
                if !missing(trust_pca2_z) & `pca_spec5_cond', vce(robust)
        }
    }

    * Export PCA table
    local outfile_pca "`tables'/trust_pca_spec5.tex"
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
    
    * Build addnote string (same format as individual trust tables)
    local addnote_text5 "Robust SEs in parentheses"
    
    * Variable labels
    local vlab_pca_all ///
        r15agey_b "Age" ///
        c.r15agey_b#c.r15agey_b "Age$^{2}$" ///
        raedyrs "Years of education" ///
        2.ragender "Female" ///
        2.race_eth "NH Black" ///
        3.race_eth "Hispanic" ///
        4.race_eth "NH Other"
    if "`additional_ctrls'" != "" {
        foreach v of local additional_ctrls {
            if "`v'" == "married_2020" {
                local vlab_pca_all `"`vlab_pca_all' married_2020 "Married""'
            }
        }
    }
    local vlab_pca_all `"`vlab_pca_all' h15aira "IRA wealth" r15cesd "Depression" r15conde "Health conditions" r15govmr "Covered by Medicare" r15govmd "Covered by Medicaid" r15lifein "Has life insurance" r15beqany "Prob. of leaving any bequest" r15mdiv "Number of reported divorces" r15mwid "Number of reported times being widowed""'
    
    * Export PC1 spec 5 table if estimated
    capture estimates dir
    local has_pca1s5 = strpos(r(names), "pca_spec5")
    if `has_pca1s5' > 0 {
        esttab pca_spec5 using "`outfile_pca'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            drop(1.ragender 1.race_eth) ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC1 on Controls + Extended (Spec 5)") ///
            addnote("`addnote_text5'")
    }

    * Export PC2 spec 5 table if estimated
    capture estimates dir
    local has_pca2s5 = strpos(r(names), "pca2_spec5")
    if `has_pca2s5' > 0 {
        local outfile_pca2 "`tables'/trust_pca2_spec5.tex"
        di as txt "Exporting LaTeX table: `outfile_pca2'"
        esttab pca2_spec5 using "`outfile_pca2'", replace ///
            booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
            compress b(%9.3f) se(%9.3f) ///
            varlabels(`vlab_pca_all') ///
            drop(1.ragender 1.race_eth) ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Trust PC2 on Controls + Extended (Spec 5)") ///
            addnote("`addnote_text5'")
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

di as txt "All regressions completed and tables exported."

log close

