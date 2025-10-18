*----------------------------------------------------------------------
* RAND_2018_merge_and_returns.do
* Merge 2018 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2018; mirrors 2020 pipeline with 2018 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2018_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
* Start from the unified analysis dataset so previously saved variables (e.g., 2022, 2020 flows)
* are preserved and augmented with 2018 flows
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2018  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2018/h18f2c_STATA/h18f2c.dta"
local out_ana   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Load longitudinal baseline and check key
* ---------------------------------------------------------------------
di as txt "=== Loading unified analysis dataset ==="
capture confirm file "`long_file'"
if _rc {
    di as error "ERROR: baseline longitudinal file not found -> `long_file'"
    exit 198
}
use "`long_file'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in longitudinal baseline"
    exit 198
}

* ---------------------------------------------------------------------
* Merge in 2018 flows from raw RAND file
* (Variable names should match 2018 wave; adjust if needed per notes)
* ---------------------------------------------------------------------
di as txt "=== Loading 2018 RAND raw file ==="
preserve
capture confirm file "`raw_2018'"
if _rc {
    di as error "ERROR: RAW 2018 file not found -> `raw_2018'"
    exit 198
}
use "`raw_2018'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2018"
    exit 198
}

* 2018 flow variables per notes
local flow18 "qr050 qr055 qr063 qr064 qr072 qr030 qr035 qr045 qq171_1 qq171_2 qq171_3 qr007 qr013 qr024"

di as txt "Checking presence of 2018 flow variables..."
foreach v of local flow18 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2018 RAW: `v'"
    else  di as txt  "  OK in 2018 RAW: `v'"
}

keep hhidpn `flow18'
tempfile raw18_flows
save "`raw18_flows'", replace
restore

di as txt "=== Merging 2018 flows into longitudinal baseline ==="
merge 1:1 hhidpn using "`raw18_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (mirror 2022 cleaning rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998
foreach v of local flow18 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2018 flow aggregates (naming parallels 2022, with _2018)
* ---------------------------------------------------------------------
* qr063 direction and magnitude
capture drop qr063_dir18
gen byte qr063_dir18 = .
replace qr063_dir18 = -1 if qr063 == 1
replace qr063_dir18 =  1 if qr063 == 2
replace qr063_dir18 =  0 if qr063 == 3

capture drop flow_bus_2018
gen double flow_bus_2018 = .
replace flow_bus_2018 = qr055 - qr050 if !missing(qr055) & !missing(qr050)
replace flow_bus_2018 = qr055 if  missing(qr050) & !missing(qr055)
replace flow_bus_2018 = -qr050 if !missing(qr050) &  missing(qr055)

capture drop flow_stk_private_2018
gen double flow_stk_private_2018 = qr063_dir18 * qr064 if !missing(qr063_dir18) & !missing(qr064)

capture drop flow_stk_public_2018
gen double flow_stk_public_2018 = qr072 if !missing(qr072)

capture drop flow_stk_2018
gen double flow_stk_2018 = cond(!missing(flow_stk_private_2018), flow_stk_private_2018, 0) + ///
                           cond(!missing(flow_stk_public_2018),  flow_stk_public_2018,  0)
replace flow_stk_2018 = . if missing(flow_stk_private_2018) & missing(flow_stk_public_2018)

capture drop flow_re_2018
gen double flow_re_2018 = .
replace flow_re_2018 = cond(missing(qr035),0,qr035) - ( cond(missing(qr030),0,qr030) + cond(missing(qr045),0,qr045) ) if !missing(qr035) | !missing(qr030) | !missing(qr045)

capture drop flow_ira_2018
egen double flow_ira_2018 = rowtotal(qq171_1 qq171_2 qq171_3)
replace flow_ira_2018 = . if missing(qq171_1) & missing(qq171_2) & missing(qq171_3)

capture drop flow_residences_2018
gen double flow_residences_2018 = .
replace flow_residences_2018 = cond(missing(sr013),0,sr013) - ( cond(missing(sr007),0,sr007) + cond(missing(sr024),0,sr024) ) if !missing(sr013) | !missing(sr007) | !missing(sr024)
replace flow_residences_2018 = . if missing(sr013) & missing(sr007) & missing(sr024)

