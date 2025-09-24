*----------------------------------------------------------------------
* HRS (Core): compute_bus_returns.do
* Compute returns for BUSINESS assets for 2022
* Using uppercase HRS variable names
*
* Formula: r_bus = (yc_bus + cg_bus - F_bus) / (A_2020 + 0.5*F_2022)
*
* Where:
* - yc_bus = business income (annualized from frequency/amount) -> INT_BUS_2022
* - cg_bus = capital gains for business -> CG_BUS_2022
* - F_bus  = net investment flows into business -> FLOW_BUS_2022
* - A_2020 = total beginning period net worth -> NETWORTH_A2020
* - F_2022 = total net investment flows (all asset classes) -> FLOW_TOTAL_2022
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_bus_returns_2022.log", replace text

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
local F2022_BUS  SQ153
local A2022_BUS  SQ155

* ---------------------------------------------------------------------
* Define BUSINESS sample
* Baseline: households with business values in BOTH years (SQ148 & RQ148)
* Augmented: OR any numerator signal (income amount+freq, or raw buy/sell flow)
* ---------------------------------------------------------------------
di as txt "=== Defining business asset sample ==="

gen byte HAS_BUSINESS_BOTH = !missing(SQ148) & !missing(RQ148)
gen byte BUS_EXPOSURE = 0
* Income exposure: amount present AND mapped frequency multiplier present
replace BUS_EXPOSURE = 1 if !missing(`A2022_BUS') & !missing(`F2022_BUS'_mult)
* Flow exposure: any raw buy/sell present
replace BUS_EXPOSURE = 1 if !missing(SR050) | !missing(SR055)

* Business sample: baseline OR exposure
gen byte BUS_SAMPLE = HAS_BUSINESS_BOTH | BUS_EXPOSURE

di as txt "Sample definition results:"
tab BUS_SAMPLE, missing
quietly count if BUS_SAMPLE == 1
local n_bus_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in business asset sample: `n_bus_sample' out of `n_total' (" %4.1f 100*`n_bus_sample'/`n_total' "%)"

di as txt "Additional inclusions due to numerator exposure:"
tab BUS_EXPOSURE if !HAS_BUSINESS_BOTH, missing

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Denominator components (A_2020, F_2022) ==="

capture drop A_2020
gen double A_2020 = NETWORTH_A2020 if BUS_SAMPLE

* ---------------------------------------------------------------------
* Denominator flows: total flows across all asset classes (FLOW_TOTAL_2022)
* Treat missing as 0 within the business sample
* ---------------------------------------------------------------------
di as txt "=== Using total flows (F_2022) component for denominator ==="

capture drop F_2022
gen double F_2022 = FLOW_TOTAL_2022 if BUS_SAMPLE
replace F_2022 = 0 if missing(F_2022) & BUS_SAMPLE

di as txt "Total flows (F_2022) summary:"
summarize F_2022 if BUS_SAMPLE, detail
tabstat F_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Numerator components for BUSINESS
*  - F_bus_2022: net investment flows into business (FLOW_BUS_2022)
*  - yc_bus_2022: business income (INT_BUS_2022)
*  - cg_bus_2022: capital gains from business (CG_BUS_2022)
* Treat missing components as 0 within the business sample
* ---------------------------------------------------------------------
di as txt "=== Building numerator components for business ==="

capture drop F_BUS_2022 YC_BUS_2022
gen double F_BUS_2022  = .
gen double YC_BUS_2022 = .

replace F_BUS_2022  = cond(missing(FLOW_BUS_2022),0,FLOW_BUS_2022) if BUS_SAMPLE
replace YC_BUS_2022 = cond(missing(INT_BUS_2022), 0,INT_BUS_2022)  if BUS_SAMPLE

di as txt "Business flows (F_BUS_2022) summary:"
summarize F_BUS_2022 if BUS_SAMPLE, detail
tabstat F_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Business income (YC_BUS_2022) summary:"
summarize YC_BUS_2022 if BUS_SAMPLE, detail
tabstat YC_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

capture confirm variable CG_BUS_2022
if _rc {
    di as error "ERROR: CG_BUS_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}

di as txt "Business capital gains (CG_BUS_2022) summary:"
summarize CG_BUS_2022 if BUS_SAMPLE, detail
tabstat CG_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute BUSINESS returns
* Denominator: A_2020 + 0.5*F_2022 (same across all asset-class return files)
* Apply final ≥$10k threshold to this denominator and compute returns
* ---------------------------------------------------------------------
di as txt "=== Computing business asset returns ==="

capture drop DENOM_BUS_2022
gen double DENOM_BUS_2022 = A_2020 + 0.5*F_2022 if BUS_SAMPLE

gen byte DENOM_BUS_POSITIVE  = DENOM_BUS_2022 > 0 if BUS_SAMPLE
gen byte DENOM_BUS_ABOVE_10K = DENOM_BUS_2022 >= 10000 if BUS_SAMPLE

di as txt "Business denominator (A_2020 + 0.5*F_2022) summary BEFORE final threshold:"
summarize DENOM_BUS_2022 if BUS_SAMPLE, detail
tabstat DENOM_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* Count before applying denominator threshold
quietly count if BUS_SAMPLE == 1
local n_initial_sample = r(N)
di as txt "Initial sample size before denominator threshold: `n_initial_sample'"

replace BUS_SAMPLE = BUS_SAMPLE & DENOM_BUS_ABOVE_10K

di as txt "Final sample size after denominator threshold (≥$10k):"
quietly count if BUS_SAMPLE == 1
local n_final_sample = r(N)
di as txt "Final business sample size: `n_final_sample'"

di as txt "Business denominator (A_2020 + 0.5*F_2022) summary AFTER final threshold:"
summarize DENOM_BUS_2022 if BUS_SAMPLE, detail
tabstat DENOM_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* Final return
capture drop R_BUS_2022
gen double R_BUS_2022 = .
replace R_BUS_2022 = (YC_BUS_2022 + cond(missing(CG_BUS_2022),0,CG_BUS_2022) - F_BUS_2022) / DENOM_BUS_2022 if BUS_SAMPLE

* ---------------------------------------------------------------------
* Report return statistics
* ---------------------------------------------------------------------
di as txt "=== Business asset returns summary ==="

di as txt "Summary stats for business asset returns (R_BUS_2022):"
summarize R_BUS_2022 if BUS_SAMPLE, detail
tabstat R_BUS_2022 if BUS_SAMPLE, stats(n mean sd p50 min max) format(%12.4f)

quietly count if !missing(R_BUS_2022) & BUS_SAMPLE
local n_valid_returns = r(N)
di as txt "Records with valid R_BUS_2022 computed = `n_valid_returns' out of `n_final_sample' in business sample"

* ---------------------------------------------------------------------
* Apply trimming (top and bottom 5%)
* ---------------------------------------------------------------------
di as txt "=== Applying 5% trimming to business asset returns ==="

_pctile R_BUS_2022 if BUS_SAMPLE & !missing(R_BUS_2022), p(5 95)
scalar trim_low = r(r1)
scalar trim_high = r(r2)

di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

capture drop R_BUS_2022_TRIM
gen double R_BUS_2022_TRIM = R_BUS_2022 if BUS_SAMPLE & !missing(R_BUS_2022) & inrange(R_BUS_2022, trim_low, trim_high)

quietly count if !missing(R_BUS_2022_TRIM)
local n_trim = r(N)
quietly count if BUS_SAMPLE & !missing(R_BUS_2022)
local n_original = r(N)
di as txt "Observations after 5% trimming: `n_trim' (dropped `=`n_original'-`n_trim'')"

di as txt "Trimmed business asset returns summary:"
summarize R_BUS_2022_TRIM, detail
tabstat R_BUS_2022_TRIM, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Diagnostics: extremes and zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extremes and components (business) ==="

di as txt "Top 20 positive business returns:"
gsort -R_BUS_2022
list HHID RSUBHH R_BUS_2022 YC_BUS_2022 CG_BUS_2022 F_BUS_2022 A_2020 F_2022 DENOM_BUS_2022 in 1/20 if BUS_SAMPLE

di as txt "Top 20 negative business returns:"
gsort R_BUS_2022
list HHID RSUBHH R_BUS_2022 YC_BUS_2022 CG_BUS_2022 F_BUS_2022 A_2020 F_2022 DENOM_BUS_2022 in 1/20 if BUS_SAMPLE

di as txt "Top 20 trimmed business returns:"
gsort -R_BUS_2022_TRIM
list HHID RSUBHH R_BUS_2022_TRIM YC_BUS_2022 CG_BUS_2022 F_BUS_2022 A_2020 F_2022 DENOM_BUS_2022 in 1/20 if !missing(R_BUS_2022_TRIM)

* ---------------------------------------------------------------------
* Zero-value checks for components (business)
* ---------------------------------------------------------------------
di as txt "=== Zero-value checks for components (business) ==="
quietly count if YC_BUS_2022 == 0 & BUS_SAMPLE
di as txt "YC_BUS_2022 equals 0 in sample: " r(N)
quietly count if CG_BUS_2022 == 0 & BUS_SAMPLE
di as txt "CG_BUS_2022 equals 0 in sample: " r(N)
quietly count if F_BUS_2022 == 0 & BUS_SAMPLE
di as txt "F_BUS_2022 equals 0 in sample: " r(N)

* ---------------------------------------------------------------------
* Save back to master
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved business asset return variables to master: `master'"

di as txt "Done. Business asset returns computed with 5% trimming."


