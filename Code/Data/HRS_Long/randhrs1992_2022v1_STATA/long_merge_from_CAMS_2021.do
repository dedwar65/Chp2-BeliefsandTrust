*----------------------------------------------------------------------
* long_merge_from_CAMS_2021.do
* Merge CAMS 2021 variables into the unified RAND-HRS wide analysis file
*
* Variables to merge from CAMS 2021 (cams21_r.dta):
*   a20_21 (show affection), a21_21 (help others), a22_21 (volunteer work),
*   a23_21 (religious attendance), a24_21 (attend meetings)
*
* Merge key: hhidpn (1:1)
* CAMS file has HHID and PN but not hhidpn, so construct hhidpn before merging
* Output (in place): _randhrs1992_2022v1_analysis.dta
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "long_merge_from_CAMS_2021.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local cams_file   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_CAMS/2021/cams2021/cams21_r.dta"
local output_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Check files exist
* ---------------------------------------------------------------------
di as txt "=== Checking file existence ==="

capture confirm file "`long_file'"
if _rc {
    di as error "ERROR: Unified analysis dataset not found -> `long_file' (run create_wide_RAND_long.do / long_merge_in.do first)"
    exit 198
}
di as txt "OK: Input wide analysis file found -> `long_file'"

capture confirm file "`cams_file'"
if _rc {
    di as error "ERROR: CAMS 2021 file not found -> `cams_file'"
    exit 198
}
di as txt "OK: CAMS 2021 file found"

* ---------------------------------------------------------------------
* Load wide analysis dataset (master)
* ---------------------------------------------------------------------
di as txt "=== Loading wide analysis dataset ==="

use "`long_file'", clear

quietly describe
local n_vars_long = r(k)
local n_obs_long  = r(N)
di as txt "Wide analysis file: `n_obs_long' obs, `n_vars_long' vars"

* Check for hhidpn in master
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in the analysis file. Aborting."
    exit 198
}
di as txt "OK: hhidpn found in master file"

* If CAMS variables already exist from a prior run, drop them to avoid rename conflicts
di as txt "Cleaning any existing CAMS 2021 variables from master (idempotent rerun safeguard)"
foreach v in cams_showaffect_2021 cams_helpothers_2021 cams_volunteer_2021 cams_religattend_2021 cams_meetings_2021 {
    capture confirm variable `v'
    if !_rc {
        drop `v'
    }
}

* Check uniqueness for hhidpn in master
quietly duplicates report hhidpn
if r(unique_value) != r(N) {
    di as error "ERROR: Master has duplicate hhidpn rows; expected unique person-level file."
    exit 198
}
di as txt "OK: Master file has unique hhidpn values"

* ---------------------------------------------------------------------
* Load CAMS 2021, construct hhidpn, keep IDs + requested vars, check uniqueness
* ---------------------------------------------------------------------
di as txt "=== Loading CAMS 2021 and extracting variables ==="

preserve
use "`cams_file'", clear

* Confirm identifiers present in CAMS (check both uppercase and lowercase)
local hhid_var ""
local pn_var ""

capture confirm variable HHID
if !_rc {
    local hhid_var "HHID"
}
else {
    capture confirm variable hhid
    if !_rc {
        local hhid_var "hhid"
    }
    else {
        di as error "ERROR: Neither HHID nor hhid found in CAMS 2021 file. Aborting."
        exit 198
    }
}

capture confirm variable PN
if !_rc {
    local pn_var "PN"
}
else {
    capture confirm variable pn
    if !_rc {
        local pn_var "pn"
    }
    else {
        di as error "ERROR: Neither PN nor pn found in CAMS 2021 file. Aborting."
        exit 198
    }
}

di as txt "OK: `hhid_var' and `pn_var' found in CAMS file"

* Construct hhidpn from HHID/hhid and PN/pn
* Standard HRS formula: hhidpn = real(HHID) * 1000 + real(PN)
capture drop hhidpn
capture confirm string variable `hhid_var'
if !_rc {
    * HHID/hhid is string, convert to numeric
    gen double hhidpn = real(`hhid_var') * 1000 + real(`pn_var')
}
else {
    * HHID/hhid is numeric
    gen double hhidpn = `hhid_var' * 1000 + real(`pn_var')
}

