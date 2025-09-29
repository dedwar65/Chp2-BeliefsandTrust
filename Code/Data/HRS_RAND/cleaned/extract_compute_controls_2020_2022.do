*----------------------------------------------------------------------
* Extract + Compute Controls (HRS RAND) and merge into master (2020-2022)
*----------------------------------------------------------------------

clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/extract_compute_controls_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local raw2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA/h20f1a.dta"
local cleaned  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned"
local master   "`cleaned'/hrs_rand_2020_2022_master.dta"

di as txt "Master path: `master'"

* ---------------------------------------------------------------------
* Verify source and master files
* ---------------------------------------------------------------------
capture confirm file "`raw2020'"
if _rc {
	di as error "ERROR: RAND 2020 raw file not found -> `raw2020'"
	exit 198
}

capture confirm file "`master'"
if _rc di as error "ERROR: master file not found -> `master'"
if _rc exit 198

* ---------------------------------------------------------------------
* Variables to extract (guided by RepNotes_G2008.md)
* Notes mapping (lowercase RAND vars):
*   Education: rz216, rb014
*   Age: ra019
*   Gender: rx060_r
*   Employment: rj005m1 rj005m2 rj005m3 rj005m4 rj005m5 rj020
*   Marital status: ra034, rz080
*   Immigration: rb085, rz230 (citizenship)
* ---------------------------------------------------------------------
local keepvars "hhid rsubhh rz216 rb014 ra019 rx060_r rj005m1 rj005m2 rj005m3 rj005m4 rj005m5 rj020 ra034 rz080 rb085 rz230 rv557 rv559 rv560 rv561 rv562 rv563 rv564"

* ---------------------------------------------------------------------
* Load 2020 raw, keep requested controls and keys
* ---------------------------------------------------------------------
use "`raw2020'", clear

* Safety: trim keys if string
capture confirm string variable hhid
if !_rc replace hhid = trim(hhid)

* RAND 2020 household key: rsubhh
capture confirm string variable rsubhh
if !_rc replace rsubhh = trim(rsubhh)
if !_rc replace rsubhh = "0" if rsubhh == ""

* Check variables exist and keep
foreach v of local keepvars {
	capture confirm variable `v'
	if _rc di as warn "MISSING control var in 2020: `v'"
}

keep `keepvars'

* Deduplicate by keys keeping row with most non-missing controls
sort hhid rsubhh
bys hhid rsubhh: gen dupN = _N
count if dupN > 1
if r(N) > 0 {
	egen nm = rownonmiss(rz216 rb014 ra019 rx060_r rj005m1 rj005m2 rj005m3 rj005m4 rj005m5 rj020 ra034 rz080 rb085 rz230), strok
	bys hhid rsubhh (nm): keep if _n==_N
	drop nm dupN
	sort hhid rsubhh
}
capture drop dupN

* Clean common numeric special missing codes to Stata missing
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of varlist _all {
	capture confirm numeric variable `v'
	if !_rc {
		foreach mc of local misscodes {
			quietly replace `v' = . if `v' == `mc'
		}
	}
}

di as txt "2020 controls extracted: obs = " _N

* ---------------------------------------------------------------------
* Diagnostics on extracted controls (summaries for all variables)
* ---------------------------------------------------------------------
qui count
local n_controls = r(N)

di as txt "Sample size in controls file (2020): `n_controls'"

* Define continuous vs categorical sets for clearer output
local cont_vars "rz216 rb014 ra019"
local cat_vars  "rx060_r rj005m1 rj005m2 rj005m3 rj005m4 rj005m5 rj020 ra034 rz080 rb085 rz230"

