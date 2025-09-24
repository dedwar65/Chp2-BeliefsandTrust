*----------------------------------------------------------------------
* compute_fin_asset_returns.do
* Compute returns for financial assets (stocks + bonds) for 2022
* 
* Formula: r_fin = (yc_fin + cg_fin - F_fin) / (A_2020 + 0.5*F_2022)
* 
* Where:
* - yc_fin = interest income from stocks, bonds, checking/savings, CDs
* - cg_fin = capital gains from stocks + bonds
* - F_fin = net investment flows into financial assets (stocks only)
* - A_2020 = total beginning period net worth
* - F_2022 = total net investment flows
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_fin_asset_returns.log", replace text

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
* Define financial asset sample: households with stocks OR bonds in both years
* ---------------------------------------------------------------------
di as txt "=== Defining financial asset sample ==="

* Check for stocks in both years (SQ317 and RQ317)
gen byte has_stocks_both = !missing(SQ317) & !missing(RQ317)

* Check for bonds in both years (SQ331 and RQ331)  
gen byte has_bonds_both = !missing(SQ331) & !missing(RQ331)

* Financial asset sample: must have either stocks OR bonds in both years
gen byte fin_sample = has_stocks_both | has_bonds_both

* Report sample statistics
di as txt "Sample definition results:"
tab fin_sample, missing
quietly count if fin_sample == 1
local n_fin_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in financial asset sample: `n_fin_sample' out of `n_total' (" %4.1f 100*`n_fin_sample'/`n_total' "%)"

* Breakdown by asset type
di as txt "Breakdown by asset type:"
tab has_stocks_both has_bonds_both, missing
quietly count if has_stocks_both & has_bonds_both
di as txt "Households with BOTH stocks and bonds in both years: " r(N)
quietly count if has_stocks_both & !has_bonds_both
di as txt "Households with stocks only (both years): " r(N)
quietly count if !has_stocks_both & has_bonds_both
di as txt "Households with bonds only (both years): " r(N)

* ---------------------------------------------------------------------
* Use total wealth (beginning of period net worth) as denominator
* ---------------------------------------------------------------------
di as txt "=== Using total wealth (A_2020) as denominator ==="

* Use existing networth_A2020 (total beginning of period wealth)
capture drop A_2020
gen double A_2020 = networth_A2020 if fin_sample

* Apply wealth threshold (10k minimum) to restrict sample
gen byte A_positive = A_2020 > 0 if fin_sample
gen byte A_above_10k = A_2020 >= 10000 if fin_sample

di as txt "Total wealth (A_2020) summary (before final denominator threshold):"
summarize A_2020 if fin_sample, detail
tabstat A_2020 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Initial wealth threshold results:"
quietly count if fin_sample == 1
local n_initial_sample = r(N)
di as txt "Initial sample size after beginning wealth threshold (≥$10k): `n_initial_sample'"
tab A_positive if fin_sample, missing
tab A_above_10k if fin_sample, missing

* ---------------------------------------------------------------------
* Compute financial asset flows (F_fin_2022) for numerator
* ---------------------------------------------------------------------
di as txt "=== Computing financial asset flows (F_fin_2022) for numerator ==="

* Financial asset flows = stock flows only (bonds have no flows)
capture drop F_fin_2022
gen double F_fin_2022 = .
* For stocks: use flow_stk_2022, treat missing as 0 if they have stocks in both years
* For bonds: no flows, so always 0
replace F_fin_2022 = cond(missing(flow_stk_2022),0,flow_stk_2022) if fin_sample

di as txt "Financial asset flows (F_fin_2022) summary:"
summarize F_fin_2022 if fin_sample, detail
tabstat F_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Use total flows (F_2022) as denominator
* ---------------------------------------------------------------------
di as txt "=== Using total flows (F_2022) as denominator ==="

* Use existing flow_total_2022 (total net investment flows)
capture drop F_2022
gen double F_2022 = flow_total_2022 if fin_sample
* Treat missing total flows as 0 for financial sample
replace F_2022 = 0 if missing(F_2022) & fin_sample

di as txt "Total flows (F_2022) summary:"
summarize F_2022 if fin_sample, detail
tabstat F_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute financial asset interest income (yc_fin_2022)
* ---------------------------------------------------------------------
di as txt "=== Computing financial asset interest income (yc_fin_2022) ==="

* Financial asset interest = stocks + bonds + checking/savings + CDs
capture drop yc_fin_2022
gen double yc_fin_2022 = .
* Sum interest income from financial assets, treat missing as 0 if they have financial assets
replace yc_fin_2022 = cond(missing(int_stk_2022),0,int_stk_2022) + ///
                     cond(missing(int_bnd_2022),0,int_bnd_2022) + ///
                     cond(missing(int_cash_2022),0,int_cash_2022) + ///
                     cond(missing(int_cds_2022),0,int_cds_2022) if fin_sample

