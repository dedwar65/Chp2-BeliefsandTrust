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
    i.year ///
    c.share_stk##i.year ///
    c.share_bond##i.year ///
    c.share_re##i.year ///
    c.share_ira##i.year ///
    c.share_bus##i.year ///
    c.liability_share##i.year, vce(cluster hhidpn)

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
di as txt "Test 6: Liability share (main and interactions)"
quietly test liability_share
local fstat_liab = r(F)
local p_liab = r(p)
di as txt "F-statistic: " %6.2f `fstat_liab' "  p-value: " %6.4f `p_liab'

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
    i.year ///
    c.share_stk##i.year ///
    c.share_bond##i.year ///
    c.share_re##i.year ///
    c.share_ira##i.year ///
    c.share_bus##i.year ///
    c.liability_share##i.year, vce(cluster hhidpn)

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
    i.year ///
    c.share_stk##i.year ///
    c.share_bond##i.year ///
    c.share_re##i.year ///
    c.share_ira##i.year ///
    c.share_bus##i.year ///
    c.liability_share##i.year, vce(cluster hhidpn)

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
    i.year ///
    c.share_stk##i.year ///
    c.share_bond##i.year ///
    c.share_re##i.year ///
    c.share_ira##i.year ///
    c.share_bus##i.year ///
    c.liability_share##i.year, vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Export results
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "=== Exporting Results                                            ==="
di as txt "===================================================================="

* Export to LaTeX table
local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
local outfile "`tables'/shares_interacted.tex"

* Short, human column titles for 4 models
local mt "Annual" "Annual (trim)" "Excl. res" "Excl. res (trim)"

* Short row names (LaTeX-safe)
local vlab age "Age"
local vlab2 age_sq "Age\$^{2}\$"
local vlab3 raedyrs "Years of education"
local vlab4 1.inlbrf "In labor force"
local vlab5 1.married "Married"
local vlab6 1.born_us "Born in U.S."
local vlab7 1.wealth_d2 "Wealth d2"
local vlab8 1.wealth_d3 "Wealth d3"
local vlab9 1.wealth_d4 "Wealth d4"
local vlab10 1.wealth_d5 "Wealth d5"
local vlab11 1.wealth_d6 "Wealth d6"
local vlab12 1.wealth_d7 "Wealth d7"
local vlab13 1.wealth_d8 "Wealth d8"
local vlab14 1.wealth_d9 "Wealth d9"
local vlab15 1.wealth_d10 "Wealth d10"
local vlab16 1.wealth_nonres_d2 "Non-res wealth d2"
local vlab17 1.wealth_nonres_d3 "Non-res wealth d3"
local vlab18 1.wealth_nonres_d4 "Non-res wealth d4"
local vlab19 1.wealth_nonres_d5 "Non-res wealth d5"
local vlab20 1.wealth_nonres_d6 "Non-res wealth d6"
local vlab21 1.wealth_nonres_d7 "Non-res wealth d7"
local vlab22 1.wealth_nonres_d8 "Non-res wealth d8"
local vlab23 1.wealth_nonres_d9 "Non-res wealth d9"
local vlab24 1.wealth_nonres_d10 "Non-res wealth d10"
local vlab25 share_stk "Stock share"
local vlab26 share_bond "Bond share"
local vlab27 share_re "Real estate share"
local vlab28 share_ira "IRA share"
local vlab29 share_bus "Business share"
local vlab30 liability_share "Liability share"

* Year dummy labels
local vlab31 2.year "2004"
local vlab32 3.year "2006"
local vlab33 4.year "2008"
local vlab34 5.year "2010"
local vlab35 6.year "2012"
local vlab36 7.year "2014"
local vlab37 8.year "2016"
local vlab38 9.year "2018"
local vlab39 10.year "2020"
local vlab40 11.year "2022"

esttab reg2_1 reg2_2 reg2_3 reg2_4 using "`outfile'", replace ///
    booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
    compress b(%9.3f) se(%9.3f) ///
    mtitles(`mt') ///
    varlabels(age "Age" age_sq "Age$^{2}$" raedyrs "Years of education" 1.inlbrf "In labor force" 1.married "Married" ///
              share_stk "Stock share" share_bond "Bond share" share_re "Real estate share" share_ira "IRA share" share_bus "Business share" liability_share "Liability share") ///
    keep(age age_sq raedyrs 1.inlbrf 1.married share_stk share_bond share_re share_ira share_bus liability_share) ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared")) ///
    title("Asset Shares × Year Interactions") ///
    addnote("Clustered standard errors at individual level in parentheses" "*** p<0.01, ** p<0.05, * p<0.10" "Wealth deciles, year dummies, and interaction terms included but not shown" "Joint F-tests by asset class reported below and in log")

* Create summary table with F-test results
di as txt ""
di as txt "===================================================================="
di as txt "=== SUMMARY TABLE: Asset Shares × Year Interactions ==="
di as txt "===================================================================="
di as txt ""
di as txt "Asset Share          F-statistic    p-value    Interpretation"
di as txt "----------------------------------------------------------------"
di as txt "Stock share          " %6.2f `fstat_stk' "        " %6.4f `p_stk' "    " cond(`p_stk'<0.01, "***", cond(`p_stk'<0.05, "**", cond(`p_stk'<0.10, "*", "Not significant")))
di as txt "Bond share           " %6.2f `fstat_bond' "        " %6.4f `p_bond' "    " cond(`p_bond'<0.01, "***", cond(`p_bond'<0.05, "**", cond(`p_bond'<0.10, "*", "Not significant")))
di as txt "Real estate share    " %6.2f `fstat_re' "        " %6.4f `p_re' "    " cond(`p_re'<0.01, "***", cond(`p_re'<0.05, "**", cond(`p_re'<0.10, "*", "Not significant")))
di as txt "IRA share            " %6.2f `fstat_ira' "        " %6.4f `p_ira' "    " cond(`p_ira'<0.01, "***", cond(`p_ira'<0.05, "**", cond(`p_ira'<0.10, "*", "Not significant")))
di as txt "Business share       " %6.2f `fstat_bus' "        " %6.4f `p_bus' "    " cond(`p_bus'<0.01, "***", cond(`p_bus'<0.05, "**", cond(`p_bus'<0.10, "*", "Not significant")))
di as txt "Liability share      " %6.2f `fstat_liab' "        " %6.4f `p_liab' "    " cond(`p_liab'<0.01, "***", cond(`p_liab'<0.05, "**", cond(`p_liab'<0.10, "*", "Not significant")))
di as txt ""
di as txt "Notes: F-tests examine whether asset share effects vary significantly across years"
di as txt "       *** p<0.01, ** p<0.05, * p<0.10"

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

capture log off
capture log close
quietly di ""   // force _rc = 0 on the last line

