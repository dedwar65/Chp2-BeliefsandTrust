*----------------------------------------------------------------------
* create_wide_RAND_long.do
* Master script to create wide panel dataset with returns from RAND HRS longitudinal
* 
* This script runs all component scripts in sequence to:
* 1. Start from original RAND longitudinal file (randhrs1992_2022v1.dta)
* 2. Merge 2022 flows and trust variables
* 3. Merge CAMS 2021 variables
* 4. Compute returns for all years (2022, 2020, 2018, ..., 2002)
* 5. Prepare controls and compute asset shares/wealth deciles
* 6. Output final wide-format analysis dataset (_randhrs1992_2022v1_analysis.dta)
*
* USAGE: 
*   cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
*   do create_wide_RAND_long.do
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"

set more off

di as txt "===================================================================="
di as txt "=== MASTER SCRIPT: create_wide_RAND_long.do                     ==="
di as txt "=== Creating wide panel dataset with returns (2002-2022)        ==="
di as txt "===================================================================="
di as txt ""

* Delete existing analysis dataset to start fresh
capture erase "_randhrs1992_2022v1_analysis.dta"
di as txt "Deleted existing _randhrs1992_2022v1_analysis.dta (if it existed)"
di as txt ""

* ---------------------------------------------------------------------
* STEP 1: Merge 2022 flows from raw HRS RAND file
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 1: Merging 2022 flows (long_merge_in.do)"
di as txt "===================================================================="
capture do "long_merge_in.do"
if _rc {
    di as error "ERROR: long_merge_in.do failed with return code " _rc
    exit _rc
}
di as txt "STEP 1 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* STEP 2: Merge 2020 trust variables
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 2: Merging 2020 trust variables (long_merge_in_trust_2020.do)"
di as txt "===================================================================="
capture do "long_merge_in_trust_2020.do"
if _rc {
    di as error "ERROR: long_merge_in_trust_2020.do failed with return code " _rc
    exit _rc
}
di as txt "STEP 2 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* STEP 3: Merge CAMS 2021 variables
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 3: Merging CAMS 2021 variables (long_merge_from_CAMS_2021.do)"
di as txt "===================================================================="
capture do "long_merge_from_CAMS_2021.do"
if _rc {
    di as error "ERROR: long_merge_from_CAMS_2021.do failed with return code " _rc
    exit _rc
}
di as txt "STEP 3 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* STEP 4: Prep 2022 controls & income, create 2020 wealth deciles
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 4: Prep controls and income (prep_controls_income_2020.do)"
di as txt "===================================================================="
do "prep_controls_income_2020.do"
di as txt ""

* ---------------------------------------------------------------------
* STEP 5: Compute 2022 returns
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 5: Computing 2022 returns (compute_tot_ret_2022.do)"
di as txt "===================================================================="
capture do "compute_tot_ret_2022.do"
if _rc {
    di as error "ERROR: compute_tot_ret_2022.do failed with return code " _rc
    exit _rc
}
di as txt "STEP 5 completed successfully"
di as txt ""

* ---------------------------------------------------------------------
* STEP 6-15: Compute returns for 2020, 2018, ..., 2002 (in reverse order)
* Each step merges flows, computes returns, and prepares prior-wave controls
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 6: Computing 2020 returns (RAND_2020_merge_and_returns.do)"
di as txt "===================================================================="
capture do "RAND_2020_merge_and_returns.do"
if _rc {
    di as error "ERROR: RAND_2020_merge_and_returns.do failed with return code " _rc
    exit _rc
}
di as txt "STEP 6 completed successfully"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 7: Computing 2018 returns (RAND_2018_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2018_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 8: Computing 2016 returns (RAND_2016_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2016_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 9: Computing 2014 returns (RAND_2014_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2014_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 10: Computing 2012 returns (RAND_2012_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2012_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 11: Computing 2010 returns (RAND_2010_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2010_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 12: Computing 2008 returns (RAND_2008_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2008_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 13: Computing 2006 returns (RAND_2006_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2006_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 14: Computing 2004 returns (RAND_2004_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2004_merge_and_returns.do"
di as txt ""

di as txt "===================================================================="
di as txt "STEP 15: Computing 2002 returns (RAND_2002_merge_and_returns.do)"
di as txt "===================================================================="
do "RAND_2002_merge_and_returns.do"
di as txt ""

* ---------------------------------------------------------------------
* STEP 16: Compute asset shares, liability shares, wealth deciles for all waves
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "STEP 16: Computing asset shares and wealth deciles (prep_controls_ret_panel.do)"
di as txt "===================================================================="
do "prep_controls_ret_panel.do"
di as txt ""

* ---------------------------------------------------------------------
* Final summary
* ---------------------------------------------------------------------
di as txt "===================================================================="
di as txt "=== MASTER SCRIPT COMPLETE                                       ==="
di as txt "===================================================================="
di as txt ""
di as txt "Final output dataset: _randhrs1992_2022v1_analysis.dta"
di as txt ""
di as txt "This wide-format dataset contains:"
di as txt "  - Returns for all years (2002-2022) with year suffix"
di as txt "    * r_annual_incl_YYYY and r_annual_incl_trim_YYYY (including residential)"
di as txt "    * r_annual_excl_YYYY and r_annual_excl_trim_YYYY (excluding residential)"
di as txt "  - Control variables for each wave"
di as txt "  - Asset shares and wealth deciles for all waves"
di as txt "  - Trust variables from 2020"
di as txt "  - CAMS 2021 variables (show affection, help others, volunteer, religious attendance, meetings)"
di as txt ""
di as txt "Ready for reshape to long format and panel regression analysis!"
di as txt ""

di as txt "Master script completed successfully!"
di as txt "Individual log files were created by each component script."

