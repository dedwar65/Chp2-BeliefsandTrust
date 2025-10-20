*----------------------------------------------------------------------
* reg_ret_trust_2020.do
* Cross-sectional OLS of 2022 returns on 2020 trust variables (Longitudinal dataset)
* Runs each return measure on each trust variable, with and without controls
* Returns: r_annual_2022, r_annual_trim_2022, r_annual_excl_2022, r_annual_excl_trim_2022
* Controls: r15agey_b, raedyrs, r15inlbrf, married_2020, born_us, wealth deciles (wealth_d2..wealth_d10 if present)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_ret_trust_2020.log", replace text

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

* Trust variables (2020)
local trust_vars "rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564"

* Return variables: annual and trimmed (with and without residential)
local ret_vars "r_annual_2022 r_annual_trim_2022 r_annual_excl_2022 r_annual_excl_trim_2022"

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

* Build controls actually present; exclude age from ctrl_in and add age as quadratic separately
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
di as txt "Controls included: `ctrl_in' with age quadratic if available"

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
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        * Shorten model name to avoid Stata's 32-char limit with _est_ prefix
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_2022","22",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "`t'_raw_`yshort'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' if !missing(`y') & !missing(`t'), vce(robust)
        local models_raw "`models_raw' `mname'"
    }

    * With controls
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        * Shorten model name to avoid Stata's 32-char limit with _est_ prefix
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_2022","22",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "`t'_ctl_`yshort'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' `age_quad' `ctrl_in' if !missing(`y') & !missing(`t'), vce(robust)
        local models_ctl "`models_ctl' `mname'"
    }

    * Export table for this trust variable
    local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
    local outfile "`tables'/trust_`t'_returns.tex"
    di as txt "Exporting LaTeX table: `outfile'"
    if "`models_raw'`models_ctl'" != "" {
        * Short, human column titles for 8 models
        local mt "Annual" "Annual (trim)" "Excl. res" "Excl. res (trim)" "Annual +C" "Annual (trim) +C" "Excl. res +C" "Excl. res (trim) +C"
        
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
            mtitles("Annual" "Annual (trim)" "Excl. res." "Excl. res. (trim)" ///
                    "Annual" "Annual (trim)" "Excl. res." "Excl. res. (trim)") ///
            posthead("& \multicolumn{4}{c}{No controls} & \multicolumn{4}{c}{With controls} \\\\ \cmidrule(lr){2-5}\cmidrule(lr){6-9}") ///
            varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Returns (2022) on Trust `t'") ///
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
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        * Shorten model name as above
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_2022","22",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "pca_raw_`yshort'"
        eststo `mname': regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z if !missing(`y') & !missing(trust_pca1_z), vce(robust)
        local models_pca_raw "`models_pca_raw' `mname'"
    }

    * With controls
    foreach y of local ret_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_z)
        if r(N)==0 continue
        * Shorten model name as above
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_2022","22",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "pca_ctl_`yshort'"
        eststo `mname': regress `y' c.trust_pca1_z c.trust_pca1_z#c.trust_pca1_z `age_quad' `ctrl_in' if !missing(`y') & !missing(trust_pca1_z), vce(robust)
        local models_pca_ctl "`models_pca_ctl' `mname'"
    }

    * Export PCA table
    local outfile_pca "`tables'/trust_pca_returns.tex"
    di as txt "Exporting LaTeX table: `outfile_pca'"
    if "`models_pca_raw'`models_pca_ctl'" != "" {
        local pc1_str : display %6.3f pc1_prop
        
        * Short, human column titles for 8 models
        local mt "Annual" "Annual (trim)" "Excl. res" "Excl. res (trim)" "Annual +C" "Annual (trim) +C" "Excl. res +C" "Excl. res (trim) +C"
        
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
            mtitles("Annual" "Annual (trim)" "Excl. res." "Excl. res. (trim)" ///
                    "Annual" "Annual (trim)" "Excl. res." "Excl. res. (trim)") ///
            posthead("& \multicolumn{4}{c}{No controls} & \multicolumn{4}{c}{With controls} \\\\ \cmidrule(lr){2-5}\cmidrule(lr){6-9}") ///
            varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
            stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
            title("Returns (2022) on Trust PC1") ///
            addnote("Robust SEs in parentheses; Age entered quadratically when available." "Controls (when included): raedyrs, in labor force, married, born in U.S." "PC1 variance prop = `pc1_str'")
    }
    else {
        di as warn "No PCA models estimated; skipping export."
    }
}
else {
    di as error "PCA failed; trust PCA regressions skipped."
}

