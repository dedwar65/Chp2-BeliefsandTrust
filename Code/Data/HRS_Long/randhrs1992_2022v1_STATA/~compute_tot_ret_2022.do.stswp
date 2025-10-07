*----------------------------------------------------------------------
* compute_tot_ret_2022.do
* Compute total returns to net worth for 2022 using HRS longitudinal file
* 
* Formula: r_annual = (1 + R_period)^(1/2) - 1
* Where R_period = num_period / base
* num_period = y^c_2022 + sum_c(cg_class) - F_total_period - debt_payments_2022
* base = A_{2020} + 0.5 * F_total_period
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "compute_tot_ret_2022.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local input_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local output_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Load data
* ---------------------------------------------------------------------
di as txt "=== Loading merged longitudinal file ==="

capture confirm file "`input_file'"
if _rc {
    di as error "ERROR: Input file not found -> `input_file'"
    di as error "Please run long_merge_in.do first"
    exit 198
}

use "`input_file'", clear

di as txt "File loaded successfully"
quietly describe
local n_vars = r(k)
local n_obs = r(N)
di as txt "Variables: `n_vars', Observations: `n_obs'"

* ---------------------------------------------------------------------
* Clean missing value codes
* ---------------------------------------------------------------------
di as txt "=== Cleaning missing value codes ==="

local misscodes 999999998 999999999 -8 -9
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Step 1: Check for imported flow_total_2022 variable
* ---------------------------------------------------------------------
di as txt "=== Checking for imported flow_total_2022 variable ==="

capture confirm variable flow_total_2022
if _rc {
    di as error "ERROR: flow_total_2022 not found - this should have been imported by long_merge_in.do"
    exit 198
}

di as txt "flow_total_2022 found - using imported flows from HRS_RAND data"
di as txt "Total net investment flows (flow_total_2022) summary:"
summarize flow_total_2022, detail

* Note: We will not create "safe" copies; we'll build numerators/denominators inline

* ---------------------------------------------------------------------
* Step 2: Beginning net worth (A_{2020})
* ---------------------------------------------------------------------
di as txt "=== Computing beginning net worth (A_2020) ==="

* Use H15ATOTB (Total of all assets net of debt, Wave 15 = 2020)
capture confirm variable h15atotb
if _rc {
    di as error "ERROR: h15atotb not found - this is required for beginning net worth"
    exit 198
}

gen double a_2020 = h15atotb
di as txt "Beginning net worth (A_2020) summary:"
summarize a_2020, detail
quietly count if !missing(a_2020)
di as txt "Non-missing A_2020: " r(N)

* ---------------------------------------------------------------------
* Step 3: Capital income (y^c_t)
* ---------------------------------------------------------------------
di as txt "=== Computing capital income (y^c_t) ==="

* Use H16ICAP (Household capital income, Wave 16 = 2022)
capture confirm variable h16icap
if _rc {
    di as error "ERROR: h16icap not found - this is required for capital income"
    exit 198
}

gen double y_c_2022 = h16icap
di as txt "Capital income (y_c_2022) summary:"
summarize y_c_2022, detail

* We'll use y_c_2022 directly in inline expressions below

* ---------------------------------------------------------------------
* Step 4: Compute capital gains by asset class (V_2022 - V_2020)
* ---------------------------------------------------------------------
di as txt "=== Computing capital gains by asset class ==="

* Primary residence (net)
capture confirm variable h16atoth h15atoth
if _rc {
    di as txt "WARNING: Primary residence variables (h16atoth, h15atoth) not found"
    gen double cg_res_2022 = .
}
else {
    gen double cg_res_2022 = h16atoth - h15atoth
    di as txt "Primary residence capital gains summary:"
    summarize cg_res_2022, detail
}

* Secondary residence (net)
capture confirm variable h16anethb h15anethb
if _rc {
    di as txt "WARNING: Secondary residence variables (h16anethb, h15anethb) not found"
    gen double cg_res2_2022 = .
}
else {
    gen double cg_res2_2022 = h16anethb - h15anethb
    di as txt "Secondary residence capital gains summary:"
    summarize cg_res2_2022, detail
}

