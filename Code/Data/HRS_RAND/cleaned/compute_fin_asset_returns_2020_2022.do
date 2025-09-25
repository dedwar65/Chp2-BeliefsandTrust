*----------------------------------------------------------------------
* RAND: compute_fin_asset_returns.do
* Compute returns for financial assets (stocks + bonds) for 2022
* Using lowercase RAND variable names
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
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_fin_asset_returns_2022.log", replace text

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
local f2022_stk  sq322
local a2022_stk  sq324
local f2022_bnd  sq336
local a2022_bnd  sq338
local f2022_cash sq350
local a2022_cash sq352
local f2022_cds  sq362
local a2022_cds  sq364

* ---------------------------------------------------------------------
* Define financial asset sample
* Baseline: stocks OR bonds in both years
* Augmented: OR any numerator signal (any int_* non-missing OR stock flows non-missing)
* ---------------------------------------------------------------------
di as txt "=== Defining financial asset sample ==="

* Check for stocks in both years (sq317 and rq317)
gen byte has_stocks_both = !missing(sq317) & !missing(rq317)

* Check for bonds in both years (sq331 and rq331)  
gen byte has_bonds_both = !missing(sq331) & !missing(rq331)

* Exposure via numerator components present (raw checks)
* Interest income exposure: amount present AND mapped frequency multiplier present
gen byte fin_exposure = 0
replace fin_exposure = 1 if !missing(`a2022_stk')  & !missing(`f2022_stk'_mult)
replace fin_exposure = 1 if !missing(`a2022_bnd')  & !missing(`f2022_bnd'_mult)
replace fin_exposure = 1 if !missing(`a2022_cash') & !missing(`f2022_cash'_mult)
replace fin_exposure = 1 if !missing(`a2022_cds')  & !missing(`f2022_cds'_mult)
* Stock flow exposure: either private (sr064 with sr063_dir) or public sells (sr073)
replace fin_exposure = 1 if (!missing(sr064) & !missing(sr063_dir)) | !missing(sr073)

* Financial asset sample: baseline OR exposure
gen byte fin_sample = has_stocks_both | has_bonds_both | fin_exposure

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
di as txt "Additional inclusions due to numerator exposure:"
tab fin_exposure if !has_stocks_both & !has_bonds_both, missing
quietly count if has_stocks_both & has_bonds_both
di as txt "Households with BOTH stocks and bonds in both years: " r(N)
quietly count if has_stocks_both & !has_bonds_both
di as txt "Households with stocks only (both years): " r(N)
quietly count if !has_stocks_both & has_bonds_both
di as txt "Households with bonds only (both years): " r(N)

* ---------------------------------------------------------------------
* Denominator components
* ---------------------------------------------------------------------
di as txt "=== Denominator components (A_2020, F_2022) ==="

capture drop A_2020
gen double A_2020 = networth_A2020 if fin_sample

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
di as txt "=== Using total flows (F_2022) component for denominator ==="

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

* Count before applying denominator threshold
quietly count if fin_sample == 1
local n_initial_sample = r(N)
di as txt "Initial sample size before denominator threshold: `n_initial_sample'"

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
di as txt "=== Diagnostics: component inspection (no top-20 listings) ==="

* ---------------------------------------------------------------------
* Zero-value checks for summed components
* ---------------------------------------------------------------------
di as txt "=== Zero-value checks for components (financial) ==="
quietly count if yc_fin_2022 == 0 & fin_sample
di as txt "yc_fin_2022 equals 0 in sample: " r(N)
quietly count if cg_fin_2022 == 0 & fin_sample
di as txt "cg_fin_2022 equals 0 in sample: " r(N)
quietly count if F_fin_2022 == 0 & fin_sample
di as txt "F_fin_2022 equals 0 in sample: " r(N)

* ---------------------------------------------------------------------
* Additional: Compute separate stock and bond returns (no structural changes)
* ---------------------------------------------------------------------
di as txt "=== Computing separate stock and bond returns ==="

* ---------------------------
* STOCK RETURNS
* ---------------------------
di as txt "-- Stock returns --"

* Sample: stocks in both years OR exposure via income or stock flows
capture drop has_stk_both
gen byte has_stk_both = !missing(sq317) & !missing(rq317)
capture drop stk_exposure
gen byte stk_exposure = 0
replace stk_exposure = 1 if !missing(`a2022_stk') & !missing(`f2022_stk'_mult)
replace stk_exposure = 1 if (!missing(sr064) & !missing(sr063_dir)) | !missing(sr073)
capture drop stk_sample
gen byte stk_sample = has_stk_both | stk_exposure

* Denominator components for stocks
capture drop A_2020_stk
gen double A_2020_stk = networth_A2020 if stk_sample
capture drop F_2022_stk
gen double F_2022_stk = flow_total_2022 if stk_sample
replace F_2022_stk = 0 if missing(F_2022_stk) & stk_sample
capture drop denom_stk_2022
gen double denom_stk_2022 = A_2020_stk + 0.5*F_2022_stk if stk_sample
capture drop denom_stk_above_10k
gen byte denom_stk_above_10k = denom_stk_2022 >= 10000 if stk_sample
replace stk_sample = stk_sample & denom_stk_above_10k

* Numerator: yc, cg, flows
capture drop yc_stk_2022
gen double yc_stk_2022 = int_stk_2022 if stk_sample
replace yc_stk_2022 = 0 if missing(yc_stk_2022) & stk_sample
capture drop cg_stk_used_2022
gen double cg_stk_used_2022 = cg_stk_2022 if stk_sample
replace cg_stk_used_2022 = 0 if missing(cg_stk_used_2022) & stk_sample
capture drop F_stk_2022
gen double F_stk_2022 = flow_stk_2022 if stk_sample
replace F_stk_2022 = 0 if missing(F_stk_2022) & stk_sample

* Return and trimming
capture drop r_stk_2022
gen double r_stk_2022 = (yc_stk_2022 + cg_stk_used_2022 - F_stk_2022) / denom_stk_2022 if stk_sample
quietly _pctile r_stk_2022 if stk_sample & !missing(r_stk_2022), p(5 95)
scalar stk_p5 = r(r1)
scalar stk_p95 = r(r2)
capture drop r_stk_2022_trim
gen double r_stk_2022_trim = r_stk_2022 if stk_sample & !missing(r_stk_2022) & inrange(r_stk_2022, stk_p5, stk_p95)

* Summaries
di as txt "Stock returns summary (raw):"
summarize r_stk_2022 if stk_sample, detail
tabstat r_stk_2022 if stk_sample, stats(n mean sd p50 min max) format(%12.4f)
di as txt "Stock returns summary (trimmed):"
summarize r_stk_2022_trim, detail
tabstat r_stk_2022_trim, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------
* BOND RETURNS
* ---------------------------
di as txt "-- Bond returns --"

* Sample: bonds in both years OR exposure via income (no flow component for bonds)
capture drop has_bnd_both
gen byte has_bnd_both = !missing(sq331) & !missing(rq331)
capture drop bnd_exposure
gen byte bnd_exposure = 0
replace bnd_exposure = 1 if !missing(`a2022_bnd') & !missing(`f2022_bnd'_mult)
capture drop bnd_sample
gen byte bnd_sample = has_bnd_both | bnd_exposure

* Denominator components for bonds
capture drop A_2020_bnd
gen double A_2020_bnd = networth_A2020 if bnd_sample
capture drop F_2022_bnd
gen double F_2022_bnd = flow_total_2022 if bnd_sample
replace F_2022_bnd = 0 if missing(F_2022_bnd) & bnd_sample
capture drop denom_bnd_2022
gen double denom_bnd_2022 = A_2020_bnd + 0.5*F_2022_bnd if bnd_sample
capture drop denom_bnd_above_10k
gen byte denom_bnd_above_10k = denom_bnd_2022 >= 10000 if bnd_sample
replace bnd_sample = bnd_sample & denom_bnd_above_10k

* Numerator: yc, cg, flows (flows = 0 for bonds)
capture drop yc_bnd_2022
gen double yc_bnd_2022 = int_bnd_2022 if bnd_sample
replace yc_bnd_2022 = 0 if missing(yc_bnd_2022) & bnd_sample
capture drop cg_bnd_used_2022
gen double cg_bnd_used_2022 = cg_bnd_2022 if bnd_sample
replace cg_bnd_used_2022 = 0 if missing(cg_bnd_used_2022) & bnd_sample
capture drop F_bnd_2022
gen double F_bnd_2022 = 0 if bnd_sample

* Return and trimming
capture drop r_bnd_2022
gen double r_bnd_2022 = (yc_bnd_2022 + cg_bnd_used_2022 - F_bnd_2022) / denom_bnd_2022 if bnd_sample
quietly _pctile r_bnd_2022 if bnd_sample & !missing(r_bnd_2022), p(5 95)
scalar bnd_p5 = r(r1)
scalar bnd_p95 = r(r2)
capture drop r_bnd_2022_trim
gen double r_bnd_2022_trim = r_bnd_2022 if bnd_sample & !missing(r_bnd_2022) & inrange(r_bnd_2022, bnd_p5, bnd_p95)

* Summaries
di as txt "Bond returns summary (raw):"
summarize r_bnd_2022 if bnd_sample, detail
tabstat r_bnd_2022 if bnd_sample, stats(n mean sd p50 min max) format(%12.4f)
di as txt "Bond returns summary (trimmed):"
summarize r_bnd_2022_trim, detail
tabstat r_bnd_2022_trim, stats(n mean sd p50 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Save dataset with new financial asset return variables
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved financial asset return variables to master: `master'"

di as txt "Done. Financial asset returns computed with 5% trimming."
