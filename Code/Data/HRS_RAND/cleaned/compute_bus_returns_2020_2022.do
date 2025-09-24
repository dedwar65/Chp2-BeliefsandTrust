*----------------------------------------------------------------------
* RAND: compute_bus_returns.do
* Compute returns for BUSINESS assets for 2022
* Using lowercase RAND variable names
*
* Formula: r_bus = (yc_bus + cg_bus - F_bus) / (A_2020 + 0.5*F_2022)
*
* Where:
* - yc_bus = business income (annualized from frequency/amount)
* - cg_bus = capital gains for business
* - F_bus  = net investment flows into business
* - A_2020 = total beginning period net worth
* - F_2022 = total net investment flows (all asset classes)
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_bus_returns_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* Prerequisites: run these 8 scripts first (manually)
* - extract_household_2020_ret_calc_end
* - extract_household_2022_ret_calc_start
* - merge_2020_2022
* - compute_int_inc_div_2020_2022
* - compute_net_inv_flows_2020_2022
* - compute_debt_payments_2020_2022
* - compute_cap_gains_2020_2022
* - compute_beg_per_net_worth_2020_2022
* ---------------------------------------------------------------------

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
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
local f2022_bus  sq153
local a2022_bus  sq155

* ---------------------------------------------------------------------
* Define BUSINESS sample
* Baseline: households with business values in BOTH years (sq148 & rq148)
* Augmented: OR any numerator signal (income amount+freq, or raw buy/sell flow)
* ---------------------------------------------------------------------
di as txt "=== Defining business asset sample ==="

gen byte has_business_both = !missing(sq148) & !missing(rq148)
gen byte bus_exposure = 0
* Income exposure: amount present AND mapped frequency multiplier present
replace bus_exposure = 1 if !missing(`a2022_bus') & !missing(`f2022_bus'_mult)
* Flow exposure: any raw buy/sell present
replace bus_exposure = 1 if !missing(sr050) | !missing(sr055)

* Business sample: baseline OR exposure
gen byte bus_sample = has_business_both | bus_exposure

di as txt "Sample definition results:"
tab bus_sample, missing
quietly count if bus_sample == 1
local n_bus_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in business asset sample: `n_bus_sample' out of `n_total' (" %4.1f 100*`n_bus_sample'/`n_total' "%)"

di as txt "Additional inclusions due to numerator exposure:"
tab bus_exposure if !has_business_both, missing

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Denominator components (A_2020, F_2022) ==="

capture drop A_2020
gen double A_2020 = networth_A2020 if bus_sample

* ---------------------------------------------------------------------
* Denominator flows: total flows across all asset classes (flow_total_2022)
* Treat missing as 0 within the business sample
* ---------------------------------------------------------------------
di as txt "=== Using total flows (F_2022) component for denominator ==="

capture drop F_2022
gen double F_2022 = flow_total_2022 if bus_sample
replace F_2022 = 0 if missing(F_2022) & bus_sample

di as txt "Total flows (F_2022) summary:"
summarize F_2022 if bus_sample, detail
tabstat F_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Numerator components for BUSINESS
*  - F_bus_2022: net investment flows into business (flow_bus_2022)
*  - yc_bus_2022: business income (int_bus_2022)
*  - cg_bus_2022: capital gains from business
* Treat missing components as 0 within the business sample
* ---------------------------------------------------------------------
di as txt "=== Building numerator components for business ==="

capture drop F_bus_2022 yc_bus_2022
gen double F_bus_2022  = .
gen double yc_bus_2022 = .

replace F_bus_2022  = cond(missing(flow_bus_2022),0,flow_bus_2022) if bus_sample
replace yc_bus_2022 = cond(missing(int_bus_2022), 0,int_bus_2022)  if bus_sample

di as txt "Business flows (F_bus_2022) summary:"
summarize F_bus_2022 if bus_sample, detail
tabstat F_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Business income (yc_bus_2022) summary:"
summarize yc_bus_2022 if bus_sample, detail
tabstat yc_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

* Capital gains already constructed in compute_cap_gains_2020_2022.do as cg_bus_2022
capture confirm variable cg_bus_2022
if _rc {
    di as error "ERROR: cg_bus_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}

di as txt "Business capital gains (cg_bus_2022) summary:"
summarize cg_bus_2022 if bus_sample, detail
tabstat cg_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute BUSINESS returns
* Denominator: A_2020 + 0.5*F_2022 (same across all asset-class return files)
* Apply final ≥$10k threshold to this denominator and compute returns
* ---------------------------------------------------------------------
di as txt "=== Computing business asset returns ==="

capture drop denom_bus_2022
gen double denom_bus_2022 = A_2020 + 0.5*F_2022 if bus_sample

gen byte denom_bus_positive   = denom_bus_2022 > 0 if bus_sample
gen byte denom_bus_above_10k  = denom_bus_2022 >= 10000 if bus_sample

di as txt "Business denominator (A_2020 + 0.5*F_2022) summary BEFORE final threshold:"
summarize denom_bus_2022 if bus_sample, detail
tabstat denom_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

* Count before applying denominator threshold
quietly count if bus_sample == 1
local n_initial_sample = r(N)
di as txt "Initial sample size before denominator threshold: `n_initial_sample'"

replace bus_sample = bus_sample & denom_bus_above_10k

di as txt "Final sample size after denominator threshold (≥$10k):"
quietly count if bus_sample == 1
local n_final_sample = r(N)
di as txt "Final business sample size: `n_final_sample'"

di as txt "Business denominator (A_2020 + 0.5*F_2022) summary AFTER final threshold:"
summarize denom_bus_2022 if bus_sample, detail
tabstat denom_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.2f)

