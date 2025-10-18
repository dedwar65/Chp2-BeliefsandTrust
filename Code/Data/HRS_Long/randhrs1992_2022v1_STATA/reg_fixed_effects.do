*----------------------------------------------------------------------
* reg_fixed_effects.do
* Regression Set 3: Individual Fixed Effects
* Control for time-invariant individual heterogeneity
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_fixed_effects.log", replace text

set more off
log on

* Install estout package if not already installed
capture which estout
if _rc {
    ssc install estout, replace
}

di as txt "===================================================================="
di as txt "=== Regression Set 3: Individual Fixed Effects                   ==="
di as txt "===================================================================="
di as txt ""

* ---------------------------------------------------------------------
* Regression 3.1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 3.1: r_annual (including residential)"
di as txt "===================================================================="

* Load fresh data and create truly balanced panel for r_annual
use "_randhrs1992_2022v1_panel.dta", clear
xtset hhidpn year

* Generate age_sq first
gen age_sq = age^2

* Build the complete variable set that will be used in the regression
* Check for ANY missing values across ALL variables that xtreg will use
egen any_miss = rowmiss(r_annual age age_sq married inlbrf ///
    wealth_d2 wealth_d3 wealth_d4 wealth_d5 wealth_d6 ///
    wealth_d7 wealth_d8 wealth_d9 wealth_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 ///
    year_7 year_8 year_9 year_10 year_11)

* Drop any individual-year with ANY missing variable
drop if any_miss > 0

* Now require balanced panel: each individual must have exactly 11 rows
bysort hhidpn: gen n_obs = _N
keep if n_obs == 11

* Verify balance
quietly summarize n_obs
di as txt "Estimation sample: Min obs per id = " r(min) ", Max = " r(max) ", Mean = " r(mean)
drop n_obs any_miss

eststo clear
eststo reg3_1: xtreg r_annual age age_sq i.married i.inlbrf ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, fe vce(cluster hhidpn)

* Display fixed effects summary
di as txt "Fixed effects summary for regression 3.1:"
di as txt "Number of groups (individuals): " e(N_g)
di as txt "Average observations per group: " %6.2f e(g_avg)

* Predict and plot fixed effects
predict fe_hat, u
histogram fe_hat, title("Distribution of Individual Fixed Effects") ///
    subtitle("Regression 3.1: r_annual") ///
    xtitle("Fixed Effect Coefficient") ///
    ytitle("Density") ///
    normal
graph export "fixed_effects_hist_reg3_1.png", replace

* Summary statistics of fixed effects
summarize fe_hat, detail
di as txt "Fixed effects summary statistics:"
di as txt "Mean: " %8.4f r(mean)
di as txt "Std Dev: " %8.4f r(sd)
di as txt "Min: " %8.4f r(min)
di as txt "Max: " %8.4f r(max)
drop fe_hat

di as txt ""
di as txt "Note: raedyrs and born_us dropped (time-invariant)"
di as txt ""

