*----------------------------------------------------------------------
* RAND: compute_net_flows_2022.do (mirror HRS checks/diagnostics; lowercase vars)
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_net_flows_2022.log", replace text

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

local vars_to_check "sr050 sr055 sr063 sr064 sr073 sr030 sr035 sr045 sq171_1 sq171_2 sq171_3 sr007 sr013 sr024"
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

* Clean sr063
capture confirm variable sr063
if _rc {
    di as txt "sr063 not found; skipping sr063 cleaning/mapping."
}
else {
    di as txt "Cleaning sr063 (private stock net buyer/seller)..."
    quietly replace sr063 = . if inlist(sr063,8,9)
    quietly replace sr063 = 0 if sr063 == 3
    capture drop sr063_dir
    gen byte sr063_dir = . 
    replace sr063_dir = -1 if sr063 == 1
    replace sr063_dir =  1 if sr063 == 2
    replace sr063_dir =  0 if sr063 == 3
    di as txt "sr063 mapping summary (post-clean):"
    tab sr063, missing
    di as txt "sr063_dir summary:"
    tab sr063_dir, missing
}

* Flows
* --- Private business: sr055 (sell/inflow) minus sr050 (invest/outflow)
capture confirm variable sr055
if _rc {
    di as txt "sr055 missing -> setting flow_bus_2022 to missing"
    gen double flow_bus_2022 = .
}
else {
    capture confirm variable sr050
    if _rc {
        di as txt "sr050 missing; using sr055 only for flow_bus_2022"
        gen double flow_bus_2022 = sr055
    }
    else {
        capture drop flow_bus_2022
        gen double flow_bus_2022 = . 
        replace flow_bus_2022 = sr055 - sr050 if !missing(sr055) | !missing(sr050)
    }
    di as txt "Private business flow summary:"
    summarize flow_bus_2022, detail
}

* --- Private stocks: sr063_dir * sr064
capture confirm variable sr064
if _rc {
    di as txt "sr064 (stock magnitude) missing -> setting flow_stk_private_2022 to missing"
    gen double flow_stk_private_2022 = .
}
else {
    capture drop flow_stk_private_2022
    gen double flow_stk_private_2022 = .
    replace flow_stk_private_2022 = sr063_dir * sr064 if !missing(sr063_dir) & !missing(sr064)
    di as txt "Private stock flow summary (sr063_dir * sr064):"
    summarize flow_stk_private_2022, detail
}

* --- Public stocks: sr073 is reported as sold amount (inflow). Keep positive.
capture confirm variable sr073
if _rc {
    di as txt "sr073 not found -> flow_stk_public_2022 missing"
    gen double flow_stk_public_2022 = .
}
else {
    capture drop flow_stk_public_2022
    gen double flow_stk_public_2022 = sr073
    di as txt "Public stock (sold) flow summary (sr073):"
    summarize flow_stk_public_2022, detail
}

* Combine private + public stocks into total stocks flow
capture drop flow_stk_2022
egen double flow_stk_2022 = rowtotal(flow_stk_private_2022 flow_stk_public_2022)
di as txt "TOTAL stocks flow (2022) summary:"
summarize flow_stk_2022, detail

* --- Real estate: sr035 (sold, inflow) - sr030 (buy, outflow) - sr045 (improvement costs, outflow)
capture drop flow_re_2022
gen double flow_re_2022 = .
replace flow_re_2022 = cond(missing(sr035),0,sr035) - ( cond(missing(sr030),0,sr030) + cond(missing(sr045),0,sr045) ) if !missing(sr035) | !missing(sr030) | !missing(sr045)
di as txt "Real estate flow summary:"
summarize flow_re_2022, detail

* --- IRA: sum sq171_1 sq171_2 sq171_3 (kept as reported)
capture drop flow_ira_2022
egen double flow_ira_2022 = rowtotal(sq171_1 sq171_2 sq171_3)
di as txt "IRA flow summary (row-sum of sq171_1/2/3):"
summarize flow_ira_2022, detail
tabstat flow_ira_2022, stats(n mean sd p50 min max) format(%12.2f)

* --- Primary/secondary residence(s): sr013 (sell, inflow) - sr007 (buy, outflow) - sr024 (improvements, outflow)
capture drop flow_residences_2022
gen double flow_residences_2022 = .
replace flow_residences_2022 = cond(missing(sr013),0,sr013) - ( cond(missing(sr007),0,sr007) + cond(missing(sr024),0,sr024) ) if !missing(sr013) | !missing(sr007) | !missing(sr024)
di as txt "Primary/secondary residences flow summary:"
summarize flow_residences_2022, detail
capture drop flow_ira_2022_neg
gen double flow_ira_2022_neg = -flow_ira_2022

capture drop flow_total_2022
egen double flow_total_2022 = rowtotal(flow_bus_2022 flow_stk_2022 flow_re_2022 flow_ira_2022_neg flow_residences_2022)
di as txt "TOTAL net investment flows 2022 summary (sum across asset classes; IRA negated):"
summarize flow_total_2022, detail
tabstat flow_total_2022, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Diagnostics...
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: sr063 direction missing but sr064 magnitude present ==="
capture confirm variable sr064
if _rc == 0 {
    quietly count if missing(sr063_dir) & !missing(sr064)
    di as txt "Records with sr064 present but sr063_dir missing = " r(N)
    quietly list hhid rsubhh sr063 sr063_dir sr064 flow_stk_private_2022 in 1/20 if missing(sr063_dir) & !missing(sr064)
}

di as txt "=== Diagnostics: magnitude present for sells/buys but computed flow missing ==="
foreach pair in "sr055 sr050 flow_bus_2022" "sr035 sr030 flow_re_2022" "sr013 sr007 flow_residences_2022" "sr073 sr073 flow_stk_public_2022" {
    local sell : word 1 of `pair'
    local buy  : word 2 of `pair'
    local outv : word 3 of `pair'
    di as txt "---- Checking `outv' (sell `sell' ; buy `buy')"
    quietly count if ( (!missing(`sell') | !missing(`buy')) & missing(`outv') )
    di as txt "Records with sell/buy present but `outv' missing = " r(N)
    quietly list hhid rsubhh `sell' `buy' `outv' in 1/20 if ( (!missing(`sell') | !missing(`buy')) & missing(`outv') )
}

save "`master'", replace
di as txt "Saved 2022 net-flow vars back to master: `master'"

log close

