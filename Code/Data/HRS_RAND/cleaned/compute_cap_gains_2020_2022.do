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

di as txt "Proceeding with capital gains computation..."

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
replace v_ira_2022 = . if missing(sq166_1) & missing(sq166_2) & missing(sq166_3)
replace v_ira_2020 = . if missing(rq166_1) & missing(rq166_2) & missing(rq166_3)
di as txt "IRA totals (2022 and 2020; missing when all components missing):"
summarize v_ira_2022 v_ira_2020, detail
quietly count if !missing(v_ira_2022) & !missing(v_ira_2020)
di as txt "Observations with BOTH IRA V_2022 & V_2020 present = " r(N)
* Overlap diagnostics for IRA components (2022 and 2020)
capture drop ok_ira22_1 ok_ira22_2 ok_ira22_3 ira22_pattern ok_ira20_1 ok_ira20_2 ok_ira20_3 ira20_pattern
gen byte ok_ira22_1 = !missing(sq166_1)
gen byte ok_ira22_2 = !missing(sq166_2)
gen byte ok_ira22_3 = !missing(sq166_3)
gen byte ira22_pattern = ok_ira22_1*4 + ok_ira22_2*2 + ok_ira22_3
label define iraPat2 0 "none" 1 "3 only" 2 "2 only" 3 "2+3" 4 "1 only" 5 "1+3" 6 "1+2" 7 "1+2+3", replace
label values ira22_pattern iraPat2
di as txt "Counts of presence patterns for IRA 2022 components (sq166_1/2/3):"
tab ira22_pattern, missing
gen byte ok_ira20_1 = !missing(rq166_1)
gen byte ok_ira20_2 = !missing(rq166_2)
gen byte ok_ira20_3 = !missing(rq166_3)
gen byte ira20_pattern = ok_ira20_1*4 + ok_ira20_2*2 + ok_ira20_3
label define iraPat0 0 "none" 1 "3 only" 2 "2 only" 3 "2+3" 4 "1 only" 5 "1+3" 6 "1+2" 7 "1+2+3", replace
label values ira20_pattern iraPat0
di as txt "Counts of presence patterns for IRA 2020 components (rq166_1/2/3):"
tab ira20_pattern, missing

egen double v_res_2022 = rowtotal(sh020 sh162)
egen double v_res_2020 = rowtotal(rh020 rh162)
replace v_res_2022 = . if missing(sh020) & missing(sh162)
replace v_res_2020 = . if missing(rh020) & missing(rh162)
di as txt "Residence totals (combined primary + secondary; missing when both components missing):"
summarize v_res_2022 v_res_2020, detail
quietly count if !missing(v_res_2022) & !missing(v_res_2020)
di as txt "Observations with BOTH V_res_2022 & V_2020 present = " r(N)
* Overlap diagnostics for residence components (2022 and 2020)
capture drop ok_res22_p ok_res22_s res22_pattern ok_res20_p ok_res20_s res20_pattern
gen byte ok_res22_p = !missing(sh020)
gen byte ok_res22_s = !missing(sh162)
gen byte res22_pattern = ok_res22_p*2 + ok_res22_s
label define resPat22 0 "none" 1 "sec only" 2 "prim only" 3 "prim+sec", replace
label values res22_pattern resPat22
di as txt "Counts of presence patterns for residence 2022 components (sh020/sh162):"
tab res22_pattern, missing
gen byte ok_res20_p = !missing(rh020)
gen byte ok_res20_s = !missing(rh162)
gen byte res20_pattern = ok_res20_p*2 + ok_res20_s
label define resPat20 0 "none" 1 "sec only" 2 "prim only" 3 "prim+sec", replace
label values res20_pattern resPat20
di as txt "Counts of presence patterns for residence 2020 components (rh020/rh162):"
tab res20_pattern, missing

* Capital gains per class
capture drop cg_bus_2022 cg_re_2022 cg_stk_2022 cg_ira_2022 cg_bnd_2022 cg_res_total_2022

gen double cg_bus_2022 = .
replace cg_bus_2022 = (sq148 - rq148) - cond(missing(flow_bus_2022),0,flow_bus_2022) if !missing(sq148) & !missing(rq148)
di as txt "Business cg (cg_bus_2022) summary:"
summarize cg_bus_2022, detail
quietly count if !missing(cg_bus_2022)
di as txt "Records with cg_bus_2022 computed = " r(N)
* Tabulation of cases for business capital gains
capture drop bus_cases
gen byte bus_cases = .
replace bus_cases = 1 if !missing(sq148) & !missing(rq148) & !missing(flow_bus_2022)  // both years + flow
replace bus_cases = 2 if !missing(sq148) & !missing(rq148) & missing(flow_bus_2022)   // both years, no flow
replace bus_cases = 3 if missing(sq148) | missing(rq148)                              // missing years
label define busCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values bus_cases busCases
di as txt "Business capital gains cases:"
tab bus_cases, missing

