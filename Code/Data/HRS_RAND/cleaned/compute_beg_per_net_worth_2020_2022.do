*----------------------------------------------------------------------
* RAND: compute_net_worth_A2020.do (lowercase vars, RAND paths)
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_net_worth_A2020.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

local assets_vars "rh020 rh162 rq134 rq148 rq317 rq166_1 rq166_2 rq166_3 rq331 rq345 rq357 rq371 rq381"
local liab_vars   "rh032 rh171 rq478"

di as txt "Checking presence of required 2020 variables..."
foreach v of local assets_vars {
    capture confirm variable `v'
    if _rc di as err "  MISSING asset var: `v'"
    else di as txt "  OK asset var: `v'"
}
foreach v of local liab_vars {
    capture confirm variable `v'
    if _rc di as err "  MISSING liability var: `v'"
    else di as txt "  OK liability var: `v'"
}

capture drop n_assets_2020 n_liab_2020
egen n_assets_2020 = rownonmiss(`assets_vars')
egen n_liab_2020   = rownonmiss(`liab_vars')

capture drop assets_total_2020 liab_total_2020
egen assets_total_2020 = rowtotal(`assets_vars')
recast double assets_total_2020
replace assets_total_2020 = . if n_assets_2020 == 0
di as txt "Summary: assets_total_2020 (post-rowtotal / set to missing when no components):"
summarize assets_total_2020, detail
quietly count if !missing(assets_total_2020)
di as txt "Records with non-missing assets_total_2020 = " r(N)

egen liab_total_2020 = rowtotal(`liab_vars')
recast double liab_total_2020
replace liab_total_2020 = . if n_liab_2020 == 0
di as txt "Summary: liab_total_2020 (post-rowtotal / set to missing when no components):"
summarize liab_total_2020, detail
quietly count if !missing(liab_total_2020)
di as txt "Records with non-missing liab_total_2020 = " r(N)

capture drop networth_A2020
gen double networth_A2020 = .
replace networth_A2020 = (cond(missing(assets_total_2020),0,assets_total_2020) - cond(missing(liab_total_2020),0,liab_total_2020)) if n_assets_2020 > 0 | n_liab_2020 > 0

di as txt "Summary: networth_A2020 (assets_total_2020 - liab_total_2020):"
summarize networth_A2020, detail
tabstat networth_A2020, stats(n mean sd p50 min max) format(%12.2f)

quietly count if !missing(networth_A2020)
di as txt "Records with networth_A2020 computed = " r(N) " out of " _N

di as txt "Extremes: top 20 highest networth_A2020:"
gsort -networth_A2020
list hhid rsubhh networth_A2020 assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20

di as txt "Extremes: top 20 lowest networth_A2020:"
gsort networth_A2020
list hhid rsubhh networth_A2020 assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20

di as txt "Cases where assets missing but liabilities present (networth computed treating assets=0):"
quietly count if n_assets_2020==0 & n_liab_2020>0
di as txt "  count = " r(N)
quietly list hhid rsubhh assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20 if n_assets_2020==0 & n_liab_2020>0

di as txt "Cases where liabilities missing but assets present (networth computed treating liab=0):"
quietly count if n_liab_2020==0 & n_assets_2020>0
di as txt "  count = " r(N)
quietly list hhid rsubhh assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20 if n_liab_2020==0 & n_assets_2020>0

save "`master'", replace
di as txt "Saved A2020 net worth back to master: `master'"

log close

