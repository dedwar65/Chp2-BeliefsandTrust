*----------------------------------------------------------------------
* compute_net_flows_2022.do
* Compute net investment flows F_t by asset class for 2022
* Loads and then saves back to the master so other scripts keep variables.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_net_flows_2022.log", replace text

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
* Optional: convert common special codes to Stata missing (numeric variables)
* ---------------------------------------------------------------------
local misscodes 999999998 999999999 -8 -9
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Variables (2022)
* - private business: SR050 (invest), SR055 (sell)
* - stocks (private): SR063 (direction), SR064 (magnitude)
*   - public stocks (sold only): SR073 (sold)
* - real estate: SR030 (buy), SR035 (sold), SR045 (improvement costs)
* - IRA: SQ171_1, SQ171_2, SQ171_3
* - primary/secondary residence(s): SR007 (buy), SR013 (sell), SR024 (improvement costs)
* ---------------------------------------------------------------------

local vars_to_check "SR050 SR055 SR063 SR064 SR073 SR030 SR035 SR045 SQ171_1 SQ171_2 SQ171_3 SR007 SR013 SR024"
di as txt "Checking existence of required 2022 variables..."
foreach v of local vars_to_check {
    capture confirm variable `v'
    if _rc {
        di as err "  WARNING: variable `v' not found in master dataset"
    }
    else {
        di as txt "  OK: `v' present"
    }
}

* ---------------------------------------------------------------------
* Clean SR063: convert codes 8 and 9 -> missing; convert 3 -> 0
* Then map direction: 1 -> -1 (put money in), 2 -> +1 (take money out), 3 -> 0
* ---------------------------------------------------------------------
capture confirm variable SR063
if _rc {
    di as txt "SR063 not found; skipping SR063 cleaning/mapping."
}
else {
    di as txt "Cleaning SR063 (private stock net buyer/seller)..."
    quietly replace SR063 = . if inlist(SR063,8,9)
    quietly replace SR063 = 0 if SR063 == 3
    capture drop sr063_dir
    gen byte sr063_dir = . 
    replace sr063_dir = -1 if SR063 == 1
    replace sr063_dir =  1 if SR063 == 2
    replace sr063_dir =  0 if SR063 == 3
    di as txt "SR063 mapping summary (post-clean):"
    tab SR063, missing
    di as txt "sr063_dir summary:"
    tab sr063_dir, missing
}

* ---------------------------------------------------------------------
* Compute net flows per asset class (2022)
* ---------------------------------------------------------------------
* --- Private business: SR055 (sell/inflow) minus SR050 (invest/outflow)
capture drop flow_bus_2022
gen double flow_bus_2022 = .
* both present -> net
replace flow_bus_2022 = SR055 - SR050 if !missing(SR055) & !missing(SR050)
* sell only -> positive inflow
replace flow_bus_2022 = SR055 if  missing(SR050) & !missing(SR055)
* buy only -> negative outflow
replace flow_bus_2022 = -SR050 if !missing(SR050) &  missing(SR055)
di as txt "Private business flow summary:"
summarize flow_bus_2022, detail

* --- Private stocks: sr063_dir * SR064
capture confirm variable SR064
if _rc {
    di as txt "SR064 (stock magnitude) missing -> setting flow_stk_private_2022 to missing"
    gen double flow_stk_private_2022 = .
}
else {
    gen double flow_stk_private_2022 = .
    replace flow_stk_private_2022 = sr063_dir * SR064 if !missing(sr063_dir) & !missing(SR064)
    di as txt "Private stock flow summary (sr063_dir * SR064):"
    summarize flow_stk_private_2022, detail
}

* --- Public stocks: SR073 is reported as sold amount (inflow). Keep positive.
capture confirm variable SR073
if _rc {
    di as txt "SR073 not found -> flow_stk_public_2022 missing"
    gen double flow_stk_public_2022 = .
}
else {
    gen double flow_stk_public_2022 = SR073
    di as txt "Public stock (sold) flow summary (SR073):"
    summarize flow_stk_public_2022, detail
}

* Combine private + public stocks into total stocks flow (missing when both components missing)
capture drop flow_stk_2022
gen double flow_stk_2022 = cond(!missing(flow_stk_private_2022), flow_stk_private_2022, 0) + ///
                            cond(!missing(flow_stk_public_2022),  flow_stk_public_2022,  0)
replace flow_stk_2022 = . if missing(flow_stk_private_2022) & missing(flow_stk_public_2022)
di as txt "TOTAL stocks flow (2022) summary (missing when both components missing):"
summarize flow_stk_2022, detail

* Quick check: households with BOTH public (SR073) and private magnitude (SR064) present
di as txt "Checking overlap: SR073 (public sells) AND SR064 (private magnitude) both non-missing"
quietly count if !missing(SR073) & !missing(SR064)
di as txt "Count with SR073 & SR064 both present = " r(N)
quietly list HHID RSUBHH SR073 SR064 flow_stk_public_2022 flow_stk_private_2022 in 1/10 if !missing(SR073) & !missing(SR064)

* --- Real estate: SR035 (sold, inflow) - SR030 (buy, outflow) - SR045 (improvement costs, outflow)
gen double flow_re_2022 = .
replace flow_re_2022 = cond(missing(SR035),0,SR035) - ( cond(missing(SR030),0,SR030) + cond(missing(SR045),0,SR045) ) ///
    if !missing(SR035) | !missing(SR030) | !missing(SR045)