capture drop flow_total_2018
gen double flow_total_2018 = .
egen byte any_flow_present18 = rownonmiss(flow_bus_2018 flow_re_2018 flow_stk_2018 flow_ira_2018 flow_residences_2018)
replace flow_total_2018 = cond(missing(flow_bus_2018),0,flow_bus_2018) + ///
                          cond(missing(flow_re_2018),0,flow_re_2018) + ///
                          cond(missing(flow_stk_2018),0,flow_stk_2018) + ///
                          cond(missing(flow_ira_2018),0,flow_ira_2018) + ///
                          cond(missing(flow_residences_2018),0,flow_residences_2018) ///
                          if any_flow_present18 > 0
drop any_flow_present18

di as txt "Flows 2018 summaries:"
summarize flow_bus_2018 flow_re_2018 flow_stk_2018 flow_ira_2018 flow_residences_2018 flow_total_2018

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2018 (period 2016-2018)
* Mirrors compute_tot_ret_2022.do with 2016/2018 variables
* ---------------------------------------------------------------------
di as txt "=== Computing 2018 returns (2016-2018) ==="

* Denominator base: A_{2016}
capture drop a_2016
gen double a_2016 = h13atotb
label var a_2016 "Total net assets (A_2016 = h13atotb)"

* Capital income y^c_2018
capture drop y_c_2018
gen double y_c_2018 = h14icap
label var y_c_2018 "Capital income 2018 (h14icap)"

* Capital gains per class: cg_class = V_2018 - V_2016
capture drop cg_pri_res_2018 cg_sec_res_2018 cg_re_2018 cg_bus_2018 cg_ira_2018 cg_stk_2018 cg_bond_2018 cg_chck_2018 cg_cd_2018 cg_veh_2018 cg_oth_2018
gen double cg_pri_res_2018 = h14atoth - h13atoth
gen double cg_sec_res_2018 = h14anethb - h13anethb
gen double cg_re_2018      = h14arles - h13arles
gen double cg_bus_2018     = h14absns - h13absns
gen double cg_ira_2018     = h14aira  - h13aira
gen double cg_stk_2018     = h14astck - h13astck
gen double cg_bond_2018    = h14abond - h13abond
gen double cg_chck_2018    = h14achck - h13achck
gen double cg_cd_2018      = h14acd   - h13acd
gen double cg_veh_2018     = h14atran - h13atran
gen double cg_oth_2018     = h14aothr - h13aothr

* Summaries of each capital gains component
di as txt "Capital gains components (2016->2018) summaries:"
summarize cg_pri_res_2018 cg_sec_res_2018 cg_re_2018 cg_bus_2018 cg_ira_2018 cg_stk_2018 cg_bond_2018 cg_chck_2018 cg_cd_2018 cg_veh_2018 cg_oth_2018

* Total capital gains with missing logic: missing only if all components missing
capture drop cg_total_2018
egen byte any_cg_2018 = rownonmiss(cg_pri_res_2018 cg_sec_res_2018 cg_re_2018 cg_bus_2018 cg_ira_2018 cg_stk_2018 cg_bond_2018 cg_chck_2018 cg_cd_2018 cg_veh_2018 cg_oth_2018)
gen double cg_total_2018 = .
replace cg_total_2018 = cond(missing(cg_pri_res_2018),0,cg_pri_res_2018) + ///
                        cond(missing(cg_sec_res_2018),0,cg_sec_res_2018) + ///
                        cond(missing(cg_re_2018),0,cg_re_2018) + ///
                        cond(missing(cg_bus_2018),0,cg_bus_2018) + ///
                        cond(missing(cg_ira_2018),0,cg_ira_2018) + ///
                        cond(missing(cg_stk_2018),0,cg_stk_2018) + ///
                        cond(missing(cg_bond_2018),0,cg_bond_2018) + ///
                        cond(missing(cg_chck_2018),0,cg_chck_2018) + ///
                        cond(missing(cg_cd_2018),0,cg_cd_2018) + ///
                        cond(missing(cg_veh_2018),0,cg_veh_2018) + ///
                        cond(missing(cg_oth_2018),0,cg_oth_2018) if any_cg_2018>0