di as txt "Constructed hhidpn from HHID and PN"

* ---------------------------------------------------------------------
* DIAGNOSTIC: Check hhidpn construction in CAMS file
* ---------------------------------------------------------------------
di as txt "=== DIAGNOSTIC: Checking hhidpn construction in CAMS file ==="
quietly count
di as txt "CAMS file total observations: " r(N)
quietly count if !missing(hhidpn)
di as txt "CAMS file with non-missing hhidpn: " r(N)
quietly summarize hhidpn, detail
di as txt "CAMS hhidpn range: " r(min) " to " r(max)
di as txt "CAMS hhidpn mean: " %12.2f r(mean)
di as txt "Sample of CAMS hhidpn values (first 10):"
quietly list hhidpn `hhid_var' `pn_var' in 1/10, noobs

* Save CAMS file with constructed hhidpn for inspection
local cams_with_hhidpn "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_CAMS/2021/cams2021/cams21_r_with_hhidpn.dta"
save "`cams_with_hhidpn'", replace
di as txt "Saved CAMS file with constructed hhidpn to: `cams_with_hhidpn'"
di as txt "  You can now open this file in Stata to inspect hhidpn values"

* Keep only IDs and needed CAMS vars
local cams_keep "a20_21 a21_21 a22_21 a23_21 a24_21"

foreach v of local cams_keep {
    capture confirm variable `v'
    if _rc {
        di as txt "WARNING: `v' not found in CAMS 2021 (will be missing after merge)"
    }
    else {
        di as txt "OK: `v' found in CAMS 2021"
    }
}

keep hhidpn `cams_keep'

* Check uniqueness on CAMS side
quietly duplicates report hhidpn
if r(unique_value) != r(N) {
    di as error "ERROR: CAMS 2021 has duplicate hhidpn rows after construction; expected one row per person."
    exit 198
}
di as txt "OK: CAMS file has unique hhidpn values"

tempfile cams_keep
save "`cams_keep'", replace

* Save diagnostics about CAMS file before restore
quietly count
local cams_total = r(N)
quietly count if !missing(hhidpn)
local cams_with_hhidpn = r(N)
quietly summarize hhidpn
local cams_hhidpn_min = r(min)
local cams_hhidpn_max = r(max)
quietly levelsof hhidpn if !missing(hhidpn), local(cams_hhidpn_levels)
local cams_unique_hhidpn : word count `cams_hhidpn_levels'

restore

* ---------------------------------------------------------------------
* DIAGNOSTIC: Check master file hhidpn before merge
* ---------------------------------------------------------------------
di as txt "=== DIAGNOSTIC: Checking master file hhidpn ==="
quietly count
di as txt "Master file total observations: " r(N)
quietly count if !missing(hhidpn)
di as txt "Master file with non-missing hhidpn: " r(N)
quietly summarize hhidpn, detail
di as txt "Master hhidpn range: " r(min) " to " r(max)
di as txt "Master hhidpn mean: " %12.2f r(mean)

* Check for potential overlap
di as txt "CAMS file has `cams_unique_hhidpn' unique hhidpn values"
quietly count if inrange(hhidpn, `cams_hhidpn_min', `cams_hhidpn_max')
local master_in_range = r(N)
di as txt "Master observations with hhidpn in CAMS range: " `master_in_range'

* Check exact overlap - count how many master hhidpn values exist in CAMS
preserve
use "`cams_keep'", clear
quietly keep hhidpn
tempfile cams_hhidpn_only
quietly save "`cams_hhidpn_only'", replace
restore

quietly merge 1:1 hhidpn using "`cams_hhidpn_only'", keep(master match)
quietly count if _merge == 3
local potential_matches = r(N)
di as txt "Potential matches (master hhidpn values that exist in CAMS): " `potential_matches'
drop _merge

* ---------------------------------------------------------------------
* Merge CAMS → master (1:1 on hhidpn)
* ---------------------------------------------------------------------
di as txt "=== Merging CAMS 2021 into wide analysis dataset ==="

merge 1:1 hhidpn using "`cams_keep'", keep(master match)

* Report merge results
di as txt "Merge results:"
tab _merge

quietly count if _merge==3
local n_match = r(N)
quietly count if _merge==1
local n_master_only = r(N)
quietly count if _merge==2
local n_cams_only   = r(N)

di as txt "  matched: `n_match'   master only: `n_master_only'   CAMS only: `n_cams_only'"

drop _merge

* ---------------------------------------------------------------------
* DIAGNOSTIC: Check raw CAMS values BEFORE renaming and cleaning
* ---------------------------------------------------------------------
di as txt "=== DIAGNOSTIC: Raw CAMS values before renaming and cleaning ==="
foreach v in a20_21 a21_21 a22_21 a23_21 a24_21 {
    capture confirm variable `v'
    if !_rc {
        quietly count if !missing(`v')
        di as txt "Raw `v' (before any processing): " r(N) " non-missing"
        quietly count if inlist(`v', -9, -8, 98, 99)
        if r(N) > 0 {
            di as txt "  `v' has " r(N) " values that will be cleaned to missing (codes: -9, -8, 98, 99)"
        }
    }
}

