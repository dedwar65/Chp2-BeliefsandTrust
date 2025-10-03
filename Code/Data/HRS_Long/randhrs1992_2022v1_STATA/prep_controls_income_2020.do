*----------------------------------------------------------------------
* prep_controls_income_2020.do
* Prepare controls (marital, immigration) and respondent income aggregates for 2020
* - Works on unified analysis dataset and writes back to it
* - Creates:
*   married_2020 (from r15mstat)
*   born_us (from rabplacf/rabplace)
*   resp_lab_inc (sum: r15earn r15pena r15issdi r15isret r15iunwc r15igxfr)
*   resp_tot_inc (resp_lab_inc + hwicap + hwiother)
*   Sums follow rule: missing only if all components missing; otherwise treat missing as 0
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "prep_controls_income_2020.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local inout "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local fallback "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_with_flows.dta"

* ---------------------------------------------------------------------
* Load unified dataset (fallback to flows file if needed)
* ---------------------------------------------------------------------
capture confirm file "`inout'"
if _rc {
    di as txt "Analysis dataset not found; falling back to flows dataset and will write unified file."
    capture confirm file "`fallback'"
    if _rc {
        di as error "ERROR: Neither analysis nor flows dataset found. Run long_merge_in.do first."
        exit 198
    }
    use "`fallback'", clear
}
else {
    use "`inout'", clear
}

quietly describe
di as txt "Observations: " %9.0f r(N)
di as txt "Variables:    " %9.0f r(k)

* ---------------------------------------------------------------------
* Marital status: married vs not married
* ---------------------------------------------------------------------
di as txt "=== Constructing marital status dummy from r15mstat ==="
capture confirm variable r15mstat
if _rc {
    di as error "ERROR: r15mstat not found"
    exit 198
}

capture drop married_2020
gen byte married_2020 = .
replace married_2020 = 1 if inlist(r15mstat, 1, 2)
replace married_2020 = 0 if inlist(r15mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "not married" 1 "married", replace
label values married_2020 yesno
label var married_2020 "Married (r15mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (r15mstat) distribution:"
tab r15mstat, missing

di as txt "Married_2020 dummy summary:"
tab married_2020, missing

* ---------------------------------------------------------------------
* Immigration status: born in US dummy from rabplace only
* ---------------------------------------------------------------------
di as txt "=== Constructing born-in-US dummy from rabplace ==="
capture confirm variable rabplace
if _rc {
    di as error "ERROR: rabplace not found"
    exit 198
}

* Ensure we have a numeric version to compare against codes 1..13
capture drop rabplace_num
capture confirm numeric variable rabplace
if _rc {
    quietly destring rabplace, generate(rabplace_num) force
} 
else {
    generate double rabplace_num = rabplace
}

capture drop born_us
gen byte born_us = .
* 1-10 are US Census divisions; 12=US territory => treat as US-born
replace born_us = 1 if inrange(rabplace_num,1,10) | rabplace_num == 12
* 11=Not US or US territory; 13=Not US => not US-born
replace born_us = 0 if inlist(rabplace_num,11,13)
label values born_us yesno
label var born_us "Born in US (1) vs not US (0)"

di as txt "Immigration raw distribution (rabplace or numeric copy):"
tab rabplace_num, missing
quietly count if !missing(born_us)
di as txt "Non-missing born_us count: " r(N)
di as txt "Born-in-US dummy summary:"
tab born_us, missing

* ---------------------------------------------------------------------
* Respondent income aggregates (2020)
* ---------------------------------------------------------------------
di as txt "=== Constructing respondent income aggregates for 2020 ==="

* Labor income components
local lab_vars "r15iearn r15ipena r15issdi r15isret r15iunwc r15igxfr"

* Check presence
foreach v of local lab_vars {
    capture confirm variable `v'
    if _rc {
        di as txt "  WARNING: `v' not found"
    }
}

* Sum with rule: missing only if all components missing
capture drop resp_lab_inc
egen double resp_lab_inc = rowtotal(`lab_vars')
replace resp_lab_inc = . if missing(r15iearn) & missing(r15ipena) & missing(r15issdi) & missing(r15isret) & missing(r15iunwc) & missing(r15igxfr)
label var resp_lab_inc "Respondent labor income (sum of 6 components; missing if all missing)"

di as txt "resp_lab_inc summary:"
summarize resp_lab_inc, detail

* Total income = labor income + household capital income + other household income
local tot_add "h15icap h15iothr"
foreach v of local tot_add {
    capture confirm variable `v'
    if _rc {
        di as txt "  WARNING: `v' not found"
    }
}

capture drop resp_tot_inc
gen double resp_tot_inc = resp_lab_inc ///
    + cond(missing(h15icap), 0, h15icap) ///
    + cond(missing(h15iothr), 0, h15iothr)
* If labor income is missing AND both additions are missing, set total to missing as well
replace resp_tot_inc = . if missing(resp_lab_inc) & missing(h15icap) & missing(h15iothr)
label var resp_tot_inc "Respondent total income (labor + hwicap + hwiother; missing if all missing)"

di as txt "resp_tot_inc summary:"
summarize resp_tot_inc, detail

* ---------------------------------------------------------------------
* Wealth percentile (0-100) and wealth deciles (1-10) using 2020 net worth (h15atotb)
* ---------------------------------------------------------------------
di as txt "=== Constructing wealth percentile and deciles from h15atotb (A_2020) ==="
capture confirm variable h15atotb
if _rc {
    di as error "ERROR: h15atotb (A_2020) not found"
    exit 198
}

* Wealth percentile (continuous 0-100 across non-missing)
capture drop wealth_rank wealth_pct
quietly count if !missing(h15atotb)
local N_wealth = r(N)
egen double wealth_rank = rank(h15atotb) if !missing(h15atotb)
gen double wealth_pct = .
replace wealth_pct = 100 * (wealth_rank - 1) / (`N_wealth' - 1) if `N_wealth' > 1 & !missing(wealth_rank)
replace wealth_pct = 50 if `N_wealth' == 1 & !missing(wealth_rank)
label variable wealth_pct "Wealth percentile (based on h15atotb)"

di as txt "Wealth percentile diagnostics:"
quietly count if !missing(wealth_pct)
di as txt "  Non-missing wealth_pct: " r(N)
tabstat wealth_pct, stats(n mean sd p50 min max) format(%12.4f)
di as txt "[summarize] wealth_pct"
capture noisily summarize wealth_pct, detail

* Wealth deciles (1-10) across non-missing h15atotb
capture drop wealth_decile
xtile wealth_decile = h15atotb if !missing(h15atotb), n(10)
label var wealth_decile "Wealth decile (1=lowest,10=highest)"
di as txt "Wealth decile distribution:"
tab wealth_decile, missing

* Create decile dummies wealth_d1-wealth_d10
forvalues d = 1/10 {
    capture drop wealth_d`d'
    gen byte wealth_d`d' = wealth_decile == `d' if !missing(wealth_decile)
    label values wealth_d`d' yesno
    label var wealth_d`d' "Wealth decile `d'"
}

* ---------------------------------------------------------------------
* Save back to unified analysis dataset
* ---------------------------------------------------------------------
di as txt "=== Saving unified analysis dataset (includes flows, trust, controls, income) ==="
save "`inout'", replace
di as txt "Saved unified dataset: `inout'"

log close