* Other real estate
capture confirm variable h16arles h15arles
if _rc {
    di as txt "WARNING: Other real estate variables (h16arles, h15arles) not found"
    gen double cg_re_2022 = .
}
else {
    gen double cg_re_2022 = h16arles - h15arles
    di as txt "Other real estate capital gains summary:"
    summarize cg_re_2022, detail
}

* Private business
capture confirm variable h16absns h15absns
if _rc {
    di as txt "WARNING: Private business variables (h16absns, h15absns) not found"
    gen double cg_bus_2022 = .
}
else {
    gen double cg_bus_2022 = h16absns - h15absns
    di as txt "Private business capital gains summary:"
    summarize cg_bus_2022, detail
}

* IRA / Keogh
capture confirm variable h16aira h15aira
if _rc {
    di as txt "WARNING: IRA/Keogh variables (h16aira, h15aira) not found"
    gen double cg_ira_2022 = .
}
else {
    gen double cg_ira_2022 = h16aira - h15aira
    di as txt "IRA/Keogh capital gains summary:"
    summarize cg_ira_2022, detail
}

* Stocks / mutual funds
capture confirm variable h16astck h15astck
if _rc {
    di as txt "WARNING: Stock variables (h16astck, h15astck) not found"
    gen double cg_stk_2022 = .
}
else {
    gen double cg_stk_2022 = h16astck - h15astck
    di as txt "Stock capital gains summary:"
    summarize cg_stk_2022, detail
}

* Bonds
capture confirm variable h16abond h15abond
if _rc {
    di as txt "WARNING: Bond variables (h16abond, h15abond) not found"
    gen double cg_bnd_2022 = .
}
else {
    gen double cg_bnd_2022 = h16abond - h15abond
    di as txt "Bond capital gains summary:"
    summarize cg_bnd_2022, detail
}

* Checking / savings / money market
capture confirm variable h16achck h15achck
if _rc {
    di as txt "WARNING: Checking/savings variables (h16achck, h15achck) not found"
    gen double cg_chk_2022 = .
}
else {
    gen double cg_chk_2022 = h16achck - h15achck
    di as txt "Checking/savings capital gains summary:"
    summarize cg_chk_2022, detail
}

* CDs / T-bills
capture confirm variable h16acd h15acd
if _rc {
    di as txt "WARNING: CD/T-bill variables (h16acd, h15acd) not found"
    gen double cg_cd_2022 = .
}
else {
    gen double cg_cd_2022 = h16acd - h15acd
    di as txt "CD/T-bill capital gains summary:"
    summarize cg_cd_2022, detail
}

* Vehicles
capture confirm variable h16atran h15atran
if _rc {
    di as txt "WARNING: Vehicle variables (h16atran, h15atran) not found"
    gen double cg_veh_2022 = .
}
else {
    gen double cg_veh_2022 = h16atran - h15atran
    di as txt "Vehicle capital gains summary:"
    summarize cg_veh_2022, detail
}

* Other assets
capture confirm variable h16aothr h15aothr
if _rc {
    di as txt "WARNING: Other asset variables (h16aothr, h15aothr) not found"
    gen double cg_oth_2022 = .
}
else {
    gen double cg_oth_2022 = h16aothr - h15aothr
    di as txt "Other asset capital gains summary:"
    summarize cg_oth_2022, detail
}

* Total capital gains (sum non-missing components; set total to missing if ALL components missing)
capture drop cg_total_2022
egen byte any_cg_2022 = rownonmiss(cg_res_2022 cg_res2_2022 cg_re_2022 cg_bus_2022 cg_ira_2022 cg_stk_2022 cg_bnd_2022 cg_chk_2022 cg_cd_2022 cg_veh_2022 cg_oth_2022)
gen double cg_total_2022 = .
replace cg_total_2022 = cond(missing(cg_res_2022), 0, cg_res_2022) + ///
                          cond(missing(cg_res2_2022), 0, cg_res2_2022) + ///
                          cond(missing(cg_re_2022), 0, cg_re_2022) + ///
                          cond(missing(cg_bus_2022), 0, cg_bus_2022) + ///
                          cond(missing(cg_ira_2022), 0, cg_ira_2022) + ///
                          cond(missing(cg_stk_2022), 0, cg_stk_2022) + ///
                          cond(missing(cg_bnd_2022), 0, cg_bnd_2022) + ///
                          cond(missing(cg_chk_2022), 0, cg_chk_2022) + ///
                          cond(missing(cg_cd_2022), 0, cg_cd_2022) + ///
                          cond(missing(cg_veh_2022), 0, cg_veh_2022) + ///
                          cond(missing(cg_oth_2022), 0, cg_oth_2022) if any_cg_2022>0
