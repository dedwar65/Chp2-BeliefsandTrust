*----------------------------------------------------------------------
* compute_real_estate_returns_2020_2022.do
* Compute returns for real estate assets for 2022
* 
* Formula: r_re = (yc_re + cg_re - F_re) / (A_2020 + 0.5*F_2022)
* 
* Where:
* - yc_re = rental income from real estate
* - cg_re = capital gains from real estate (SQ134 - RQ134)
* - F_re = net investment flows into real estate (buy/sell/improvements)
* - A_2020 = total beginning period net worth
* - F_2022 = total net investment flows
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_real_estate_returns_2022.log", replace text

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
* Raw variable locals (align with compute_int_inc_div_2020_2022.do)
* ---------------------------------------------------------------------
local F2022_RE   SQ139
local A2022_RE   SQ141

* ---------------------------------------------------------------------
* Define real estate sample
* Baseline: real estate values in both years (SQ134 and RQ134)
* Augmented: OR any numerator signal (rental income amount+frequency OR any flow component)
* ---------------------------------------------------------------------
di as txt "=== Defining real estate sample ==="

* Check for real estate in both years (SQ134 and RQ134)
gen byte has_re_both = !missing(SQ134) & !missing(RQ134)

* Exposure via numerator components present (raw checks)
* Rental income exposure: amount present AND mapped frequency multiplier present
gen byte re_exposure = 0
replace re_exposure = 1 if !missing(`A2022_RE') & !missing(`F2022_RE'_mult)
* Real estate flow exposure: any of buy (SR030), sell (SR035), or improvements (SR045)
replace re_exposure = 1 if !missing(SR030) | !missing(SR035) | !missing(SR045)

* Real estate sample: baseline OR exposure
gen byte re_sample = has_re_both | re_exposure

* Report sample statistics
di as txt "Sample definition results:"
tab re_sample, missing
quietly count if re_sample == 1
local n_re_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in real estate sample: `n_re_sample' out of `n_total' (" %4.1f 100*`n_re_sample'/`n_total' "%)"

* Breakdown by asset type
di as txt "Breakdown by asset type:"
di as txt "Households with real estate in both years:"
tab has_re_both, missing
di as txt "Additional inclusions due to numerator exposure:"
tab re_exposure if !has_re_both, missing

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Computing denominator components ==="

* Total beginning period net worth
capture drop A_2020
gen double A_2020 = networth_A2020 if re_sample

* Total net investment flows (treat missing as 0 within sample)
capture drop F_2022
gen double F_2022 = flow_total_2022 if re_sample
replace F_2022 = 0 if missing(F_2022) & re_sample

* Final denominator: A_2020 + 0.5*F_2022
capture drop denom_re_2022
gen double denom_re_2022 = A_2020 + 0.5*F_2022 if re_sample

* Apply denominator threshold (≥$10k)
gen byte denom_re_above_10k = denom_re_2022 >= 10000 if re_sample
replace re_sample = re_sample & denom_re_above_10k

* Report final sample restriction results
di as txt "Final sample restriction results:"
quietly count if re_sample == 1
local n_final_sample = r(N)
di as txt "Final sample size after denominator threshold (≥$10k): `n_final_sample'"
di as txt "Observations dropped due to negative/small denominators: `=`n_re_sample'-`n_final_sample''"

* ---------------------------------------------------------------------
* Numerator components
* ---------------------------------------------------------------------
di as txt "=== Computing numerator components ==="

* 1) Rental income (yc_re_2022)
capture drop yc_re_2022
gen double yc_re_2022 = int_re_2022 if re_sample
replace yc_re_2022 = 0 if missing(yc_re_2022) & re_sample

* 2) Capital gains (cg_re_2022) - use existing variable, treat missing as 0 within sample
capture drop cg_re_2022_temp
gen double cg_re_2022_temp = cg_re_2022 if re_sample
replace cg_re_2022_temp = 0 if missing(cg_re_2022_temp) & re_sample
capture drop cg_re_2022
rename cg_re_2022_temp cg_re_2022

* 3) Net investment flows (F_re_2022) - treat missing as 0 within sample
capture drop F_re_2022
gen double F_re_2022 = flow_re_2022 if re_sample
replace F_re_2022 = 0 if missing(F_re_2022) & re_sample

* ---------------------------------------------------------------------
* Component summaries and diagnostics
* ---------------------------------------------------------------------
di as txt "=== Component summaries ==="

di as txt "Rental income (yc_re_2022) summary:"
summarize yc_re_2022 if re_sample, detail

di as txt "Capital gains (cg_re_2022) summary:"
summarize cg_re_2022 if re_sample, detail

