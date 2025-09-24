*----------------------------------------------------------------------
* RAND: compute_retirement_returns.do
* Compute returns for RETIREMENT (IRA) assets for 2022
* Using lowercase RAND variable names
*
* Formula: r_ira = (yc_ira + cg_ira - F_ira) / (A_2020 + 0.5*F_2022)
*
* Where:
* - yc_ira = IRA payouts/annuity income (int_ira_2022)
* - cg_ira = capital gains for IRA (cg_ira_2022)
* - F_ira  = net investment flows into IRA (flow_ira_2022)
* - A_2020 = total beginning period net worth (networth_A2020)
* - F_2022 = total net investment flows (flow_total_2022)
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_retirement_returns_2022.log", replace text

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

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Define IRA sample
* Baseline: households with IRA totals in BOTH years (v_ira_2022 & v_ira_2020)
* Augmented: OR any numerator signal (IRA income amount+freq, or IRA flow components)
* ---------------------------------------------------------------------
di as txt "=== Defining IRA asset sample ==="

capture confirm variable v_ira_2022
if _rc {
    di as error "ERROR: v_ira_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}
capture confirm variable v_ira_2020
if _rc {
    di as error "ERROR: v_ira_2020 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}

gen byte has_ira_both = !missing(v_ira_2022) & !missing(v_ira_2020)
gen byte ira_exposure = 0
* Income exposure: IRA amount present AND mapped frequency multiplier present
* (int_ira_2022 was built from `a2022_ira' * `f2022_ira'_mult in the interest script)
capture confirm variable sq190
capture confirm variable sq194_mult
replace ira_exposure = 1 if !_rc & !missing(sq190) & !missing(sq194_mult)
* Flow exposure: any IRA flow component present (sq171_1/2/3)
replace ira_exposure = 1 if !missing(sq171_1) | !missing(sq171_2) | !missing(sq171_3)

* IRA sample: baseline OR exposure
gen byte ira_sample = has_ira_both | ira_exposure

di as txt "Sample definition results:"
tab ira_sample, missing
quietly count if ira_sample == 1
local n_ira_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in IRA asset sample: `n_ira_sample' out of `n_total' (" %4.1f 100*`n_ira_sample'/`n_total' "%)"

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Denominator components (A_2020, F_2022) ==="

capture drop A_2020 F_2022
gen double A_2020 = networth_A2020 if ira_sample
gen double F_2022 = flow_total_2022 if ira_sample
replace F_2022 = 0 if missing(F_2022) & ira_sample

di as txt "A_2020 summary (before final denominator threshold):"
summarize A_2020 if ira_sample, detail
tabstat A_2020 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "F_2022 summary:"
summarize F_2022 if ira_sample, detail
tabstat F_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Numerator components (treat missing as 0 within sample)
* ---------------------------------------------------------------------
di as txt "=== Building numerator components for IRA ==="

capture confirm variable int_ira_2022
if _rc {
    di as error "ERROR: int_ira_2022 not found. Run compute_int_inc_div_2020_2022.do first."
    exit 198
}
capture confirm variable cg_ira_2022
if _rc {
    di as error "ERROR: cg_ira_2022 not found. Run compute_cap_gains_2020_2022.do first."
    exit 198
}
capture confirm variable flow_ira_2022
if _rc {
    di as error "ERROR: flow_ira_2022 not found. Run compute_net_inv_flows_2020_2022.do first."
    exit 198
}

capture drop yc_ira_2022 F_ira_2022
gen double yc_ira_2022 = .
gen double F_ira_2022  = .
replace yc_ira_2022 = cond(missing(int_ira_2022),0,int_ira_2022) if ira_sample
replace F_ira_2022  = cond(missing(flow_ira_2022),0,flow_ira_2022) if ira_sample

di as txt "IRA income (yc_ira_2022) summary:"
summarize yc_ira_2022 if ira_sample, detail
tabstat yc_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA flows (F_ira_2022) summary:"
summarize F_ira_2022 if ira_sample, detail
tabstat F_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA capital gains (cg_ira_2022) summary:"
summarize cg_ira_2022 if ira_sample, detail
tabstat cg_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Denominator and thresholds
* ---------------------------------------------------------------------
di as txt "=== Computing IRA denominator and applying threshold ==="

capture drop denom_ira_2022
gen double denom_ira_2022 = A_2020 + 0.5*F_2022 if ira_sample

gen byte denom_ira_positive  = denom_ira_2022 > 0 if ira_sample
gen byte denom_ira_above_10k = denom_ira_2022 >= 10000 if ira_sample

di as txt "IRA denominator summary BEFORE final threshold:"
summarize denom_ira_2022 if ira_sample, detail
tabstat denom_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "IRA denominator thresholds:"
tab denom_ira_positive if ira_sample, missing
tab denom_ira_above_10k if ira_sample, missing

replace ira_sample = ira_sample & denom_ira_above_10k

quietly count if ira_sample == 1
local n_final_sample = r(N)
di as txt "Final IRA sample size after denominator threshold (≥$10k): `n_final_sample'"

di as txt "IRA denominator summary AFTER final threshold:"
summarize denom_ira_2022 if ira_sample, detail
tabstat denom_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Returns and trimming
* ---------------------------------------------------------------------
di as txt "=== Computing IRA returns ==="

capture drop r_ira_2022
gen double r_ira_2022 = .
replace r_ira_2022 = (yc_ira_2022 + cond(missing(cg_ira_2022),0,cg_ira_2022) - F_ira_2022) / denom_ira_2022 if ira_sample

di as txt "IRA returns summary:"
summarize r_ira_2022 if ira_sample, detail
tabstat r_ira_2022 if ira_sample, stats(n mean sd p50 min max) format(%12.4f)

quietly count if !missing(r_ira_2022) & ira_sample
local n_valid_returns = r(N)
di as txt "Records with valid r_ira_2022 computed = `n_valid_returns' out of `n_final_sample' in IRA sample"

di as txt "=== Applying 5% trimming to IRA returns ==="
_pctile r_ira_2022 if ira_sample & !missing(r_ira_2022), p(5 95)
scalar trim_low = r(r1)
scalar trim_high = r(r2)
di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

capture drop r_ira_2022_trim
gen double r_ira_2022_trim = r_ira_2022 if ira_sample & !missing(r_ira_2022) & inrange(r_ira_2022, trim_low, trim_high)

quietly count if !missing(r_ira_2022_trim)
local n_trim = r(N)
quietly count if ira_sample & !missing(r_ira_2022)
local n_original = r(N)
di as txt "Observations after 5% trimming: `n_trim' (dropped `=`n_original'-`n_trim'')"

di as txt "Trimmed IRA returns summary:"
summarize r_ira_2022_trim, detail
tabstat r_ira_2022_trim, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Descriptive splits: withdrawals vs no withdrawals
* (SQ171_* are withdrawals; contributions not observed here)
* ---------------------------------------------------------------------
di as txt "=== IRA returns by withdrawal status (untrimmed and trimmed) ==="
capture drop ira_withdrawal ira_no_withdrawal
gen byte ira_withdrawal     = F_ira_2022 > 0 if ira_sample
gen byte ira_no_withdrawal  = F_ira_2022 == 0 if ira_sample

di as txt "Untrimmed returns by withdrawal status:"
di as txt "  Withdrawal reported (F_ira_2022 > 0):"
summarize r_ira_2022 if ira_sample & ira_withdrawal, detail
di as txt "  No withdrawal (F_ira_2022 == 0):"
summarize r_ira_2022 if ira_sample & ira_no_withdrawal, detail

di as txt "Trimmed returns by withdrawal status:"
di as txt "  Withdrawal reported (trimmed):"
summarize r_ira_2022_trim if ira_withdrawal, detail
di as txt "  No withdrawal (trimmed):"
summarize r_ira_2022_trim if ira_no_withdrawal, detail

* ---------------------------------------------------------------------
* Diagnostics: extremes and zero-value checks
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extremes and components (IRA) ==="
di as txt "Top 20 positive IRA returns:"
gsort -r_ira_2022
list hhid rsubhh r_ira_2022 yc_ira_2022 cg_ira_2022 F_ira_2022 A_2020 F_2022 denom_ira_2022 in 1/20 if ira_sample

di as txt "Top 20 negative IRA returns:"
gsort r_ira_2022
list hhid rsubhh r_ira_2022 yc_ira_2022 cg_ira_2022 F_ira_2022 A_2020 F_2022 denom_ira_2022 in 1/20 if ira_sample

di as txt "Top 20 trimmed IRA returns:"
gsort -r_ira_2022_trim
list hhid rsubhh r_ira_2022_trim yc_ira_2022 cg_ira_2022 F_ira_2022 A_2020 F_2022 denom_ira_2022 in 1/20 if !missing(r_ira_2022_trim)

di as txt "=== Zero-value checks for components (IRA) ==="
quietly count if yc_ira_2022 == 0 & ira_sample
di as txt "yc_ira_2022 equals 0 in sample: " r(N)
quietly count if cg_ira_2022 == 0 & ira_sample
di as txt "cg_ira_2022 equals 0 in sample: " r(N)
quietly count if F_ira_2022 == 0 & ira_sample
di as txt "F_ira_2022 equals 0 in sample: " r(N)

* ---------------------------------------------------------------------
* Save back to master
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved IRA return variables to master: `master'"

di as txt "Done. IRA returns computed with 5% trimming."