di as txt "Financial asset interest income (yc_fin_2022) summary:"
summarize yc_fin_2022 if fin_sample, detail
tabstat yc_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute financial asset capital gains (cg_fin_2022)
* ---------------------------------------------------------------------
di as txt "=== Computing financial asset capital gains (cg_fin_2022) ==="

* Financial asset capital gains = stocks + bonds
capture drop cg_fin_2022
gen double cg_fin_2022 = .
* Sum capital gains from financial assets, treat missing as 0 if they have financial assets
replace cg_fin_2022 = cond(missing(cg_stk_2022),0,cg_stk_2022) + ///
                     cond(missing(cg_bnd_2022),0,cg_bnd_2022) if fin_sample

di as txt "Financial asset capital gains (cg_fin_2022) summary:"
summarize cg_fin_2022 if fin_sample, detail
tabstat cg_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute financial asset returns
* ---------------------------------------------------------------------
di as txt "=== Computing financial asset returns ==="

* Denominator: A_2020 + 0.5*F_2022
capture drop denom_fin_2022
gen double denom_fin_2022 = A_2020 + 0.5*F_2022 if fin_sample

* Check for positive denominators and apply final wealth threshold
gen byte denom_fin_positive = denom_fin_2022 > 0 if fin_sample
gen byte denom_fin_above_10k = denom_fin_2022 >= 10000 if fin_sample

di as txt "Financial asset denominator (A_2020 + 0.5*F_2022) summary BEFORE final threshold:"
summarize denom_fin_2022 if fin_sample, detail
tabstat denom_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

di as txt "Financial asset denominator thresholds:"
tab denom_fin_positive if fin_sample, missing
tab denom_fin_above_10k if fin_sample, missing

* Update financial sample to include final denominator threshold
replace fin_sample = fin_sample & denom_fin_above_10k

di as txt "Final sample restriction results:"
quietly count if fin_sample == 1
local n_final_sample = r(N)
di as txt "Final sample size after denominator threshold (≥$10k): `n_final_sample'"
di as txt "Observations dropped due to negative/small denominators: `=`n_initial_sample'-`n_final_sample''"

di as txt "Financial asset denominator (A_2020 + 0.5*F_2022) summary AFTER final threshold:"
summarize denom_fin_2022 if fin_sample, detail
tabstat denom_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Summary of all key components before return calculation
* ---------------------------------------------------------------------
di as txt "=== Summary of all key components ==="

di as txt "Numerator components:"
di as txt "  Interest income (yc_fin_2022):"
summarize yc_fin_2022 if fin_sample, detail
di as txt "  Capital gains (cg_fin_2022):"
summarize cg_fin_2022 if fin_sample, detail
di as txt "  Net investment flows (F_fin_2022):"
summarize F_fin_2022 if fin_sample, detail

di as txt "Denominator components:"
di as txt "  Beginning wealth (A_2020):"
summarize A_2020 if fin_sample, detail
di as txt "  Total flows (F_2022):"
summarize F_2022 if fin_sample, detail
di as txt "  Final denominator (A_2020 + 0.5*F_2022):"
summarize denom_fin_2022 if fin_sample, detail

* Cross-tabulation of component presence
di as txt "Component presence patterns:"
quietly count if !missing(yc_fin_2022) & fin_sample
di as txt "  yc_fin_2022 non-missing: " r(N)
quietly count if !missing(cg_fin_2022) & fin_sample
di as txt "  cg_fin_2022 non-missing: " r(N)
quietly count if !missing(F_fin_2022) & fin_sample
di as txt "  F_fin_2022 non-missing: " r(N)
quietly count if !missing(A_2020) & fin_sample
di as txt "  A_2020 non-missing: " r(N)
quietly count if !missing(F_2022) & fin_sample
di as txt "  F_2022 non-missing: " r(N)

* Return calculation (sample already filtered for positive denominators ≥$10k)
capture drop r_fin_2022
gen double r_fin_2022 = .
replace r_fin_2022 = (yc_fin_2022 + cg_fin_2022 - F_fin_2022) / denom_fin_2022 if fin_sample

* ---------------------------------------------------------------------
* Report return statistics
* ---------------------------------------------------------------------
di as txt "=== Financial asset returns summary ==="

di as txt "Summary stats for financial asset returns (r_fin_2022):"
summarize r_fin_2022 if fin_sample, detail
tabstat r_fin_2022 if fin_sample, stats(n mean sd p50 min max) format(%12.4f)

* Count valid returns
quietly count if !missing(r_fin_2022) & fin_sample
local n_valid_returns = r(N)
di as txt "Records with valid r_fin_2022 computed = `n_valid_returns' out of `n_fin_sample' in financial sample"

* ---------------------------------------------------------------------
* Apply trimming (top and bottom 5%)
* ---------------------------------------------------------------------
di as txt "=== Applying 5% trimming to financial asset returns ==="

