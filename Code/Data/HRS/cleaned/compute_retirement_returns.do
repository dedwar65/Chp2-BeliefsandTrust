*----------------------------------------------------------------------
* HRS (Core): compute_retirement_returns.do
* Compute returns for RETIREMENT (IRA) assets for 2022
* Using uppercase HRS variable names
*
* Formula: R_IRA = (YC_IRA + CG_IRA - F_IRA) / (A_2020 + 0.5*F_2022)
*
* Where:
* - YC_IRA = IRA payouts/annuity income (INT_IRA_2022)
* - CG_IRA = capital gains for IRA (CG_IRA_2022)
* - F_IRA  = net investment flows into IRA (FLOW_IRA_2022)
* - A_2020 = total beginning period net worth (NETWORTH_A2020)
* - F_2022 = total net investment flows (FLOW_TOTAL_2022)
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_retirement_returns_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* Prerequisites (run manually first):
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
* Define IRA sample
* Baseline: households with IRA totals in BOTH years (V_IRA_2022 & V_IRA_2020)
* Augmented: OR any numerator signal (IRA income amount+freq, or IRA flow components)
* ---------------------------------------------------------------------
di as txt "=== Defining IRA asset sample ==="

capture confirm variable V_IRA_2022
if _rc {
    di as error "ERROR: V_IRA_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}
capture confirm variable V_IRA_2020
if _rc {
    di as error "ERROR: V_IRA_2020 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}

gen byte HAS_IRA_BOTH = !missing(V_IRA_2022) & !missing(V_IRA_2020)
gen byte IRA_EXPOSURE = 0
* Income exposure: IRA amount present AND mapped frequency multiplier present
capture confirm variable SQ190
capture confirm variable SQ194_mult
replace IRA_EXPOSURE = 1 if !_rc & !missing(SQ190) & !missing(SQ194_mult)
* Flow exposure: any IRA flow component present (SQ171_1/2/3)
replace IRA_EXPOSURE = 1 if !missing(SQ171_1) | !missing(SQ171_2) | !missing(SQ171_3)

* IRA sample: baseline OR exposure
gen byte IRA_SAMPLE = HAS_IRA_BOTH | IRA_EXPOSURE

di as txt "Sample definition results:"
tab IRA_SAMPLE, missing
quietly count if IRA_SAMPLE == 1
local n_ira_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in IRA asset sample: `n_ira_sample' out of `n_total' (" %4.1f 100*`n_ira_sample'/`n_total' "%)"

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Denominator components (A_2020, F_2022) ==="

capture drop A_2020 F_2022
gen double A_2020 = NETWORTH_A2020 if IRA_SAMPLE
gen double F_2022 = FLOW_TOTAL_2022 if IRA_SAMPLE
replace F_2022 = 0 if missing(F_2022) & IRA_SAMPLE

di as txt "A_2020 summary (before final denominator threshold):"
summarize A_2020 if IRA_SAMPLE, detail
tabstat A_2020 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

di as txt "F_2022 summary:"
summarize F_2022 if IRA_SAMPLE, detail
tabstat F_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Numerator components (treat missing as 0 within sample)
* ---------------------------------------------------------------------
di as txt "=== Building numerator components for IRA ==="

capture confirm variable INT_IRA_2022
if _rc {
    di as error "ERROR: INT_IRA_2022 not found. Run compute_int_inc_div_2020_2022.do first."
    exit 198
}
capture confirm variable CG_IRA_2022
if _rc {
    di as error "ERROR: CG_IRA_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}
capture confirm variable FLOW_IRA_2022
if _rc {
    di as error "ERROR: FLOW_IRA_2022 not found. Run compute_net_inv_flows_2020_2022.do first."
    exit 198
}

capture drop YC_IRA_2022 F_IRA_2022
gen double YC_IRA_2022 = .
gen double F_IRA_2022  = .
replace YC_IRA_2022 = cond(missing(INT_IRA_2022),0,INT_IRA_2022) if IRA_SAMPLE
replace F_IRA_2022  = cond(missing(FLOW_IRA_2022),0,FLOW_IRA_2022) if IRA_SAMPLE

di as txt "IRA income (YC_IRA_2022) summary:"
summarize YC_IRA_2022 if IRA_SAMPLE, detail
tabstat YC_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA flows (F_IRA_2022) summary:"
summarize F_IRA_2022 if IRA_SAMPLE, detail
tabstat F_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA capital gains (CG_IRA_2022) summary:"
summarize CG_IRA_2022 if IRA_SAMPLE, detail
tabstat CG_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Denominator and thresholds
* ---------------------------------------------------------------------
di as txt "=== Computing IRA denominator and applying threshold ==="

capture drop DENOM_IRA_2022
gen double DENOM_IRA_2022 = A_2020 + 0.5*F_2022 if IRA_SAMPLE

gen byte DENOM_IRA_POSITIVE  = DENOM_IRA_2022 > 0 if IRA_SAMPLE
gen byte DENOM_IRA_ABOVE_10K = DENOM_IRA_2022 >= 10000 if IRA_SAMPLE

di as txt "IRA denominator summary BEFORE final threshold:"
summarize DENOM_IRA_2022 if IRA_SAMPLE, detail
tabstat DENOM_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA denominator thresholds:"
tab DENOM_IRA_POSITIVE if IRA_SAMPLE, missing
tab DENOM_IRA_ABOVE_10K if IRA_SAMPLE, missing

replace IRA_SAMPLE = IRA_SAMPLE & DENOM_IRA_ABOVE_10K

quietly count if IRA_SAMPLE == 1
local n_final_sample = r(N)
di as txt "Final IRA sample size after denominator threshold (≥$10k): `n_final_sample'"

di as txt "IRA denominator summary AFTER final threshold:"
summarize DENOM_IRA_2022 if IRA_SAMPLE, detail
tabstat DENOM_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Returns and trimming
* ---------------------------------------------------------------------
di as txt "=== Computing IRA returns ==="

capture drop R_IRA_2022
gen double R_IRA_2022 = .
replace R_IRA_2022 = (YC_IRA_2022 + cond(missing(CG_IRA_2022),0,CG_IRA_2022) - F_IRA_2022) / DENOM_IRA_2022 if IRA_SAMPLE

di as txt "IRA returns summary:"
summarize R_IRA_2022 if IRA_SAMPLE, detail
tabstat R_IRA_2022 if IRA_SAMPLE, stats(n mean sd p50 min max) format(%12.4f)

quietly count if !missing(R_IRA_2022) & IRA_SAMPLE
local n_valid_returns = r(N)
di as txt "Records with valid R_IRA_2022 computed = `n_valid_returns' out of `n_final_sample' in IRA sample"

di as txt "=== Applying 5% trimming to IRA returns ==="
_pctile R_IRA_2022 if IRA_SAMPLE & !missing(R_IRA_2022), p(5 95)
scalar trim_low = r(r1)
scalar trim_high = r(r2)
di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

capture drop R_IRA_2022_TRIM
gen double R_IRA_2022_TRIM = R_IRA_2022 if IRA_SAMPLE & !missing(R_IRA_2022) & inrange(R_IRA_2022, trim_low, trim_high)

quietly count if !missing(R_IRA_2022_TRIM)
local n_trim = r(N)
quietly count if IRA_SAMPLE & !missing(R_IRA_2022)
local n_original = r(N)
di as txt "Observations after 5% trimming: `n_trim' (dropped `=`n_original'-`n_trim'')"

di as txt "Trimmed IRA returns summary:"
summarize R_IRA_2022_TRIM, detail
tabstat R_IRA_2022_TRIM, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Descriptive splits: withdrawals vs no withdrawals
* (SQ171_* are withdrawals; contributions not observed here)
* ---------------------------------------------------------------------
di as txt "=== IRA returns by withdrawal status (untrimmed and trimmed) ==="
capture drop IRA_WITHDRAWAL IRA_NO_WITHDRAWAL
gen byte IRA_WITHDRAWAL     = F_IRA_2022 > 0 if IRA_SAMPLE
gen byte IRA_NO_WITHDRAWAL  = F_IRA_2022 == 0 if IRA_SAMPLE

di as txt "Untrimmed returns by withdrawal status:"
di as txt "  Withdrawal reported (F_IRA_2022 > 0):"
summarize R_IRA_2022 if IRA_SAMPLE & IRA_WITHDRAWAL, detail
di as txt "  No withdrawal (F_IRA_2022 == 0):"
summarize R_IRA_2022 if IRA_SAMPLE & IRA_NO_WITHDRAWAL, detail

di as txt "Trimmed returns by withdrawal status:"
di as txt "  Withdrawal reported (trimmed):"
summarize R_IRA_2022_TRIM if IRA_WITHDRAWAL, detail
di as txt "  No withdrawal (trimmed):"
summarize R_IRA_2022_TRIM if IRA_NO_WITHDRAWAL, detail

* ---------------------------------------------------------------------
* Diagnostics: extremes and zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extremes and components (IRA) ==="
di as txt "Top 20 positive IRA returns:"
gsort -R_IRA_2022
list HHID RSUBHH R_IRA_2022 YC_IRA_2022 CG_IRA_2022 F_IRA_2022 A_2020 F_2022 DENOM_IRA_2022 in 1/20 if IRA_SAMPLE

di as txt "Top 20 negative IRA returns:"
gsort R_IRA_2022
list HHID RSUBHH R_IRA_2022 YC_IRA_2022 CG_IRA_2022 F_IRA_2022 A_2020 F_2022 DENOM_IRA_2022 in 1/20 if IRA_SAMPLE

di as txt "Top 20 trimmed IRA returns:"
gsort -R_IRA_2022_TRIM
list HHID RSUBHH R_IRA_2022_TRIM YC_IRA_2022 CG_IRA_2022 F_IRA_2022 A_2020 F_2022 DENOM_IRA_2022 in 1/20 if !missing(R_IRA_2022_TRIM)

di as txt "=== Zero-value checks for components (IRA) ==="
quietly count if YC_IRA_2022 == 0 & IRA_SAMPLE
di as txt "YC_IRA_2022 equals 0 in sample: " r(N)
quietly count if CG_IRA_2022 == 0 & IRA_SAMPLE
di as txt "CG_IRA_2022 equals 0 in sample: " r(N)
quietly count if F_IRA_2022 == 0 & IRA_SAMPLE
di as txt "F_IRA_2022 equals 0 in sample: " r(N)

* ---------------------------------------------------------------------
* Save back to master
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved IRA return variables to master: `master'"

di as txt "Done. IRA returns computed with 5% trimming."


