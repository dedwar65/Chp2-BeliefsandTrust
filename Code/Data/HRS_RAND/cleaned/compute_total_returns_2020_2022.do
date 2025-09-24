*----------------------------------------------------------------------
* compute_total_returns_2020_2022.do
* Compute total returns to net worth for 2022
* 
* This file automatically runs all prerequisite scripts and then computes
* total returns by summing across all asset class returns.
*----------------------------------------------------------------------
clear all
set more off

* ---------------------------------------------------------------------
* Step 1: Run all prerequisite scripts (with proper logging)
* ---------------------------------------------------------------------
di as txt "Running all prerequisite scripts..."

* Extract files
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/extract_household_2020_ret_calc_end.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/extract_household_2022_ret_calc_start.do"

* Merge files
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/merge_2020_2022.do"

* Compute components
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_int_inc_div_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_net_inv_flows_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_debt_payments_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_cap_gains_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_beg_per_net_worth_2020_2022.do"

* Compute asset class returns
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_fin_asset_returns_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_bus_returns_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_retirement_returns_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_real_estate_returns_2020_2022.do"
do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_residential_returns_2020_2022.do"

di as txt "All prerequisite scripts completed successfully!"
di as txt ""

* ---------------------------------------------------------------------
* Step 2: NOW start logging for the total returns computation
* ---------------------------------------------------------------------
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_total_returns_2022.log", replace text

di as txt "=== COMPUTING TOTAL RETURNS TO NET WORTH ==="
di as txt "All prerequisite scripts have been run successfully"
di as txt ""

* ---------------------------------------------------------------------
* Step 3: Load the master dataset with all computed variables
* ---------------------------------------------------------------------
di as txt "=== Loading master dataset ==="

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Step 4: Check for required variables
* ---------------------------------------------------------------------
di as txt "=== Checking for required asset class return variables ==="

local missing_vars ""
capture confirm variable r_fin_2022
if _rc local missing_vars "`missing_vars' r_fin_2022"
capture confirm variable r_bus_2022
if _rc local missing_vars "`missing_vars' r_bus_2022"
capture confirm variable r_ira_2022
if _rc local missing_vars "`missing_vars' r_ira_2022"
capture confirm variable r_re_2022
if _rc local missing_vars "`missing_vars' r_re_2022"
capture confirm variable r_res_2022
if _rc local missing_vars "`missing_vars' r_res_2022"

if "`missing_vars'" != "" {
    di as error "ERROR: Missing required variables:`missing_vars'"
    di as error "Prerequisite scripts may have failed."
    exit 198
}

di as txt "All required asset class return variables found!"

* ---------------------------------------------------------------------
* Step 5: List available return variables
* ---------------------------------------------------------------------
di as txt "=== Available asset class return variables ==="
di as txt "  r_fin_2022: Financial asset returns"
di as txt "  r_bus_2022: Business asset returns"
di as txt "  r_ira_2022: Retirement asset returns"
di as txt "  r_re_2022: Real estate returns"
di as txt "  r_res_2022: Residential housing returns"

* ---------------------------------------------------------------------
* Step 6: Define sample for total returns computation
* ---------------------------------------------------------------------
di as txt "=== Defining sample for total returns computation ==="

* Sample: households with non-missing returns for at least 1 of the 5 asset classes
gen byte has_any_returns = 0
replace has_any_returns = 1 if !missing(r_fin_2022)
replace has_any_returns = 1 if !missing(r_bus_2022)
replace has_any_returns = 1 if !missing(r_ira_2022)
replace has_any_returns = 1 if !missing(r_re_2022)
replace has_any_returns = 1 if !missing(r_res_2022)

quietly count if has_any_returns == 1
local n_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households with at least one asset class return: `n_sample' out of `n_total' (" %4.1f 100*`n_sample'/`n_total' "%)"

* Breakdown by number of asset classes with returns
egen byte n_asset_returns = rownonmiss(r_fin_2022 r_bus_2022 r_ira_2022 r_re_2022 r_res_2022)
tab n_asset_returns if has_any_returns, missing

* ---------------------------------------------------------------------
* Detailed overlap analysis
* ---------------------------------------------------------------------
di as txt "=== Detailed overlap analysis ==="

* Count non-missing returns for each asset class
quietly count if !missing(r_fin_2022)
local n_fin = r(N)
quietly count if !missing(r_bus_2022)
local n_bus = r(N)
quietly count if !missing(r_ira_2022)
local n_ira = r(N)
quietly count if !missing(r_re_2022)
local n_re = r(N)
quietly count if !missing(r_res_2022)
local n_res = r(N)

di as txt "Individual asset class return counts:"
di as txt "  Financial returns (r_fin_2022): `n_fin'"
di as txt "  Business returns (r_bus_2022): `n_bus'"
di as txt "  Retirement returns (r_ira_2022): `n_ira'"
di as txt "  Real estate returns (r_re_2022): `n_re'"
di as txt "  Residential returns (r_res_2022): `n_res'"


* ---------------------------------------------------------------------
* Step 7: Compute total returns (raw and trimmed)
* ---------------------------------------------------------------------
di as txt "=== Computing total returns ==="

* Raw total returns: sum across all asset classes, treat missing as 0 within sample
capture drop r_total_2022
gen double r_total_2022 = .
replace r_total_2022 = cond(missing(r_fin_2022), 0, r_fin_2022) + ///
                      cond(missing(r_bus_2022), 0, r_bus_2022) + ///
                      cond(missing(r_ira_2022), 0, r_ira_2022) + ///
                      cond(missing(r_re_2022), 0, r_re_2022) + ///
                      cond(missing(r_res_2022), 0, r_res_2022) ///
                      if has_any_returns