* Calculate trim thresholds (5% from each tail)
_pctile r_fin_2022 if fin_sample & !missing(r_fin_2022), p(5 95)
scalar trim_low = r(r1)
scalar trim_high = r(r2)

di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

* Create trimmed returns
capture drop r_fin_2022_trim
gen double r_fin_2022_trim = r_fin_2022 if fin_sample & !missing(r_fin_2022) & inrange(r_fin_2022, trim_low, trim_high)

* Report trimming results
quietly count if !missing(r_fin_2022_trim)
local n_trim = r(N)
quietly count if fin_sample & !missing(r_fin_2022)
local n_original = r(N)
di as txt "Observations after 5% trimming: `n_trim' (dropped `=`n_original'-`n_trim'')"

* Trimmed returns summary
di as txt "Trimmed financial asset returns summary:"
summarize r_fin_2022_trim, detail
tabstat r_fin_2022_trim, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Diagnostics: show extremes and component breakdowns
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extreme returns and component inspection ==="

di as txt "Top 20 positive financial asset returns:"
gsort -r_fin_2022
list HHID RSUBHH r_fin_2022 yc_fin_2022 cg_fin_2022 F_fin_2022 A_2020 F_2022 denom_fin_2022 in 1/20 if fin_sample

di as txt "Top 20 negative financial asset returns:"
gsort r_fin_2022
list HHID RSUBHH r_fin_2022 yc_fin_2022 cg_fin_2022 F_fin_2022 A_2020 F_2022 denom_fin_2022 in 1/20 if fin_sample

di as txt "Top 20 trimmed financial asset returns:"
gsort -r_fin_2022_trim
list HHID RSUBHH r_fin_2022_trim yc_fin_2022 cg_fin_2022 F_fin_2022 A_2020 F_2022 denom_fin_2022 in 1/20 if !missing(r_fin_2022_trim)

* ---------------------------------------------------------------------
* Verification of summed variables and sample logic
* ---------------------------------------------------------------------
di as txt "=== Verification of summed variables and sample logic ==="

* Check that all observations in sample have the summed variables
quietly count if fin_sample
local n_sample = r(N)
di as txt "Total observations in financial sample: `n_sample'"

* Verify interest income total (yc_fin_2022)
quietly count if !missing(yc_fin_2022) & fin_sample
di as txt "yc_fin_2022 non-missing in sample: " r(N) " (should equal `n_sample')"
quietly count if missing(yc_fin_2022) & fin_sample
di as txt "yc_fin_2022 missing in sample: " r(N) " (should equal 0)"

* Verify capital gains total (cg_fin_2022)
quietly count if !missing(cg_fin_2022) & fin_sample
di as txt "cg_fin_2022 non-missing in sample: " r(N) " (should equal `n_sample')"
quietly count if missing(cg_fin_2022) & fin_sample
di as txt "cg_fin_2022 missing in sample: " r(N) " (should equal 0)"

* Verify financial flows total (F_fin_2022)
quietly count if !missing(F_fin_2022) & fin_sample
di as txt "F_fin_2022 non-missing in sample: " r(N) " (should equal `n_sample')"
quietly count if missing(F_fin_2022) & fin_sample
di as txt "F_fin_2022 missing in sample: " r(N) " (should equal 0)"

* Verify denominator (denom_fin_2022)
quietly count if !missing(denom_fin_2022) & fin_sample
di as txt "denom_fin_2022 non-missing in sample: " r(N) " (should equal `n_sample')"
quietly count if missing(denom_fin_2022) & fin_sample
di as txt "denom_fin_2022 missing in sample: " r(N) " (should equal 0)"

* Check for zero values (should be possible if all components are missing)
quietly count if yc_fin_2022 == 0 & fin_sample
di as txt "yc_fin_2022 equals 0 in sample: " r(N) " (households with no interest income)"
quietly count if cg_fin_2022 == 0 & fin_sample
di as txt "cg_fin_2022 equals 0 in sample: " r(N) " (households with no capital gains)"
quietly count if F_fin_2022 == 0 & fin_sample
di as txt "F_fin_2022 equals 0 in sample: " r(N) " (households with no stock flows)"

* Summary of summed variables
di as txt "Summary of summed variables:"
di as txt "  Interest income total (yc_fin_2022):"
summarize yc_fin_2022 if fin_sample, detail
di as txt "  Capital gains total (cg_fin_2022):"
summarize cg_fin_2022 if fin_sample, detail
di as txt "  Financial flows total (F_fin_2022):"
summarize F_fin_2022 if fin_sample, detail
di as txt "  Final denominator (denom_fin_2022):"
summarize denom_fin_2022 if fin_sample, detail

* ---------------------------------------------------------------------
* Save dataset with new financial asset return variables
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved financial asset return variables to master: `master'"

di as txt "Done. Financial asset returns computed with 5% trimming."
