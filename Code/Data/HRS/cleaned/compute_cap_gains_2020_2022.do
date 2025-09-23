*----------------------------------------------------------------------
* compute_capital_gains_2022_simple_residences.do
* Compute capital gains per asset class for 2022:
* cg_class = (V_2022 - V_2020) - F_2022_class
* Residences: PRIMARY + SECONDARY treated as a single combined asset class.
* Writes computed vars back to master so other scripts keep variables.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_capital_gains_2022_simple_residences.log", replace text

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
* Variables expected (per your list)
* Business:    SQ148 (2022), RQ148 (2020), flow: flow_bus_2022
* Real estate: SQ134 (2022), RQ134 (2020), flow: flow_re_2022
* Stocks:      SQ317 (2022), RQ317 (2020), flow: flow_stk_2022
* IRA:         SQ166_1/2/3 (2022), RQ166_1/2/3 (2020), flow: flow_ira_2022
* Bonds:       SQ331 (2022), RQ331 (2020), no flows
* Residences:  SH020 + SH162 (2022), RH020 + RH162 (2020), flow: flow_residences_2022
* ---------------------------------------------------------------------

di as txt "Checking presence of the main vars..."
local checkvars "SQ148 RQ148 SQ134 RQ134 SQ317 RQ317 SQ166_1 RQ166_1 SQ166_2 RQ166_2 SQ166_3 RQ166_3 SQ331 RQ331 SH020 RH020 SH162 RH162 flow_bus_2022 flow_re_2022 flow_stk_2022 flow_ira_2022 flow_residences_2022"
foreach v of local checkvars {
    capture confirm variable `v'
    if _rc di as warn "  MISSING: `v'" 
    else di as txt "  OK: `v'"
}

* ---------------------------------------------------------------------
* Optional: clean sentinel special-missing codes for value vars (adjust if you already cleaned)
* ---------------------------------------------------------------------
local misscodes 9999998 9999999 -8 -9 999999998 999999999
local valuevars "SQ148 RQ148 SQ134 RQ134 SQ317 RQ317 SQ166_1 RQ166_1 SQ166_2 RQ166_2 SQ166_3 RQ166_3 SQ331 RQ331 SH020 RH020 SH162 RH162"
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

* ---------------------------------------------------------------------
* IRA totals for 2022 and 2020 (sum components)
* ---------------------------------------------------------------------
capture drop V_ira_2022 V_ira_2020
egen double V_ira_2022 = rowtotal(SQ166_1 SQ166_2 SQ166_3)
egen double V_ira_2020 = rowtotal(RQ166_1 RQ166_2 RQ166_3)
replace V_ira_2022 = . if missing(SQ166_1) & missing(SQ166_2) & missing(SQ166_3)
replace V_ira_2020 = . if missing(RQ166_1) & missing(RQ166_2) & missing(RQ166_3)
di as txt "IRA totals (2022 and 2020; missing when all components missing):"
summarize V_ira_2022 V_ira_2020, detail
quietly count if !missing(V_ira_2022) & !missing(V_ira_2020)
di as txt "Observations with BOTH IRA V_2022 & V_2020 present = " r(N)
* Overlap diagnostics for IRA components
capture drop ok_ira22_1 ok_ira22_2 ok_ira22_3 ira22_pattern ok_ira20_1 ok_ira20_2 ok_ira20_3 ira20_pattern
gen byte ok_ira22_1 = !missing(SQ166_1)
gen byte ok_ira22_2 = !missing(SQ166_2)
gen byte ok_ira22_3 = !missing(SQ166_3)
gen byte ira22_pattern = ok_ira22_1*4 + ok_ira22_2*2 + ok_ira22_3
label define iraPat22 0 "none" 1 "3 only" 2 "2 only" 3 "2+3" 4 "1 only" 5 "1+3" 6 "1+2" 7 "1+2+3", replace
label values ira22_pattern iraPat22
di as txt "Counts of presence patterns for IRA 2022 components (SQ166_1/2/3):"
tab ira22_pattern, missing
gen byte ok_ira20_1 = !missing(RQ166_1)
gen byte ok_ira20_2 = !missing(RQ166_2)
gen byte ok_ira20_3 = !missing(RQ166_3)
gen byte ira20_pattern = ok_ira20_1*4 + ok_ira20_2*2 + ok_ira20_3
label define iraPat20 0 "none" 1 "3 only" 2 "2 only" 3 "2+3" 4 "1 only" 5 "1+3" 6 "1+2" 7 "1+2+3", replace
label values ira20_pattern iraPat20
di as txt "Counts of presence patterns for IRA 2020 components (RQ166_1/2/3):"
tab ira20_pattern, missing

