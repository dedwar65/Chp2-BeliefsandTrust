*----------------------------------------------------------------------
* compute_net_worth_A2020.do
* Compute total assets (2020), total liabilities (2020) and A_{t-1} = networth_A2020
* (A_{t-1} is the beginning-of-period net worth used when computing returns to 2022)
* Assumes merged master exists:
*   /Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta
*----------------------------------------------------------------------

clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_net_worth_A2020.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------
* Variables (2020) for net worth calculation:
* Assets:
*   primary residence: RH020
*   secondary residence: RH162
*   real estate (other than main home): RQ134
*   private business: RQ148
*   stocks: RQ317
*   IRA: RQ166_1 RQ166_2 RQ166_3
*   bonds: RQ331
*   checking/savings: RQ345
*   CDs: RQ357
*   vehicles: RQ371
*   other: RQ381
*
* Liabilities:
*   primary residence mortgage (outstand): RH032
*   secondary residence mortgage (outstand): RH171
*   other debts: RQ478
* ---------------------------

local assets_vars "RH020 RH162 RQ134 RQ148 RQ317 RQ166_1 RQ166_2 RQ166_3 RQ331 RQ345 RQ357 RQ371 RQ381"
local liab_vars   "RH032 RH171 RQ478"

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

* ---------------------------------------------------------------------
* Optional sentinel check (non-destructive): show counts of common sentinels for listed vars
* (this does NOT change values)
* ---------------------------------------------------------------------
di as txt "Quick sentinel-code checks (counts of common sentinels) for listed variables..."
local sentinels -8 -9 9999998 9999999 99999998 99999999 999999998 999999999
foreach v of local assets_vars {
    capture confirm variable `v'
    if _rc continue
    quietly count if inlist(`v',`sentinels')
    di as txt "  `v' sentinel-count = " r(N)
}
foreach v of local liab_vars {
    capture confirm variable `v'
    if _rc continue
    quietly count if inlist(`v',`sentinels')
    di as txt "  `v' sentinel-count = " r(N)
}

* ---------------------------------------------------------------------
* Summarize each input variable individually for quick inspection
* ---------------------------------------------------------------------
di as txt "Summarizing individual input variables (assets)..."
foreach v of local assets_vars {
    capture confirm variable `v'
    if _rc {
        di as txt "  `v' not present -> skipped"
    }
    else {
        di as txt "  Summary for `v':"
        summarize `v', detail
    }
}
di as txt "Summarizing individual input variables (liabilities)..."
foreach v of local liab_vars {
    capture confirm variable `v'
    if _rc {
        di as txt "  `v' not present -> skipped"
    }
    else {
        di as txt "  Summary for `v':"
        summarize `v', detail
    }
}

* ---------------------------------------------------------------------
* Compute row counts of non-missing components (so we can tell if a total
* is truly absent vs zero)
* ---------------------------------------------------------------------
capture drop n_assets_2020 n_liab_2020
egen n_assets_2020 = rownonmiss(`assets_vars')
egen n_liab_2020   = rownonmiss(`liab_vars')

di as txt "Non-missing component counts:"
tabstat n_assets_2020 n_liab_2020, stats(n mean sd min max p50) format(%6.0f)

* ---------------------------------------------------------------------
* Compute totals (row sums) using egen rowtotal.
* Then set totals to missing when **all** components in the group are missing.
* ---------------------------------------------------------------------
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

* Show a few top obs to inspect pairing of big assets vs liabilities
di as txt "Top 30 assets_total_2020 (inspect liabilities too):"
gsort -assets_total_2020
list HHID RSUBHH assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/30

di as txt "Top 30 liabilities_total_2020 (inspect assets too):"
gsort -liab_total_2020
list HHID RSUBHH assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/30

* ---------------------------------------------------------------------
* Compute net worth at beginning of period A_{t-1} = networth_A2020
* - If both assets_total_2020 and liab_total_2020 are missing --> networth remains missing
* - Otherwise treat missing side as zero when the other side exists (so we can compute)
* ---------------------------------------------------------------------
capture drop networth_A2020
gen double networth_A2020 = .
replace networth_A2020 = (cond(missing(assets_total_2020),0,assets_total_2020) - ///
                         cond(missing(liab_total_2020),0,liab_total_2020)) ///
    if n_assets_2020 > 0

di as txt "Summary: networth_A2020 (assets_total_2020 - liab_total_2020):"
summarize networth_A2020, detail
tabstat networth_A2020, stats(n mean sd p50 min max) format(%12.2f)

* Count how many networth values were computed
quietly count if !missing(networth_A2020)
di as txt "Records with networth_A2020 computed = " r(N) " out of " _N

* ---------------------------------------------------------------------
* Diagnostics: show extremes and cases where a side was missing but networth computed
* ---------------------------------------------------------------------
di as txt "Extremes: top 20 highest networth_A2020:"
gsort -networth_A2020
list HHID RSUBHH networth_A2020 assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20

di as txt "Extremes: top 20 lowest networth_A2020:"
gsort networth_A2020
list HHID RSUBHH networth_A2020 assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20

di as txt "Cases where assets missing but liabilities present (networth computed treating assets=0):"
quietly count if n_assets_2020==0 & n_liab_2020>0
di as txt "  count = " r(N)
quietly list HHID RSUBHH assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20 if n_assets_2020==0 & n_liab_2020>0

di as txt "Cases where liabilities missing but assets present (networth computed treating liab=0):"
quietly count if n_liab_2020==0 & n_assets_2020>0
di as txt "  count = " r(N)
quietly list HHID RSUBHH assets_total_2020 liab_total_2020 n_assets_2020 n_liab_2020 in 1/20 if n_liab_2020==0 & n_assets_2020>0

* ---------------------------------------------------------------------
* Save totals back to master (so subsequent components/returns scripts can use them)
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved assets_total_2020, liab_total_2020, networth_A2020 (and helpers) back to master: `master'"

log close
di as txt "Done."

