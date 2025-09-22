*----------------------------------------------------------------------
* Create: select variables from RAND 2020 household file and save
* Mirrors HRS extract script but uses RAND file and lowercase vars
* Usage: do "/Volumes/SSD PRO/Github-forks/.../extract_household_2020_ret_calc_end.do"
*----------------------------------------------------------------------
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA/extract_household_2020_rand.log", replace text

set more off

* --- file paths (edit if needed)
local path2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA"
local infile  "`path2020'/h20f1a.dta"
local out     "`path2020'/hrs_2020_selected.dta"

* --- list variables to keep (lowercase versions of original HRS vars)
local vars_keep "hhid rsubhh rq148 rq134 rq317 rq166_1 rq166_2 rq166_3 rq331 rq345 rq357 rq371 rq381 rq478 rh020 rh162 rh032 rh171"

* --- Safety: check file exists
capture confirm file "`infile'"
if _rc {
    di as error "ERROR: RAND 2020 file not found -> `infile'"
    exit 198
}

* --- Load RAND 2020 file and keep vars
use "`infile'", clear

* check variables exist
ds `vars_keep'
if r(N) == 0 {
    di as error "ERROR: none of the requested variables found. Check variable names."
    describe
    exit 198
}

keep `vars_keep'

* normalize keys
capture confirm string variable hhid
if !_rc {
    replace hhid = trim(hhid)
}
capture confirm string variable rsubhh
if !_rc {
    replace rsubhh = trim(rsubhh)
    replace rsubhh = "0" if rsubhh == ""
}
sort hhid rsubhh

* --- Deduplicate (keep row with most nonmissing across key vars)
bys hhid rsubhh: gen dupN = _N
count if dupN > 1
if r(N) > 0 {
    egen nm = rownonmiss(rq148 rq134 rq317 rq166_1 rq166_2 rq166_3 rq331 rq345 rq357 rq371 rq381 rq478 rh020 rh162 rh032 rh171), strok
    bys hhid rsubhh (nm): keep if _n==_N
    drop nm dupN
    sort hhid rsubhh
}

* --- Optional: clean common special missing codes to Stata missing
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* --- Save final 2020 selected
save "`out'", replace
di as txt "Saved selected 2020 RAND household data to `out'"

log close


