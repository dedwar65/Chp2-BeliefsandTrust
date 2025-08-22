*----------------------------------------------------------------------
* compute_returns_2022.do
* Compute household returns to net worth for 2022 using HRS data
* Runs all prior component scripts, then computes:
*
*    r_t = ( y^c_t + cg_t - y^d_t ) / ( A_{t-1} + 0.5 F_t )
*
* Following: Fagereng, Holm, Moll, Natvik (2019) and related literature
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_returns_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* Run all prerequisite scripts in sequence
* ---------------------------------------------------------------------
local base "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned"

do "`base'/extract_household_2020_ret_calc_end"
do "`base'/extract_household_2022_ret_calc_start"
do "`base'/merge_2020_2022"
do "`base'/compute_int_inc_div_2020_2022"
do "`base'/compute_net_inv_flows_2020_2022"
do "`base'/compute_debt_payments_2020_2022"
do "`base'/compute_cap_gains_2020_2022"
do "`base'/compute_beg_per_net_worth_2020_2022"

* ---------------------------------------------------------------------
* Gather components from master
* ---------------------------------------------------------------------
use "`base'/hrs_2020_2022_master.dta", clear

capture drop yc_2022 cg_2022 yd_2022 A_2020 F_2022
gen double yc_2022 = int_total_2022
gen double cg_2022 = cg_total_2022
gen double yd_2022 = mortgage_payments_total_2022
gen double A_2020  = networth_A2020
gen double F_2022  = flow_total_2022

* ---------------------------------------------------------------------
* Compute return: raw and cleaned versions
* ---------------------------------------------------------------------
capture drop r_2022_unchecked r_2022
gen double r_2022_unchecked = (yc_2022 + cg_2022 - yd_2022) / (A_2020 + 0.5*F_2022)

* Clean version excludes non-positive denominators
gen double r_2022 = r_2022_unchecked
replace r_2022 = . if (A_2020 + 0.5*F_2022) <= 0 | missing(A_2020 + 0.5*F_2022)

* ---------------------------------------------------------------------
* Diagnostics / inspections
* ---------------------------------------------------------------------
di as txt "Summary stats for raw return (r_2022_unchecked):"
summarize r_2022_unchecked, detail
tabstat r_2022_unchecked, stats(n mean sd p50 min max) format(%12.4f)

di as txt "Summary stats for cleaned return (r_2022):"
summarize r_2022, detail
tabstat r_2022, stats(n mean sd p50 min max) format(%12.4f)

di as txt "Histogram of cleaned return (inspect shape):"
histogram r_2022, bin(100) normal

di as txt "Top 20 positive returns:"
gsort -r_2022
list HHID RSUBHH r_2022 yc_2022 cg_2022 yd_2022 A_2020 F_2022 in 1/20

di as txt "Top 20 negative returns:"
gsort r_2022
list HHID RSUBHH r_2022 yc_2022 cg_2022 yd_2022 A_2020 F_2022 in 1/20

* ---------------------------------------------------------------------
* Save back to master file (so return variables persist)
* ---------------------------------------------------------------------
save "`base'/hrs_2020_2022_master.dta", replace
di as txt "Saved returns variables (r_2022_unchecked, r_2022) to master."

log close
di as txt "Done. Inspect the log for details."
*----------------------------------------------------------------------


