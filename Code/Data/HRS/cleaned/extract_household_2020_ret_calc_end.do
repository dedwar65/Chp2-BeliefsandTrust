*----------------------------------------------------------------------
* Create: select variables from H20Q_H.dta and H20R_H.dta and merge
* Usage: run in Stata: do "/Volumes/SSD PRO/Github-forks/.../extract_household_2020.do"
*----------------------------------------------------------------------
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2020/h20sta/extract_household_2020.log", replace text

set more off

* --- file paths (edit if needed)
local path2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2020/h20sta"
local out   "`path2020'/hrs_2020_selected.dta"
local tempQ "`path2020'/hrs_2020_Q_selected.dta"
local tempH "`path2020'/hrs_2020_H_selected.dta"

* --- list variables to keep from each file (edit these lists as you like)
* --- these are the variables you mentioned earlier plus a few housing/debt examples
local varsQ "HHID RSUBHH RQ148 RQ134 RQ317 RQ166_1 RQ166_2 RQ166_3 RQ331 RQ345 RQ357 RQ371 RQ381 RQ478"
local varsH "HHID RSUBHH RH020 RH162 RH032 RH171"

* --- Safety: check files exist
capture confirm file "`path2020'/H20Q_H.dta"
if _rc {
    di as error "ERROR: file `path2020'/H20Q_H.dta not found. Edit path and rerun."
    exit 198
}
capture confirm file "`path2020'/H20H_H.dta"
if _rc {
    di as error "ERROR: file `path2020'/H20H_H.dta not found. Edit path and rerun."
    exit 198
}

* --- Load Q household file and keep vars
use "`path2020'/H20Q_H.dta", clear
* check variables exist
ds `varsQ'
if r(N) == 0 {
    di as error "ERROR: none of the requested Q variables found. Check variable names."
    describe
    exit 198
}
keep `varsQ'
* (optional) convert string HHID to numeric if needed; ensure keys present
sort HHID RSUBHH

save "`tempQ'", replace

* --- Load H household file and keep vars
use "`path2020'/H20H_H.dta", clear
ds `varsR'
if r(N) == 0 {
    di as error "ERROR: none of the requested H variables found. Check variable names."
    describe
    exit 198
}
keep `varsH'
sort HHID RSUBHH

save "`tempH'", replace

* --- Merge Q and H selected files (1:1 household)
use "`tempQ'", clear
merge 1:1 HHID RSUBHH using "`tempH'"
* keep matched and unmatched? Here we keep all households and flag merges
tab _merge
* drop _merge after checking if you prefer
drop _merge

* --- Optional: clean common special missing codes to Stata missing
* Add or remove codes based on what HRS uses; many HRS items use 9999998/9999999 for DK/RF
local misscodes 999998 999999 -8 -9
foreach v of varlist _all {
    foreach mc of local misscodes {
        capture confirm numeric variable `v'
        if !_rc {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* --- Save final 2020 selected
save "`out'", replace
di as txt "Saved selected 2020 household data to `out'"

log close