* ---------------------------------------------------------------------
* Regression 3.2: r_annual_trim (including residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 3.2: r_annual_trim (including residential, trimmed)"
di as txt "===================================================================="

* Load fresh data and create truly balanced panel for r_annual_trim
use "_randhrs1992_2022v1_panel.dta", clear
xtset hhidpn year

* Generate age_sq first
gen age_sq = age^2

* Build the complete variable set that will be used in the regression
* Check for ANY missing values across ALL variables that xtreg will use
egen any_miss = rowmiss(r_annual_trim age age_sq married inlbrf ///
    wealth_d2 wealth_d3 wealth_d4 wealth_d5 wealth_d6 ///
    wealth_d7 wealth_d8 wealth_d9 wealth_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 ///
    year_7 year_8 year_9 year_10 year_11)

* Drop any individual-year with ANY missing variable
drop if any_miss > 0

* Now require balanced panel: each individual must have exactly 11 rows
bysort hhidpn: gen n_obs = _N
keep if n_obs == 11

* Verify balance
quietly summarize n_obs
di as txt "Estimation sample: Min obs per id = " r(min) ", Max = " r(max) ", Mean = " r(mean)
drop n_obs any_miss

eststo reg3_2: xtreg r_annual_trim age age_sq i.married i.inlbrf ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, fe vce(cluster hhidpn)

* Predict and plot fixed effects for regression 3.2
predict fe_hat, u
histogram fe_hat, title("Distribution of Individual Fixed Effects") ///
    subtitle("Regression 3.2: r_annual_trim") ///
    xtitle("Fixed Effect Coefficient") ///
    ytitle("Density") ///
    normal
graph export "fixed_effects_hist_reg3_2.png", replace
drop fe_hat

di as txt ""

* ---------------------------------------------------------------------
* Regression 3.3: r_annual_excl (excluding residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 3.3: r_annual_excl (excluding residential)"
di as txt "===================================================================="

* Load fresh data and create truly balanced panel for r_annual_excl
use "_randhrs1992_2022v1_panel.dta", clear
xtset hhidpn year

* Generate age_sq first
gen age_sq = age^2

* Build the complete variable set that will be used in the regression
* Check for ANY missing values across ALL variables that xtreg will use
egen any_miss = rowmiss(r_annual_excl age age_sq married inlbrf ///
    wealth_nonres_d2 wealth_nonres_d3 wealth_nonres_d4 wealth_nonres_d5 wealth_nonres_d6 ///
    wealth_nonres_d7 wealth_nonres_d8 wealth_nonres_d9 wealth_nonres_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 ///
    year_7 year_8 year_9 year_10 year_11)

* Drop any individual-year with ANY missing variable
drop if any_miss > 0

* Now require balanced panel: each individual must have exactly 11 rows
bysort hhidpn: gen n_obs = _N
keep if n_obs == 11

* Verify balance
quietly summarize n_obs
di as txt "Estimation sample: Min obs per id = " r(min) ", Max = " r(max) ", Mean = " r(mean)
drop n_obs any_miss

eststo reg3_3: xtreg r_annual_excl age age_sq i.married i.inlbrf ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, fe vce(cluster hhidpn)

* Predict and plot fixed effects for regression 3.3
predict fe_hat, u
histogram fe_hat, title("Distribution of Individual Fixed Effects") ///
    subtitle("Regression 3.3: r_annual_excl") ///
    xtitle("Fixed Effect Coefficient") ///
    ytitle("Density") ///
    normal
graph export "fixed_effects_hist_reg3_3.png", replace
drop fe_hat

di as txt ""

* ---------------------------------------------------------------------
* Regression 3.4: r_annual_excl_trim (excluding residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 3.4: r_annual_excl_trim (excluding residential, trimmed)"
di as txt "===================================================================="

* Load fresh data and create truly balanced panel for r_annual_excl_trim
use "_randhrs1992_2022v1_panel.dta", clear
xtset hhidpn year

* Generate age_sq first
gen age_sq = age^2

* Build the complete variable set that will be used in the regression
* Check for ANY missing values across ALL variables that xtreg will use
egen any_miss = rowmiss(r_annual_excl_trim age age_sq married inlbrf ///
    wealth_nonres_d2 wealth_nonres_d3 wealth_nonres_d4 wealth_nonres_d5 wealth_nonres_d6 ///
    wealth_nonres_d7 wealth_nonres_d8 wealth_nonres_d9 wealth_nonres_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 ///
    year_7 year_8 year_9 year_10 year_11)

* Drop any individual-year with ANY missing variable
drop if any_miss > 0

* Now require balanced panel: each individual must have exactly 11 rows
bysort hhidpn: gen n_obs = _N
keep if n_obs == 11

* Verify balance
quietly summarize n_obs
di as txt "Estimation sample: Min obs per id = " r(min) ", Max = " r(max) ", Mean = " r(mean)
drop n_obs any_miss

eststo reg3_4: xtreg r_annual_excl_trim age age_sq i.married i.inlbrf ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    risky_share year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, fe vce(cluster hhidpn)

* Predict and plot fixed effects for regression 3.4
predict fe_hat, u
histogram fe_hat, title("Distribution of Individual Fixed Effects") ///
    subtitle("Regression 3.4: r_annual_excl_trim") ///
    xtitle("Fixed Effect Coefficient") ///
    ytitle("Density") ///
    normal
graph export "fixed_effects_hist_reg3_4.png", replace
drop fe_hat

di as txt ""

* ---------------------------------------------------------------------
* Export results
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "=== Exporting Results                                            ==="
di as txt "===================================================================="

* Export to LaTeX table
esttab reg3_1 reg3_2 reg3_3 reg3_4 using "fixed_effects.tex", ///
    replace booktabs ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label compress ///
    drop(_cons) ///
    stats(N N_g r2_w r2_b r2_o, labels("Observations" "Number of groups" "R-sq within" "R-sq between" "R-sq overall")) ///
    title("Individual Fixed Effects Regressions") ///
    addnote("Clustered standard errors at individual level in parentheses" ///
            "*** p<0.01, ** p<0.05, * p<0.10" ///
            "Individual fixed effects included but not shown" ///
            "Time-invariant variables (raedyrs, born_us) dropped by fixed effects")

* Display results in log
esttab reg3_1 reg3_2 reg3_3 reg3_4, ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label compress ///
    stats(N N_g r2_w r2_b r2_o, labels("Observations" "Number of groups" "R-sq within" "R-sq between" "R-sq overall"))

di as txt ""
di as txt "===================================================================="
di as txt "=== Individual Fixed Effects Complete                            ==="
di as txt "===================================================================="

log off
log close

