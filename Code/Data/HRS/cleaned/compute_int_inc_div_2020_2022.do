*----------------------------------------------------------------------
* compute_interest_dividends_2022.do
* Compute interest income & dividends (y^c_t) by asset class for 2022 only
* Loads and then saves back to the master so other scripts keep variables.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_interest_dividends_2022.log", replace text

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
* Helper note:
* We will create for each frequency variable a multiplier var named <fq>_mult
* and optionally a label var <fq>_lbl (if decode(value label) exists).
* We'll create per-asset interest vars named:
*   int_<asset>_2022
* and a total int_total_2022
* ---------------------------------------------------------------------

* ---------------------------
* 2022: pairs (freq, amount)
* ---------------------------
local f2022_re   SQ139
local a2022_re   SQ141

local f2022_bus  SQ153
local a2022_bus  SQ155

local f2022_ira  SQ194
local a2022_ira  SQ190

local f2022_stk  SQ322
local a2022_stk  SQ324

local f2022_bnd  SQ336
local a2022_bnd  SQ338

local f2022_cash SQ350
local a2022_cash SQ352

local f2022_cds  SQ362
local a2022_cds  SQ364

* ---------------------------------------------------------------------
* Recode frequency codes 7,8,9 -> missing ONLY for the frequency variables
* ---------------------------------------------------------------------
local freqvars "`f2022_re' `f2022_bus' `f2022_ira' `f2022_stk' `f2022_bnd' `f2022_cash' `f2022_cds'"

di as txt "Recoding frequency codes 7/8/9 -> missing for 2022 frequency variables (only)."
foreach v of local freqvars {
    capture confirm variable `v'
    if _rc {
        di as txt "  Variable `v' not found in dataset -- skipping"
    }
    else {
        capture confirm numeric variable `v'
        if _rc {
            di as txt "  Variable `v' is not numeric -- skipping recode (check type)."
        }
        else {
            quietly count if inlist(`v',7,8,9)
            di as txt "  `v' records with codes 7/8/9 before recode = " r(N)
            quietly replace `v' = . if inlist(`v',7,8,9)
            quietly count if inlist(`v',7,8,9)
            di as txt "  `v' records with codes 7/8/9 after recode  = " r(N)
        }
    }
}

* ---------------------------------------------------------------------
* map_freq_to_mult: maps numeric frequency codes -> annual multipliers
* ---------------------------------------------------------------------
capture program drop map_freq_to_mult
program define map_freq_to_mult, rclass
    syntax varname
    local fq = "`varlist'"

    capture drop `fq'_lbl
    capture drop `fq'_mult

    local labname : value label `fq'
    if "`labname'" != "" {
        decode `fq', gen(`fq'_lbl)
    }

    gen double `fq'_mult = .
    quietly replace `fq'_mult = 52 if `fq' == 1
    quietly replace `fq'_mult = 24 if `fq' == 2
    quietly replace `fq'_mult = 12 if `fq' == 3
    quietly replace `fq'_mult = 4  if `fq' == 4
    quietly replace `fq'_mult = 2  if `fq' == 5
    quietly replace `fq'_mult = 1  if `fq' == 6

    di as txt "Mapping numeric codes to multipliers for `fq' completed."
    capture confirm variable `fq'_lbl
    if _rc == 0 {
        di as txt "Showing unique value-label text for `fq' (if present):"
        tab `fq'_lbl, nolabel
    }
    else {
        di as txt "No value label attached to `fq' (or decode missing). Showing raw numeric codes:"
        tab `fq', missing
    }
    quietly count if !missing(`fq'_mult)
    di as txt "`fq'_mult nonmissing observations = " r(N)
end

