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
capture confirm variable SR055
if _rc {
    di as txt "SR055 missing -> setting flow_bus_2022 to missing"
    gen double flow_bus_2022 = .
}
else {
    capture confirm variable SR050
    if _rc {
        di as txt "SR050 missing; using SR055 only for flow_bus_2022"
        gen double flow_bus_2022 = SR055
    }
    else {
        gen double flow_bus_2022 = . 
        replace flow_bus_2022 = SR055 - SR050 if !missing(SR055) | !missing(SR050)
    }
    di as txt "Private business flow summary:"
    summarize flow_bus_2022, detail
}

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

* Combine private + public stocks into total stocks flow (public component is added)
capture drop flow_stk_2022
egen double flow_stk_2022 = rowtotal(flow_stk_private_2022 flow_stk_public_2022)
di as txt "TOTAL stocks flow (2022) summary:"
summarize flow_stk_2022, detail

* --- Real estate: SR035 (sold, inflow) - SR030 (buy, outflow) - SR045 (improvement costs, outflow)
gen double flow_re_2022 = .
replace flow_re_2022 = cond(missing(SR035),0,SR035) - ( cond(missing(SR030),0,SR030) + cond(missing(SR045),0,SR045) ) ///
    if !missing(SR035) | !missing(SR030) | !missing(SR045)
di as txt "Real estate flow summary:"
summarize flow_re_2022, detail

* --- IRA: sum SQ171_1 SQ171_2 SQ171_3 (kept as reported)
egen double flow_ira_2022 = rowtotal(SQ171_1 SQ171_2 SQ171_3)
di as txt "IRA flow summary (row-sum of SQ171_1/2/3):"
summarize flow_ira_2022, detail
tabstat flow_ira_2022, stats(n mean sd p50 min max) format(%12.2f)

* --- Primary/secondary residence(s): SR013 (sell, inflow) - SR007 (buy, outflow) - SR024 (improvements, outflow)
gen double flow_residences_2022 = .
replace flow_residences_2022 = cond(missing(SR013),0,SR013) - ( cond(missing(SR007),0,SR007) + cond(missing(SR024),0,SR024) ) ///
    if !missing(SR013) | !missing(SR007) | !missing(SR024)
di as txt "Primary/secondary residences flow summary:"
summarize flow_residences_2022, detail

* ---------------------------------------------------------------------
* Total net investment flows (2022): sum over asset classes
* IRA flows negated in the overall total (treat as household outflows)
* ---------------------------------------------------------------------
capture drop flow_ira_2022_neg
gen double flow_ira_2022_neg = -flow_ira_2022

egen double flow_total_2022 = rowtotal(flow_bus_2022 flow_stk_2022 flow_re_2022 flow_ira_2022_neg flow_residences_2022)
di as txt "TOTAL net investment flows 2022 summary (sum across asset classes; IRA negated):"
summarize flow_total_2022, detail
tabstat flow_total_2022, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Diagnostics...
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: SR063 direction missing but SR064 magnitude present ==="
capture confirm variable SR064
if _rc == 0 {
    quietly count if missing(sr063_dir) & !missing(SR064)
    di as txt "Records with SR064 present but sr063_dir missing = " r(N)
    quietly list HHID RSUBHH SR063 sr063_dir SR064 flow_stk_private_2022 in 1/20 if missing(sr063_dir) & !missing(SR064)
}

di as txt "=== Diagnostics: magnitude present for sells/buys but computed flow missing ==="
foreach pair in "SR055 SR050 flow_bus_2022" "SR035 SR030 flow_re_2022" "SR013 SR007 flow_residences_2022" "SR073 SR073 flow_stk_public_2022" {
    local sell : word 1 of `pair'
    local buy  : word 2 of `pair'
    local outv : word 3 of `pair'
    di as txt "---- Checking `outv' (sell `sell' ; buy `buy')"
    quietly count if ( (!missing(`sell') | !missing(`buy')) & missing(`outv') )
    di as txt "Records with sell/buy present but `outv' missing = " r(N)
    quietly list HHID RSUBHH `sell' `buy' `outv' in 1/20 if ( (!missing(`sell') | !missing(`buy')) & missing(`outv') )
}

* ---------------------------------------------------------------------
* Save dataset with new computed net flows BACK TO MASTER (overwrite)
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved 2022 net-flow vars back to master: `master'"

log close
di as txt "Done. Inspect the log and diagnostics above."