* ----------------------------------------------------------------------
* Average Returns Regressions (2002-2022 average on 2020 trust)
* ----------------------------------------------------------------------
di as txt "=== Average Returns Regressions (2002-2022 average on 2020 trust) ==="

* Average return variables
local ret_avg_vars "r_annual_avg r_annual_trim_avg r_annual_excl_avg r_annual_excl_trim_avg"

* Quick overlap diagnostics for sample sizes
quietly count
local N_all = r(N)
di as txt "=== Quick overlap check: r_annual_avg and rv557 ==="
quietly count if !missing(r_annual_avg)
di as txt "  Non-missing r_annual_avg: " r(N) " of " `N_all'
quietly count if !missing(rv557)
di as txt "  Non-missing rv557:          " r(N) " of " `N_all'
quietly count if !missing(r_annual_avg) & !missing(rv557)
di as txt "  Non-missing both:           " r(N) " of " `N_all'
di as txt ""

* ----------------------------------------------------------------------
* Individual trust variables regressions with average returns
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
    foreach y of local ret_avg_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        * Shorten model name to avoid Stata's 32-char limit with _est_ prefix
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_avg","avg",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "`t'_raw_`yshort'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' if !missing(`y') & !missing(`t'), vce(robust)
        local models_raw "`models_raw' `mname'"
    }

    * With controls
    foreach y of local ret_avg_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(`t')
        if r(N)==0 continue
        * Shorten model name to avoid Stata's 32-char limit with _est_ prefix
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_avg","avg",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "`t'_ctl_`yshort'"
        eststo `mname': regress `y' c.`t' c.`t'#c.`t' `age_quad' `ctrl_in' if !missing(`y') & !missing(`t'), vce(robust)
        local models_ctl "`models_ctl' `mname'"
    }

    * Export table for this trust variable
    local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
    local outfile "`tables'/trust_`t'_returns_avg.tex"
    di as txt "Exporting LaTeX table: `outfile'"
    if "`models_raw'`models_ctl'" != "" {
        * Short, human column titles for 8 models
        local mt "Avg Annual" "Avg Annual (trim)" "Avg Excl. res" "Avg Excl. res (trim)" "Avg Annual +C" "Avg Annual (trim) +C" "Avg Excl. res +C" "Avg Excl. res (trim) +C"
        
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
             mtitles("Avg Annual" "Avg Annual (trim)" "Avg Excl. res." "Avg Excl. res. (trim)" ///
                     "Avg Annual" "Avg Annual (trim)" "Avg Excl. res." "Avg Excl. res. (trim)") ///
             posthead("& \multicolumn{4}{c}{No controls} & \multicolumn{4}{c}{With controls} \\\\ \cmidrule(lr){2-5}\cmidrule(lr){6-9}") ///
             varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
             stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
             title("Average Returns (2002-2022) on Trust `t'") ///
             addnote("Robust SEs in parentheses; Age entered quadratically when available." "Controls (when included): raedyrs, in labor force, married, born in U.S.")
    }
    else {
        di as warn "No models estimated for trust var `t'; skipping export."
    }
}

