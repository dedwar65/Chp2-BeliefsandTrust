*----------------------------------------------------------------------
* Merge 2020 and 2022 HRS RAND household files
* Mirrors HRS merge script but uses RAND paths and lowercase keys
* Usage: do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/merge_2020_2022.do"
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/merge_hrs_rand_2020_2022.log", replace text

set more off

* --- file paths
local cleaned "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned"
local file2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA/hrs_2020_selected.dta"
local file2022 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2022/h22e3a_STATA/hrs_2022_selected.dta"
local alt2020  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_2020_selected.dta"
local alt2022  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_2022_selected.dta"
local out "`cleaned'/hrs_rand_2020_2022_master.dta"

* --- check files exist
capture confirm file "`file2020'"
if _rc {
    capture confirm file "`alt2020'"
    if !_rc {
        local file2020 "`alt2020'"
    }
}
capture confirm file "`file2022'"
if _rc {
    capture confirm file "`alt2022'"
    if !_rc {
        local file2022 "`alt2022'"
    }
}
capture confirm file "`file2020'"
if _rc {
    di as error "ERROR: 2020 file not found -> `file2020'"
    exit 198
}
capture confirm file "`file2022'"
if _rc {
    di as error "ERROR: 2022 file not found -> `file2022'"
    exit 198
}

* --- prepare 2022 file: align key name (ssubhh -> rsubhh)
tempfile using2022
use "`file2022'", clear
capture confirm variable ssubhh
if _rc {
    di as error "ERROR: key ssubhh not found in 2022 file."
    describe
    exit 198
}
rename ssubhh rsubhh
save "`using2022'", replace

* ---------------------------------------------------------------------
* Load 2020 data (master) and merge 2022 data
* ---------------------------------------------------------------------
use "`file2020'", clear
merge 1:1 hhid rsubhh using "`using2022'"

* --- inspect merge results
di as txt "Merge 2020 + 2022 RAND results:"
tab _merge

* --- optionally keep only matched households
* keep if _merge==3

* --- drop _merge after inspection
drop _merge

* ---------------------------------------------------------------------
* Save final master dataset
* ---------------------------------------------------------------------
save "`out'", replace
di as txt "Saved merged 2020+2022 HRS RAND data to `out'"

log close