* ---------------------------------------------------------------------
* Rename CAMS vars and label (keep raw coding)
* ---------------------------------------------------------------------
capture confirm variable a20_21
if !_rc {
    rename a20_21 cams_showaffect_2021
    label var cams_showaffect_2021 "CAMS 2021: Show affection (a20_21)"
}

capture confirm variable a21_21
if !_rc {
    rename a21_21 cams_helpothers_2021
    label var cams_helpothers_2021 "CAMS 2021: Help others (a21_21)"
}

capture confirm variable a22_21
if !_rc {
    rename a22_21 cams_volunteer_2021
    label var cams_volunteer_2021 "CAMS 2021: Volunteer work (a22_21)"
}

capture confirm variable a23_21
if !_rc {
    rename a23_21 cams_religattend_2021
    label var cams_religattend_2021 "CAMS 2021: Religious attendance (a23_21)"
}

capture confirm variable a24_21
if !_rc {
    rename a24_21 cams_meetings_2021
    label var cams_meetings_2021 "CAMS 2021: Attend meetings (a24_21)"
}

* Clean common non-response codes if present (-9, -8, 98, 99)
foreach v in cams_showaffect_2021 cams_helpothers_2021 cams_volunteer_2021 cams_religattend_2021 cams_meetings_2021 {
    capture confirm numeric variable `v'
    if !_rc {
        quietly count if !missing(`v')
        local before_clean = r(N)
        quietly replace `v' = . if inlist(`v', -9, -8, 98, 99)
        quietly count if !missing(`v')
        local after_clean = r(N)
        if `before_clean' != `after_clean' {
            di as txt "Cleaned `v': " `before_clean' " -> " `after_clean' " non-missing"
        }
    }
}

di as txt "Cleaned non-response codes (-9, -8, 98, 99) to missing"

* ---------------------------------------------------------------------
* DIAGNOSTIC: Check CAMS values AFTER cleaning
* ---------------------------------------------------------------------
di as txt "=== DIAGNOSTIC: CAMS values after cleaning ==="
foreach v in cams_showaffect_2021 cams_helpothers_2021 cams_volunteer_2021 cams_religattend_2021 cams_meetings_2021 {
    capture confirm variable `v'
    if !_rc {
        quietly count if !missing(`v')
        di as txt "Final `v': " r(N) " non-missing"
    }
}

* ---------------------------------------------------------------------
* Save (in place)
* ---------------------------------------------------------------------
di as txt "=== Saving updated wide analysis file ==="

save "`output_file'", replace

quietly describe
local n_vars_final = r(k)
local n_obs_final  = r(N)
di as txt "Saved: `output_file'"
di as txt "Final file: `n_obs_final' observations, `n_vars_final' variables"

di as txt "Done."

log close