* ----------------------------------------------------------------------
* PCA of trust variables with average returns
* ----------------------------------------------------------------------
di as txt "=== PCA on trust variables with average returns ==="
capture drop trust_pca1_avg trust_pca1_avg_z
capture noisily pca rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564, components(1)
if _rc==0 {
    * Proportion of variance explained by PC1 (display only)
    capture matrix M = e(Prop)
    if _rc==0 {
        scalar pc1_prop_avg = M[1,1]
        di as txt "PC1 variance proportion: " %6.3f pc1_prop_avg
    }
    predict double trust_pca1_avg if e(sample), score
    egen double trust_pca1_avg_z = std(trust_pca1_avg)
    quietly count if !missing(trust_pca1_avg_z)
    di as txt "Non-missing trust_pca1_avg_z: " r(N)

    eststo clear
    local models_pca_raw ""
    local models_pca_ctl ""

    * RAW
    foreach y of local ret_avg_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_avg_z)
        if r(N)==0 continue
        * Shorten model name as above
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_avg","avg",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "pca_raw_`yshort'"
        eststo `mname': regress `y' c.trust_pca1_avg_z c.trust_pca1_avg_z#c.trust_pca1_avg_z if !missing(`y') & !missing(trust_pca1_avg_z), vce(robust)
        local models_pca_raw "`models_pca_raw' `mname'"
    }

    * With controls
    foreach y of local ret_avg_vars {
        capture confirm variable `y'
        if _rc continue
        quietly count if !missing(`y') & !missing(trust_pca1_avg_z)
        if r(N)==0 continue
        * Shorten model name as above
        local yshort = "`y'"
        local yshort = subinstr("`yshort'","r_annual_","rA",.)
        local yshort = subinstr("`yshort'","_avg","avg",.)
        local yshort = subinstr("`yshort'","excl","e",.)
        local yshort = subinstr("`yshort'","trim","t",.)
        local yshort = subinstr("`yshort'","_","",.)
        local mname = "pca_ctl_`yshort'"
        eststo `mname': regress `y' c.trust_pca1_avg_z c.trust_pca1_avg_z#c.trust_pca1_avg_z `age_quad' `ctrl_in' if !missing(`y') & !missing(trust_pca1_avg_z), vce(robust)
        local models_pca_ctl "`models_pca_ctl' `mname'"
    }

    * Export PCA table
    local outfile_pca_avg "`tables'/trust_pca_returns_avg.tex"
    di as txt "Exporting LaTeX table: `outfile_pca_avg'"
    if "`models_pca_raw'`models_pca_ctl'" != "" {
        local pc1_str_avg : display %6.3f pc1_prop_avg
        
        * Short, human column titles for 8 models
        local mt "Avg Annual" "Avg Annual (trim)" "Avg Excl. res" "Avg Excl. res (trim)" "Avg Annual +C" "Avg Annual (trim) +C" "Avg Excl. res +C" "Avg Excl. res (trim) +C"
        
        * Short row names (LaTeX-safe)
        local vlab trust_pca1_avg_z         "Trust PC1"
        local vlab2 c.trust_pca1_avg_z#c.trust_pca1_avg_z "Trust PC1\$^{2}\$"
        local vlab3 r15agey_b    "Age"
        local vlab4 c.r15agey_b#c.r15agey_b "Age\$^{2}\$"
        local vlab5 raedyrs      "Years of education"
        local vlab6 r15inlbrf    "In labor force"
        local vlab7 married_2020 "Married"
        local vlab8 born_us      "Born in U.S."
        
         esttab `models_pca_raw' `models_pca_ctl' using "`outfile_pca_avg'", replace ///
             booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
             compress b(%9.3f) se(%9.3f) ///
             mtitles("Avg Annual" "Avg Annual (trim)" "Avg Excl. res." "Avg Excl. res. (trim)" ///
                     "Avg Annual" "Avg Annual (trim)" "Avg Excl. res." "Avg Excl. res. (trim)") ///
             posthead("& \multicolumn{4}{c}{No controls} & \multicolumn{4}{c}{With controls} \\\\ \cmidrule(lr){2-5}\cmidrule(lr){6-9}") ///
             varlabels(`vlab' `vlab2' `vlab3' `vlab4' `vlab5' `vlab6' `vlab7' `vlab8') ///
             stats(N r2_a, labels("Observations" "Adj. R-squared")) ///
             title("Average Returns (2002-2022) on Trust PC1") ///
             addnote("Robust SEs in parentheses; Age entered quadratically when available." "Controls (when included): raedyrs, in labor force, married, born in U.S." "PC1 variance prop = `pc1_str_avg'")
    }
    else {
        di as warn "No PCA models estimated; skipping export."
    }
}
else {
    di as error "PCA failed; trust PCA regressions with average returns skipped."
}

di as txt "All regressions completed and tables exported."

log close

