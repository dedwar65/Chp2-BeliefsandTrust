*----------------------------------------------------------------------
* reg_ret_panel.do
* Convert wide-format RAND HRS longitudinal dataset to long-format panel dataset
* for panel regression analysis
*
* This script:
* 1. Loads the wide-format analysis dataset
* 2. Creates separate long tables for returns and controls
* 3. Merges them with proper lag mapping (controls from 2 years prior)
* 4. Creates year dummies and sets panel structure
*
* Input:  _randhrs1992_2022v1_analysis.dta (wide format)
* Output: _randhrs1992_2022v1_panel.dta (long format)
*----------------------------------------------------------------------

clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_ret_panel.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local wide_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local panel_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_panel.dta"

* ---------------------------------------------------------------------
* Load wide-format analysis dataset
* ---------------------------------------------------------------------
di as txt "=== Loading wide-format analysis dataset ==="
capture confirm file `"`wide_file'"'
if _rc {
    di as error "ERROR: Wide-format analysis dataset not found -> `wide_file'"
    exit 198
}
use "`wide_file'", clear
quietly describe
local n_vars_wide = r(k)
local n_obs_wide = r(N)
di as txt "Wide dataset loaded: `n_obs_wide' observations, `n_vars_wide' variables"

capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in wide dataset"
    exit 198
}
di as txt "OK: hhidpn found in wide dataset"

* ---------------------------------------------------------------------
* Step 1: Create returns long table
* ---------------------------------------------------------------------
di as txt "=== Step 1: Creating returns long table ==="

* Keep only return variables and hhidpn
preserve
keep hhidpn r_annual_* r_annual_trim_* r_annual_excl_* r_annual_excl_trim_*

* Reshape return variables to long format
reshape long r_annual_ r_annual_trim_ r_annual_excl_ r_annual_excl_trim_, i(hhidpn) j(return_year)

* Rename variables for clarity
rename r_annual_ r_annual
rename r_annual_trim_ r_annual_trim
rename r_annual_excl_ r_annual_excl
rename r_annual_excl_trim_ r_annual_excl_trim

* Save returns long table
tempfile returns_long
save "`returns_long'", replace

quietly describe
local n_obs_returns = r(N)
di as txt "Returns long table: `n_obs_returns' observations"
restore

* ---------------------------------------------------------------------
* Step 2: Create controls long table
* ---------------------------------------------------------------------
di as txt "=== Step 2: Creating controls long table ==="

* Keep control variables and hhidpn
preserve
keep hhidpn age_* inlbrf_* married_* born_us raedyrs ///
     share_pri_res_* share_sec_res_* share_re_* share_vehicles_* share_bus_* share_ira_* ///
     share_stk_* share_chck_* share_cd_* share_bond_* share_other_* risky_share_* ///
     liability_share_* wealth_nonres_* wealth_nonres_decile_* ///
     wealth_nonres_d1_* wealth_nonres_d2_* wealth_nonres_d3_* wealth_nonres_d4_* wealth_nonres_d5_* ///
     wealth_nonres_d6_* wealth_nonres_d7_* wealth_nonres_d8_* wealth_nonres_d9_* wealth_nonres_d10_* ///
     wealth_d1_* wealth_d2_* wealth_d3_* wealth_d4_* wealth_d5_* ///
     wealth_d6_* wealth_d7_* wealth_d8_* wealth_d9_* wealth_d10_*

* Reshape control variables to long format
reshape long age_ inlbrf_ married_ ///
             share_pri_res_ share_sec_res_ share_re_ share_vehicles_ share_bus_ share_ira_ ///
             share_stk_ share_chck_ share_cd_ share_bond_ share_other_ risky_share_ ///
             liability_share_ wealth_nonres_ wealth_nonres_decile_ ///
             wealth_nonres_d1_ wealth_nonres_d2_ wealth_nonres_d3_ wealth_nonres_d4_ wealth_nonres_d5_ ///
             wealth_nonres_d6_ wealth_nonres_d7_ wealth_nonres_d8_ wealth_nonres_d9_ wealth_nonres_d10_ ///
             wealth_d1_ wealth_d2_ wealth_d3_ wealth_d4_ wealth_d5_ ///
             wealth_d6_ wealth_d7_ wealth_d8_ wealth_d9_ wealth_d10_, ///
             i(hhidpn) j(control_year)

