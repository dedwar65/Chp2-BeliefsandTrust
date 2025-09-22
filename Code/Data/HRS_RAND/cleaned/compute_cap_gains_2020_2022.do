*----------------------------------------------------------------------
* RAND: compute_capital_gains_2022_simple_residences.do
* Lowercase RAND vars, same logic
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_capital_gains_2022_simple_residences.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}
use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Variables expected (RAND lowercase)
* Business:    sq148 (2022), rq148 (2020), flow: flow_bus_2022
* Real estate: sq134 (2022), rq134 (2020), flow: flow_re_2022
* Stocks:      sq317 (2022), rq317 (2020), flow: flow_stk_2022
* IRA:         sq166_1/2/3 (2022), rq166_1/2/3 (2020), flow: flow_ira_2022
* Bonds:       sq331 (2022), rq331 (2020), no flows
* Residences:  sh020 + sh162 (2022), rh020 + rh162 (2020), flow: flow_residences_2022
* ---------------------------------------------------------------------

di as txt "Checking presence of the main vars..."
local checkvars "sq148 rq148 sq134 rq134 sq317 rq317 sq166_1 rq166_1 sq166_2 rq166_2 sq166_3 rq166_3 sq331 rq331 sh020 rh020 sh162 rh162 flow_bus_2022 flow_re_2022 flow_stk_2022 flow_ira_2022 flow_residences_2022"
foreach v of local checkvars {
    capture confirm variable `v'
    if _rc di as warn "  MISSING: `v'" 
    else di as txt "  OK: `v'"
}

* ---------------------------------------------------------------------
* Optional: clean sentinel special-missing codes for value vars (adjust if already cleaned)
* ---------------------------------------------------------------------
local misscodes 9999998 9999999 -8 -9 999999998 999999999
local valuevars "sq148 rq148 sq134 rq134 sq317 rq317 sq166_1 rq166_1 sq166_2 rq166_2 sq166_3 rq166_3 sq331 rq331 sh020 rh020 sh162 rh162"
di as txt "Recoding common sentinel codes to missing for value vars (if present)..."
foreach v of local valuevars {
    capture confirm variable `v'
    if _rc continue
    foreach mc of local misscodes {
        quietly replace `v' = . if `v' == `mc'
    }
    di as txt " Summary for `v' (post-recode):"
    summarize `v', detail
}

* Totals for IRA and residences
capture drop v_ira_2022 v_ira_2020 v_res_2022 v_res_2020
egen double v_ira_2022 = rowtotal(sq166_1 sq166_2 sq166_3)
egen double v_ira_2020 = rowtotal(rq166_1 rq166_2 rq166_3)
di as txt "IRA totals (2022 and 2020):"
summarize v_ira_2022 v_ira_2020, detail
quietly count if !missing(v_ira_2022) & !missing(v_ira_2020)
di as txt "Observations with BOTH IRA V_2022 & V_2020 present = " r(N)

egen double v_res_2022 = rowtotal(sh020 sh162)
egen double v_res_2020 = rowtotal(rh020 rh162)
di as txt "Residence totals (combined primary + secondary):"
summarize v_res_2022 v_res_2020, detail
quietly count if !missing(v_res_2022) & !missing(v_res_2020)
di as txt "Observations with BOTH V_res_2022 & V_res_2020 present = " r(N)

* Capital gains per class
capture drop cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022

gen double cg_bus_2022 = .
replace cg_bus_2022 = (sq148 - rq148) - cond(missing(flow_bus_2022),0,flow_bus_2022) if !missing(sq148) & !missing(rq148)
di as txt "Business cg (cg_bus_2022) summary:"
summarize cg_bus_2022, detail
quietly count if !missing(cg_bus_2022)
di as txt "Records with cg_bus_2022 computed = " r(N)

gen double cg_re_2022 = .
replace cg_re_2022 = (sq134 - rq134) - cond(missing(flow_re_2022),0,flow_re_2022) if !missing(sq134) & !missing(rq134)
di as txt "Real estate cg (cg_re_2022) summary:"
summarize cg_re_2022, detail
quietly count if !missing(cg_re_2022)
di as txt "Records with cg_re_2022 computed = " r(N)

gen double cg_stk_2022 = .
replace cg_stk_2022 = (sq317 - rq317) - cond(missing(flow_stk_2022),0,flow_stk_2022) if !missing(sq317) & !missing(rq317)
di as txt "Stocks cg (cg_stk_2022) summary:"
summarize cg_stk_2022, detail
quietly count if !missing(cg_stk_2022)
di as txt "Records with cg_stk_2022 computed = " r(N)

gen double cg_ira_2022 = .
replace cg_ira_2022 = (v_ira_2022 - v_ira_2020) - cond(missing(flow_ira_2022),0,flow_ira_2022) if !missing(v_ira_2022) & !missing(v_ira_2020)
di as txt "IRA cg (cg_ira_2022) summary:"
summarize cg_ira_2022, detail
quietly count if !missing(cg_ira_2022)
di as txt "Records with cg_ira_2022 computed = " r(N)

gen double cg_bnd_2022 = .
replace cg_bnd_2022 = (sq331 - rq331) if !missing(sq331) & !missing(rq331)
di as txt "Bonds cg (cg_bnd_2022) summary:"
summarize cg_bnd_2022, detail
quietly count if !missing(cg_bnd_2022)
di as txt "Records with cg_bnd_2022 computed = " r(N)

gen double cg_res_total_2022 = .
replace cg_res_total_2022 = (v_res_2022 - v_res_2020) - cond(missing(flow_residences_2022),0,flow_residences_2022) if !missing(v_res_2022) & !missing(v_res_2020)
di as txt "Combined residences cg (cg_res_total_2022) summary:"
summarize cg_res_total_2022, detail
quietly count if !missing(cg_res_total_2022)
di as txt "Records with cg_res_total_2022 computed = " r(N)

capture drop cg_total_2022
egen double cg_total_2022 = rowtotal(cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022)
di as txt "TOTAL capital gains (cg_total_2022) summary (sum across classes):"
summarize cg_total_2022, detail
tabstat cg_total_2022, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Diagnostics: inspect top/bottom observations and counts per class
* ---------------------------------------------------------------------
di as txt "Top 30 largest positive cg_total_2022 (inspect components):"
gsort -cg_total_2022
list hhid rsubhh cg_total_2022 cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022 in 1/30

di as txt "Top 30 largest negative cg_total_2022 (inspect components):"
gsort cg_total_2022
list hhid rsubhh cg_total_2022 cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022 in 1/30

foreach v in cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022 {
    quietly count if !missing(`v')
    di as txt "`v' computed for " r(N) " obs"
}

save "`master'", replace
di as txt "Saved capital gains vars back to master: `master'"

log close

