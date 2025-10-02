*----------------------------------------------------------------------
* Create: select variables from RAND 2022 household files and merge (Q,R,H)
* Mirrors HRS extract script but uses RAND files and lowercase vars
* Usage: do "/Volumes/SSD PRO/Github-forks/.../extract_household_2022_ret_calc_start.do"
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2022/h22e3a_STATA/extract_household_2022_rand.log", replace text

set more off

* --- file paths (edit if needed)
local path2022 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2022/h22e3a_STATA"
local qfile    "`path2022'/h22e3a.dta"
local rfile    "`path2022'/h22e3a.dta"
local hfile    "`path2022'/h22e3a.dta"
local out      "`path2022'/hrs_2022_selected.dta"
local tempQ    "`path2022'/hrs_2022_Q_selected.dta"
local tempR    "`path2022'/hrs_2022_R_selected.dta"
local tempH    "`path2022'/hrs_2022_H_selected.dta"

* --- lists of variables to keep (lowercase versions)
local varsQ "hhidpn hhid ssubhh sq139 sq141 sq153 sq155 sq190 sq194 sq322 sq324 sq336 sq338 sq350 sq352 sq362 sq364 sq171_1 sq171_2 sq171_3 sq148 sq134 sq317 sq166_1 sq166_2 sq166_3 sq331"
local varsR "hhidpn hhid ssubhh sr050 sr055 sr063 sr064 sr073 sr030 sr035 sr045 sr007 sr013 sr024"
local varsH "hhidpn hhid ssubhh sh020 sh162 sh025 sh029 sh036 sh040 sh175 sh179"

* --- Safety: check files exist
capture confirm file "`qfile'"
if _rc {
    di as error "ERROR: RAND 2022 file not found -> `qfile'"
    exit 198
}

* ---------------------------------------------------------------------
* Extract Q and keep vars
* ---------------------------------------------------------------------
use "`qfile'", clear
ds `varsQ'
if r(N) == 0 {
    di as error "ERROR: none of the requested Q variables found."
    describe
    exit 198
}
keep `varsQ'
capture confirm string variable hhid
if !_rc { replace hhid = trim(hhid) }
capture confirm string variable ssubhh
if !_rc {
    replace ssubhh = trim(ssubhh)
    replace ssubhh = "0" if ssubhh == ""
}
sort hhid ssubhh
save "`tempQ'", replace

* Deduplicate Q
use "`tempQ'", clear
bys hhid ssubhh: gen dupN = _N
count if dupN > 1
if r(N) > 0 {
    egen nm = rownonmiss(sq139 sq141 sq153 sq155 sq190 sq194 sq322 sq324 sq336 sq338 sq350 sq352 sq362 sq364 sq171_1 sq171_2 sq171_3 sq148 sq134 sq317 sq166_1 sq166_2 sq166_3 sq331), strok
    bys hhid ssubhh (nm): keep if _n==_N
    drop nm dupN
    sort hhid ssubhh
    save "`tempQ'", replace
}

* ---------------------------------------------------------------------
* Extract R and keep vars (same RAND combined file)
* ---------------------------------------------------------------------
use "`rfile'", clear
ds `varsR'
if r(N) == 0 {
    di as error "ERROR: none of the requested R variables found."
    describe
    exit 198
}
keep `varsR'
capture confirm string variable hhid
if !_rc { replace hhid = trim(hhid) }
capture confirm string variable ssubhh
if !_rc {
    replace ssubhh = trim(ssubhh)
    replace ssubhh = "0" if ssubhh == ""
}
sort hhid ssubhh
save "`tempR'", replace

* Deduplicate R
use "`tempR'", clear
bys hhid ssubhh: gen dupN = _N
count if dupN > 1
if r(N) > 0 {
    egen nm = rownonmiss(sr050 sr055 sr063 sr064 sr073 sr030 sr045 sr007 sr013 sr024), strok
    bys hhid ssubhh (nm): keep if _n==_N
    drop nm dupN
    sort hhid ssubhh
    save "`tempR'", replace
}

* ---------------------------------------------------------------------
* Extract H and keep vars (same RAND combined file)
* ---------------------------------------------------------------------
use "`hfile'", clear
ds `varsH'
if r(N) == 0 {
    di as error "ERROR: none of the requested H variables found."
    describe
    exit 198
}
keep `varsH'
capture confirm string variable hhid
if !_rc { replace hhid = trim(hhid) }
capture confirm string variable ssubhh
if !_rc {
    replace ssubhh = trim(ssubhh)
    replace ssubhh = "0" if ssubhh == ""
}
sort hhid ssubhh
save "`tempH'", replace

* Deduplicate H
use "`tempH'", clear
bys hhid ssubhh: gen dupN = _N
count if dupN > 1
if r(N) > 0 {
    egen nm = rownonmiss(sh020 sh162), strok
    bys hhid ssubhh (nm): keep if _n==_N
    drop nm dupN
    sort hhid ssubhh
    save "`tempH'", replace
}

* ---------------------------------------------------------------------
* Merge Q + R + H
* ---------------------------------------------------------------------
use "`tempQ'", clear
merge 1:1 hhid ssubhh using "`tempR'"
drop _merge
merge 1:1 hhid ssubhh using "`tempH'"
drop _merge

* Optional: clean special codes
local misscodes 99999999 99999998 999999998 999999999 9999999 9999998 9999999999 9999999998 -8 -9
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* Save final
save "`out'", replace
di as txt "Saved selected 2022 RAND household data to `out'"

log close



exit, clear