gen double cg_re_2022 = .
replace cg_re_2022 = (sq134 - rq134) - cond(missing(flow_re_2022),0,flow_re_2022) if !missing(sq134) & !missing(rq134)
di as txt "Real estate cg (cg_re_2022) summary:"
summarize cg_re_2022, detail
quietly count if !missing(cg_re_2022)
di as txt "Records with cg_re_2022 computed = " r(N)
* Tabulation of cases for real estate capital gains
capture drop re_cases
gen byte re_cases = .
replace re_cases = 1 if !missing(sq134) & !missing(rq134) & !missing(flow_re_2022)  // both years + flow
replace re_cases = 2 if !missing(sq134) & !missing(rq134) & missing(flow_re_2022)   // both years, no flow
replace re_cases = 3 if missing(sq134) | missing(rq134)                              // missing years
label define reCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values re_cases reCases
di as txt "Real estate capital gains cases:"
tab re_cases, missing

gen double cg_stk_2022 = .
replace cg_stk_2022 = (sq317 - rq317) - cond(missing(flow_stk_2022),0,flow_stk_2022) if !missing(sq317) & !missing(rq317)
di as txt "Stocks cg (cg_stk_2022) summary:"
summarize cg_stk_2022, detail
quietly count if !missing(cg_stk_2022)
di as txt "Records with cg_stk_2022 computed = " r(N)
* Tabulation of cases for stocks capital gains
capture drop stk_cases
gen byte stk_cases = .
replace stk_cases = 1 if !missing(sq317) & !missing(rq317) & !missing(flow_stk_2022)  // both years + flow
replace stk_cases = 2 if !missing(sq317) & !missing(rq317) & missing(flow_stk_2022)   // both years, no flow
replace stk_cases = 3 if missing(sq317) | missing(rq317)                              // missing years
label define stkCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values stk_cases stkCases
di as txt "Stocks capital gains cases:"
tab stk_cases, missing

gen double cg_ira_2022 = .
replace cg_ira_2022 = (v_ira_2022 - v_ira_2020) - cond(missing(flow_ira_2022),0,flow_ira_2022) if !missing(v_ira_2022) & !missing(v_ira_2020)
di as txt "IRA cg (cg_ira_2022) summary:"
summarize cg_ira_2022, detail
quietly count if !missing(cg_ira_2022)
di as txt "Records with cg_ira_2022 computed = " r(N)
* Tabulation of cases for IRA capital gains
capture drop ira_cases
gen byte ira_cases = .
replace ira_cases = 1 if !missing(v_ira_2022) & !missing(v_ira_2020) & !missing(flow_ira_2022)  // both years + flow
replace ira_cases = 2 if !missing(v_ira_2022) & !missing(v_ira_2020) & missing(flow_ira_2022)   // both years, no flow
replace ira_cases = 3 if missing(v_ira_2022) | missing(v_ira_2020)                              // missing years
label define iraCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values ira_cases iraCases
di as txt "IRA capital gains cases:"
tab ira_cases, missing

gen double cg_bnd_2022 = .
replace cg_bnd_2022 = (sq331 - rq331) if !missing(sq331) & !missing(rq331)
di as txt "Bonds cg (cg_bnd_2022) summary:"
summarize cg_bnd_2022, detail
quietly count if !missing(cg_bnd_2022)
di as txt "Records with cg_bnd_2022 computed = " r(N)
* Tabulation of cases for bonds capital gains (no flows)
capture drop bnd_cases
gen byte bnd_cases = .
replace bnd_cases = 1 if !missing(sq331) & !missing(rq331)  // both years present
replace bnd_cases = 2 if missing(sq331) | missing(rq331)    // missing years
label define bndCases 1 "both years present" 2 "missing years", replace
label values bnd_cases bndCases
di as txt "Bonds capital gains cases:"
tab bnd_cases, missing

gen double cg_res_total_2022 = .
replace cg_res_total_2022 = (v_res_2022 - v_res_2020) - cond(missing(flow_residences_2022),0,flow_residences_2022) if !missing(v_res_2022) & !missing(v_res_2020)
di as txt "Combined residences cg (cg_res_total_2022) summary:"
summarize cg_res_total_2022, detail
quietly count if !missing(cg_res_total_2022)
di as txt "Records with cg_res_total_2022 computed = " r(N)
* Tabulation of cases for residences capital gains
capture drop res_cases
gen byte res_cases = .
replace res_cases = 1 if !missing(v_res_2022) & !missing(v_res_2020) & !missing(flow_residences_2022)  // both years + flow
replace res_cases = 2 if !missing(v_res_2022) & !missing(v_res_2020) & missing(flow_residences_2022)   // both years, no flow
replace res_cases = 3 if missing(v_res_2022) | missing(v_res_2020)                              // missing years
label define resCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values res_cases resCases
di as txt "Residences capital gains cases:"
tab res_cases, missing

* Totals and cross-class diagnostics moved to compute_returns

save "`master'", replace
di as txt "Saved capital gains vars back to master: `master'"

log close
exit, clear