* ---------------------------
* Apply mapping to all 2022 frequency variables
* ---------------------------
di as txt "=== Mapping 2022 frequency variables ==="
map_freq_to_mult `f2022_re'
map_freq_to_mult `f2022_bus'
map_freq_to_mult `f2022_ira'
map_freq_to_mult `f2022_stk'
map_freq_to_mult `f2022_bnd'
map_freq_to_mult `f2022_cash'
map_freq_to_mult `f2022_cds'

* ---------------------------------------------------------------------
* Compute per-asset interest for 2022 when both amount & multiplier exist
* ---------------------------------------------------------------------
cap drop int_re_2022 int_bus_2022 int_ira_2022 int_stk_2022 int_bnd_2022 int_cash_2022 int_cds_2022

di as txt "=== Computing 2022 interest/dividends per asset ==="

gen double int_re_2022 = .
replace int_re_2022 = `a2022_re' * `f2022_re'_mult if !missing(`a2022_re') & !missing(`f2022_re'_mult)
di as txt "Real estate (2022) summary:"
summarize int_re_2022, detail

gen double int_bus_2022 = .
replace int_bus_2022 = `a2022_bus' * `f2022_bus'_mult if !missing(`a2022_bus') & !missing(`f2022_bus'_mult)
di as txt "Private business (2022) summary:"
summarize int_bus_2022, detail

gen double int_ira_2022 = .
replace int_ira_2022 = `a2022_ira' * `f2022_ira'_mult if !missing(`a2022_ira') & !missing(`f2022_ira'_mult)
di as txt "IRA (2022) summary:"
summarize int_ira_2022, detail

gen double int_stk_2022 = .
replace int_stk_2022 = `a2022_stk' * `f2022_stk'_mult if !missing(`a2022_stk') & !missing(`f2022_stk'_mult)
di as txt "Stocks (2022) summary:"
summarize int_stk_2022, detail

gen double int_bnd_2022 = .
replace int_bnd_2022 = `a2022_bnd' * `f2022_bnd'_mult if !missing(`a2022_bnd') & !missing(`f2022_bnd'_mult)
di as txt "Bonds (2022) summary:"
summarize int_bnd_2022, detail

gen double int_cash_2022 = .
replace int_cash_2022 = `a2022_cash' * `f2022_cash'_mult if !missing(`a2022_cash') & !missing(`f2022_cash'_mult)
di as txt "Checking/savings (2022) summary:"
summarize int_cash_2022, detail

gen double int_cds_2022 = .
replace int_cds_2022 = `a2022_cds' * `f2022_cds'_mult if !missing(`a2022_cds') & !missing(`f2022_cds'_mult)
di as txt "CDS/t-bills (2022) summary:"
summarize int_cds_2022, detail

egen double int_total_2022 = rowtotal(int_re_2022 int_bus_2022 int_ira_2022 int_stk_2022 int_bnd_2022 int_cash_2022 int_cds_2022)
di as txt "TOTAL interest/dividends 2022 summary (sum across asset classes):"
summarize int_total_2022, detail
tabstat int_total_2022, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* Diagnostics: find cases where amount exists but multiplier missing (2022)
* ---------------------------------------------------------------------
di as txt "=== Diagnostics: amount present but freq multiplier missing (2022) ==="
foreach pair in ///
    "`f2022_re' `a2022_re' int_re_2022" ///
    "`f2022_bus' `a2022_bus' int_bus_2022" ///
    "`f2022_ira' `a2022_ira' int_ira_2022" ///
    "`f2022_stk' `a2022_stk' int_stk_2022" ///
    "`f2022_bnd' `a2022_bnd' int_bnd_2022" ///
    "`f2022_cash' `a2022_cash' int_cash_2022" ///
    "`f2022_cds' `a2022_cds' int_cds_2022" {
    local fq : word 1 of `pair'
    local amt : word 2 of `pair'
    local intv : word 3 of `pair'
    di as txt "---- `intv' (amount var `amt' ; freq var `fq')"
    quietly tab `fq', missing
    quietly count if !missing(`amt') & missing(`fq'_mult)
    di as txt "Records with amount but missing multiplier = " r(N)
    quietly list HHID RSUBHH `fq' `amt' in 1/10 if !missing(`amt') & missing(`fq'_mult)
}

* ---------------------------------------------------------------------
* Save dataset with new computed variables BACK TO MASTER (overwrite)
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved 2022 interest/dividend vars back to master: `master'"

log close
di as txt "Done. Inspect the log and tab/summarize outputs for any suspicious frequency codes or missing multipliers."



