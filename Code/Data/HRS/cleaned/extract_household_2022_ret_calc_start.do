*----------------------------------------------------------------------
* Create: select variables from H22Q_H.dta, H22R_H.dta and H22H_H.dta and merge
* Usage: do "…/extract_household_2022.do"
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2022/h22sta/extract_household_2022.log", replace text

set more off

* --- file paths (edit if needed)
local path2022 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2022/h22sta"
local out   "`path2022'/hrs_2022_selected.dta"
local tempQ "`path2022'/hrs_2022_Q_selected.dta"
local tempR "`path2022'/hrs_2022_R_selected.dta"
local tempH "`path2022'/hrs_2022_H_selected.dta"

* --- list variables to keep from each file (edit these lists as you like)
local varsQ "HHID RSUBHH SQ139 SQ141 SQ153 SQ155 SQ190 SQ194 SQ322 SQ324 SQ336 SQ338 SQ350 SQ352 SQ362 SQ364 SQ171_1 SQ171_2 SQ171_3 SQ148 SQ134 SQ317 SQ166_1 SQ166_2 SQ166_3 SQ331"
local varsR "HHID RSUBHH SR050 SR055 SR063 SR064 SR072 SR030 SR045 SR007 SR013 SR024"
local varsH "HHID RSUBHH SH020 SH162 SH025 SH029 SH036 SH040 SH175 SH179"

* --- Safety: check files exist
capture confirm file "`path2022'/H22Q_H.dta"
if _rc {
    di as error "ERROR: file `path2022'/H22Q_H.dta not found. Edit path and rerun."
    exit 198
}
capture confirm file "`path2022'/H22R_H.dta"
if _rc {
    di as error "ERROR: file `path2022'/H22R_H.dta not found. Edit path and rerun."
    exit 198
}
capture confirm file "`path2022'/H22H_H.dta"
if _rc {
    di as error "ERROR: file `path2022'/H22H_H.dta not found. Edit path and rerun."
    exit 198
}

* ---------------------------------------------------------------------
* Extract Q household file and keep vars
* ---------------------------------------------------------------------
use "`path2022'/H22Q_H.dta", clear
ds `varsQ'
if r(N) == 0 {
    di as error "ERROR: none of the requested Q variables found in H22Q_H.dta. Check variable names."
    describe
    exit 198
}
keep `varsQ'
replace HHID = trim(HHID)
replace RSUBHH = trim(RSUBHH)
replace RSUBHH = "0" if RSUBHH == ""
sort HHID RSUBHH
save "`tempQ'", replace

* ---------------------------------------------------------------------
* Deduplicate Q (keep row with most nonmissing values per HHID+RSUBHH)
* ---------------------------------------------------------------------
use "`tempQ'", clear
bys HHID RSUBHH: gen dupN = _N
count if dupN > 1
di as txt "Q duplicate observations before deduplication = " r(N)

if r(N) > 0 {
    egen nm = rownonmiss(SQ171_1 SQ171_2 SQ171_3 SQ143 SQ157 SQ326 SQ340 SQ354 SQ366 SQ139 SQ141 SQ153 SQ155 SQ190 SQ194 SQ322 SQ324 SQ336 SQ338 SQ350 SQ352 SQ362 SQ364 SQ148 SQ134 SQ317 SQ166_1 SQ166_2 SQ166_3 SQ331), strok
    bys HHID RSUBHH (nm): keep if _n==_N   // keep max nonmissing
    drop nm dupN
    sort HHID RSUBHH
    save "`tempQ'", replace
    di as txt "Deduplicated Q saved -> `tempQ'"
}

* ---------------------------------------------------------------------
* Extract R household file and keep vars
* ---------------------------------------------------------------------
use "`path2022'/H22R_H.dta", clear
ds `varsR'
if r(N) == 0 {
    di as error "ERROR: none of the requested R variables found in H22R_H.dta. Check variable names."
    describe
    exit 198
}
keep `varsR'
replace HHID = trim(HHID)
replace RSUBHH = trim(RSUBHH)
replace RSUBHH = "0" if RSUBHH == ""
sort HHID RSUBHH
save "`tempR'", replace

* ---------------------------------------------------------------------
* Deduplicate R (keep row with most nonmissing values per HHID+RSUBHH)
* ---------------------------------------------------------------------
use "`tempR'", clear
bys HHID RSUBHH: gen dupN = _N
count if dupN > 1
di as txt "R duplicate observations before deduplication = " r(N)

if r(N) > 0 {
    egen nm = rownonmiss(SR050 SR055 SR063 SR064 SR072 SR030 SR045 SR007 SR013 SR024), strok
    bys HHID RSUBHH (nm): keep if _n==_N   // keep max nonmissing
    drop nm dupN
    sort HHID RSUBHH
    save "`tempR'", replace
    di as txt "Deduplicated R saved -> `tempR'"
}

* ---------------------------------------------------------------------
* Extract H household file and keep vars
* ---------------------------------------------------------------------
use "`path2022'/H22H_H.dta", clear
ds `varsH'
if r(N) == 0 {
    di as error "ERROR: none of the requested H variables found in H22H_H.dta. Check variable names."
    describe
    exit 198
}
keep `varsH'
replace HHID = trim(HHID)
replace RSUBHH = trim(RSUBHH)
replace RSUBHH = "0" if RSUBHH == ""
sort HHID RSUBHH
save "`tempH'", replace

* ---------------------------------------------------------------------
* Deduplicate H (keep row with most nonmissing values per HHID+RSUBHH)
* ---------------------------------------------------------------------
use "`tempH'", clear
bys HHID RSUBHH: gen dupN = _N
count if dupN > 1
di as txt "H duplicate observations before deduplication = " r(N)

if r(N) > 0 {
    egen nm = rownonmiss(SH020 SH162), strok
    bys HHID RSUBHH (nm): keep if _n==_N   // keep max nonmissing
    drop nm dupN
    sort HHID RSUBHH
    save "`tempH'", replace
    di as txt "Deduplicated H saved -> `tempH'"
}


* ---------------------------------------------------------------------
* Merge Q + R + H (1:1 on HHID RSUBHH)
* ---------------------------------------------------------------------
use "`tempQ'", clear
merge 1:1 HHID RSUBHH using "`tempR'"
di as txt "After merging Q + R:"
tab _merge
* inspect results, then drop _merge if okay
drop _merge

merge 1:1 HHID RSUBHH using "`tempH'"
di as txt "After merging Q+R with H:"
tab _merge
drop _merge

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
* Save final selected file
* ---------------------------------------------------------------------
save "`out'", replace
di as txt "Saved selected 2022 household data to `out'"

log close





