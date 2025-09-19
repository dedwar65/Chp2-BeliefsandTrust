*----------------------------------------------------------------------
* compute_returns_sample.do
* Compute household returns to net worth for 2022 using HRS data
* with sample restriction to households reporting primary residence values in both 2020 and 2022
* 
* This file assumes the existing pipeline has been run and creates
* sample-restricted versions of all return components and final returns.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_returns_sample.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Define analysis sample: households with primary residence values in both years
* ---------------------------------------------------------------------
di as txt "=== Defining analysis sample based on primary residence values ==="

* Count non-missing primary residence values in each year
egen n_res_2022 = rownonmiss(SH020)
egen n_res_2020 = rownonmiss(RH020)

* Define sample: must have primary residence value in both 2020 and 2022
gen sample_res_both = (n_res_2022 > 0) & (n_res_2020 > 0)

* Report sample statistics
di as txt "Sample definition results:"
tab sample_res_both, missing
quietly count if sample_res_both == 1
local n_sample = r(N)
quietly count
local n_total = r(N)
di as txt "Households in analysis sample: `n_sample' out of `n_total' (" %4.1f 100*`n_sample'/`n_total' "%)"

* ---------------------------------------------------------------------
* Create masked per-asset/class components for sample-restricted analysis
* ---------------------------------------------------------------------
di as txt "=== Creating sample-restricted component variables ==="

* Interest/dividends components
di as txt "Masking interest/dividend components..."
gen double int_re_2022_sample = .
replace int_re_2022_sample = int_re_2022 if sample_res_both

gen double int_bus_2022_sample = .
replace int_bus_2022_sample = int_bus_2022 if sample_res_both

gen double int_ira_2022_sample = .
replace int_ira_2022_sample = int_ira_2022 if sample_res_both

gen double int_stk_2022_sample = .
replace int_stk_2022_sample = int_stk_2022 if sample_res_both

gen double int_bnd_2022_sample = .
replace int_bnd_2022_sample = int_bnd_2022 if sample_res_both

gen double int_cash_2022_sample = .
replace int_cash_2022_sample = int_cash_2022 if sample_res_both

gen double int_cds_2022_sample = .
replace int_cds_2022_sample = int_cds_2022 if sample_res_both

* Net investment flows components
di as txt "Masking net investment flow components..."
gen double flow_bus_2022_sample = .
replace flow_bus_2022_sample = flow_bus_2022 if sample_res_both

gen double flow_stk_private_2022_sample = .
replace flow_stk_private_2022_sample = flow_stk_private_2022 if sample_res_both

gen double flow_stk_public_2022_sample = .
replace flow_stk_public_2022_sample = flow_stk_public_2022 if sample_res_both

gen double flow_re_2022_sample = .
replace flow_re_2022_sample = flow_re_2022 if sample_res_both

gen double flow_ira_2022_sample = .
replace flow_ira_2022_sample = flow_ira_2022 if sample_res_both

gen double flow_ira_2022_neg_sample = .
replace flow_ira_2022_neg_sample = -flow_ira_2022_sample if sample_res_both

gen double flow_residences_2022_sample = .
replace flow_residences_2022_sample = flow_residences_2022 if sample_res_both

* Mortgage payment components
di as txt "Masking mortgage payment components..."
gen double mort1_pay_annual_sample = .
replace mort1_pay_annual_sample = mort1_pay_annual if sample_res_both

gen double mort2_pay_annual_sample = .
replace mort2_pay_annual_sample = mort2_pay_annual if sample_res_both

gen double secmort_pay_annual_sample = .
replace secmort_pay_annual_sample = secmort_pay_annual if sample_res_both

* Capital gains components
di as txt "Masking capital gains components..."
gen double cg_bus_2022_sample = .
replace cg_bus_2022_sample = cg_bus_2022 if sample_res_both

gen double cg_re_2022_sample = .
replace cg_re_2022_sample = cg_re_2022 if sample_res_both

gen double cg_stk_2022_sample = .
replace cg_stk_2022_sample = cg_stk_2022 if sample_res_both

gen double cg_ira_2022_sample = .
replace cg_ira_2022_sample = cg_ira_2022 if sample_res_both

gen double cg_bnd_2022_sample = .
replace cg_bnd_2022_sample = cg_bnd_2022 if sample_res_both

gen double cg_res_total_2022_sample = .
replace cg_res_total_2022_sample = cg_res_total_2022 if sample_res_both

* Net worth component
di as txt "Masking net worth component..."
gen double networth_A2020_sample = .
replace networth_A2020_sample = networth_A2020 if sample_res_both

* ---------------------------------------------------------------------
* Compute sample-restricted totals
* ---------------------------------------------------------------------
di as txt "=== Computing sample-restricted totals ==="

* Interest/dividends total
gen double yc_2022_sample = .
egen yc_2022_temp = rowtotal(int_re_2022_sample int_bus_2022_sample int_ira_2022_sample int_stk_2022_sample int_bnd_2022_sample int_cash_2022_sample int_cds_2022_sample) if sample_res_both
replace yc_2022_sample = yc_2022_temp if sample_res_both
drop yc_2022_temp

