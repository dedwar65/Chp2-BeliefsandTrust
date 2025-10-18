*----------------------------------------------------------------------
* panel_regs_2002_2022.do
* Master script to run all panel regressions (2002-2022)
*
* This script runs all three regression sets in sequence:
* 1. Baseline Pooled OLS
* 2. Asset Shares × Year Interactions
* 3. Individual Fixed Effects
*
* USAGE: 
*   cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
*   do panel_regs_2002_2022.do
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"

set more off

di as txt "===================================================================="
di as txt "=== MASTER SCRIPT: Panel Regressions (2002-2022)                ==="
di as txt "===================================================================="
di as txt ""
di as txt "This script will run three sets of panel regressions:"
di as txt "  1. Baseline Pooled OLS"
di as txt "  2. Asset Shares × Year Interactions"
di as txt "  3. Individual Fixed Effects"
di as txt ""
di as txt "Each set runs 4 regressions (one for each return measure):"
di as txt "  - r_annual (including residential)"
di as txt "  - r_annual_trim (including residential, trimmed)"
di as txt "  - r_annual_excl (excluding residential)"
di as txt "  - r_annual_excl_trim (excluding residential, trimmed)"
di as txt ""
di as txt "Output files will be created in the current directory:"
di as txt "  - Log files: reg_baseline_pooled.log, reg_shares_interacted.log, reg_fixed_effects.log"
di as txt "  - LaTeX tables: baseline_pooled.tex, shares_interacted.tex, fixed_effects.tex"
di as txt ""

* ---------------------------------------------------------------------
* Run Regression Set 1: Baseline Pooled OLS
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "REGRESSION SET 1: Baseline Pooled OLS"
di as txt "===================================================================="
do "reg_baseline_pooled.do"
if _rc {
    di as error "ERROR: reg_baseline_pooled.do failed with return code " _rc
    exit _rc
}
di as txt "REGRESSION SET 1 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* Run Regression Set 2: Asset Shares × Year Interactions
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "REGRESSION SET 2: Asset Shares × Year Interactions"
di as txt "===================================================================="
do "reg_shares_interacted.do"
if _rc {
    di as error "ERROR: reg_shares_interacted.do failed with return code " _rc
    exit _rc
}
di as txt "REGRESSION SET 2 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* Run Regression Set 3: Individual Fixed Effects
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "REGRESSION SET 3: Individual Fixed Effects"
di as txt "===================================================================="
do "reg_fixed_effects.do"
if _rc {
    di as error "ERROR: reg_fixed_effects.do failed with return code " _rc
    exit _rc
}
di as txt "REGRESSION SET 3 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* Final summary
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "=== ALL REGRESSIONS COMPLETE                                     ==="
di as txt "===================================================================="
di as txt ""
di as txt "Output files created:"
di as txt "  - Log files:"
di as txt "    * reg_baseline_pooled.log"
di as txt "    * reg_shares_interacted.log"
di as txt "    * reg_fixed_effects.log"
di as txt ""
di as txt "  - LaTeX tables:"
di as txt "    * baseline_pooled.tex"
di as txt "    * shares_interacted.tex"
di as txt "    * fixed_effects.tex"
di as txt ""
di as txt "Master script completed successfully!"
di as txt "Review the log files and LaTeX tables for detailed results."