* Trimmed total returns: sum across trimmed asset class returns
capture drop r_total_2022_trimmed
gen double r_total_2022_trimmed = .
replace r_total_2022_trimmed = cond(missing(r_fin_2022_trim), 0, r_fin_2022_trim) + ///
                              cond(missing(r_bus_2022_trim), 0, r_bus_2022_trim) + ///
                              cond(missing(r_ira_2022_trim), 0, r_ira_2022_trim) + ///
                              cond(missing(r_re_2022_trimmed), 0, r_re_2022_trimmed) + ///
                              cond(missing(r_res_2022_trimmed), 0, r_res_2022_trimmed) ///
                              if has_any_returns

* Final trimmed total returns: apply additional 5% trimming to the sum of trimmed asset class returns
capture drop r_total_2022_final_trim
gen double r_total_2022_final_trim = .

* Calculate trimming thresholds for the sum of trimmed returns
quietly _pctile r_total_2022_trimmed if has_any_returns, p(5 95)
scalar p5_trimmed = r(r1)
scalar p95_trimmed = r(r2)

di as txt "Final trimming thresholds for sum of trimmed returns:"
di as txt "  5th percentile: " %12.4f p5_trimmed
di as txt "  95th percentile: " %12.4f p95_trimmed

* Apply final trimming
replace r_total_2022_final_trim = r_total_2022_trimmed if has_any_returns & ///
                                  r_total_2022_trimmed >= p5_trimmed & ///
                                  r_total_2022_trimmed <= p95_trimmed

quietly count if !missing(r_total_2022_final_trim)
local n_final_trim = r(N)
quietly count if has_any_returns
local n_trimmed_total = r(N)
di as txt "Final trimmed sample: `n_final_trim' out of `n_trimmed_total' trimmed total returns (" %4.1f 100*`n_final_trim'/`n_trimmed_total' "%)"

* ---------------------------------------------------------------------
* Step 8: Summaries and diagnostics
* ---------------------------------------------------------------------
di as txt "=== Total returns summaries ==="

di as txt "Raw total returns (r_total_2022) summary:"
summarize r_total_2022 if has_any_returns, detail
tabstat r_total_2022 if has_any_returns, stats(n mean sd p50 min max) format(%12.4f)

di as txt "Trimmed total returns (r_total_2022_trimmed) summary:"
summarize r_total_2022_trimmed if has_any_returns, detail
tabstat r_total_2022_trimmed if has_any_returns, stats(n mean sd p50 min max) format(%12.4f)

di as txt "Final trimmed total returns (r_total_2022_final_trim) summary:"
summarize r_total_2022_final_trim, detail
tabstat r_total_2022_final_trim, stats(n mean sd p50 min max) format(%12.4f)

* Check for extreme values
quietly count if r_total_2022 > 5 & has_any_returns
di as txt "Raw total returns > 500%: " r(N)
quietly count if r_total_2022 < -1 & has_any_returns
di as txt "Raw total returns < -100%: " r(N)

quietly count if r_total_2022_trimmed > 5 & has_any_returns
di as txt "Trimmed total returns > 500%: " r(N)
quietly count if r_total_2022_trimmed < -1 & has_any_returns
di as txt "Trimmed total returns < -100%: " r(N)

quietly count if r_total_2022_final_trim > 5
di as txt "Final trimmed total returns > 500%: " r(N)
quietly count if r_total_2022_final_trim < -1
di as txt "Final trimmed total returns < -100%: " r(N)

* ---------------------------------------------------------------------
* Step 9: Top 20 returns display
* ---------------------------------------------------------------------
di as txt "=== Top 20 total returns ==="

di as txt "Top 20 positive raw total returns:"
gsort -r_total_2022
list hhid rsubhh r_total_2022 r_fin_2022 r_bus_2022 r_ira_2022 r_re_2022 r_res_2022 in 1/20 if has_any_returns

di as txt "Top 20 negative raw total returns:"
gsort r_total_2022
list hhid rsubhh r_total_2022 r_fin_2022 r_bus_2022 r_ira_2022 r_re_2022 r_res_2022 in 1/20 if has_any_returns

di as txt "Top 20 positive trimmed total returns:"
gsort -r_total_2022_trimmed
list hhid rsubhh r_total_2022_trimmed r_fin_2022_trim r_bus_2022_trim r_ira_2022_trim r_re_2022_trimmed r_res_2022_trimmed in 1/20 if has_any_returns

di as txt "Top 20 positive final trimmed total returns:"
gsort -r_total_2022_final_trim
list hhid rsubhh r_total_2022_final_trim r_fin_2022_trim r_bus_2022_trim r_ira_2022_trim r_re_2022_trimmed r_res_2022_trimmed in 1/20 if !missing(r_total_2022_final_trim)

* ---------------------------------------------------------------------
* Step 10: Save results
* ---------------------------------------------------------------------
di as txt "=== Saving results ==="

save "`master'", replace
di as txt "Saved total return variables to master: `master'"

* List of variables created
di as txt "Variables created:"
di as txt "  has_any_returns: sample indicator (at least 1 asset class return)"
di as txt "  n_asset_returns: number of asset classes with returns"
di as txt "  r_total_2022: raw total returns (sum of raw asset class returns)"
di as txt "  r_total_2022_trimmed: trimmed total returns (sum of trimmed asset class returns)"
di as txt "  r_total_2022_final_trim: final trimmed total returns (additional 5% trimming applied to sum of trimmed returns)"

di as txt ""
di as txt "Total returns computation completed successfully!"

log close
exit, clear