di as txt "-- Continuous variables (summarize, detail) --"
foreach v of local cont_vars {
	di as txt "[summarize] `v'"
	capture noisily summarize `v', detail
}

di as txt "-- Categorical variables (tabulate) --"
foreach v of local cat_vars {
	di as txt "[tab] `v'"
	capture noisily tab `v', missing
}

* ---------------------------------------------------------------------
* Merge controls into master
* ---------------------------------------------------------------------
tempfile controls2020
save "`controls2020'", replace

use "`master'", clear

* Ensure key format matches (master uses hhid + rsubhh)
capture confirm string variable hhid
if !_rc replace hhid = trim(hhid)
capture confirm string variable rsubhh
if !_rc replace rsubhh = trim(rsubhh)
if !_rc replace rsubhh = "0" if rsubhh == ""

merge 1:1 hhid rsubhh using "`controls2020'"

di as txt "Merge results (master + controls2020):"
quietly tab _merge

di as txt "_merge counts:"
tab _merge

* keep all master households; drop _merge after
* Optionally fill controls only where missing in master

* Drop merge indicator
drop _merge

save "`master'", replace

di as txt "Saved updated master with controls -> `master'"

* Load the updated master to leave it in memory for next steps
use "`master'", clear
di as txt "Loaded updated master: `master'"

* Show which control variables are now present in master (explicit RHS list)
local controls_only "rz216 rb014 ra019 rx060_r rj005m1 rj005m2 rj005m3 rj005m4 rj005m5 rj020 ra034 rz080 rb085 rz230"
local found ""
foreach v of local controls_only {
	capture confirm variable `v'
	if !_rc local found "`found' `v'"
}
di as txt "Controls present in master (post-merge):"
di as txt "`found'"

log close

* Keep the updated master loaded and display a brief variables summary
quietly describe
local k = r(k)
di as txt "Variables in memory: `k'"
capture noisily ds

* ---------------------------------------------------------------------
* Construct standardized controls for regression: Gender (rx060_r)
* Mapping per HRS codebook: 1=male, 2=female, missing otherwise
* User preference: create binary 'gender' where male=1, female=0
* ---------------------------------------------------------------------
capture drop gender
gen byte gender = .
replace gender = 1 if rx060_r == 1
replace gender = 0 if rx060_r == 2
label variable gender "Gender (1=male, 0=female)"
label define male01 0 "Female" 1 "Male"
label values gender male01
di as txt "Sex (rx060_r) -> gender mapping (1=male,0=female):"
tab rx060_r gender, missing

* Save updated master with constructed control and keep in memory
* ---------------------------------------------------------------------
* Construct standardized controls: Employment status (rj020)
* Mapping per codebook: 1=YES (working now), 5=NO (not working now)
* Treat -8/8/9 and blanks as missing in derived binary
* ---------------------------------------------------------------------
capture drop employed
gen byte employed = .
replace employed = 1 if rj020 == 1
replace employed = 0 if rj020 == 5
label variable employed "Currently working for pay (1=yes,0=no)"
label define yesno2 0 "No" 1 "Yes"
label values employed yesno2
di as txt "Employment (rj020) -> employed mapping (1=yes,0=no):"
tab rj020 employed, missing

* Save updated master with constructed controls and keep in memory
save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Rename core demographics to standard names
* ra019 -> age, rz216 -> education
* ---------------------------------------------------------------------
capture confirm variable ra019
if !_rc {
	capture confirm variable age
	if _rc rename ra019 age
	label variable age "Age"
}

capture confirm variable rz216
if !_rc {
	capture confirm variable education
	if _rc rename rz216 education
	label variable education "Education (years or code as provided)"
}

save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Compute asset-class shares of wealth (denominator: networth_A2020)
* Asset classes:
*  - Residential: primary + secondary residences (rh020 + rh162)
*  - Real estate (non-residential): rq134
*  - Business: rq148
*  - Retirement: rq166_1 + rq166_2 + rq166_3 (v_ira_2020 if present)
*  - Financial: stocks rq317 + bonds rq331 + checking/savings rq345 + CDs rq357
* Denominator: networth_A2020; shares set missing when denom <= 0 or missing
* Missing numerators treated as 0 (no holdings)
* ---------------------------------------------------------------------

capture confirm variable networth_A2020
if _rc {
	di as error "ERROR: networth_A2020 not found in master. Run net worth scripts first."
}

* Build numerators (2020 values)
capture drop num_residential_2020 num_re_2020 num_bus_2020 num_ira_2020 num_fin_2020 num_stocks_2020 num_safe_2020
gen double num_residential_2020 = cond(missing(rh020),0,rh020) + cond(missing(rh162),0,rh162)
gen double num_re_2020         = cond(missing(rq134),0,rq134)
gen double num_bus_2020        = cond(missing(rq148),0,rq148)
* IRA total: construct from raw components for consistency
gen double num_ira_2020        = cond(missing(rq166_1),0,rq166_1) + cond(missing(rq166_2),0,rq166_2) + cond(missing(rq166_3),0,rq166_3)
gen double num_fin_2020        = cond(missing(rq317),0,rq317) + cond(missing(rq331),0,rq331) + cond(missing(rq345),0,rq345) + cond(missing(rq357),0,rq357)
* Split financial into stocks vs safe (bonds+cash+CDs)
gen double num_stocks_2020     = cond(missing(rq317),0,rq317)
gen double num_safe_2020       = cond(missing(rq331),0,rq331) + cond(missing(rq345),0,rq345) + cond(missing(rq357),0,rq357)

* Shares: numerator / networth_A2020 when denom > 0
capture drop share_residential share_realestate share_business share_retirement share_financial share_stocks share_safe
gen double share_residential = .
gen double share_realestate = .
gen double share_business   = .
gen double share_retirement = .
gen double share_financial  = .
gen double share_stocks     = .
gen double share_safe       = .

replace share_residential = num_residential_2020 / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_realestate = num_re_2020        / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_business   = num_bus_2020       / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_retirement = num_ira_2020       / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_financial  = num_fin_2020       / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_stocks     = num_stocks_2020    / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0
replace share_safe       = num_safe_2020      / networth_A2020 if !missing(networth_A2020) & networth_A2020 > 0

label variable share_residential "Share of net worth: residential (2020)"
label variable share_realestate "Share of net worth: real estate (2020)"
label variable share_business   "Share of net worth: business (2020)"
label variable share_retirement "Share of net worth: retirement (2020)"
label variable share_financial  "Share of net worth: financial (2020)"
label variable share_stocks     "Share of net worth: stocks (2020)"
label variable share_safe       "Share of net worth: safe assets (bonds+cash+CDs, 2020)"

* Diagnostics
di as txt "Asset-class share diagnostics (denominator networth_A2020>0)"
quietly count if missing(networth_A2020)
di as txt "  Missing networth_A2020: " r(N)
quietly count if !missing(networth_A2020) & networth_A2020 <= 0
di as txt "  Non-positive networth_A2020: " r(N)

tabstat share_residential share_realestate share_business share_retirement share_financial share_stocks share_safe, stats(n mean sd p50 min max) format(%12.4f)

* Drop intermediate numerators used to compute shares
capture drop num_residential_2020 num_re_2020 num_bus_2020 num_ira_2020 num_fin_2020 num_stocks_2020 num_safe_2020

save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Compute wealth percentiles (percentile rank of networth_A2020)
* Continuous 0-100 scale across non-missing net worth
* ---------------------------------------------------------------------
capture drop wealth_rank wealth_pct
quietly count if !missing(networth_A2020)
local N_wealth = r(N)
egen double wealth_rank = rank(networth_A2020) if !missing(networth_A2020)
gen double wealth_pct = .
replace wealth_pct = 100 * (wealth_rank - 1) / (`N_wealth' - 1) if `N_wealth' > 1 & !missing(wealth_rank)
replace wealth_pct = 50 if `N_wealth' == 1 & !missing(wealth_rank)
label variable wealth_pct "Wealth percentile (based on networth_A2020)"

di as txt "Wealth percentile diagnostics:"
quietly count if !missing(wealth_pct)
di as txt "  Non-missing wealth_pct: " r(N)
tabstat wealth_pct, stats(n mean sd p50 min max) format(%12.4f)

save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Create wealth decile dummies from wealth_pct (10 bins of width 10)
* wealth_decile: 1=0-<10th, ..., 10=90th-100th; missing if wealth_pct missing
* Dummies: wealth_d1 ... wealth_d10 (simple names, mutually exclusive)
* ---------------------------------------------------------------------
capture drop wealth_decile
gen byte wealth_decile = .
replace wealth_decile = floor(wealth_pct/10) + 1 if !missing(wealth_pct)
replace wealth_decile = 10 if wealth_decile == 11
label define wdec 1 "P0-P10" 2 "P10-P20" 3 "P20-P30" 4 "P30-P40" 5 "P40-P50" 6 "P50-P60" 7 "P60-P70" 8 "P70-P80" 9 "P80-P90" 10 "P90-P100"
label values wealth_decile wdec
label variable wealth_decile "Wealth decile (from wealth_pct)"

* Generate 10 dummy variables
forvalues d = 1/10 {
	capture drop wealth_d`d'
	gen byte wealth_d`d' = .
	replace wealth_d`d' = 1 if wealth_decile == `d'
	replace wealth_d`d' = 0 if !missing(wealth_decile) & wealth_decile != `d'
	label variable wealth_d`d' "Wealth decile `d' dummy"
}

di as txt "Wealth decile diagnostics:"
tab wealth_decile, missing
tabstat wealth_d1 wealth_d2 wealth_d3 wealth_d4 wealth_d5 wealth_d6 wealth_d7 wealth_d8 wealth_d9 wealth_d10, stats(n mean) format(%9.0g)

save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Construct standardized controls: Immigration (rz230 - US born)
* immigration = 1 if not US-born (rz230==5); 0 if US-born (rz230==1); else missing
* ---------------------------------------------------------------------
capture drop immigration
gen byte immigration = .
replace immigration = 1 if rz230 == 5
replace immigration = 0 if rz230 == 1
label variable immigration "Immigrant (1=not US-born, 0=US-born)"
label define immigr01 0 "US-born" 1 "Immigrant"
label values immigration immigr01
di as txt "US born (rz230) -> immigration mapping (1=immigrant,0=US-born):"
tab rz230 immigration, missing

save "`master'", replace
use "`master'", clear

* ---------------------------------------------------------------------
* Construct standardized controls: Marital status (rz080, prev wave)
* Coupled=1 for married or married-spouse-absent (codes 1,2,3)
* Not coupled=0 for divorced/separated, widowed, never married (4,5,6)
* Unknown/blank (0, .) -> missing
* ---------------------------------------------------------------------
capture drop coupled
gen byte coupled = .
replace coupled = 1 if inlist(rz080,1,2,3)
replace coupled = 0 if inlist(rz080,4,5,6)
label variable coupled "Coupled (1=married/married-spouse-absent, 0=not coupled)"
label define couple01 0 "Not coupled" 1 "Coupled"
label values coupled couple01
di as txt "Marital status (rz080) -> coupled mapping (1=coupled,0=not):"
tab rz080 coupled, missing

save "`master'", replace
use "`master'", clear

