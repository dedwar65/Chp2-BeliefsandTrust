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
* Regression 1.1: r_annual (including residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.1: r_annual (including residential)"
di as txt "===================================================================="

* Load fresh data
use "_randhrs1992_2022v1_panel.dta", clear

* Set panel structure
xtset hhidpn year
gen age_sq = age^2

eststo clear
eststo reg1_1: reg r_annual age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 1.2: r_annual_trim (including residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.2: r_annual_trim (including residential, trimmed)"
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

eststo reg1_2: reg r_annual_trim age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_d2 i.wealth_d3 i.wealth_d4 i.wealth_d5 i.wealth_d6 ///
    i.wealth_d7 i.wealth_d8 i.wealth_d9 i.wealth_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 1.3: r_annual_excl (excluding residential)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.3: r_annual_excl (excluding residential)"
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

eststo reg1_3: reg r_annual_excl age age_sq raedyrs i.inlbrf i.married i.born_us ///
    i.wealth_nonres_d2 i.wealth_nonres_d3 i.wealth_nonres_d4 i.wealth_nonres_d5 i.wealth_nonres_d6 ///
    i.wealth_nonres_d7 i.wealth_nonres_d8 i.wealth_nonres_d9 i.wealth_nonres_d10 ///
    year_1 year_2 year_3 year_4 year_5 year_6 year_7 year_8 year_9 year_10 year_11, ///
    vce(cluster hhidpn)

di as txt ""

* ---------------------------------------------------------------------
* Regression 1.4: r_annual_excl_trim (excluding residential, trimmed)
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "Regression 1.4: r_annual_excl_trim (excluding residential, trimmed)"
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
di as txt "=== Exporting Results                                            ==="
di as txt "===================================================================="

* Export to LaTeX table
local tables "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Paper/Tables"
local outfile "`tables'/baseline_pooled.tex"

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

esttab reg1_1 reg1_2 reg1_3 reg1_4 using "`outfile'", replace ///
    booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
    compress b(%9.3f) se(%9.3f) ///
    mtitles(`mt') ///
    varlabels(age "Age" age_sq "Age$^{2}$" raedyrs "Years of education" 1.inlbrf "In labor force" 1.married "Married" 1.born_us "Born in U.S.") ///
    keep(age age_sq raedyrs 1.inlbrf 1.married 1.born_us) ///
    nocons ///
    stats(N r2 r2_a, labels("Observations" "R-squared" "Adjusted R-squared")) ///
    title("Baseline Pooled OLS Regressions") ///
    addnote("Clustered standard errors at individual level in parentheses" "*** p<0.01, ** p<0.05, * p<0.10" "Wealth deciles and other controls included but not shown; see text")

* Display results in log (summary only)
di as txt "Regression 1.1 (Annual returns): N=" e(N) ", R²=" %6.3f e(r2)
di as txt "Regression 1.2 (Annual returns, trimmed): N=" e(N) ", R²=" %6.3f e(r2)
di as txt "Regression 1.3 (Excl. residential): N=" e(N) ", R²=" %6.3f e(r2)
di as txt "Regression 1.4 (Excl. residential, trimmed): N=" e(N) ", R²=" %6.3f e(r2)

di as txt ""
di as txt "===================================================================="
di as txt "=== Baseline Pooled OLS Complete                                 ==="
di as txt "===================================================================="

capture log off
di as txt "Log file closed."
capture log close
quietly di ""   // force _rc = 0 on the last line