di as txt "Real estate flow summary:"
summarize flow_re_2022, detail

* Overlap diagnostics for real estate raw components (buy/sell/improvements)
gen byte ok_buy  = !missing(SR030)
gen byte ok_sell = !missing(SR035)
gen byte ok_impr = !missing(SR045)
gen byte re_pattern = ok_sell*4 + ok_buy*2 + ok_impr
label define rePat 0 "none" 1 "impr only" 2 "buy only" 3 "buy+impr" 4 "sell only" 5 "sell+impr" 6 "sell+buy" 7 "sell+buy+impr"
label values re_pattern rePat
di as txt "Counts of buy/sell/improvements presence patterns (real estate):"
tab re_pattern, missing
quietly count if ok_sell & ok_buy & ok_impr
di as txt "Households with ALL THREE present = " r(N)

* --- IRA: sum SQ171_1 SQ171_2 SQ171_3 (kept as reported)
egen double flow_ira_2022 = rowtotal(SQ171_1 SQ171_2 SQ171_3)
* Set to missing if ALL three components are missing
replace flow_ira_2022 = . if missing(SQ171_1) & missing(SQ171_2) & missing(SQ171_3)
di as txt "IRA flow summary (row-sum of SQ171_1/2/3; missing when all three missing):"
summarize flow_ira_2022, detail
tabstat flow_ira_2022, stats(n mean sd p50 min max) format(%12.2f)

* Overlap diagnostics for IRA components
gen byte ok_ira1 = !missing(SQ171_1)
gen byte ok_ira2 = !missing(SQ171_2)
gen byte ok_ira3 = !missing(SQ171_3)
gen byte ira_pattern = ok_ira1*4 + ok_ira2*2 + ok_ira3
label define iraPat 0 "none" 1 "3 only" 2 "2 only" 3 "2+3" 4 "1 only" 5 "1+3" 6 "1+2" 7 "1+2+3"
label values ira_pattern iraPat
di as txt "Counts of presence patterns for IRA components (SQ171_1/2/3):"
tab ira_pattern, missing

* --- Primary/secondary residence(s): SR013 (sell, inflow) - SR007 (buy, outflow) - SR024 (improvements, outflow)
gen double flow_residences_2022 = .
replace flow_residences_2022 = cond(missing(SR013),0,SR013) - ( cond(missing(SR007),0,SR007) + cond(missing(SR024),0,SR024) ) ///
    if !missing(SR013) | !missing(SR007) | !missing(SR024)
di as txt "Primary/secondary residences flow summary:"
summarize flow_residences_2022, detail

* Ensure missing only when all three residence components are missing
replace flow_residences_2022 = . if missing(SR013) & missing(SR007) & missing(SR024)

* Overlap diagnostics for residence components (buy/sell/improvements)
gen byte ok_res_buy  = !missing(SR007)
gen byte ok_res_sell = !missing(SR013)
gen byte ok_res_impr = !missing(SR024)
gen byte res_pattern = ok_res_sell*4 + ok_res_buy*2 + ok_res_impr
label define resPat 0 "none" 1 "impr only" 2 "buy only" 3 "buy+impr" 4 "sell only" 5 "sell+impr" 6 "sell+buy" 7 "sell+buy+impr"
label values res_pattern resPat
di as txt "Counts of presence patterns for residence components (SR007/SR013/SR024):"
tab res_pattern, missing
quietly count if ok_res_sell & ok_res_buy & ok_res_impr
di as txt "Households with ALL THREE residence components present = " r(N)

* ---------------------------------------------------------------------
* Total net investment flows for 2022
* Missing only if ALL asset class flows are missing
* Otherwise, sum non-missing flows (treat missing as zero)
* ---------------------------------------------------------------------
capture drop flow_total_2022
gen double flow_total_2022 = .
* Check if at least one asset class has non-missing flow
egen byte any_flow_present = rownonmiss(flow_bus_2022 flow_re_2022 flow_stk_2022 flow_ira_2022 flow_residences_2022)
* Compute total only if at least one flow is present
replace flow_total_2022 = cond(missing(flow_bus_2022),0,flow_bus_2022) + ///
                         cond(missing(flow_re_2022),0,flow_re_2022) + ///
                         cond(missing(flow_stk_2022),0,flow_stk_2022) + ///
                         cond(missing(flow_ira_2022),0,flow_ira_2022) + ///
                         cond(missing(flow_residences_2022),0,flow_residences_2022) ///
                         if any_flow_present > 0
drop any_flow_present

di as txt "Total net investment flows (flow_total_2022) summary:"
summarize flow_total_2022, detail
quietly count if !missing(flow_total_2022)
di as txt "Records with flow_total_2022 computed = " r(N)

* ---------------------------------------------------------------------
* Diagnostics...
* ---------------------------------------------------------------------
* (Generic diagnostics removed)

* ---------------------------------------------------------------------
* Save dataset with new computed net flows BACK TO MASTER (overwrite)
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved 2022 net-flow vars back to master: `master'"

log close
di as txt "Done. Inspect the log and diagnostics above."
