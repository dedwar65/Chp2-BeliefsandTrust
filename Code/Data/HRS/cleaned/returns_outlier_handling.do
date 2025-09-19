*----------------------------------------------------------------------
* returns_outlier_handling.do
* Apply outlier handling to sample-restricted returns
* 
* This file assumes compute_returns_sample.do has been run and creates
* trimmed and winsorized versions of returns with various thresholds.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/returns_outlier_handling.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear
di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Define analysis universe and thresholds (easily adjustable)
* ---------------------------------------------------------------------
di as txt "=== Setting up outlier handling parameters ==="

* Thresholds (change these as needed)
local min_denom = 1000        // Minimum denominator threshold
local trim_pct = 1            // Trim top/bottom percentage
local winsor_pct = 1          // Winsorize tails percentage

di as txt "Parameters:"
di as txt "  Minimum denominator: $`min_denom'"
di as txt "  Trim percentage: `trim_pct'%"
di as txt "  Winsorize percentage: `winsor_pct'%"

* Define analysis universe
capture drop analysis_ok
gen byte analysis_ok = sample_res_both == 1 & ///
                      !missing(r_2022_sample) & ///
                      !missing(A_2020_sample) & ///
                      !missing(F_2022_sample) & ///
                      (A_2020_sample + 0.5*F_2022_sample) >= `min_denom'

* Report analysis universe
quietly count if analysis_ok
local n_analysis = r(N)
quietly count if sample_res_both == 1
local n_sample = r(N)
di as txt "Analysis universe: `n_analysis' observations out of `n_sample' in sample"
di as txt "  (excluded `=`n_sample'-`n_analysis'' due to missing data or small denominators)"