di as txt "Real estate flows (F_re_2022) summary:"
summarize F_re_2022 if re_sample, detail

di as txt "Final denominator (A_2020 + 0.5*F_2022) summary:"
summarize denom_re_2022 if re_sample, detail

* Cross-tabulation of component presence
di as txt "Component presence patterns:"
quietly count if !missing(yc_re_2022) & re_sample
di as txt "  yc_re_2022 non-missing: " r(N)
quietly count if !missing(cg_re_2022) & re_sample
di as txt "  cg_re_2022 non-missing: " r(N)
quietly count if !missing(F_re_2022) & re_sample
di as txt "  F_re_2022 non-missing: " r(N)
quietly count if !missing(A_2020) & re_sample
di as txt "  A_2020 non-missing: " r(N)
quietly count if !missing(F_2022) & re_sample
di as txt "  F_2022 non-missing: " r(N)

* ---------------------------------------------------------------------
* Return calculation
* ---------------------------------------------------------------------
di as txt "=== Computing real estate returns ==="

* Raw return calculation
capture drop r_re_2022
gen double r_re_2022 = (yc_re_2022 + cg_re_2022 - F_re_2022) / denom_re_2022 if re_sample

* Summary of raw returns
di as txt "Raw real estate returns (r_re_2022) summary:"
summarize r_re_2022 if re_sample, detail

* Check for extreme values
quietly count if r_re_2022 > 5 & re_sample
di as txt "Returns > 500%: " r(N)
quietly count if r_re_2022 < -1 & re_sample
di as txt "Returns < -100%: " r(N)

* ---------------------------------------------------------------------
* Trimming extreme values (top and bottom 5%)
* ---------------------------------------------------------------------
di as txt "=== Trimming extreme returns ==="

* Calculate percentiles for trimming
quietly _pctile r_re_2022 if re_sample, p(5 95)
scalar p5 = r(r1)
scalar p95 = r(r2)
di as txt "5th percentile: " p5
di as txt "95th percentile: " p95

* Create trimmed returns
capture drop r_re_2022_trimmed
gen double r_re_2022_trimmed = r_re_2022 if re_sample
replace r_re_2022_trimmed = . if r_re_2022 < p5 | r_re_2022 > p95

* Summary of trimmed returns
di as txt "Trimmed real estate returns (r_re_2022_trimmed) summary:"
summarize r_re_2022_trimmed if re_sample, detail

quietly count if !missing(r_re_2022_trimmed) & re_sample
di as txt "Observations after trimming: " r(N)

* ---------------------------------------------------------------------
* Top 20 returns display
* ---------------------------------------------------------------------
di as txt "Top 20 positive real estate returns:"
gsort -r_re_2022
list HHID RSUBHH r_re_2022 yc_re_2022 cg_re_2022 F_re_2022 A_2020 F_2022 denom_re_2022 in 1/20 if re_sample

di as txt "Top 20 negative real estate returns:"
gsort r_re_2022
list HHID RSUBHH r_re_2022 yc_re_2022 cg_re_2022 F_re_2022 A_2020 F_2022 denom_re_2022 in 1/20 if re_sample

di as txt "Top 20 trimmed real estate returns:"
gsort -r_re_2022_trimmed
list HHID RSUBHH r_re_2022_trimmed yc_re_2022 cg_re_2022 F_re_2022 A_2020 F_2022 denom_re_2022 in 1/20 if !missing(r_re_2022_trimmed)

* ---------------------------------------------------------------------
* Zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Zero-value analysis ==="

quietly count if yc_re_2022 == 0 & re_sample
di as txt "Households with zero rental income: " r(N)
quietly count if cg_re_2022 == 0 & re_sample
di as txt "Households with zero capital gains: " r(N)
quietly count if F_re_2022 == 0 & re_sample
di as txt "Households with zero real estate flows: " r(N)

* ---------------------------------------------------------------------
* Save results
* ---------------------------------------------------------------------
di as txt "=== Saving results ==="

save "`master'", replace
di as txt "Saved real estate return variables to master: `master'"

* List of variables created
di as txt "Variables created:"
di as txt "  re_sample: sample indicator"
di as txt "  A_2020: beginning period net worth"
di as txt "  F_2022: total net investment flows"
di as txt "  denom_re_2022: final denominator"
di as txt "  yc_re_2022: rental income"
di as txt "  cg_re_2022: capital gains"
di as txt "  F_re_2022: real estate flows"
di as txt "  r_re_2022: raw returns"
di as txt "  r_re_2022_trimmed: trimmed returns"

log close
exit, clear