* Final return
capture drop r_bus_2022
gen double r_bus_2022 = .
replace r_bus_2022 = (yc_bus_2022 + cond(missing(cg_bus_2022),0,cg_bus_2022) - F_bus_2022) / denom_bus_2022 if bus_sample

* ---------------------------------------------------------------------
* Report return statistics
* ---------------------------------------------------------------------
di as txt "=== Business asset returns summary ==="

di as txt "Summary stats for business asset returns (r_bus_2022):"
summarize r_bus_2022 if bus_sample, detail
tabstat r_bus_2022 if bus_sample, stats(n mean sd p50 min max) format(%12.4f)

quietly count if !missing(r_bus_2022) & bus_sample
local n_valid_returns = r(N)
di as txt "Records with valid r_bus_2022 computed = `n_valid_returns' out of `n_final_sample' in business sample"

* ---------------------------------------------------------------------
* Apply trimming (top and bottom 5%)
* ---------------------------------------------------------------------
di as txt "=== Applying 5% trimming to business asset returns ==="

_pctile r_bus_2022 if bus_sample & !missing(r_bus_2022), p(5 95)
scalar trim_low = r(r1)
scalar trim_high = r(r2)

di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

capture drop r_bus_2022_trim
gen double r_bus_2022_trim = r_bus_2022 if bus_sample & !missing(r_bus_2022) & inrange(r_bus_2022, trim_low, trim_high)

quietly count if !missing(r_bus_2022_trim)
local n_trim = r(N)
quietly count if bus_sample & !missing(r_bus_2022)
local n_original = r(N)
di as txt "Observations after 5% trimming: `n_trim' (dropped `=`n_original'-`n_trim'')"

di as txt "Trimmed business asset returns summary:"
summarize r_bus_2022_trim, detail
tabstat r_bus_2022_trim, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Diagnostics: extremes and zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extremes and components (business) ==="

di as txt "Top 20 positive business returns:"
gsort -r_bus_2022
list hhid rsubhh r_bus_2022 yc_bus_2022 cg_bus_2022 F_bus_2022 A_2020 F_2022 denom_bus_2022 in 1/20 if bus_sample

di as txt "Top 20 negative business returns:"
gsort r_bus_2022
list hhid rsubhh r_bus_2022 yc_bus_2022 cg_bus_2022 F_bus_2022 A_2020 F_2022 denom_bus_2022 in 1/20 if bus_sample

di as txt "Top 20 trimmed business returns:"
gsort -r_bus_2022_trim
list hhid rsubhh r_bus_2022_trim yc_bus_2022 cg_bus_2022 F_bus_2022 A_2020 F_2022 denom_bus_2022 in 1/20 if !missing(r_bus_2022_trim)

* ---------------------------------------------------------------------
* Zero-value checks for components (business)
* ---------------------------------------------------------------------
di as txt "=== Zero-value checks for components (business) ==="
quietly count if yc_bus_2022 == 0 & bus_sample
di as txt "yc_bus_2022 equals 0 in sample: " r(N)
quietly count if cg_bus_2022 == 0 & bus_sample
di as txt "cg_bus_2022 equals 0 in sample: " r(N)
quietly count if F_bus_2022 == 0 & bus_sample
di as txt "F_bus_2022 equals 0 in sample: " r(N)

* ---------------------------------------------------------------------
* Save back to master
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved business asset return variables to master: `master'"

di as txt "Done. Business asset returns computed with 5% trimming."


