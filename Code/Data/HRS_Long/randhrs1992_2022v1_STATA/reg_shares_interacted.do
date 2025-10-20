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
* Regression 2.1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 2.1: r_annual (including residential)"
di as txt "===================================================================="

* Load fresh data
use "_randhrs1992_2022v1_panel.dta", clear

* Set panel structure
xtset hhidpn year
gen age_sq = age^2

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

* Load fresh data and restrict to balanced panel for r_annual_trim
use "_randhrs1992_2022v1_panel.dta", clear

* Count non-missing r_annual_trim per individual
bysort hhidpn: egen n_nonmiss = count(r_annual_trim) if !missing(r_annual_trim)
bysort hhidpn: egen total_obs = count(r_annual_trim)
bysort hhidpn: egen max_nonmiss = max(n_nonmiss)

* Keep only individuals with non-missing r_annual_trim in ALL years (11 years total)
keep if max_nonmiss == 11 & total_obs == 11
drop n_nonmiss total_obs max_nonmiss

* Verify balanced panel
bysort hhidpn: gen n_obs = _N
summarize n_obs
di as txt "Sample restricted to individuals with r_annual_trim in all 11 years: " _N " observations"
di as txt "Min obs per individual: " r(min) ", Max obs per individual: " r(max)
drop n_obs

* Set panel structure
xtset hhidpn year
gen age_sq = age^2

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

* Load fresh data and restrict to balanced panel for r_annual_excl
use "_randhrs1992_2022v1_panel.dta", clear

* Count non-missing r_annual_excl per individual
bysort hhidpn: egen n_nonmiss = count(r_annual_excl) if !missing(r_annual_excl)
bysort hhidpn: egen total_obs = count(r_annual_excl)
bysort hhidpn: egen max_nonmiss = max(n_nonmiss)

* Keep only individuals with non-missing r_annual_excl in ALL years (11 years total)
keep if max_nonmiss == 11 & total_obs == 11
drop n_nonmiss total_obs max_nonmiss

* Verify balanced panel
bysort hhidpn: gen n_obs = _N
summarize n_obs
di as txt "Sample restricted to individuals with r_annual_excl in all 11 years: " _N " observations"
di as txt "Min obs per individual: " r(min) ", Max obs per individual: " r(max)
drop n_obs

* Set panel structure
xtset hhidpn year
gen age_sq = age^2

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

* Load fresh data and restrict to balanced panel for r_annual_excl_trim
use "_randhrs1992_2022v1_panel.dta", clear

* Count non-missing r_annual_excl_trim per individual
bysort hhidpn: egen n_nonmiss = count(r_annual_excl_trim) if !missing(r_annual_excl_trim)
bysort hhidpn: egen total_obs = count(r_annual_excl_trim)
bysort hhidpn: egen max_nonmiss = max(n_nonmiss)

* Keep only individuals with non-missing r_annual_excl_trim in ALL years (11 years total)
keep if max_nonmiss == 11 & total_obs == 11
drop n_nonmiss total_obs max_nonmiss

* Verify balanced panel
bysort hhidpn: gen n_obs = _N
summarize n_obs
di as txt "Sample restricted to individuals with r_annual_excl_trim in all 11 years: " _N " observations"
di as txt "Min obs per individual: " r(min) ", Max obs per individual: " r(max)
drop n_obs

* Set panel structure
xtset hhidpn year
gen age_sq = age^2

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
di as txt "=== Exporting Results                                            ==="
di as txt "===================================================================="

* Export to LaTeX table
esttab reg2_1 reg2_2 reg2_3 reg2_4 using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables/shares_interacted.tex", ///
    replace booktabs ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    label compress ///
    drop(_cons) ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared")) ///
    title("Asset Shares × Year Interactions") ///
    addnote("Clustered standard errors at individual level in parentheses" ///
            "*** p<0.01, ** p<0.05, * p<0.10" ///
            "Interaction terms between asset shares and year dummies included but not shown" ///
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