* ---------------------------------------------------------------------
* Combined residence totals (primary + secondary) at 2022 and 2020
* ---------------------------------------------------------------------
capture drop V_res_2022 V_res_2020
egen double V_res_2022 = rowtotal(SH020 SH162)
egen double V_res_2020 = rowtotal(RH020 RH162)
replace V_res_2022 = . if missing(SH020) & missing(SH162)
replace V_res_2020 = . if missing(RH020) & missing(RH162)
di as txt "Residence totals (combined primary + secondary; missing when both components missing):"
summarize V_res_2022 V_res_2020, detail
quietly count if !missing(V_res_2022) & !missing(V_res_2020)
di as txt "Observations with BOTH V_res_2022 & V_res_2020 present = " r(N)
* Overlap diagnostics for residence components
capture drop ok_res22_p ok_res22_s res22_pattern ok_res20_p ok_res20_s res20_pattern
gen byte ok_res22_p = !missing(SH020)
gen byte ok_res22_s = !missing(SH162)
gen byte res22_pattern = ok_res22_p*2 + ok_res22_s
label define resPat22 0 "none" 1 "sec only" 2 "prim only" 3 "prim+sec", replace
label values res22_pattern resPat22
di as txt "Counts of presence patterns for residence 2022 components (SH020/SH162):"
tab res22_pattern, missing
gen byte ok_res20_p = !missing(RH020)
gen byte ok_res20_s = !missing(RH162)
gen byte res20_pattern = ok_res20_p*2 + ok_res20_s
label define resPat20 0 "none" 1 "sec only" 2 "prim only" 3 "prim+sec", replace
label values res20_pattern resPat20
di as txt "Counts of presence patterns for residence 2020 components (RH020/RH162):"
tab res20_pattern, missing

* ---------------------------------------------------------------------
* Helper: a small function to compute cg safely treating missing flow as zero
* (We compute cg only when both V2022 & V2020 are nonmissing)
* ---------------------------------------------------------------------
cap program drop compute_cg
program define compute_cg, rclass
    syntax varname(varlist) varname(varlist) [varname]
    // compute_cg <v2022> <v2020> [flowvar]
    local v2022 : word 1 of `varlist'
    local v2020 : word 2 of `varlist'
    local flow  : word 3 of `varlist'
    // target variable name
    local out = "cg_" + lower("`v2022'") + "_from_" + lower("`v2020'")
    // but we'll pass explicit out names when calling below; this is a fallback
end

* ---------------------------------------------------------------------
* 1) Business: cg_bus_2022 = (SQ148 - RQ148) - flow_bus_2022
*    Treat missing flow as 0; compute only when both values present
* ---------------------------------------------------------------------
capture confirm variable SQ148
capture confirm variable RQ148
if (_rc) {
    di as warn "Business values missing -> cg_bus_2022 set to missing"
    gen double cg_bus_2022 = .
}
else {
    gen double cg_bus_2022 = .
    replace cg_bus_2022 = (SQ148 - RQ148) - cond(missing(flow_bus_2022),0,flow_bus_2022) ///
        if !missing(SQ148) & !missing(RQ148)
    di as txt "Business cg (cg_bus_2022) summary:"
    summarize cg_bus_2022, detail
    quietly count if !missing(cg_bus_2022)
    di as txt "Records with cg_bus_2022 computed = " r(N)
    * Tabulation of cases for business capital gains
    capture drop bus_cases
    gen byte bus_cases = .
    replace bus_cases = 1 if !missing(SQ148) & !missing(RQ148) & !missing(flow_bus_2022)  // both years + flow
    replace bus_cases = 2 if !missing(SQ148) & !missing(RQ148) & missing(flow_bus_2022)   // both years, no flow
    replace bus_cases = 3 if missing(SQ148) | missing(RQ148)                              // missing years
    label define busCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
    label values bus_cases busCases
    di as txt "Business capital gains cases:"
    tab bus_cases, missing
}