* Rename variables for clarity
rename age_ age
rename inlbrf_ inlbrf
rename married_ married
rename share_pri_res_ share_pri_res
rename share_sec_res_ share_sec_res
rename share_re_ share_re
rename share_vehicles_ share_vehicles
rename share_bus_ share_bus
rename share_ira_ share_ira
rename share_stk_ share_stk
rename share_chck_ share_chck
rename share_cd_ share_cd
rename share_bond_ share_bond
rename share_other_ share_other
rename risky_share_ risky_share
rename liability_share_ liability_share
rename wealth_nonres_ wealth_nonres
rename wealth_nonres_decile_ wealth_nonres_decile
rename wealth_nonres_d1_ wealth_nonres_d1
rename wealth_nonres_d2_ wealth_nonres_d2
rename wealth_nonres_d3_ wealth_nonres_d3
rename wealth_nonres_d4_ wealth_nonres_d4
rename wealth_nonres_d5_ wealth_nonres_d5
rename wealth_nonres_d6_ wealth_nonres_d6
rename wealth_nonres_d7_ wealth_nonres_d7
rename wealth_nonres_d8_ wealth_nonres_d8
rename wealth_nonres_d9_ wealth_nonres_d9
rename wealth_nonres_d10_ wealth_nonres_d10
rename wealth_d1_ wealth_d1
rename wealth_d2_ wealth_d2
rename wealth_d3_ wealth_d3
rename wealth_d4_ wealth_d4
rename wealth_d5_ wealth_d5
rename wealth_d6_ wealth_d6
rename wealth_d7_ wealth_d7
rename wealth_d8_ wealth_d8
rename wealth_d9_ wealth_d9
rename wealth_d10_ wealth_d10

* Save controls long table
tempfile controls_long
save "`controls_long'", replace

quietly describe
local n_obs_controls = r(N)
di as txt "Controls long table: `n_obs_controls' observations"
restore

* ---------------------------------------------------------------------
* Step 3: Merge returns with controls using lag mapping
* ---------------------------------------------------------------------
di as txt "=== Step 3: Merging returns with controls (2-year lag) ==="

* Load returns long table
use "`returns_long'", clear

* Create control_year = return_year - 2 (2-year lag)
gen control_year = return_year - 2

* Merge with controls
merge m:1 hhidpn control_year using "`controls_long'", keep(match master)

* Check merge results
quietly count if _merge == 1
local n_unmatched_returns = r(N)
quietly count if _merge == 2
local n_unmatched_controls = r(N)
quietly count if _merge == 3
local n_matched = r(N)

di as txt "Merge results:"
di as txt "  Matched: `n_matched' observations"
di as txt "  Unmatched returns: `n_unmatched_returns' observations"
di as txt "  Unmatched controls: `n_unmatched_controls' observations"

* Keep only matched observations
keep if _merge == 3
drop _merge

* Rename return_year to year for consistency
rename return_year year

di as txt "Final dataset: `n_matched' observations with returns and lagged controls"

* ---------------------------------------------------------------------
* Step 4: Create year dummies
* ---------------------------------------------------------------------
di as txt "=== Step 4: Creating year dummies ==="

* Create year dummies
tab year, gen(year_)

di as txt "Year dummies created"

* ---------------------------------------------------------------------
* Step 5: Set panel structure
* ---------------------------------------------------------------------
di as txt "=== Step 5: Setting panel structure ==="

* Set panel structure
xtset hhidpn year

* Check panel structure
di as txt "Panel structure set:"
xtdescribe, patterns(10)

* ---------------------------------------------------------------------
* Step 6: Save panel dataset
* ---------------------------------------------------------------------
di as txt "=== Step 6: Saving panel dataset ==="

save "`panel_file'", replace
di as txt "Panel dataset saved: `panel_file'"

quietly describe
local n_vars_final = r(k)
local n_obs_final = r(N)
di as txt "Final panel dataset: `n_obs_final' observations, `n_vars_final' variables"

* ---------------------------------------------------------------------
* Final summary
* ---------------------------------------------------------------------
di as txt "=== Panel Dataset Creation Complete ==="
di as txt "Input wide dataset: `n_obs_wide' observations, `n_vars_wide' variables"
di as txt "Returns long table: `n_obs_returns' observations"
di as txt "Controls long table: `n_obs_controls' observations"
di as txt "Final panel dataset: `n_obs_final' observations, `n_vars_final' variables"
di as txt "Panel structure: hhidpn (individual) x year (time)"
di as txt "Lag structure: Controls from 2 years prior to returns"
di as txt "Return measures: r_annual, r_annual_trim, r_annual_excl, r_annual_excl_trim"
di as txt "Ready for panel regression analysis!"

log close