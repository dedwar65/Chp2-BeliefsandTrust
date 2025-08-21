*----------------------------------------------------------------------
* Merge 2020 and 2022 HRS household files
* Usage: do "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/merge_hrs_2020_2022.do"
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/merge_hrs_2020_2022.log", replace text

set more off

* --- file paths
local cleaned "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned"
local file2020 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2020/h20sta/hrs_2020_selected.dta"
local file2022 "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/_raw/2022/h22sta/hrs_2022_selected.dta"
local out "`cleaned'/hrs_2020_2022_master.dta"

* --- check files exist
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

* ---------------------------------------------------------------------
* Load 2020 data (master) and merge 2022 data
* ---------------------------------------------------------------------
use "`file2020'", clear
merge 1:1 HHID RSUBHH using "`file2022'"

* --- inspect merge results
di as txt "Merge 2020 + 2022 results:"
tab _merge

* --- optionally keep only matched households
* keep if _merge==3

* --- drop _merge after inspection
drop _merge

* ---------------------------------------------------------------------
* Save final master dataset
* ---------------------------------------------------------------------
save "`out'", replace
di as txt "Saved merged 2020+2022 HRS data to `out'"

log close