* ---------------------------------------------------------------------
* 2) Real estate (other than main home): cg_re_2022 = (SQ134 - RQ134) - flow_re_2022
* ---------------------------------------------------------------------
capture confirm variable SQ134
capture confirm variable RQ134
if (_rc) {
    di as warn "Real estate values missing -> cg_re_2022 set to missing"
    gen double cg_re_2022 = .
}
else {
    gen double cg_re_2022 = .
    replace cg_re_2022 = (SQ134 - RQ134) - cond(missing(flow_re_2022),0,flow_re_2022) ///
        if !missing(SQ134) & !missing(RQ134)
    di as txt "Real estate cg (cg_re_2022) summary:"
    summarize cg_re_2022, detail
    quietly count if !missing(cg_re_2022)
    di as txt "Records with cg_re_2022 computed = " r(N)
    * Tabulation of cases for real estate capital gains
    capture drop re_cases
    gen byte re_cases = .
    replace re_cases = 1 if !missing(SQ134) & !missing(RQ134) & !missing(flow_re_2022)  // both years + flow
    replace re_cases = 2 if !missing(SQ134) & !missing(RQ134) & missing(flow_re_2022)   // both years, no flow
    replace re_cases = 3 if missing(SQ134) | missing(RQ134)                              // missing years
    label define reCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
    label values re_cases reCases
    di as txt "Real estate capital gains cases:"
    tab re_cases, missing
}

* ---------------------------------------------------------------------
* 3) Stocks: cg_stk_2022 = (SQ317 - RQ317) - flow_stk_2022
* ---------------------------------------------------------------------
capture confirm variable SQ317
capture confirm variable RQ317
if (_rc) {
    di as warn "Stock value vars missing -> cg_stk_2022 set to missing"
    gen double cg_stk_2022 = .
}
else {
    gen double cg_stk_2022 = .
    replace cg_stk_2022 = (SQ317 - RQ317) - cond(missing(flow_stk_2022),0,flow_stk_2022) ///
        if !missing(SQ317) & !missing(RQ317)
    di as txt "Stocks cg (cg_stk_2022) summary:"
    summarize cg_stk_2022, detail
    quietly count if !missing(cg_stk_2022)
    di as txt "Records with cg_stk_2022 computed = " r(N)
    * Tabulation of cases for stocks capital gains
    capture drop stk_cases
    gen byte stk_cases = .
    replace stk_cases = 1 if !missing(SQ317) & !missing(RQ317) & !missing(flow_stk_2022)  // both years + flow
    replace stk_cases = 2 if !missing(SQ317) & !missing(RQ317) & missing(flow_stk_2022)   // both years, no flow
    replace stk_cases = 3 if missing(SQ317) | missing(RQ317)                              // missing years
    label define stkCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
    label values stk_cases stkCases
    di as txt "Stocks capital gains cases:"
    tab stk_cases, missing
}

* ---------------------------------------------------------------------
* 4) IRA: cg_ira_2022 = (V_ira_2022 - V_ira_2020) - flow_ira_2022
* ---------------------------------------------------------------------
gen double cg_ira_2022 = .
replace cg_ira_2022 = (V_ira_2022 - V_ira_2020) - cond(missing(flow_ira_2022),0,flow_ira_2022) ///
    if !missing(V_ira_2022) & !missing(V_ira_2020)