* ---------------------------------------------------------------------
* Original returns summary (analysis universe only)
* ---------------------------------------------------------------------
di as txt "=== Original returns summary (analysis universe) ==="
summarize r_2022_sample if analysis_ok, detail
tabstat r_2022_sample if analysis_ok, stats(n mean sd p50 p10 p90 p1 p99 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Trim returns (drop extreme tails)
* ---------------------------------------------------------------------
di as txt "=== Trimming returns (drop top/bottom `trim_pct'%) ==="

* Calculate trim thresholds
_pctile r_2022_sample if analysis_ok, p(`trim_pct' `=100-`trim_pct'')
scalar trim_low = r(r1)
scalar trim_high = r(r2)

di as txt "Trim thresholds: `=trim_low' to `=trim_high'"

* Create trimmed sample indicator
capture drop keep_trim
gen byte keep_trim = analysis_ok & inrange(r_2022_sample, trim_low, trim_high)

* Create trimmed returns variable
capture drop r_2022_sample_trim
gen double r_2022_sample_trim = r_2022_sample if keep_trim

* Report trimming results
quietly count if keep_trim
local n_trim = r(N)
di as txt "Observations after trimming: `n_trim' (dropped `=`n_analysis'-`n_trim'')"

* Trimmed returns summary
di as txt "Trimmed returns summary:"
summarize r_2022_sample if keep_trim, detail
tabstat r_2022_sample if keep_trim, stats(n mean sd p50 p10 p90 p1 p99 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Winsorize returns (cap extreme tails)
* ---------------------------------------------------------------------
di as txt "=== Winsorizing returns (cap top/bottom `winsor_pct'%) ==="

* Calculate winsorize thresholds
_pctile r_2022_sample if analysis_ok, p(`winsor_pct' `=100-`winsor_pct'')
scalar winsor_low = r(r1)
scalar winsor_high = r(r2)

di as txt "Winsorize thresholds: `=winsor_low' to `=winsor_high'"

* Create winsorized returns
capture drop r_2022_sample_winsor
gen double r_2022_sample_winsor = r_2022_sample if analysis_ok
replace r_2022_sample_winsor = winsor_low if analysis_ok & r_2022_sample < winsor_low
replace r_2022_sample_winsor = winsor_high if analysis_ok & r_2022_sample > winsor_high

* Report winsorizing results
quietly count if !missing(r_2022_sample_winsor)
local n_winsor = r(N)
di as txt "Observations after winsorizing: `n_winsor'"

* Winsorized returns summary
di as txt "Winsorized returns summary:"
summarize r_2022_sample_winsor if analysis_ok, detail
tabstat r_2022_sample_winsor if analysis_ok, stats(n mean sd p50 p10 p90 p1 p99 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Alternative winsorization: winsorize returns at different percentiles
* ---------------------------------------------------------------------
di as txt "=== Alternative winsorization methods ==="

* Winsorize at 0.5% tails (more aggressive)
_pctile r_2022_sample if analysis_ok, p(0.5 99.5)
scalar winsor_05_low = r(r1)
scalar winsor_05_high = r(r2)

capture drop r_2022_sample_winsor_05
gen double r_2022_sample_winsor_05 = r_2022_sample if analysis_ok
replace r_2022_sample_winsor_05 = winsor_05_low if analysis_ok & r_2022_sample < winsor_05_low
replace r_2022_sample_winsor_05 = winsor_05_high if analysis_ok & r_2022_sample > winsor_05_high

di as txt "0.5% winsorized returns summary:"
summarize r_2022_sample_winsor_05 if analysis_ok, detail
tabstat r_2022_sample_winsor_05 if analysis_ok, stats(n mean sd p50 p10 p90 p1 p99 min max) format(%12.4f)

* Winsorize at 2% tails (less aggressive)
_pctile r_2022_sample if analysis_ok, p(2 98)
scalar winsor_2_low = r(r1)
scalar winsor_2_high = r(r2)

capture drop r_2022_sample_winsor_2
gen double r_2022_sample_winsor_2 = r_2022_sample if analysis_ok
replace r_2022_sample_winsor_2 = winsor_2_low if analysis_ok & r_2022_sample < winsor_2_low
replace r_2022_sample_winsor_2 = winsor_2_high if analysis_ok & r_2022_sample > winsor_2_high

di as txt "2% winsorized returns summary:"
summarize r_2022_sample_winsor_2 if analysis_ok, detail
tabstat r_2022_sample_winsor_2 if analysis_ok, stats(n mean sd p50 p10 p90 p1 p99 min max) format(%12.4f)

* ---------------------------------------------------------------------
* Comparison of all methods
* ---------------------------------------------------------------------
di as txt "=== Comparison of all return methods ==="

di as txt "Original returns (analysis universe):"
tabstat r_2022_sample if analysis_ok, stats(n mean sd p50) format(%12.4f)

di as txt "Trimmed returns (drop `trim_pct'% tails):"
tabstat r_2022_sample if keep_trim, stats(n mean sd p50) format(%12.4f)

di as txt "Winsorized returns (cap `winsor_pct'% tails):"
tabstat r_2022_sample_winsor if analysis_ok, stats(n mean sd p50) format(%12.4f)

di as txt "0.5% winsorized returns:"
tabstat r_2022_sample_winsor_05 if analysis_ok, stats(n mean sd p50) format(%12.4f)

di as txt "2% winsorized returns:"
tabstat r_2022_sample_winsor_2 if analysis_ok, stats(n mean sd p50) format(%12.4f)

* ---------------------------------------------------------------------
* Extreme value diagnostics
* ---------------------------------------------------------------------
di as txt "=== Extreme value diagnostics ==="

di as txt "Top 20 original returns (analysis universe):"
quietly count if analysis_ok
di as txt "Total observations in analysis universe: " r(N)
gsort -r_2022_sample
list HHID RSUBHH r_2022_sample A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if analysis_ok

di as txt "Top 20 winsorized returns:"
gsort -r_2022_sample_winsor
list HHID RSUBHH r_2022_sample_winsor A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if analysis_ok

di as txt "Bottom 20 original returns (analysis universe):"
gsort r_2022_sample
list HHID RSUBHH r_2022_sample A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if analysis_ok

di as txt "Bottom 20 winsorized returns:"
gsort r_2022_sample_winsor
list HHID RSUBHH r_2022_sample_winsor A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if analysis_ok

di as txt "Top 20 trimmed returns:"
gsort -r_2022_sample_trim
list HHID RSUBHH r_2022_sample_trim A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if !missing(r_2022_sample_trim)

di as txt "Bottom 20 trimmed returns:"
gsort r_2022_sample_trim
list HHID RSUBHH r_2022_sample_trim A_2020_sample F_2022_sample yc_2022_sample cg_2022_sample yd_2022_sample in 1/20 if !missing(r_2022_sample_trim)

* ---------------------------------------------------------------------
* Save dataset with new outlier-handled variables
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved outlier-handled return variables to master: `master'"

log close
di as txt "Done. Outlier handling completed with `trim_pct'% trimming and `winsor_pct'% winsorization."

* ---------------------------------------------------------------------
* Instructions for adjusting thresholds
* ---------------------------------------------------------------------
di as txt "To adjust thresholds, edit these lines at the top of this file:"
di as txt "  local min_denom = 1000        // Minimum denominator threshold"
di as txt "  local trim_pct = 1            // Trim top/bottom percentage"
di as txt "  local winsor_pct = 1          // Winsorize tails percentage"
