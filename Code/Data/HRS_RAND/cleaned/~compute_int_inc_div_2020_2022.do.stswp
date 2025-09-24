*----------------------------------------------------------------------
* compute_int_inc_div_2020_2022_modified.do
* Asset-specific, wave-accurate frequency -> annual multiplier mappings
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/compute_interest_dividends_2022.log", replace text

set more off

local master "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/cleaned/hrs_rand_2020_2022_master.dta"
capture confirm file "`master'"
if _rc {
    di as error "ERROR: master file not found -> `master'"
    exit 198
}

use "`master'", clear

di as txt "Using master file: `master'"

* ---------------------------------------------------------------------
* Local mappings of RAND variable names (wave-specific locals)
* NOTE: update these locals to match your RAND/Core variable names if needed
* ---------------------------------------------------------------------
local f2022_re   sq139    // rental income frequency
local a2022_re   sq141    // rental income amount (per period)
local f2022_bus  sq153    // business income frequency
local a2022_bus  sq155
local f2022_ira  sq194    // IRA annuity frequency
local a2022_ira  sq190
local f2022_stk  sq322    // stock dividends frequency
local a2022_stk  sq324
local f2022_bnd  sq336    // bond interest frequency
local a2022_bnd  sq338
local f2022_cash sq350    // checking/savings interest frequency
local a2022_cash sq352
local f2022_cds  sq362    // cds/gov bond frequency
local a2022_cds  sq364

* ---------------------------------------------------------------------
* Create per-asset frequency multiplier variables using the explicit
* mappings derived from the survey coding you provided.
* ---------------------------------------------------------------------

* --- Rental income (survey codes you provided):
* 1 WEEKLY, 2 2x per month, 3 MONTHLY, 4 QUARTERLY, 5 EVERY 6 MONTHS, 6 YEARLY,
* 7 OTHER, 8 DK, 9 RF, Blank INAP
capture drop `f2022_re'_mult
gen double `f2022_re'_mult = .
quietly replace `f2022_re'_mult = 52 if `f2022_re' == 1
quietly replace `f2022_re'_mult = 24 if `f2022_re' == 2
quietly replace `f2022_re'_mult = 12 if `f2022_re' == 3
quietly replace `f2022_re'_mult = 4  if `f2022_re' == 4
quietly replace `f2022_re'_mult = 2  if `f2022_re' == 5
quietly replace `f2022_re'_mult = 1  if `f2022_re' == 6
* leave 7/8/9/missing as . (OTHER/DK/RF/INAP)