drop any_cg_2022

* Use cg_total_2022 directly below with inline missing handling

di as txt "Total capital gains (cg_total_2022) summary:"
summarize cg_total_2022, detail

* ---------------------------------------------------------------------
* Variant: Exclude residential housing from numerator (keep denominator same)
* - Remove primary and secondary residence components from CG and flows
* - Follow same missing/zero rules as current calculation
* ---------------------------------------------------------------------
di as txt "=== Building EXCL-RESIDENTIAL components (numerator only) ==="

* Capital gains excluding residences: sum all non-residential components (treat missing as zero)
capture drop cg_total_2022_excl_res
gen double cg_total_2022_excl_res = ///
      cond(missing(cg_re_2022),   0, cg_re_2022)   + /// other real estate
      cond(missing(cg_bus_2022),  0, cg_bus_2022)  + /// business
      cond(missing(cg_ira_2022),  0, cg_ira_2022)  + /// ira/keogh
      cond(missing(cg_stk_2022),  0, cg_stk_2022)  + /// stocks
      cond(missing(cg_bnd_2022),  0, cg_bnd_2022)  + /// bonds
      cond(missing(cg_chk_2022),  0, cg_chk_2022)  + /// checking/savings
      cond(missing(cg_cd_2022),   0, cg_cd_2022)   + /// cds/t-bills
      cond(missing(cg_veh_2022),  0, cg_veh_2022)  + /// vehicles
      cond(missing(cg_oth_2022),  0, cg_oth_2022)    /// other assets

* Safe version (zero already when all components missing)
capture drop cg_total_2022_excl_res_safe
gen double cg_total_2022_excl_res_safe = cond(missing(cg_total_2022_excl_res), 0, cg_total_2022_excl_res)

* Flows excluding residences: sum non-residential asset-class flows
* Requires component flows from long_merge_in.do
capture drop flow_total_2022_excl_res
gen double flow_total_2022_excl_res = .
egen byte any_flow_present_nonres = rownonmiss(flow_bus_2022 flow_re_2022 flow_stk_2022 flow_ira_2022)
replace flow_total_2022_excl_res = ///
      cond(missing(flow_bus_2022),0,flow_bus_2022) + /// business
      cond(missing(flow_re_2022), 0,flow_re_2022)  + /// other real estate
      cond(missing(flow_stk_2022),0,flow_stk_2022) + /// stocks
      cond(missing(flow_ira_2022),0,flow_ira_2022)   /// ira
      if any_flow_present_nonres > 0
drop any_flow_present_nonres

* Safe version of non-residential flows
capture drop flow_total_2022_excl_res_safe
gen double flow_total_2022_excl_res_safe = cond(missing(flow_total_2022_excl_res), 0, flow_total_2022_excl_res)

di as txt "EXCL-RES: cg_total_2022_excl_res and flow_total_2022_excl_res summaries:"
summarize cg_total_2022_excl_res flow_total_2022_excl_res

* ---------------------------------------------------------------------
* Step 5: Compute debt payments (if needed)
* ---------------------------------------------------------------------
di as txt "=== Computing debt payments ==="

* For now, set debt payments to zero as they may not be needed in this formulation
* This can be added later if specific debt payment variables are identified
gen double debt_payments_2022 = 0

di as txt "Debt payments set to zero for now"

* ---------------------------------------------------------------------
* Step 6: Compute period returns
* ---------------------------------------------------------------------
di as txt "=== Computing period returns ==="