drop any_cg_2018

* Diagnostics
di as txt "[summarize] y_c_2018, cg_total_2018, flow_total_2018"
summarize y_c_2018 cg_total_2018 flow_total_2018

* Base: A_2016 + 0.5 * F_2018 (treat flows as 0 only when A_2016 is non-missing)
capture drop base_2018
gen double base_2018 = .
replace base_2018 = a_2016 + 0.5 * cond(missing(flow_total_2018),0,flow_total_2018) if !missing(a_2016)
label var base_2018 "Base for 2018 returns (A_2016 + 0.5*F_2018)"
di as txt "[summarize] base_2018"
summarize base_2018, detail

* Period return and annualization (2-year)
capture drop num_period_2018 r_period_2018 r_annual_2018 r_annual_trim_2018
gen double num_period_2018 = cond(missing(y_c_2018),0,y_c_2018) + ///
                             cond(missing(cg_total_2018),0,cg_total_2018) - ///
                             cond(missing(flow_total_2018),0,flow_total_2018)
egen byte __num18_has = rownonmiss(y_c_2018 cg_total_2018 flow_total_2018)
replace num_period_2018 = . if __num18_has == 0
drop __num18_has

gen double r_period_2018 = num_period_2018 / base_2018
replace r_period_2018 = . if base_2018 < 10000
gen double r_annual_2018 = (1 + r_period_2018)^(1/2) - 1
replace r_annual_2018 = . if missing(r_period_2018)

* Trim 5% tails
capture drop r_annual_trim_2018
xtile __p_2018 = r_annual_2018 if !missing(r_annual_2018), n(100)
gen double r_annual_trim_2018 = r_annual_2018
replace r_annual_trim_2018 = . if __p_2018 <= 5 | __p_2018 > 95
drop __p_2018

di as txt "[summarize] r_period_2018, r_annual_2018, r_annual_trim_2018"
summarize r_period_2018 r_annual_2018 r_annual_trim_2018

* Excluding residential housing (remove primary and secondary residence from cg and flows)
capture drop cg_total_2018_excl_res flow_total_2018_excl_res
gen double flow_total_2018_excl_res = .
egen byte any_flow18_excl = rownonmiss(flow_bus_2018 flow_re_2018 flow_stk_2018 flow_ira_2018)  // exclude residences
replace flow_total_2018_excl_res = cond(missing(flow_bus_2018),0,flow_bus_2018) + ///
                                   cond(missing(flow_re_2018),0,flow_re_2018) + ///
                                   cond(missing(flow_stk_2018),0,flow_stk_2018) + ///
                                   cond(missing(flow_ira_2018),0,flow_ira_2018) if any_flow18_excl>0
drop any_flow18_excl

gen double cg_total_2018_excl_res = .
egen byte any_cg18_excl = rownonmiss(cg_re_2018 cg_bus_2018 cg_ira_2018 cg_stk_2018 cg_bond_2018 cg_chck_2018 cg_cd_2018 cg_veh_2018 cg_oth_2018)
replace cg_total_2018_excl_res = cond(missing(cg_re_2018),0,cg_re_2018) + ///
                                 cond(missing(cg_bus_2018),0,cg_bus_2018) + ///
                                 cond(missing(cg_ira_2018),0,cg_ira_2018) + ///
                                 cond(missing(cg_stk_2018),0,cg_stk_2018) + ///
                                 cond(missing(cg_bond_2018),0,cg_bond_2018) + ///
                                 cond(missing(cg_chck_2018),0,cg_chck_2018) + ///
                                 cond(missing(cg_cd_2018),0,cg_cd_2018) + ///
                                 cond(missing(cg_veh_2018),0,cg_veh_2018) + ///
                                 cond(missing(cg_oth_2018),0,cg_oth_2018) if any_cg18_excl>0