di as txt "IRA cg (cg_ira_2022) summary:"
summarize cg_ira_2022, detail
quietly count if !missing(cg_ira_2022)
di as txt "Records with cg_ira_2022 computed = " r(N)
* Tabulation of cases for IRA capital gains
capture drop ira_cases
gen byte ira_cases = .
replace ira_cases = 1 if !missing(V_ira_2022) & !missing(V_ira_2020) & !missing(flow_ira_2022)  // both years + flow
replace ira_cases = 2 if !missing(V_ira_2022) & !missing(V_ira_2020) & missing(flow_ira_2022)   // both years, no flow
replace ira_cases = 3 if missing(V_ira_2022) | missing(V_ira_2020)                              // missing years
label define iraCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values ira_cases iraCases
di as txt "IRA capital gains cases:"
tab ira_cases, missing

* ---------------------------------------------------------------------
* 5) Bonds: cg_bnd_2022 = SQ331 - RQ331  (no flow subtraction)
* ---------------------------------------------------------------------
capture confirm variable SQ331
capture confirm variable RQ331
if (_rc) {
    di as warn "Bond value vars missing -> cg_bnd_2022 set to missing"
    gen double cg_bnd_2022 = .
}
else {
    gen double cg_bnd_2022 = .
    replace cg_bnd_2022 = (SQ331 - RQ331) if !missing(SQ331) & !missing(RQ331)
    di as txt "Bonds cg (cg_bnd_2022) summary:"
    summarize cg_bnd_2022, detail
    quietly count if !missing(cg_bnd_2022)
    di as txt "Records with cg_bnd_2022 computed = " r(N)
    * Tabulation of cases for bonds capital gains (no flows)
    capture drop bnd_cases
    gen byte bnd_cases = .
    replace bnd_cases = 1 if !missing(SQ331) & !missing(RQ331)  // both years present
    replace bnd_cases = 2 if missing(SQ331) | missing(RQ331)    // missing years
    label define bndCases 1 "both years present" 2 "missing years", replace
    label values bnd_cases bndCases
    di as txt "Bonds capital gains cases:"
    tab bnd_cases, missing
}

* ---------------------------------------------------------------------
* 6) Residences (combined primary + secondary):
*    cg_res_total_2022 = (V_res_2022 - V_res_2020) - flow_residences_2022
* ---------------------------------------------------------------------
gen double cg_res_total_2022 = .
replace cg_res_total_2022 = (V_res_2022 - V_res_2020) - cond(missing(flow_residences_2022),0,flow_residences_2022) ///
    if !missing(V_res_2022) & !missing(V_res_2020)
di as txt "Combined residences cg (cg_res_total_2022) summary:"
summarize cg_res_total_2022, detail
quietly count if !missing(cg_res_total_2022)
di as txt "Records with cg_res_total_2022 computed = " r(N)
* Tabulation of cases for residences capital gains
capture drop res_cases
gen byte res_cases = .
replace res_cases = 1 if !missing(V_res_2022) & !missing(V_res_2020) & !missing(flow_residences_2022)  // both years + flow
replace res_cases = 2 if !missing(V_res_2022) & !missing(V_res_2020) & missing(flow_residences_2022)   // both years, no flow
replace res_cases = 3 if missing(V_res_2022) | missing(V_res_2020)                              // missing years
label define resCases 1 "both years + flow" 2 "both years, no flow" 3 "missing years", replace
label values res_cases resCases
di as txt "Residences capital gains cases:"
tab res_cases, missing

* ---------------------------------------------------------------------
* (Total capital gains across classes moved to compute_returns)
* ---------------------------------------------------------------------

* ---------------------------------------------------------------------
* 8) Diagnostics: inspect top/bottom observations and counts per class
* ---------------------------------------------------------------------
* Diagnostics will focus on per-class components only (totals in compute_returns)

* ---------------------------------------------------------------------
* Save dataset with new capital gains variables BACK TO MASTER (overwrite)
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved capital gains vars back to master: `master'"

log close
di as txt "Done. Inspect the log and the listed diagnostics. If you later want per-residence split, we can add allocation options — but currently residues are a single asset class as requested."
