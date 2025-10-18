*----------------------------------------------------------------------
* reg_shares_interacted.do
* Regression Set 2: Asset Shares × Year Interactions
* Test whether asset share effects vary over time
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_shares_interacted.log", replace text

set more off
log on

* Install estout package if not already installed
capture which estout
if _rc {
    ssc install estout, replace
}

di as txt "===================================================================="
di as txt "=== Regression Set 2: Asset Shares × Year Interactions          ==="
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

* ---------------------------------------------------------------------
* Regression 2.1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 2.1: r_annual (including residential)"
di as txt "===================================================================="

eststo clear
eststo reg2_1: reg r_annual age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    c.share_stk##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bond##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_re##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_ira##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bus##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    liability_share, vce(cluster hhidpn)

* Joint F-tests for asset shares
di as txt ""
di as txt "--- Joint F-tests: Testing equality of coefficients across years ---"
di as txt ""

* Note: These tests check if the interaction coefficients are jointly different from zero
* which tests whether asset share effects vary significantly across years

di as txt "Test 1: Stock share (main and interactions)"
quietly test c.share_stk
local fstat_stk = r(F)
local p_stk = r(p)
di as txt "F-statistic: " %6.2f `fstat_stk' "  p-value: " %6.4f `p_stk'

di as txt ""
di as txt "Test 2: Bond share (main and interactions)"
quietly test c.share_bond
local fstat_bond = r(F)
local p_bond = r(p)
di as txt "F-statistic: " %6.2f `fstat_bond' "  p-value: " %6.4f `p_bond'

di as txt ""
di as txt "Test 3: Real estate share (main and interactions)"
quietly test c.share_re
local fstat_re = r(F)
local p_re = r(p)
di as txt "F-statistic: " %6.2f `fstat_re' "  p-value: " %6.4f `p_re'

di as txt ""
di as txt "Test 4: IRA share (main and interactions)"
quietly test c.share_ira
local fstat_ira = r(F)
local p_ira = r(p)
di as txt "F-statistic: " %6.2f `fstat_ira' "  p-value: " %6.4f `p_ira'

di as txt ""
di as txt "Test 5: Business share (main and interactions)"
quietly test c.share_bus
local fstat_bus = r(F)
local p_bus = r(p)
di as txt "F-statistic: " %6.2f `fstat_bus' "  p-value: " %6.4f `p_bus'

di as txt ""

* ---------------------------------------------------------------------
* Regression 2.2: r_annual_trim (including residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 2.2: r_annual_trim (including residential, trimmed)"
di as txt "===================================================================="

eststo reg2_2: reg r_annual_trim age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    c.share_stk##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bond##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_re##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_ira##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bus##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    liability_share, vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 2.3: r_annual_excl (excluding residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 2.3: r_annual_excl (excluding residential)"
di as txt "===================================================================="

eststo reg2_3: reg r_annual_excl age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    c.share_stk##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bond##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_re##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_ira##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bus##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    liability_share, vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 2.4: r_annual_excl_trim (excluding residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 2.4: r_annual_excl_trim (excluding residential, trimmed)"
di as txt "===================================================================="

eststo reg2_4: reg r_annual_excl_trim age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    c.share_stk##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bond##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_re##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_ira##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    c.share_bus##(year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11) ///
    liability_share, vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Export results
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Exporting results to shares_interacted.tex"
di as txt "===================================================================="

esttab reg2_1 reg2_2 reg2_3 reg2_4 using "shares_interacted.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs compress nogaps ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared")) ///
    title("Asset Shares Interacted with Year Dummies") ///
    addnote("Clustered standard errors at individual level in parentheses" ///
            "*** p<0.01, ** p<0.05, * p<0.10" ///
            "Asset shares interacted with year dummies: share_stk, share_bond, share_re, share_ira, share_bus" ///
            "Joint F-tests for coefficient equality across years reported in log file")

* Display summary results in log
di as txt ""
di as txt "===================================================================="
di as txt "=== Summary: Joint F-test Results (from Regression 2.1)         ==="
di as txt "===================================================================="
di as txt ""
di as txt "Asset Share      F-statistic    p-value"
di as txt "----------------------------------------------"
di as txt "Stock            " %6.2f `fstat_stk' "        " %6.4f `p_stk'
di as txt "Bond             " %6.2f `fstat_bond' "        " %6.4f `p_bond'
di as txt "Real Estate      " %6.2f `fstat_re' "        " %6.4f `p_re'
di as txt "IRA              " %6.2f `fstat_ira' "        " %6.4f `p_ira'
di as txt "Business         " %6.2f `fstat_bus' "        " %6.4f `p_bus'
di as txt ""

di as txt ""
di as txt "===================================================================="
di as txt "=== Asset Shares × Year Interactions Complete                   ==="
di as txt "===================================================================="

log off
log close