drop any_cg18_excl

di as txt "EXCL-RES: cg_total_2018_excl_res and flow_total_2018_excl_res summaries:"
summarize cg_total_2018_excl_res flow_total_2018_excl_res

* Use SAME base_2018
capture drop num_period_2018_excl_res r_period_2018_excl_res r_annual_excl_2018 r_annual_excl_trim_2018
gen double num_period_2018_excl_res = cond(missing(y_c_2018),0,y_c_2018) + ///
                                      cond(missing(cg_total_2018_excl_res),0,cg_total_2018_excl_res) - ///
                                      cond(missing(flow_total_2018_excl_res),0,flow_total_2018_excl_res)
egen byte __num18ex_has = rownonmiss(y_c_2018 cg_total_2018_excl_res flow_total_2018_excl_res)
replace num_period_2018_excl_res = . if __num18ex_has == 0
drop __num18ex_has

gen double r_period_2018_excl_res = num_period_2018_excl_res / base_2018
replace r_period_2018_excl_res = . if base_2018 < 10000
gen double r_annual_excl_2018 = (1 + r_period_2018_excl_res)^(1/2) - 1
replace r_annual_excl_2018 = . if missing(r_period_2018_excl_res)

* Trim 5% for excl-res
xtile __p_ex18 = r_annual_excl_2018 if !missing(r_annual_excl_2018), n(100)
gen double r_annual_excl_trim_2018 = r_annual_excl_2018
replace r_annual_excl_trim_2018 = . if __p_ex18 <= 5 | __p_ex18 > 95
drop __p_ex18

di as txt "[summarize] r_period_2018_excl_res, r_annual_excl_2018, r_annual_excl_trim_2018"
summarize r_period_2018_excl_res r_annual_excl_2018 r_annual_excl_trim_2018

* ---------------------------------------------------------------------
* Prepare 2016 controls inline (married_2016, wealth_*_2016, age_2016, inlbrf_2016)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2016 controls (inline) ==="