di as txt "Interest/dividends total (yc_2022_sample) summary:"
summarize yc_2022_sample, detail
tabstat yc_2022_sample, stats(n mean sd p50 min max) format(%12.2f)

* Net investment flows total
gen double F_2022_sample = .
egen F_2022_temp = rowtotal(flow_bus_2022_sample flow_stk_private_2022_sample flow_stk_public_2022_sample flow_re_2022_sample flow_ira_2022_neg_sample flow_residences_2022_sample) if sample_res_both
replace F_2022_sample = F_2022_temp if sample_res_both
drop F_2022_temp

di as txt "Net investment flows total (F_2022_sample) summary:"
summarize F_2022_sample, detail
tabstat F_2022_sample, stats(n mean sd p50 min max) format(%12.2f)

* Debt payments total
gen double yd_2022_sample = .
egen yd_2022_temp = rowtotal(mort1_pay_annual_sample mort2_pay_annual_sample secmort_pay_annual_sample) if sample_res_both
replace yd_2022_sample = yd_2022_temp if sample_res_both
drop yd_2022_temp

di as txt "Debt payments total (yd_2022_sample) summary:"
summarize yd_2022_sample, detail
tabstat yd_2022_sample, stats(n mean sd p50 min max) format(%12.2f)

* Capital gains total
gen double cg_2022_sample = .
egen cg_2022_temp = rowtotal(cg_bus_2022_sample cg_re_2022_sample cg_stk_2022_sample cg_ira_2022_sample cg_bnd_2022_sample cg_res_total_2022_sample) if sample_res_both
replace cg_2022_sample = cg_2022_temp if sample_res_both
drop cg_2022_temp

di as txt "Capital gains total (cg_2022_sample) summary:"
summarize cg_2022_sample, detail
tabstat cg_2022_sample, stats(n mean sd p50 min max) format(%12.2f)

* Beginning net worth (already computed, just masked)
gen double A_2020_sample = .
replace A_2020_sample = networth_A2020_sample if sample_res_both

di as txt "Beginning net worth (A_2020_sample) summary:"
summarize A_2020_sample, detail
tabstat A_2020_sample, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Compute sample-restricted returns
* ---------------------------------------------------------------------
di as txt "=== Computing sample-restricted returns ==="

* Raw return calculation
gen double r_2022_unchecked_sample = .
replace r_2022_unchecked_sample = (yc_2022_sample + cg_2022_sample - yd_2022_sample) / (A_2020_sample + 0.5*F_2022_sample) if sample_res_both

* Clean return: exclude non-positive denominators
gen double r_2022_sample = .
replace r_2022_sample = r_2022_unchecked_sample if sample_res_both
replace r_2022_sample = . if (A_2020_sample + 0.5*F_2022_sample) <= 0 | missing(A_2020_sample + 0.5*F_2022_sample)

* Report return statistics
di as txt "Summary stats for raw return (r_2022_unchecked_sample):"
summarize r_2022_unchecked_sample, detail
tabstat r_2022_unchecked_sample, stats(n mean sd p50 min max) format(%12.4f)

di as txt "Summary stats for cleaned return (r_2022_sample):"
summarize r_2022_sample, detail
tabstat r_2022_sample, stats(n mean sd p50 min max) format(%12.4f)

* Count valid returns
quietly count if !missing(r_2022_sample)
local n_valid_returns = r(N)
di as txt "Records with valid r_2022_sample computed = `n_valid_returns' out of `n_sample' in sample"

* ---------------------------------------------------------------------
* Diagnostics: show extremes and component breakdowns
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: extreme returns and component inspection ==="

di as txt "Top 20 positive returns:"
gsort -r_2022_sample
list HHID RSUBHH r_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample A_2020_sample F_2022_sample in 1/20

di as txt "Top 20 negative returns:"
gsort r_2022_sample
list HHID RSUBHH r_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample A_2020_sample F_2022_sample in 1/20

* ---------------------------------------------------------------------
* Per-asset/class component summaries for sample
* ---------------------------------------------------------------------
di as txt "=== Per-asset/class component summaries (sample only) ==="

di as txt "Interest/dividend components:"
foreach var in int_re_2022 int_bus_2022 int_ira_2022 int_stk_2022 int_bnd_2022 int_cash_2022 int_cds_2022 {
    di as txt "Summary for `var'_sample:"
    summarize `var'_sample, detail
}

di as txt "Net investment flow components:"
foreach var in flow_bus_2022 flow_stk_private_2022 flow_stk_public_2022 flow_re_2022 flow_ira_2022 flow_residences_2022 {
    di as txt "Summary for `var'_sample:"
    summarize `var'_sample, detail
}

di as txt "Mortgage payment components:"
foreach var in mort1_pay_annual mort2_pay_annual secmort_pay_annual {
    di as txt "Summary for `var'_sample:"
    summarize `var'_sample, detail
}

di as txt "Capital gains components:"
foreach var in cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022 {
    di as txt "Summary for `var'_sample:"
    summarize `var'_sample, detail
}

* ---------------------------------------------------------------------
* Save dataset with new sample-restricted variables
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved sample-restricted return variables to master: `master'"

log close
di as txt "Done. Sample-restricted returns computed for `n_sample' households with primary residence values in both years."
