*----------------------------------------------------------------------
* compute_interest_dividends_2022.do
* Compute interest income & dividends (y^c_t) by asset class for 2022 only
* Assumes merged master exists:
*   /Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2020_2022_master.dta
* (This is the 2022-only trimmed version of the previous script)
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
* - real estate (other than main home): SQ139 (freq), SQ141 (amt)
* - private business: SQ153 (freq), SQ155 (amt)
* - IRA: SQ194 (freq), SQ190 (amt)
* - stocks: SQ322 (freq), SQ324 (amt)
* - bonds: SQ336 (freq), SQ338 (amt)
* - checking/savings: SQ350 (freq), SQ352 (amt)
* - CDS/t-bills: SQ362 (freq), SQ364 (amt)
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
* This leaves the original variables present but removes codes 7/8/9
* from being treated as valid multipliers later. Do not change other vars.
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
* Survey mapping:
*   1 WEEKLY    -> 52
*   2 2x/month  -> 24
*   3 MONTHLY   -> 12
*   4 QUARTERLY -> 4
*   5 EVERY 6 MONTHS -> 2
*   6 YEARLY    -> 1
* Codes 7/8/9 were recoded to . above and will produce missing *_mult.
* ---------------------------------------------------------------------
program define map_freq_to_mult, rclass
    syntax varname
    local fq = "`varlist'"

    /* drop any previously created helpers to avoid collisions */
    capture drop `fq'_lbl
    capture drop `fq'_mult

    /* create a decoded label string variable if a value label is attached */
    local labname : value label `fq'
    if "`labname'" != "" {
        decode `fq', gen(`fq'_lbl)
    }

    /* create multiplier (double) and map by numeric code (survey coding) */
    gen double `fq'_mult = .
    quietly replace `fq'_mult = 52 if `fq' == 1    // WEEKLY
    quietly replace `fq'_mult = 24 if `fq' == 2    // 2 times per month
    quietly replace `fq'_mult = 12 if `fq' == 3    // MONTHLY
    quietly replace `fq'_mult = 4  if `fq' == 4    // QUARTERLY
    quietly replace `fq'_mult = 2  if `fq' == 5    // EVERY 6 MONTHS
    quietly replace `fq'_mult = 1  if `fq' == 6    // YEARLY
    /* 7/8/9 were recoded to . above; any remaining 7/8/9 (unlikely) will leave *_mult missing */

    /* diagnostics / reporting */
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
* After each computed variable we summarize it.
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
* These are rows where an amount is reported but the frequency multiplier is missing
* (e.g., originally codes 7/8/9 or blank).
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
    /* optional: list a few cases for inspection */
    quietly list HHID RSUBHH `fq' `amt' in 1/10 if !missing(`amt') & missing(`fq'_mult)
}

* ---------------------------------------------------------------------
* Save dataset with new computed variables (2022-only interest)
* ---------------------------------------------------------------------
local out "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/hrs_2022_with_interest.dta"
save "`out'", replace
di as txt "Saved 2022 interest/dividend vars to `out'"

log close
di as txt "Done. Inspect the log and tab/summarize outputs for any suspicious frequency codes or missing multipliers."


