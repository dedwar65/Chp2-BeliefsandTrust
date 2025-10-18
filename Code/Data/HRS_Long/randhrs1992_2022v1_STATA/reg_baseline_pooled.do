*----------------------------------------------------------------------
* reg_baseline_pooled.do
* Regression Set 1: Baseline Pooled OLS
* Panel regressions of returns on demographics and wealth controls
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_baseline_pooled.log", replace text

set more off
log on

* Install estout package if not already installed
capture which estout
if _rc {
    ssc install estout, replace
}

di as txt "===================================================================="
di as txt "=== Regression Set 1: Baseline Pooled OLS                       ==="
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
di as txt ""

* Check what variables exist
di as txt "Checking available variables..."
describe r_annual*, short
describe wealth_d*, short
describe wealth_nonres_d*, short
di as txt ""

* Check for missing values in key variables
di as txt "Checking for missing values..."
count if missing(r_annual)
di as txt "Missing r_annual: " r(N)
count if missing(wealth_d2)
di as txt "Missing wealth_d2: " r(N)
count if missing(raedyrs)
di as txt "Missing raedyrs: " r(N)
count if missing(born_us)
di as txt "Missing born_us: " r(N)
di as txt ""

* Check year variable
tab year, missing
di as txt ""

* ---------------------------------------------------------------------
* Regression 1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.1: r_annual (including residential)"
di as txt "===================================================================="

* Check if required variables exist
capture confirm variable r_annual
if _rc {
    di as error "ERROR: r_annual not found"
    exit 198
}

capture confirm variable wealth_d2
if _rc {
    di as error "ERROR: wealth_d2 not found"
    exit 198
}


eststo clear
eststo reg1_1: reg r_annual age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 2: r_annual_trim (including residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.2: r_annual_trim (including residential, trimmed)"
di as txt "===================================================================="

eststo reg1_2: reg r_annual_trim age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 3: r_annual_excl (excluding residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.3: r_annual_excl (excluding residential)"
di as txt "===================================================================="

eststo reg1_3: reg r_annual_excl age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 4: r_annual_excl_trim (excluding residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.4: r_annual_excl_trim (excluding residential, trimmed)"
di as txt "===================================================================="

eststo reg1_4: reg r_annual_excl_trim age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Export results
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Exporting results to baseline_pooled.tex"
di as txt "===================================================================="

esttab reg1_1 reg1_2 reg1_3 reg1_4 using "baseline_pooled.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs compress nogaps ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared")) ///
    title("Baseline Pooled OLS Regressions") ///
    addnote("Clustered standard errors at individual level in parentheses" ///
            "*** p<0.01, ** p<0.05, * p<0.10" ///
            "Columns (1)-(2): Returns including residential wealth; Columns (3)-(4): Returns excluding residential wealth" ///
            "Wealth deciles: d1 (lowest) is reference category")

* Display results in log
esttab reg1_1 reg1_2 reg1_3 reg1_4, ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label compress ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared"))

di as txt ""
di as txt "===================================================================="
di as txt "=== Baseline Pooled OLS Complete                                 ==="
di as txt "===================================================================="

log off
di as txt "Log file closed."
log close

