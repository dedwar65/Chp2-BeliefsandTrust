*----------------------------------------------------------------------
* compute_residential_returns_2020_2022.do
* Compute returns for residential housing assets for 2022
* 
* Formula: r_res = (yc_res + cg_res - F_res) / (A_2020 + 0.5*F_2022)
* 
* Where:
* - yc_res = 0 (no interest income/dividends for residential housing)
* - cg_res = capital gains from residential housing (V_res_2022 - V_res_2020)
* - F_res = net investment flows into residential housing (buy/sell/improvements)
* - A_2020 = total beginning period net worth
* - F_2022 = total net investment flows
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_residential_returns_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* Note: Prerequisite scripts must be run first:
* - extract_household_2020_ret_calc_end
* - extract_household_2022_ret_calc_start  
* - merge_2020_2022
* - compute_int_inc_div_2020_2022
* - compute_net_inv_flows_2020_2022
* - compute_debt_payments_2020_2022
* - compute_cap_gains_2020_2022
* - compute_beg_per_net_worth_2020_2022
* ---------------------------------------------------------------------

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Define residential housing sample
* Baseline: residential housing values in both years (V_res_2022 and V_res_2020)
* Augmented: OR any flow component (buy/sell/improvements)
* ---------------------------------------------------------------------
di as txt "=== Defining residential housing sample ==="

* Check for residential housing in both years (V_res_2022 and V_res_2020)
gen byte has_res_both = !missing(V_res_2022) & !missing(V_res_2020)

* Exposure via flow components present (raw checks)
* Residential flow exposure: any of buy (SR007), sell (SR013), or improvements (SR024)
gen byte res_exposure = 0
replace res_exposure = 1 if !missing(SR007) | !missing(SR013) | !missing(SR024)

* Residential sample: baseline OR exposure
gen byte res_sample = has_res_both | res_exposure

* Report sample statistics
di as txt "Sample definition results:"
tab res_sample, missing
quietly count if res_sample == 1
local n_res_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in residential housing sample: `n_res_sample' out of `n_total' (" %4.1f 100*`n_res_sample'/`n_total' "%)"

* Breakdown by asset type
di as txt "Breakdown by asset type:"
di as txt "Households with residential housing in both years:"
tab has_res_both, missing
di as txt "Additional inclusions due to flow exposure:"
tab res_exposure if !has_res_both, missing

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Computing denominator components ==="

* Total beginning period net worth
capture drop A_2020
gen double A_2020 = networth_A2020 if res_sample

* Total net investment flows (treat missing as 0 within sample)
capture drop F_2022
gen double F_2022 = flow_total_2022 if res_sample
replace F_2022 = 0 if missing(F_2022) & res_sample

* Final denominator: A_2020 + 0.5*F_2022
capture drop denom_res_2022
gen double denom_res_2022 = A_2020 + 0.5*F_2022 if res_sample

* Apply denominator threshold (≥$10k)
gen byte denom_res_above_10k = denom_res_2022 >= 10000 if res_sample
replace res_sample = res_sample & denom_res_above_10k

* Report final sample restriction results
di as txt "Final sample restriction results:"
quietly count if res_sample == 1
local n_final_sample = r(N)
di as txt "Final sample size after denominator threshold (≥$10k): `n_final_sample'"
di as txt "Observations dropped due to negative/small denominators: `=`n_res_sample'-`n_final_sample''"

* ---------------------------------------------------------------------
* Numerator components
* ---------------------------------------------------------------------
di as txt "=== Computing numerator components ==="

* Check for required variables
capture confirm variable cg_res_total_2022
if _rc {
    di as error "ERROR: cg_res_total_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}
capture confirm variable flow_residences_2022
if _rc {
    di as error "ERROR: flow_residences_2022 not found. Run compute_net_inv_flows_2020_2022.do first."
    exit 198
}

* 1) Interest income (yc_res_2022) - always 0 for residential housing
capture drop yc_res_2022
gen double yc_res_2022 = 0 if res_sample

* 2) Capital gains (cg_res_2022) - use existing variable, treat missing as 0 within sample
capture drop cg_res_2022
gen double cg_res_2022 = cg_res_total_2022 if res_sample
replace cg_res_2022 = 0 if missing(cg_res_2022) & res_sample

* 3) Net investment flows (F_res_2022) - treat missing as 0 within sample
capture drop F_res_2022
gen double F_res_2022 = flow_residences_2022 if res_sample
replace F_res_2022 = 0 if missing(F_res_2022) & res_sample

* ---------------------------------------------------------------------
* Component summaries and diagnostics
* ---------------------------------------------------------------------
di as txt "=== Component summaries ==="

