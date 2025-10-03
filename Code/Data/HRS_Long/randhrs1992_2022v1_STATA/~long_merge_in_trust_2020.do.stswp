*----------------------------------------------------------------------
* long_merge_in_trust_2020.do
* Merge 2020 trust variables from raw HRS RAND fat file into longitudinal file
*
* Variables to merge from 2020 raw file: rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564
* Merge key: hhidpn (1:1)
* Output: randhrs1992_2022v1_with_trust_2020.dta
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "long_merge_in_trust_2020.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
* Prefer starting from the flows-merged file if available so we build a unified dataset
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/randhrs1992_2022v1_with_flows.dta"
local raw_2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA/h20f1a.dta"
local output_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Check if files exist
* ---------------------------------------------------------------------
di as txt "=== Checking file existence ==="

capture confirm file "`long_file'"
if _rc {
    * Fallback to base longitudinal file if flows file is not yet created
    local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/randhrs1992_2022v1.dta"
    capture confirm file "`long_file'"
    if _rc {
        di as error "ERROR: Longitudinal file not found -> `long_file'"
        exit 198
    }
}
di as txt "OK: Input longitudinal file found -> `long_file'"

capture confirm file "`raw_2020'"
if _rc {
    di as error "ERROR: Raw 2020 file not found -> `raw_2020'"
    exit 198
}
di as txt "OK: Raw 2020 file found"

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
* Load raw 2020 file and extract needed variables
* ---------------------------------------------------------------------
di as txt "=== Loading raw 2020 file and extracting trust variables ==="
preserve
use "`raw_2020'", clear

di as txt "Raw 2020 file loaded successfully"
quietly describe
local n_vars_raw = r(k)
local n_obs_raw = r(N)
di as txt "Variables in raw 2020 file: `n_vars_raw'"
di as txt "Observations in raw 2020 file: `n_obs_raw'"

* Check for hhidpn
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in raw 2020 file"
    exit 198
}
di as txt "OK: hhidpn found in raw 2020 file"

* Check for trust variables
local trust_vars "rv557 rv558 rv559 rv560 rv561 rv562 rv563 rv564"
di as txt "Checking for trust variables..."
foreach v of local trust_vars {
    capture confirm variable `v'
    if _rc {
        di as txt "  WARNING: `v' not found in raw 2020 file"
    }
    else {
        di as txt "  OK: `v' found"
    }
}

* Keep only hhidpn and trust variables
keep hhidpn `trust_vars'

* Check for duplicates in raw file
quietly duplicates report hhidpn
local n_dups_raw = r(unique_value)
if `n_dups_raw' != `n_obs_raw' {
    di as error "ERROR: Duplicate hhidpn found in raw 2020 file"
    di as error "Unique hhidpn: `n_dups_raw', Total observations: `n_obs_raw'"
    di as error "The raw file should have unique hhidpn values (one per person)"
    exit 198
}
else {
    di as txt "OK: No duplicate hhidpn in raw 2020 file"
}

* Save temporary file
tempfile raw_trust
save "`raw_trust'", replace
restore

* ---------------------------------------------------------------------
* Merge trust variables into longitudinal data
* ---------------------------------------------------------------------
di as txt "=== Merging trust variables into longitudinal data ==="

merge 1:1 hhidpn using "`raw_trust'"

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
di as txt "Raw 2020 only: `n_raw_only'"

* Keep only matched observations
keep if _merge == 3
drop _merge

di as txt "Kept `n_matched' matched observations"

* ---------------------------------------------------------------------
* Clean miscodes and summarize merged trust variables
* ---------------------------------------------------------------------
di as txt "=== Cleaning miscodes for trust variables (set 98/99 to missing) ==="
foreach v of local trust_vars {
    capture confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', 98, 99, -8)
    }
}

di as txt "=== Summaries of merged trust variables (2020) ==="
foreach v of local trust_vars {
    capture confirm variable `v'
    if !_rc {
        di as txt "Summary for `v':"
        summarize `v', detail
    }
}

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

log close