* Marital status (2016): r13mstat -> married_2016
capture confirm variable r13mstat
if _rc {
    di as error "ERROR: r13mstat not found"
    exit 198
}
capture drop married_2016
gen byte married_2016 = .
replace married_2016 = 1 if inlist(r13mstat, 1, 2)
replace married_2016 = 0 if inlist(r13mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2016 yesno
label var married_2016 "Married (r13mstat: 1 or 2) vs not married (3-8)"
di as txt "Marital status (2016) summary:"
tab married_2016, missing

* Wealth percentile/deciles for 2016 using h13atotb
capture confirm variable h13atotb
if _rc {
    di as error "ERROR: h13atotb not found"
    exit 198
}
capture drop wealth_rank_2016 wealth_pct_2016
quietly count if !missing(h13atotb)
local N_wealth16 = r(N)
egen double wealth_rank_2016 = rank(h13atotb) if !missing(h13atotb)
gen double wealth_pct_2016 = .
replace wealth_pct_2016 = 100 * (wealth_rank_2016 - 1) / (`N_wealth16' - 1) if `N_wealth16' > 1 & !missing(wealth_rank_2016)
replace wealth_pct_2016 = 50 if `N_wealth16' == 1 & !missing(wealth_rank_2016)
label variable wealth_pct_2016 "Wealth percentile (based on h13atotb)"
di as txt "Wealth percentile (2016) summary:"
summarize wealth_pct_2016

capture drop wealth_decile_2016
xtile wealth_decile_2016 = h13atotb if !missing(h13atotb), n(10)
label var wealth_decile_2016 "Wealth decile (1=lowest,10=highest)"
di as txt "Wealth decile distribution (2016):"
tab wealth_decile_2016, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2016
    gen byte wealth_d`d'_2016 = wealth_decile_2016 == `d' if !missing(wealth_decile_2016)
    label values wealth_d`d'_2016 yesno
    label var wealth_d`d'_2016 "Wealth decile `d' (2016)"
}

* Age (2016): carry r13agey_b to age_2016 for consistency
capture confirm variable r13agey_b
if _rc {
    di as error "ERROR: r13agey_b not found"
    exit 198
}
capture drop age_2016
gen double age_2016 = r13agey_b
label var age_2016 "Respondent age in 2016 (r13agey_b)"
di as txt "Age (2016) summary:"
summarize age_2016

* Employment (2016): carry r13inlbrf to inlbrf_2016 for consistency
capture confirm variable r13inlbrf
if _rc {
    di as error "ERROR: r13inlbrf not found"
    exit 198
}
capture drop inlbrf_2016
clonevar inlbrf_2016 = r13inlbrf
label var inlbrf_2016 "Labor force status in 2016 (r13inlbrf)"
di as txt "Employment (2016) distribution:"
tab inlbrf_2016, missing

* Save back to unified analysis dataset
di as txt "=== Saving updated analysis dataset (with 2018 flows and returns) ==="

* Simple N diagnostics for included/excl-res returns (2022, 2020, and 2018)
di as txt "=== N diagnostics (included vs excl-res; 2022, 2020, and 2018) ==="
capture confirm variable r_period
if _rc di as txt "  Note: 2022 returns not in memory (run 2022 returns first if needed)"
quietly count if !missing(r_period)
di as txt "  2022 included:   N r_period = " %9.0f r(N)
quietly count if !missing(r_annual_2022)
di as txt "                    N r_annual_2022 = " %9.0f r(N)
quietly count if !missing(r_period_excl_res)
di as txt "  2022 excl-res:   N r_period_excl_res = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2022)
di as txt "                    N r_annual_excl_2022 = " %9.0f r(N)

* Both annual and trimmed available (2022 included/excl-res)
quietly count if !missing(r_annual_2022) & !missing(r_annual_trim_2022)
di as txt "  2022 included:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_trim_2022)
di as txt "  2022 excl-res:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)

quietly count if !missing(r_period_2020)
di as txt "  2020 included:   N r_period_2020 = " %9.0f r(N)
quietly count if !missing(r_annual_2020)
di as txt "                    N r_annual_2020 = " %9.0f r(N)
quietly count if !missing(r_period_2020_excl_res)
di as txt "  2020 excl-res:   N r_period_2020_excl_res = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2020)
di as txt "                    N r_annual_excl_2020 = " %9.0f r(N)

* Both annual and trimmed available (2020 included/excl-res)
quietly count if !missing(r_annual_2020) & !missing(r_annual_trim_2020)
di as txt "  2020 included:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2020) & !missing(r_annual_excl_trim_2020)
di as txt "  2020 excl-res:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)

quietly count if !missing(r_period_2018)
di as txt "  2018 included:   N r_period_2018 = " %9.0f r(N)
quietly count if !missing(r_annual_2018)
di as txt "                    N r_annual_2018 = " %9.0f r(N)
quietly count if !missing(r_period_2018_excl_res)
di as txt "  2018 excl-res:   N r_period_2018_excl_res = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2018)
di as txt "                    N r_annual_excl_2018 = " %9.0f r(N)

* Both annual and trimmed available (2018 included/excl-res)
quietly count if !missing(r_annual_2018) & !missing(r_annual_trim_2018)
di as txt "  2018 included:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)
quietly count if !missing(r_annual_excl_2018) & !missing(r_annual_excl_trim_2018)
di as txt "  2018 excl-res:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)

* Overlap analysis: how many obs have returns for all 3 years
di as txt "=== OVERLAP ANALYSIS: N observations with returns across years ==="

* All 3 years - included returns
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018)
di as txt "  All 3 years (included): " %9.0f r(N)

* All 3 years - included returns with trimming
quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018)
di as txt "  All 3 years (included, trimmed): " %9.0f r(N)

* All 3 years - excluded residential
quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018)
di as txt "  All 3 years (excl-res): " %9.0f r(N)

* All 3 years - excluded residential with trimming
quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018)
di as txt "  All 3 years (excl-res, trimmed): " %9.0f r(N)


save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close
