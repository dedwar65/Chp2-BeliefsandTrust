*----------------------------------------------------------------------
* compute_mortgage_payments_2022.do
* Compute annual mortgage payments (first, second, secondary) for 2022
* Loads and then saves back to the master so other scripts keep variables.
*----------------------------------------------------------------------
clear all
capture log close
log using "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS/cleaned/compute_mortgage_payments_2022.log", replace text

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
* Variable list for mortgages in HRS (as discussed)
* SH025 - first mortgage payment amount
* SH029 - first mortgage payment frequency
* SH036 - second mortgage payment amount
* SH040 - second mortgage payment frequency
* SH175 - secondary residence first mortgage payment amount
* SH179 - secondary residence first mortgage payment frequency
* ---------------------------------------------------------------------

local amtvars "SH025 SH036 SH175"
local freqvars "SH029 SH040 SH179"

* ---------------------------------------------------------------------
* 1) Recode frequency codes 7/8/9 -> missing (do this BEFORE computations)
* ---------------------------------------------------------------------
di as txt "Recoding frequency codes 7,8,9 -> missing for mortgage frequency vars..."
foreach v of local freqvars {
    capture confirm variable `v'
    if _rc {
        di as txt "  Variable `v' not present -> skipping recode"
    }
    else {
        quietly count if inlist(`v',7,8,9)
        di as txt "  `v' records with codes 7/8/9 before recode = " r(N)
        quietly replace `v' = . if inlist(`v',7,8,9)
        quietly count if inlist(`v',7,8,9)
        di as txt "  `v' records with codes 7/8/9 after recode  = " r(N)
        quietly tab `v', missing
    }
}

* ---------------------------------------------------------------------
* 2) Clean amount variables: set common sentinel codes -> missing
* ---------------------------------------------------------------------
local amt_misscodes 9999998 9999999 -8 -9
di as txt "Cleaning mortgage amount sentinel codes to missing for: `amtvars'"
foreach v of local amtvars {
    capture confirm variable `v'
    if _rc {
        di as txt "  Amount variable `v' not found -> skipping"
    }
    else {
        foreach mc of local amt_misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
        di as txt "  Summary for `v' after recoding sentinels:"
        summarize `v', detail
    }
}

* ---------------------------------------------------------------------
* 3) Define a small program to map freq -> annual multiplier
* ---------------------------------------------------------------------
capture program drop map_freq_to_mult
program define map_freq_to_mult, rclass
    syntax varname
    local fq = "`varlist'"
    capture confirm variable `fq'
    if _rc {
        di as txt "  map_freq_to_mult: variable `fq' not found -> exiting program"
        exit 0
    }
    capture drop `fq'_mult
    gen double `fq'_mult = .
    quietly replace `fq'_mult = 52 if `fq' == 1
    quietly replace `fq'_mult = 24 if `fq' == 2
    quietly replace `fq'_mult = 12 if `fq' == 3
    quietly replace `fq'_mult = 4  if `fq' == 4
    quietly replace `fq'_mult = 2  if `fq' == 5
    quietly replace `fq'_mult = 1  if `fq' == 6
    quietly count if !missing(`fq'_mult)
    di as txt "  `fq'_mult nonmissing observations = " r(N)
    tab `fq', missing
end

* ---------------------------------------------------------------------
* 4) Apply mapping to each mortgage frequency var
* ---------------------------------------------------------------------
di as txt "Mapping mortgage frequency variables to multipliers..."
map_freq_to_mult SH029
map_freq_to_mult SH040
map_freq_to_mult SH179

* ---------------------------------------------------------------------
* 5) Compute annual payments: amount * multiplier
* ---------------------------------------------------------------------
di as txt "Computing annual mortgage payments (amount * multiplier)..."

capture confirm variable SH025
if _rc {
    di as txt "SH025 not found -> mort1_pay_annual set to missing"
    gen double mort1_pay_annual = .
}
else {
    capture confirm variable SH029_mult
    if _rc {
        di as txt "SH029_mult not found -> cannot annualize SH025 -> mort1_pay_annual missing"
        gen double mort1_pay_annual = .
    }
    else {
        gen double mort1_pay_annual = .
        replace mort1_pay_annual = SH025 * SH029_mult if !missing(SH025) & !missing(SH029_mult)
        di as txt "First mortgage annual payment summary (mort1_pay_annual):"
        summarize mort1_pay_annual, detail
    }
}

capture confirm variable SH036
if _rc {
    di as txt "SH036 not found -> mort2_pay_annual set to missing"
    gen double mort2_pay_annual = .
}
else {
    capture confirm variable SH040_mult
    if _rc {
        di as txt "SH040_mult not found -> cannot annualize SH036 -> mort2_pay_annual missing"
        gen double mort2_pay_annual = .
    }
    else {
        gen double mort2_pay_annual = .
        replace mort2_pay_annual = SH036 * SH040_mult if !missing(SH036) & !missing(SH040_mult)
        di as txt "Second mortgage annual payment summary (mort2_pay_annual):"
        summarize mort2_pay_annual, detail
    }
}

capture confirm variable SH175
if _rc {
    di as txt "SH175 not found -> secmort_pay_annual set to missing"
    gen double secmort_pay_annual = .
}
else {
    capture confirm variable SH179_mult
    if _rc {
        di as txt "SH179_mult not found -> cannot annualize SH175 -> secmort_pay_annual missing"
        gen double secmort_pay_annual = .
    }
    else {
        gen double secmort_pay_annual = .
        replace secmort_pay_annual = SH175 * SH179_mult if !missing(SH175) & !missing(SH179_mult)
        di as txt "Secondary mortgage annual payment summary (secmort_pay_annual):"
        summarize secmort_pay_annual, detail
    }
}

* ---------------------------------------------------------------------
* 6) Diagnostics: cases where amount exists but multiplier missing
* ---------------------------------------------------------------------
di as txt "Diagnostics: amount present but multiplier missing (first mortgage)"
quietly count if !missing(SH025) & missing(SH029_mult)
di as txt "Records with SH025 present & SH029_mult missing = " r(N)
quietly list HHID RSUBHH SH025 SH029 SH029_mult mort1_pay_annual in 1/20 if !missing(SH025) & missing(SH029_mult)

di as txt "Diagnostics: amount present but multiplier missing (second mortgage)"
quietly count if !missing(SH036) & missing(SH040_mult)
di as txt "Records with SH036 present & SH040_mult missing = " r(N)
quietly list HHID RSUBHH SH036 SH040 SH040_mult mort2_pay_annual in 1/20 if !missing(SH036) & missing(SH040_mult)

di as txt "Diagnostics: amount present but multiplier missing (secondary residence mortgage)"
quietly count if !missing(SH175) & missing(SH179_mult)
di as txt "Records with SH175 present & SH179_mult missing = " r(N)
quietly list HHID RSUBHH SH175 SH179 SH179_mult secmort_pay_annual in 1/20 if !missing(SH175) & missing(SH179_mult)

* ---------------------------------------------------------------------
* 7) Sum annual payments across mortgage types
* ---------------------------------------------------------------------
capture drop mortgage_payments_total_2022
egen double mortgage_payments_total_2022 = rowtotal(mort1_pay_annual mort2_pay_annual secmort_pay_annual)

di as txt "TOTAL mortgage payments (annual) summary:"
summarize mortgage_payments_total_2022, detail
tabstat mortgage_payments_total_2022, stats(n mean sd p50 min max) format(%12.2f)

* ---------------------------------------------------------------------
* 8) Save dataset with new mortgage payment variables BACK TO MASTER
* ---------------------------------------------------------------------
save "`master'", replace
di as txt "Saved mortgage payment vars back to master: `master'"

log close
di as txt "Done. Inspect the log and the tab/summarize outputs for any suspicious values or recode needs."
