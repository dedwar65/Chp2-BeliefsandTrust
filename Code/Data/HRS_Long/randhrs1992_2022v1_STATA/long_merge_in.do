*----------------------------------------------------------------------
* long_merge_in.do
* Merge flow variables from raw 2022 HRS file into longitudinal file
* 
* This script merges hhidpn and flow variables from the raw 2022 file
* into the HRS longitudinal file for 2022 returns computation
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "long_merge_in.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1.dta"
local raw_2022 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2022/h22e3a_STATA/h22e3a.dta"
local output_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Check if files exist
* ---------------------------------------------------------------------
di as txt "=== Checking file existence ==="

capture confirm file "`long_file'"
if _rc {
    di as error "ERROR: Longitudinal file not found -> `long_file'"
    exit 198
}
di as txt "OK: Longitudinal file found"

capture confirm file "`raw_2022'"
if _rc {
    di as error "ERROR: Raw 2022 file not found -> `raw_2022'"
    exit 198
}
di as txt "OK: Raw 2022 file found"

* ---------------------------------------------------------------------
* Load longitudinal file
* ---------------------------------------------------------------------
di as txt "=== Loading longitudinal file ==="
use "`long_file'", clear

di as txt "Longitudinal file loaded successfully"
quietly describe
local n_vars_long = r(k)
local n_obs_long = r(N)
di as txt "Variables in longitudinal file: `n_vars_long'"
di as txt "Observations in longitudinal file: `n_obs_long'"

* Check for hhidpn
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in longitudinal file"
    exit 198
}
di as txt "OK: hhidpn found in longitudinal file"

* Check for duplicates in longitudinal file
quietly duplicates report hhidpn
local n_dups_long = r(unique_value)
if `n_dups_long' != `n_obs_long' {
    di as error "ERROR: Duplicate hhidpn found in longitudinal file"
    di as error "Unique hhidpn: `n_dups_long', Total observations: `n_obs_long'"
    exit 198
}
di as txt "OK: No duplicate hhidpn in longitudinal file"

* ---------------------------------------------------------------------
* Load raw 2022 file and extract needed variables
* ---------------------------------------------------------------------
di as txt "=== Loading raw 2022 file and extracting flow variables ==="
preserve
use "`raw_2022'", clear

di as txt "Raw 2022 file loaded successfully"
quietly describe
local n_vars_raw = r(k)
local n_obs_raw = r(N)
di as txt "Variables in raw 2022 file: `n_vars_raw'"
di as txt "Observations in raw 2022 file: `n_obs_raw'"

* Check for hhidpn
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in raw 2022 file"
    exit 198
}
di as txt "OK: hhidpn found in raw 2022 file"

* Check for flow variables
local flow_vars "sr050 sr055 sr063 sr064 sr073 sr030 sr035 sr045 sq171_1 sq171_2 sq171_3 sr007 sr013 sr024"
di as txt "Checking for flow variables..."
foreach v of local flow_vars {
    capture confirm variable `v'
    if _rc {
        di as txt "  WARNING: `v' not found in raw 2022 file"
    }
    else {
        di as txt "  OK: `v' found"
    }
}

* Keep only hhidpn and flow variables
keep hhidpn `flow_vars'

* Check for duplicates in raw file
quietly duplicates report hhidpn
local n_dups_raw = r(unique_value)
if `n_dups_raw' != `n_obs_raw' {
    di as error "ERROR: Duplicate hhidpn found in raw 2022 file"
    di as error "Unique hhidpn: `n_dups_raw', Total observations: `n_obs_raw'"
    di as error "The raw file should have unique hhidpn values (one per person)"
    di as error "This indicates a problem with the raw file structure"
    exit 198
}
else {
    di as txt "OK: No duplicate hhidpn in raw 2022 file"
}

* Save temporary file
tempfile raw_flows
save "`raw_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flow variables into longitudinal data
* ---------------------------------------------------------------------
di as txt "=== Merging flow variables into longitudinal data ==="

merge 1:1 hhidpn using "`raw_flows'"

* Report merge results
di as txt "Merge results:"
tab _merge

quietly count if _merge == 3
local n_matched = r(N)
quietly count if _merge == 1
local n_long_only = r(N)
quietly count if _merge == 2
local n_raw_only = r(N)