di as txt "Interest income (yc_res_2022) summary:"
summarize yc_res_2022 if res_sample, detail
tabstat yc_res_2022 if res_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Capital gains (cg_res_2022) summary:"
summarize cg_res_2022 if res_sample, detail
tabstat cg_res_2022 if res_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Residential flows (F_res_2022) summary:"
summarize F_res_2022 if res_sample, detail
tabstat F_res_2022 if res_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Final denominator (A_2020 + 0.5*F_2022) summary:"
summarize denom_res_2022 if res_sample, detail

* Cross-tabulation of component presence
di as txt "Component presence patterns:"
quietly count if !missing(yc_res_2022) & res_sample
di as txt "  yc_res_2022 non-missing: " r(N)
quietly count if !missing(cg_res_2022) & res_sample
di as txt "  cg_res_2022 non-missing: " r(N)
quietly count if !missing(F_res_2022) & res_sample
di as txt "  F_res_2022 non-missing: " r(N)
quietly count if !missing(A_2020) & res_sample
di as txt "  A_2020 non-missing: " r(N)
quietly count if !missing(F_2022) & res_sample
di as txt "  F_2022 non-missing: " r(N)

* ---------------------------------------------------------------------
* Return calculation
* ---------------------------------------------------------------------
di as txt "=== Computing residential housing returns ==="

* Raw return calculation
capture drop r_res_2022
gen double r_res_2022 = (yc_res_2022 + cg_res_2022 - F_res_2022) / denom_res_2022 if res_sample

* Summary of raw returns
di as txt "Raw residential housing returns (r_res_2022) summary:"
summarize r_res_2022 if res_sample, detail

* Check for extreme values
quietly count if r_res_2022 > 5 & res_sample
di as txt "Returns > 500%: " r(N)
quietly count if r_res_2022 < -1 & res_sample
di as txt "Returns < -100%: " r(N)

* ---------------------------------------------------------------------
* Trimming extreme values (top and bottom 5%)
* ---------------------------------------------------------------------
di as txt "=== Trimming extreme returns ==="

* Calculate percentiles for trimming
quietly _pctile r_res_2022 if res_sample, p(5 95)
scalar p5 = r(r1)
scalar p95 = r(r2)
di as txt "5th percentile: " p5
di as txt "95th percentile: " p95

* Create trimmed returns
capture drop r_res_2022_trimmed
gen double r_res_2022_trimmed = r_res_2022 if res_sample
replace r_res_2022_trimmed = . if r_res_2022 < p5 | r_res_2022 > p95

* Summary of trimmed returns
di as txt "Trimmed residential housing returns (r_res_2022_trimmed) summary:"
summarize r_res_2022_trimmed if res_sample, detail

quietly count if !missing(r_res_2022_trimmed) & res_sample
di as txt "Observations after trimming: " r(N)

* ---------------------------------------------------------------------
* Top 20 returns display
* ---------------------------------------------------------------------
di as txt "Top 20 positive residential housing returns:"
gsort -r_res_2022
list HHID RSUBHH r_res_2022 yc_res_2022 cg_res_2022 F_res_2022 A_2020 F_2022 denom_res_2022 in 1/20 if res_sample

di as txt "Top 20 negative residential housing returns:"
gsort r_res_2022
list HHID RSUBHH r_res_2022 yc_res_2022 cg_res_2022 F_res_2022 A_2020 F_2022 denom_res_2022 in 1/20 if res_sample

di as txt "Top 20 trimmed residential housing returns:"
gsort -r_res_2022_trimmed
list HHID RSUBHH r_res_2022_trimmed yc_res_2022 cg_res_2022 F_res_2022 A_2020 F_2022 denom_res_2022 in 1/20 if !missing(r_res_2022_trimmed)

* ---------------------------------------------------------------------
* Zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Zero-value analysis ==="

quietly count if yc_res_2022 == 0 & res_sample
di as txt "Households with zero interest income: " r(N)
quietly count if cg_res_2022 == 0 & res_sample
di as txt "Households with zero capital gains: " r(N)
quietly count if F_res_2022 == 0 & res_sample
di as txt "Households with zero residential flows: " r(N)

* ---------------------------------------------------------------------
* Save results
* ---------------------------------------------------------------------
di as txt "=== Saving results ==="

save "`master'", replace
di as txt "Saved residential housing return variables to master: `master'"

* List of variables created
di as txt "Variables created:"
di as txt "  res_sample: sample indicator"
di as txt "  A_2020: beginning period net worth"
di as txt "  F_2022: total net investment flows"
di as txt "  denom_res_2022: final denominator"
di as txt "  yc_res_2022: interest income (always 0)"
di as txt "  cg_res_2022: capital gains"
di as txt "  F_res_2022: residential flows"
di as txt "  r_res_2022: raw returns"
di as txt "  r_res_2022_trimmed: trimmed returns"

log close
exit, clear