* Numerator: y^c_2022 + cg_total_2022 - flow_total_2022
* - Treat missing components as 0 when present with others
* - If ALL three are missing, set numerator to missing
capture drop num_period
gen double num_period = cond(missing(y_c_2022),0,y_c_2022) + ///
                        cond(missing(cg_total_2022),0,cg_total_2022) - ///
                        cond(missing(flow_total_2022),0,flow_total_2022)
egen byte __num_has = rownonmiss(y_c_2022 cg_total_2022 flow_total_2022)
replace num_period = . if __num_has == 0
drop __num_has

* Base: A_{2020} + 0.5 * F_total_period (treat missing flows as 0 only when A_2020 is non-missing)
capture drop base
gen double base = .
replace base = a_2020 + 0.5 * cond(missing(flow_total_2022),0,flow_total_2022) if !missing(a_2020)

* --- EXCLUDE RESIDENTIAL: compute returns using same base ---
capture drop num_period_excl_res
gen double num_period_excl_res = cond(missing(y_c_2022),0,y_c_2022) + ///
                                 cond(missing(cg_total_2022_excl_res),0,cg_total_2022_excl_res) - ///
                                 cond(missing(flow_total_2022_excl_res),0,flow_total_2022_excl_res)
egen byte __num_has_ex = rownonmiss(y_c_2022 cg_total_2022_excl_res flow_total_2022_excl_res)
replace num_period_excl_res = . if __num_has_ex == 0
drop __num_has_ex

capture drop r_period_excl_res
gen double r_period_excl_res = num_period_excl_res / base
replace r_period_excl_res = . if base < 10000

di as txt "Period returns excl-res (r_period_excl_res) summary:"
summarize r_period_excl_res, detail

* Annualize excl-res
capture drop r_annual_2022_excl_res
gen double r_annual_2022_excl_res = (1 + r_period_excl_res)^(1/2) - 1
replace r_annual_2022_excl_res = . if missing(r_period_excl_res)

di as txt "Annual returns excl-res (r_annual_2022_excl_res) summary:"
summarize r_annual_2022_excl_res, detail

* 5% trimming excl-res
capture drop r_annual_2022_excl_res_trim
gen double r_annual_2022_excl_res_trim = r_annual_2022_excl_res
quietly _pctile r_annual_2022_excl_res, p(5 95)
scalar p5_ex = r(r1)
scalar p95_ex = r(r2)
replace r_annual_2022_excl_res_trim = . if r_annual_2022_excl_res < p5_ex | r_annual_2022_excl_res > p95_ex

di as txt "Trimmed returns excl-res (r_annual_2022_excl_res_trim) summary:"
summarize r_annual_2022_excl_res_trim, detail

* Period return: R_period = num_period / base
gen double r_period = num_period / base

* Set to missing if base is below threshold 10,000
replace r_period = . if base < 10000

di as txt "Period returns (r_period) summary:"
summarize r_period, detail

* Stage counts for sample attrition and component presence
quietly count
local n_total = r(N)
quietly count if !missing(a_2020)
local n_has_a = r(N)
quietly count if !missing(base)
local n_has_base = r(N)
quietly count if base >= 0 & !missing(base)
local n_base_nonneg = r(N)
quietly count if base >= 10000 & !missing(base)
local n_basepos = r(N)
quietly count if !missing(r_period)
local n_r = r(N)
di as txt "Stage counts -> total=`n_total' | has A_2020=`n_has_a' | has base=`n_has_base' | base>=0=`n_base_nonneg' | base>=10k=`n_basepos' | r_period non-missing=`n_r'"

* Denominator diagnostics
di as txt "Denominator (base) diagnostics:"
di as txt "  A_2020 non-missing (potential denominators): `n_has_a'"
di as txt "  Base non-missing: `n_has_base'"
di as txt "  Base >= 0: `n_base_nonneg'"
di as txt "  Base >= 10,000: `n_basepos'"
di as txt "  Base summary (all non-missing):"
summarize base if !missing(base), detail