di as txt "`f2022_re'_mult nonmissing = " _N - sum(missing(`f2022_re'_mult))

* --- Business income (survey codes): 1 WEEKLY, 2 2x per month, 3 MONTHLY,
* 4 QUARTERLY, 5 EVERY 6 MONTHS, 6 YEARLY, 7 OTHER, 8 DK, 9 RF, Blank INAP
capture drop `f2022_bus'_mult
gen double `f2022_bus'_mult = .
quietly replace `f2022_bus'_mult = 52 if `f2022_bus' == 1
quietly replace `f2022_bus'_mult = 24 if `f2022_bus' == 2
quietly replace `f2022_bus'_mult = 12 if `f2022_bus' == 3
quietly replace `f2022_bus'_mult = 4  if `f2022_bus' == 4
quietly replace `f2022_bus'_mult = 2  if `f2022_bus' == 5
quietly replace `f2022_bus'_mult = 1  if `f2022_bus' == 6

di as txt "`f2022_bus'_mult nonmissing = " _N - sum(missing(`f2022_bus'_mult))

* --- IRA annuity frequency (survey codes): 3 = MONTH, 4 = QUARTER, 5 = 6 MONTH,
* 6 = YEAR, 7 = OTHER, 8 = DK, 9 = RF, Blank INAP
capture drop `f2022_ira'_mult
gen double `f2022_ira'_mult = .
quietly replace `f2022_ira'_mult = 12 if `f2022_ira' == 3
quietly replace `f2022_ira'_mult = 4  if `f2022_ira' == 4
quietly replace `f2022_ira'_mult = 2  if `f2022_ira' == 5
quietly replace `f2022_ira'_mult = 1  if `f2022_ira' == 6
* leave other codes missing

di as txt "`f2022_ira'_mult nonmissing = " _N - sum(missing(`f2022_ira'_mult))

* --- Stock dividends (survey codes): 1 = IT ACCUMULATES OR IS REINVESTED,
* 3 = MONTHLY, 4 = QUARTERLY, 5 = EVERY 6 MONTHS, 6 = YEARLY, 7 OTHER, 8 DK, 9 RF
capture drop `f2022_stk'_mult
gen double `f2022_stk'_mult = .
quietly replace `f2022_stk'_mult = 0  if `f2022_stk' == 1   // accumulates/reinvested -> no realized cash flow
quietly replace `f2022_stk'_mult = 12 if `f2022_stk' == 3
quietly replace `f2022_stk'_mult = 4  if `f2022_stk' == 4
quietly replace `f2022_stk'_mult = 2  if `f2022_stk' == 5
quietly replace `f2022_stk'_mult = 1  if `f2022_stk' == 6

di as txt "`f2022_stk'_mult nonmissing = " _N - sum(missing(`f2022_stk'_mult))

* --- Bond interest (survey codes similar to stock): 1 accumulates, 3 monthly,
* 4 quarterly, 5 every 6 months, 6 yearly, 7 other, 8 DK, 9 RF
capture drop `f2022_bnd'_mult
gen double `f2022_bnd'_mult = .
quietly replace `f2022_bnd'_mult = 0  if `f2022_bnd' == 1
quietly replace `f2022_bnd'_mult = 12 if `f2022_bnd' == 3
quietly replace `f2022_bnd'_mult = 4  if `f2022_bnd' == 4
quietly replace `f2022_bnd'_mult = 2  if `f2022_bnd' == 5
quietly replace `f2022_bnd'_mult = 1  if `f2022_bnd' == 6

di as txt "`f2022_bnd'_mult nonmissing = " _N - sum(missing(`f2022_bnd'_mult))

* --- Cash (checking/savings) interest: 1 accumulates, 3 monthly, 4 quarterly,
* 5 every 6 months, 6 yearly, 7 other, 8 DK, 9 RF
capture drop `f2022_cash'_mult
gen double `f2022_cash'_mult = .
quietly replace `f2022_cash'_mult = 0  if `f2022_cash' == 1
quietly replace `f2022_cash'_mult = 12 if `f2022_cash' == 3
quietly replace `f2022_cash'_mult = 4  if `f2022_cash' == 4
quietly replace `f2022_cash'_mult = 2  if `f2022_cash' == 5
quietly replace `f2022_cash'_mult = 1  if `f2022_cash' == 6

di as txt "`f2022_cash'_mult nonmissing = " _N - sum(missing(`f2022_cash'_mult))

* --- CDs / government bonds / T-bills: 1 accumulates, 3 monthly, 4 quarterly,
* 5 every 6 months, 6 yearly, 7 other, 8 DK, 9 RF
capture drop `f2022_cds'_mult
gen double `f2022_cds'_mult = .
quietly replace `f2022_cds'_mult = 0  if `f2022_cds' == 1
quietly replace `f2022_cds'_mult = 12 if `f2022_cds' == 3
quietly replace `f2022_cds'_mult = 4  if `f2022_cds' == 4
quietly replace `f2022_cds'_mult = 2  if `f2022_cds' == 5
quietly replace `f2022_cds'_mult = 1  if `f2022_cds' == 6

di as txt "`f2022_cds'_mult nonmissing = " _N - sum(missing(`f2022_cds'_mult))

* ---------------------------------------------------------------------
* Annualize amount/per-period variables into interest/dividend components
* int_*_2022 = amount_per_period * freq_mult
* We only create the int_* vars if the amount vars exist in the dataset.
* ---------------------------------------------------------------------

capture confirm variable `a2022_re'
if _rc == 0 {
    capture drop int_re_2022
    gen double int_re_2022 = .
    replace int_re_2022 = `a2022_re' * `f2022_re'_mult if !missing(`a2022_re') & !missing(`f2022_re'_mult)
    di as txt "int_re_2022 computed: nonmissing = " _N - sum(missing(int_re_2022))
}

capture confirm variable `a2022_bus'
if _rc == 0 {
    capture drop int_bus_2022
    gen double int_bus_2022 = .
    replace int_bus_2022 = `a2022_bus' * `f2022_bus'_mult if !missing(`a2022_bus') & !missing(`f2022_bus'_mult)
    di as txt "int_bus_2022 computed: nonmissing = " _N - sum(missing(int_bus_2022))
}

capture confirm variable `a2022_ira'
if _rc == 0 {
    capture drop int_ira_2022
    gen double int_ira_2022 = .
    replace int_ira_2022 = `a2022_ira' * `f2022_ira'_mult if !missing(`a2022_ira') & !missing(`f2022_ira'_mult)
    di as txt "int_ira_2022 computed: nonmissing = " _N - sum(missing(int_ira_2022))
}

capture confirm variable `a2022_stk'
if _rc == 0 {
    capture drop int_stk_2022
    gen double int_stk_2022 = .
    replace int_stk_2022 = `a2022_stk' * `f2022_stk'_mult if !missing(`a2022_stk') & !missing(`f2022_stk'_mult)
    di as txt "int_stk_2022 computed: nonmissing = " _N - sum(missing(int_stk_2022))
}

capture confirm variable `a2022_bnd'
if _rc == 0 {
    capture drop int_bnd_2022
    gen double int_bnd_2022 = .
    replace int_bnd_2022 = `a2022_bnd' * `f2022_bnd'_mult if !missing(`a2022_bnd') & !missing(`f2022_bnd'_mult)
    di as txt "int_bnd_2022 computed: nonmissing = " _N - sum(missing(int_bnd_2022))
}

capture confirm variable `a2022_cash'
if _rc == 0 {
    capture drop int_cash_2022
    gen double int_cash_2022 = .
    replace int_cash_2022 = `a2022_cash' * `f2022_cash'_mult if !missing(`a2022_cash') & !missing(`f2022_cash'_mult)
    di as txt "int_cash_2022 computed: nonmissing = " _N - sum(missing(int_cash_2022))
}

capture confirm variable `a2022_cds'
if _rc == 0 {
    capture drop int_cds_2022
    gen double int_cds_2022 = .
    replace int_cds_2022 = `a2022_cds' * `f2022_cds'_mult if !missing(`a2022_cds') & !missing(`f2022_cds'_mult)
    di as txt "int_cds_2022 computed: nonmissing = " _N - sum(missing(int_cds_2022))
}

* ---------------------------------------------------------------------
* Summary diagnostics for the mapped multipliers and the annualized components
* ---------------------------------------------------------------------

di as txt "=== Frequency multipliers: summary (per asset) ==="
foreach v in `f2022_re' `f2022_bus' `f2022_ira' `f2022_stk' `f2022_bnd' `f2022_cash' `f2022_cds' {
    capture confirm variable `v'_mult
    if _rc == 0 {
        di as txt "Variable: `v'_mult"
        tab `v'_mult, missing
    }
}

di as txt "=== Annualized interest/dividend components: summary ==="
foreach v in int_re_2022 int_bus_2022 int_ira_2022 int_stk_2022 int_bnd_2022 int_cash_2022 int_cds_2022 {
    capture confirm variable `v'
    if _rc == 0 {
        di as txt "Summary for `v'"
        summarize `v', detail
    }
}

/* removed total computations; totals will be computed in compute_returns */

* ---------------------------------------------------------------------
* Save back to master (overwrite) – comment out if you prefer to save to new file
* ---------------------------------------------------------------------
save "`master'", replace

log close
exit, clear

di as txt "Done. Modified file saved to `master'"