di as txt "Matched observations: `n_matched'"
di as txt "Longitudinal only: `n_long_only'"
di as txt "Raw 2022 only: `n_raw_only'"

* Keep only matched observations
keep if _merge == 3
drop _merge

di as txt "Kept `n_matched' matched observations"

* ---------------------------------------------------------------------
* Compute flow_total_2022 from individual flow variables
* ---------------------------------------------------------------------
di as txt "=== Computing flow_total_2022 from individual flow variables ==="

* Clean missing value codes
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of local flow_vars {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* Flows - EXACT COPY FROM HRS_RAND VERSION

* Clean sr063 and create direction variable
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
}

* --- Private business: sr055 (sell/inflow) minus sr050 (invest/outflow)
capture drop flow_bus_2022
gen double flow_bus_2022 = .
* both present -> net
replace flow_bus_2022 = sr055 - sr050 if !missing(sr055) & !missing(sr050)
* sell only -> positive inflow
replace flow_bus_2022 = sr055 if  missing(sr050) & !missing(sr055)
* buy only -> negative outflow
replace flow_bus_2022 = -sr050 if !missing(sr050) &  missing(sr055)

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
}

* --- Public stocks: SR073 is reported as sold amount (inflow). Keep positive.
capture drop flow_stk_public_2022
gen double flow_stk_public_2022 = .
capture confirm variable sr073
if !_rc replace flow_stk_public_2022 = sr073

* Combine private + public stocks into total stocks flow
capture drop flow_stk_2022
gen double flow_stk_2022 = cond(!missing(flow_stk_private_2022), flow_stk_private_2022, 0) + ///
                            cond(!missing(flow_stk_public_2022),  flow_stk_public_2022,  0)
replace flow_stk_2022 = . if missing(flow_stk_private_2022) & missing(flow_stk_public_2022)

* --- Real estate: sr035 (sold, inflow) - sr030 (buy, outflow) - sr045 (improvement costs, outflow)
capture drop flow_re_2022
gen double flow_re_2022 = .
replace flow_re_2022 = cond(missing(sr035),0,sr035) - ( cond(missing(sr030),0,sr030) + cond(missing(sr045),0,sr045) ) if !missing(sr035) | !missing(sr030) | !missing(sr045)

* --- IRA: sum sq171_1 sq171_2 sq171_3 (kept as reported)
capture drop flow_ira_2022
egen double flow_ira_2022 = rowtotal(sq171_1 sq171_2 sq171_3)
* Set to missing if ALL three components are missing
replace flow_ira_2022 = . if missing(sq171_1) & missing(sq171_2) & missing(sq171_3)

* --- Primary/secondary residence(s): sr013 (sell, inflow) - sr007 (buy, outflow) - sr024 (improvements, outflow)
capture drop flow_residences_2022
gen double flow_residences_2022 = .
replace flow_residences_2022 = cond(missing(sr013),0,sr013) - ( cond(missing(sr007),0,sr007) + cond(missing(sr024),0,sr024) ) if !missing(sr013) | !missing(sr007) | !missing(sr024)

* Ensure missing only when all three residence components are missing
replace flow_residences_2022 = . if missing(sr013) & missing(sr007) & missing(sr024)

* Total net investment flows for 2022
* Missing only if ALL asset class flows are missing
* Otherwise, sum non-missing flows (treat missing as zero)
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

di as txt "flow_total_2022 computed successfully"
summarize flow_total_2022, detail

* ---------------------------------------------------------------------
* Save results
* ---------------------------------------------------------------------
di as txt "=== Saving results ==="

save "`output_file'", replace
di as txt "Saved merged file to: `output_file'"

quietly describe
local n_vars_final = r(k)
local n_obs_final = r(N)
di as txt "Final file: `n_obs_final' observations, `n_vars_final' variables"

* ---------------------------------------------------------------------
* Summary
* ---------------------------------------------------------------------
di as txt "=== Merge Summary ==="
di as txt "Original longitudinal observations: `n_obs_long'"
di as txt "Raw 2022 observations: `n_obs_raw'"
di as txt "Successfully matched: `n_matched'"
di as txt "Final merged file: `n_obs_final' observations, `n_vars_final' variables"

quietly count if !missing(flow_total_2022)
local n_with_flows = r(N)
di as txt "Observations with flow_total_2022: `n_with_flows'"

log close