* Diagnostics: which numerator components are present (non-missing pre-safe)
gen byte has_yc   = !missing(y_c_2022)
gen byte has_cg   = !missing(cg_total_2022)
gen byte has_flow = !missing(flow_total_2022)
egen byte num_comp_nonmiss = rownonmiss(y_c_2022 cg_total_2022 flow_total_2022)
di as txt "Numerator components (pre-safe) presence counts among A_2020 non-missing:"
quietly count if has_yc   == 1 & !missing(a_2020)
di as txt "  y_c_2022 present: " r(N)
quietly count if has_cg   == 1 & !missing(a_2020)
di as txt "  cg_total_2022 present: " r(N)
quietly count if has_flow == 1 & !missing(a_2020)
di as txt "  flow_total_2022 present: " r(N)
quietly count if num_comp_nonmiss == 0 & !missing(a_2020)
di as txt "  none present (numerator will be 0 via safe): " r(N)

* ---------------------------------------------------------------------
* Step 7: Annualize returns
* ---------------------------------------------------------------------
di as txt "=== Annualizing returns ==="

* Annual return: r_annual = (1 + R_period)^(1/2) - 1
gen double r_annual_2022 = (1 + r_period)^(1/2) - 1

* Set to missing if period return is missing
replace r_annual_2022 = . if missing(r_period)

di as txt "Annual returns (r_annual_2022) summary:"
summarize r_annual_2022, detail

* ---------------------------------------------------------------------
* Step 8: Apply 5% trimming
* ---------------------------------------------------------------------
di as txt "=== Applying 5% trimming ==="

* Calculate trimming thresholds
quietly _pctile r_annual_2022, p(5 95)
scalar p5 = r(r1)
scalar p95 = r(r2)

di as txt "5th percentile: " %12.4f p5
di as txt "95th percentile: " %12.4f p95

* Create trimmed returns
gen double r_annual_2022_trimmed = r_annual_2022
replace r_annual_2022_trimmed = . if r_annual_2022 < p5 | r_annual_2022 > p95

quietly count if !missing(r_annual_2022_trimmed)
local n_trimmed = r(N)
quietly count if !missing(r_annual_2022)
local n_original = r(N)

di as txt "Original sample size: `n_original'"
di as txt "Trimmed sample size: `n_trimmed'"
di as txt "Trimmed sample size: " %4.1f 100*`n_trimmed'/`n_original' "% of original"

di as txt "Trimmed returns summary:"
summarize r_annual_2022_trimmed, detail

* ---------------------------------------------------------------------
* Step 9: Simple N diagnostics (included vs excl-res)
* ---------------------------------------------------------------------
di as txt "=== N diagnostics (included and excl-res) ==="
quietly count if !missing(r_period)
di as txt "  N r_period (included): " r(N)
quietly count if !missing(r_annual_2022)
di as txt "  N r_annual_2022 (included): " r(N)
quietly count if !missing(r_period_excl_res)
di as txt "  N r_period_excl_res: " r(N)
quietly count if !missing(r_annual_2022_excl_res)
di as txt "  N r_annual_2022_excl_res: " r(N)

* ---------------------------------------------------------------------
* Save results
* ---------------------------------------------------------------------
di as txt "=== Saving results ==="

save "`output_file'", replace
di as txt "Saved results to: `output_file'"

quietly describe
local n_vars_final = r(k)
local n_obs_final = r(N)
di as txt "Final file: `n_obs_final' observations, `n_vars_final' variables"

log close

* ---------------------------------------------------------------------
* Post-run diagnostics: counts and overlap of included vs excl-res returns
* ---------------------------------------------------------------------
di as txt "=== Returns availability diagnostics (2022) ==="
capture noisily {
    quietly count if !missing(r_annual_2022)
    local N_inc = r(N)
    quietly count if !missing(r_annual_2022_excl_res)
    local N_ex = r(N)
    quietly count if !missing(r_annual_2022) & !missing(r_annual_2022_excl_res)
    local N_both = r(N)
    di as txt "  Non-missing included: `N_inc'"
    di as txt "  Non-missing excl-res: `N_ex'"
    di as txt "  Non-missing both: `N_both'"
    gen byte has_r22    = !missing(r_annual_2022)
    gen byte has_r22_ex = !missing(r_annual_2022_excl_res)
    di as txt "  Cross-tab of included vs excl-res availability:"
    tab has_r22 has_r22_ex, missing
    drop has_r22 has_r22_ex
}
