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
* Load panel dataset
* ---------------------------------------------------------------------
use "_randhrs1992_2022v1_panel.dta", clear

* Restrict to balanced panel: keep only individuals with non-missing returns in ALL waves
di as txt "Initial sample size: " %9.0f _N

* Check which years are in the dataset
quietly summarize year
local min_year = r(min)
local max_year = r(max)
di as txt "Years in dataset: `min_year' to `max_year'"

* Count how many years each individual has non-missing r_annual
bysort hhidpn: egen n_nonmissing_returns = count(r_annual) if !missing(r_annual)

* Count total years per individual
bysort hhidpn: gen n_total_years = _N

* Check if individual has returns in ALL years
gen has_all_returns = (n_nonmissing_returns == n_total_years)

* Keep only individuals with returns in ALL years
keep if has_all_returns == 1
di as txt "After keeping only individuals with returns in ALL years: " %9.0f _N

* Count unique individuals
quietly bysort hhidpn: gen tag = _n == 1
quietly count if tag == 1
local n_individuals = r(N)
di as txt "Number of unique individuals in balanced panel: " %9.0f `n_individuals'
drop tag n_nonmissing_returns n_total_years has_all_returns

* Set panel structure
xtset hhidpn year

* Generate age squared
gen age_sq = age^2
label var age_sq "Age squared"

di as txt "Panel structure set: hhidpn (individual) x year (time)"
di as txt "Observations: " _N
di as txt "Individuals: " r(N_g)
di as txt ""

* ---------------------------------------------------------------------
* Regression 3.1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 3.1: r_annual (including residential)"
di as txt "===================================================================="

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
di as txt "Exporting results to fixed_effects.tex"
di as txt "===================================================================="

esttab reg3_1 reg3_2 reg3_3 reg3_4 using "fixed_effects.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs compress nogaps ///
    stats(N N_g r2_w r2_b r2_o, labels("Observations" "Individuals" "Within R-sq" "Between R-sq" "Overall R-sq")) ///
    title("Individual Fixed Effects Regressions") ///
    addnote("Clustered standard errors at individual level in parentheses" ///
            "*** p<0.01, ** p<0.05, * p<0.10" ///
            "Individual fixed effects control for time-invariant heterogeneity" ///
            "Time-invariant variables (raedyrs, born_us) automatically dropped")

* Display results in log
esttab reg3_1 reg3_2 reg3_3 reg3_4, ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label compress ///
    stats(N N_g r2_w r2_b r2_o, labels("Observations" "Individuals" "Within R-sq" "Between R-sq" "Overall R-sq"))

di as txt ""
di as txt "===================================================================="
di as txt "=== Individual Fixed Effects Complete                            ==="
di as txt "===================================================================="

log off
log close

