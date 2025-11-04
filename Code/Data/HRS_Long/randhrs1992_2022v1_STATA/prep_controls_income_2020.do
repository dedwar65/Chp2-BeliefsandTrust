*----------------------------------------------------------------------
* prep_controls_income_2020.do
* Prepare controls (marital, immigration, race/ethnicity) and respondent income aggregates for 2020
* - Works on unified analysis dataset and writes back to it
* - Creates:
*   married_2022 (from r15mstat)
*   born_us (from rabplacf/rabplace)
*   race_eth (from raracem and rahispan: 1=NH White, 2=NH Black, 3=Hispanic, 4=NH Other)
*   resp_lab_inc_2022 (sum: r15earn r15pena r15issdi r15isret r15iunwc r15igxfr)
*   resp_tot_inc_2022 (resp_lab_inc_2022 + hwicap + hwiother)
*   wealth_pct_2020, wealth_decile_2020, wealth_d1_2020-wealth_d10_2020 (based on h15atotb)
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

capture drop married_2022
gen byte married_2022 = .
replace married_2022 = 1 if inlist(r15mstat, 1, 2)
replace married_2022 = 0 if inlist(r15mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "not married" 1 "married", replace
label values married_2022 yesno
label var married_2022 "Married (r15mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (r15mstat) distribution:"
tab r15mstat, missing

di as txt "Married_2022 dummy summary:"
tab married_2022, missing

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
* Race/Ethnicity: combined race and ethnicity variable from RARACEM and RAHISPAN
* ---------------------------------------------------------------------
di as txt "=== Constructing race/ethnicity variable from raracem and rahispan ==="
local race_vars_found = 0
capture confirm variable raracem
if _rc {
    di as warn "WARNING: raracem not found; race_eth will not be created"
}
else {
    local race_vars_found = `race_vars_found' + 1
    capture confirm variable rahispan
    if _rc {
        di as warn "WARNING: rahispan not found; race_eth will not be created"
    }
    else {
        local race_vars_found = `race_vars_found' + 1
        * Check the coding
        di as txt "Race (raracem) distribution:"
        tab raracem, missing
        di as txt "Hispanic (rahispan) distribution:"
        tab rahispan, missing
        
        * Generate combined race/ethnicity category
        * 1 = Non-Hispanic White (reference category - will be omitted)
        * 2 = Non-Hispanic Black
        * 3 = Hispanic (any race)
        * 4 = Non-Hispanic Other
        capture drop race_eth
        gen byte race_eth = .
        label define raceeth 1 "NH White" 2 "NH Black" 3 "Hispanic" 4 "NH Other"
        
        * Hispanic: any race (rahispan == 1)
        replace race_eth = 3 if rahispan == 1
        * Non-Hispanic White (rahispan == 0 & raracem == 1)
        replace race_eth = 1 if rahispan == 0 & raracem == 1
        * Non-Hispanic Black (rahispan == 0 & raracem == 2)
        replace race_eth = 2 if rahispan == 0 & raracem == 2
        * Non-Hispanic Other (rahispan == 0 & raracem == 3)
        replace race_eth = 4 if rahispan == 0 & raracem == 3
        
        label values race_eth raceeth
        label var race_eth "Race/ethnicity (1=NH White, 2=NH Black, 3=Hispanic, 4=NH Other)"
        
        di as txt "Race/ethnicity (race_eth) distribution:"
        tab race_eth, missing
        quietly count if !missing(race_eth)
        di as txt "Non-missing race_eth count: " r(N)
    }
}
* Final status check
capture confirm variable race_eth
if _rc {
    di as warn "FINAL STATUS: race_eth variable was NOT created (source variables missing)"
}
else {
    di as txt "FINAL STATUS: race_eth variable successfully created"
}

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
capture drop resp_lab_inc_2022
egen double resp_lab_inc_2022 = rowtotal(`lab_vars')
replace resp_lab_inc_2022 = . if missing(r15iearn) & missing(r15ipena) & missing(r15issdi) & missing(r15isret) & missing(r15iunwc) & missing(r15igxfr)
label var resp_lab_inc_2022 "Respondent labor income (sum of 6 components; missing if all missing)"

di as txt "resp_lab_inc_2022 summary:"
summarize resp_lab_inc_2022, detail

* Total income = labor income + household capital income + other household income
local tot_add "h15icap h15iothr"
foreach v of local tot_add {
    capture confirm variable `v'
    if _rc {
        di as txt "  WARNING: `v' not found"
    }
}

capture drop resp_tot_inc_2022
gen double resp_tot_inc_2022 = resp_lab_inc_2022 ///
    + cond(missing(h15icap), 0, h15icap) ///
    + cond(missing(h15iothr), 0, h15iothr)
* If labor income is missing AND both additions are missing, set total to missing as well
replace resp_tot_inc_2022 = . if missing(resp_lab_inc_2022) & missing(h15icap) & missing(h15iothr)
label var resp_tot_inc_2022 "Respondent total income (labor + hwicap + hwiother; missing if all missing)"

di as txt "resp_tot_inc_2022 summary:"
summarize resp_tot_inc_2022, detail

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
capture drop wealth_rank_2020 wealth_pct_2020
quietly count if !missing(h15atotb)
local N_wealth = r(N)
egen double wealth_rank_2020 = rank(h15atotb) if !missing(h15atotb)
gen double wealth_pct_2020 = .
replace wealth_pct_2020 = 100 * (wealth_rank_2020 - 1) / (`N_wealth' - 1) if `N_wealth' > 1 & !missing(wealth_rank_2020)
replace wealth_pct_2020 = 50 if `N_wealth' == 1 & !missing(wealth_rank_2020)
label variable wealth_pct_2020 "Wealth percentile (based on h15atotb)"

di as txt "Wealth percentile diagnostics:"
quietly count if !missing(wealth_pct_2020)
di as txt "  Non-missing wealth_pct_2020: " r(N)
tabstat wealth_pct_2020, stats(n mean sd p50 min max) format(%12.4f)
di as txt "[summarize] wealth_pct_2020"
capture noisily summarize wealth_pct_2020, detail

* Wealth deciles (1-10) across non-missing h15atotb
capture drop wealth_decile_2020
xtile wealth_decile_2020 = h15atotb if !missing(h15atotb), n(10)
label var wealth_decile_2020 "Wealth decile (1=lowest,10=highest)"
di as txt "Wealth decile distribution:"
tab wealth_decile_2020, missing

* Create decile dummies wealth_d1-wealth_d10
forvalues d = 1/10 {
    capture drop wealth_d`d'_2020
    gen byte wealth_d`d'_2020 = wealth_decile_2020 == `d' if !missing(wealth_decile_2020)
    label values wealth_d`d'_2020 yesno
    label var wealth_d`d'_2020 "Wealth decile `d'"
}

* ---------------------------------------------------------------------
* Save back to unified analysis dataset
* ---------------------------------------------------------------------
di as txt "=== Saving unified analysis dataset (includes flows, trust, controls, income) ==="
save "`inout'", replace
di as txt "Saved unified dataset: `inout'"

log close

