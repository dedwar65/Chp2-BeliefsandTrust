*******************************************************
* merge_2017_2019_single.do
* Merge 2017 & 2019 PSID subsets
*******************************************************

clear

// 1) Load your 2017 clean file and rename its ID
use "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/PSID/cleaned/2017/rep_DP2024_2017_vars.dta", clear
rename ER66002 hid
tempfile data2017
save `data2017'

// 2) Load 2019 file, rename its ID, and save temporarily
use "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/PSID/cleaned/2019/rep_DP2024_2019_vars.dta", clear
rename ER72002 hid
tempfile data2019
save `data2019'

// 3) Merge datasets
use `data2017', clear
merge 1:1 hid using `data2019'

// 4) Inspect and keep only matched
tab _merge
keep if _merge == 3
drop _merge

// 5) Save the merged dataset
save "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/PSID/merged/rep_DP2024_2017_2019.dta", replace

*******************************************************
* End of merge_2017_2019_single.do
*******************************************************

