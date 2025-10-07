*----------------------------------------------------------------------
* RAND_2020_merge_and_returns.do
* Merge 2020 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2020; mirrors 2022 pipeline with 2020 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2020_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
* Start from the unified analysis dataset so previously saved variables (e.g., 2022 flows)
* are preserved and augmented with 2020 flows
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2020  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2020/h20f1a_STATA/h20f1a.dta"
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
* Merge in 2020 flows from raw RAND file
* (Variable names should match 2020 wave; adjust if needed per notes)
* ---------------------------------------------------------------------
di as txt "=== Loading 2020 RAND raw file ==="
preserve
capture confirm file "`raw_2020'"
if _rc {
    di as error "ERROR: RAW 2020 file not found -> `raw_2020'"
    exit 198
}
use "`raw_2020'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2020"
    exit 198
}

* TODO: Replace the placeholder list below with exact 2020 flow variables per Notes/2020_returns_HRS_long.md
local flow20 "rr050 rr055 rr063 rr064 rr073 rr030 rr035 rr045 rq171_1 rq171_2 rq171_3 rr007 rr013 rr024"

di as txt "Checking presence of 2020 flow variables..."
foreach v of local flow20 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2020 RAW: `v'"
    else  di as txt  "  OK in 2020 RAW: `v'"
}

keep hhidpn `flow20'
tempfile raw20_flows
save "`raw20_flows'", replace
restore

di as txt "=== Merging 2020 flows into longitudinal baseline ==="
merge 1:1 hhidpn using "`raw20_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (mirror 2022 cleaning rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of local flow20 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2020 flow aggregates (naming parallels 2022, with _2020)
* ---------------------------------------------------------------------
* sr063 direction and magnitude
capture drop rr063_dir20
gen byte rr063_dir20 = .
replace rr063_dir20 = -1 if rr063 == 1
replace rr063_dir20 =  1 if rr063 == 2
replace rr063_dir20 =  0 if rr063 == 3

capture drop flow_bus_2020
gen double flow_bus_2020 = .
replace flow_bus_2020 = rr055 - rr050 if !missing(rr055) & !missing(rr050)
replace flow_bus_2020 = rr055 if  missing(rr050) & !missing(rr055)
replace flow_bus_2020 = -rr050 if !missing(rr050) &  missing(rr055)

capture drop flow_stk_private_2020
gen double flow_stk_private_2020 = rr063_dir20 * rr064 if !missing(rr063_dir20) & !missing(rr064)

capture drop flow_stk_public_2020
gen double flow_stk_public_2020 = rr073 if !missing(rr073)

capture drop flow_stk_2020
gen double flow_stk_2020 = cond(!missing(flow_stk_private_2020), flow_stk_private_2020, 0) + ///
                           cond(!missing(flow_stk_public_2020),  flow_stk_public_2020,  0)
replace flow_stk_2020 = . if missing(flow_stk_private_2020) & missing(flow_stk_public_2020)

capture drop flow_re_2020
gen double flow_re_2020 = .
replace flow_re_2020 = cond(missing(rr035),0,rr035) - ( cond(missing(rr030),0,rr030) + cond(missing(rr045),0,rr045) ) if !missing(rr035) | !missing(rr030) | !missing(rr045)

capture drop flow_ira_2020
egen double flow_ira_2020 = rowtotal(rq171_1 rq171_2 rq171_3)
replace flow_ira_2020 = . if missing(rq171_1) & missing(rq171_2) & missing(rq171_3)

capture drop flow_residences_2020
gen double flow_residences_2020 = .
replace flow_residences_2020 = cond(missing(rr013),0,rr013) - ( cond(missing(rr007),0,rr007) + cond(missing(rr024),0,rr024) ) if !missing(rr013) | !missing(rr007) | !missing(rr024)
replace flow_residences_2020 = . if missing(rr013) & missing(rr007) & missing(rr024)

capture drop flow_total_2020
gen double flow_total_2020 = .
egen byte any_flow_present20 = rownonmiss(flow_bus_2020 flow_re_2020 flow_stk_2020 flow_ira_2020 flow_residences_2020)
replace flow_total_2020 = cond(missing(flow_bus_2020),0,flow_bus_2020) + ///
                          cond(missing(flow_re_2020),0,flow_re_2020) + ///
                          cond(missing(flow_stk_2020),0,flow_stk_2020) + ///
                          cond(missing(flow_ira_2020),0,flow_ira_2020) + ///
                          cond(missing(flow_residences_2020),0,flow_residences_2020) ///
                          if any_flow_present20 > 0
drop any_flow_present20

di as txt "Flows 2020 summaries:"
summarize flow_bus_2020 flow_re_2020 flow_stk_2020 flow_ira_2020 flow_residences_2020 flow_total_2020

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2020 (period 2018-2020)
* Mirrors compute_tot_ret_2022.do with 2018/2020 variables
* ---------------------------------------------------------------------
di as txt "=== Computing 2020 returns (2018-2020) ==="

* Denominator base: A_{2018}
capture drop a_2018
gen double a_2018 = h14atotb
label var a_2018 "Total net assets (A_2018 = h14atotb)"

* Capital income y^c_2020
capture drop y_c_2020
gen double y_c_2020 = h15icap
label var y_c_2020 "Capital income 2020 (h15icap)"

* Capital gains per class: cg_class = V_2020 - V_2018
capture drop cg_pri_res_2020 cg_sec_res_2020 cg_re_2020 cg_bus_2020 cg_ira_2020 cg_stk_2020 cg_bond_2020 cg_chck_2020 cg_cd_2020 cg_veh_2020 cg_oth_2020
gen double cg_pri_res_2020 = h15atoth - h14atoth
gen double cg_sec_res_2020 = h15anethb - h14anethb
gen double cg_re_2020      = h15arles - h14arles
gen double cg_bus_2020     = h15absns - h14absns
gen double cg_ira_2020     = h15aira  - h14aira
gen double cg_stk_2020     = h15astck - h14astck
gen double cg_bond_2020    = h15abond - h14abond
gen double cg_chck_2020    = h15achck - h14achck
gen double cg_cd_2020      = h15acd   - h14acd
gen double cg_veh_2020     = h15atran - h14atran
gen double cg_oth_2020     = h15aothr - h14aothr

* Summaries of each capital gains component
di as txt "Capital gains components (2018->2020) summaries:"
summarize cg_pri_res_2020 cg_sec_res_2020 cg_re_2020 cg_bus_2020 cg_ira_2020 cg_stk_2020 cg_bond_2020 cg_chck_2020 cg_cd_2020 cg_veh_2020 cg_oth_2020

* Total capital gains with missing logic: missing only if all components missing
capture drop cg_total_2020
egen byte any_cg_2020 = rownonmiss(cg_pri_res_2020 cg_sec_res_2020 cg_re_2020 cg_bus_2020 cg_ira_2020 cg_stk_2020 cg_bond_2020 cg_chck_2020 cg_cd_2020 cg_veh_2020 cg_oth_2020)
gen double cg_total_2020 = .
replace cg_total_2020 = cond(missing(cg_pri_res_2020),0,cg_pri_res_2020) + ///
                        cond(missing(cg_sec_res_2020),0,cg_sec_res_2020) + ///
                        cond(missing(cg_re_2020),0,cg_re_2020) + ///
                        cond(missing(cg_bus_2020),0,cg_bus_2020) + ///
                        cond(missing(cg_ira_2020),0,cg_ira_2020) + ///
                        cond(missing(cg_stk_2020),0,cg_stk_2020) + ///
                        cond(missing(cg_bond_2020),0,cg_bond_2020) + ///
                        cond(missing(cg_chck_2020),0,cg_chck_2020) + ///
                        cond(missing(cg_cd_2020),0,cg_cd_2020) + ///
                        cond(missing(cg_veh_2020),0,cg_veh_2020) + ///
                        cond(missing(cg_oth_2020),0,cg_oth_2020) if any_cg_2020>0
drop any_cg_2020

* Use cg_total_2020 and flow_total_2020 directly in formulas below

* Diagnostics
di as txt "[summarize] y_c_2020, cg_total_2020, flow_total_2020"
summarize y_c_2020 cg_total_2020 flow_total_2020

* Base: A_2018 + 0.5 * F_2020 (treat flows as 0 only when A_2018 is non-missing)
capture drop base_2020
gen double base_2020 = .
replace base_2020 = a_2018 + 0.5 * cond(missing(flow_total_2020),0,flow_total_2020) if !missing(a_2018)
label var base_2020 "Base for 2020 returns (A_2018 + 0.5*F_2020)"
di as txt "[summarize] base_2020"
summarize base_2020, detail

* Period return and annualization (2-year)
capture drop num_period_2020 r_period_2020 r_annual_2020 r_annual_2020_trim
gen double num_period_2020 = cond(missing(y_c_2020),0,y_c_2020) + ///
                             cond(missing(cg_total_2020),0,cg_total_2020) - ///
                             cond(missing(flow_total_2020),0,flow_total_2020)
egen byte __num20_has = rownonmiss(y_c_2020 cg_total_2020 flow_total_2020)
replace num_period_2020 = . if __num20_has == 0
drop __num20_has
gen double r_period_2020 = num_period_2020 / base_2020
replace r_period_2020 = . if base_2020 < 10000
gen double r_annual_2020 = (1 + r_period_2020)^(1/2) - 1
replace r_annual_2020 = . if missing(r_period_2020)

* Trim 5% tails
capture drop r_annual_2020_trim
xtile __p_2020 = r_annual_2020 if !missing(r_annual_2020), n(100)
gen double r_annual_2020_trim = r_annual_2020
replace r_annual_2020_trim = . if __p_2020 <= 5 | __p_2020 > 95
drop __p_2020

di as txt "[summarize] r_period_2020, r_annual_2020, r_annual_2020_trim"
summarize r_period_2020 r_annual_2020 r_annual_2020_trim

* Excluding residential housing (remove primary and secondary residence from cg and flows)
capture drop cg_total_2020_excl_res cg_total_2020_excl_res_safe flow_total_2020_excl_res flow_total_2020_excl_res_safe
gen double flow_total_2020_excl_res = .
egen byte any_flow20_excl = rownonmiss(flow_bus_2020 flow_re_2020 flow_stk_2020 flow_ira_2020)  // exclude residences
replace flow_total_2020_excl_res = cond(missing(flow_bus_2020),0,flow_bus_2020) + ///
                                   cond(missing(flow_re_2020),0,flow_re_2020) + ///
                                   cond(missing(flow_stk_2020),0,flow_stk_2020) + ///
                                   cond(missing(flow_ira_2020),0,flow_ira_2020) if any_flow20_excl>0
drop any_flow20_excl
* No separate safe variable; use inline handling below

gen double cg_total_2020_excl_res = .
egen byte any_cg20_excl = rownonmiss(cg_re_2020 cg_bus_2020 cg_ira_2020 cg_stk_2020 cg_bond_2020 cg_chck_2020 cg_cd_2020 cg_veh_2020 cg_oth_2020)
replace cg_total_2020_excl_res = cond(missing(cg_re_2020),0,cg_re_2020) + ///
                                 cond(missing(cg_bus_2020),0,cg_bus_2020) + ///
                                 cond(missing(cg_ira_2020),0,cg_ira_2020) + ///
                                 cond(missing(cg_stk_2020),0,cg_stk_2020) + ///
                                 cond(missing(cg_bond_2020),0,cg_bond_2020) + ///
                                 cond(missing(cg_chck_2020),0,cg_chck_2020) + ///
                                 cond(missing(cg_cd_2020),0,cg_cd_2020) + ///
                                 cond(missing(cg_veh_2020),0,cg_veh_2020) + ///
                                 cond(missing(cg_oth_2020),0,cg_oth_2020) if any_cg20_excl>0
drop any_cg20_excl
* No separate safe variable; use inline handling below

di as txt "EXCL-RES: cg_total_2020_excl_res and flow_total_2020_excl_res summaries:"
summarize cg_total_2020_excl_res flow_total_2020_excl_res

* Use SAME base_2020
capture drop num_period_2020_excl_res r_period_2020_excl_res r_annual_2020_excl_res r_annual_2020_excl_res_trim
gen double num_period_2020_excl_res = cond(missing(y_c_2020),0,y_c_2020) + ///
                                      cond(missing(cg_total_2020_excl_res),0,cg_total_2020_excl_res) - ///
                                      cond(missing(flow_total_2020_excl_res),0,flow_total_2020_excl_res)
egen byte __num20ex_has = rownonmiss(y_c_2020 cg_total_2020_excl_res flow_total_2020_excl_res)
replace num_period_2020_excl_res = . if __num20ex_has == 0
drop __num20ex_has
gen double r_period_2020_excl_res = num_period_2020_excl_res / base_2020
replace r_period_2020_excl_res = . if base_2020 < 10000
gen double r_annual_2020_excl_res = (1 + r_period_2020_excl_res)^(1/2) - 1
replace r_annual_2020_excl_res = . if missing(r_period_2020_excl_res)

* Trim 5% for excl-res
xtile __p_ex20 = r_annual_2020_excl_res if !missing(r_annual_2020_excl_res), n(100)
gen double r_annual_2020_excl_res_trim = r_annual_2020_excl_res
replace r_annual_2020_excl_res_trim = . if __p_ex20 <= 5 | __p_ex20 > 95
drop __p_ex20

di as txt "[summarize] r_period_2020_excl_res, r_annual_2020_excl_res, r_annual_2020_excl_res_trim"
summarize r_period_2020_excl_res r_annual_2020_excl_res r_annual_2020_excl_res_trim

* ---------------------------------------------------------------------
* Prepare 2018 controls inline (married_2018, born_us_2018, wealth_*_2018)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2018 controls (inline) ==="

* Marital status (2018): r14mstat -> married_2018
capture confirm variable r14mstat
if _rc {
    di as error "ERROR: r14mstat not found"
    exit 198
}
capture drop married_2018
gen byte married_2018 = .
replace married_2018 = 1 if inlist(r14mstat, 1, 2)
replace married_2018 = 0 if inlist(r14mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2018 yesno
label var married_2018 "Married (r14mstat: 1 or 2) vs not married (3-8)"
di as txt "Marital status (2018) summary:"
tab married_2018, missing

* Wealth percentile/deciles for 2018 using h14atotb
capture confirm variable h14atotb
if _rc {
    di as error "ERROR: h14atotb not found"
    exit 198
}
capture drop wealth_rank_2018 wealth_pct_2018
quietly count if !missing(h14atotb)
local N_wealth18 = r(N)
egen double wealth_rank_2018 = rank(h14atotb) if !missing(h14atotb)
gen double wealth_pct_2018 = .
replace wealth_pct_2018 = 100 * (wealth_rank_2018 - 1) / (`N_wealth18' - 1) if `N_wealth18' > 1 & !missing(wealth_rank_2018)
replace wealth_pct_2018 = 50 if `N_wealth18' == 1 & !missing(wealth_rank_2018)
label variable wealth_pct_2018 "Wealth percentile (based on h14atotb)"
di as txt "Wealth percentile (2018) summary:"
summarize wealth_pct_2018

capture drop wealth_decile_2018
xtile wealth_decile_2018 = h14atotb if !missing(h14atotb), n(10)
label var wealth_decile_2018 "Wealth decile (1=lowest,10=highest)"
di as txt "Wealth decile distribution (2018):"
tab wealth_decile_2018, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2018
    gen byte wealth_d`d'_2018 = wealth_decile_2018 == `d' if !missing(wealth_decile_2018)
    label values wealth_d`d'_2018 yesno
    label var wealth_d`d'_2018 "Wealth decile `d' (2018)"
}

* Age (2018): carry r14agey_b to age_2018 for consistency
capture confirm variable r14agey_b
if _rc {
    di as error "ERROR: r14agey_b not found"
    exit 198
}
capture drop age_2018
gen double age_2018 = r14agey_b
label var age_2018 "Respondent age in 2018 (r14agey_b)"
di as txt "Age (2018) summary:"
summarize age_2018

* Employment (2018): carry r14inlbrf to inlbrf_2018 for consistency
capture confirm variable r14inlbrf
if _rc {
    di as error "ERROR: r14inlbrf not found"
    exit 198
}
capture drop inlbrf_2018
clonevar inlbrf_2018 = r14inlbrf
label var inlbrf_2018 "Labor force status in 2018 (r14inlbrf)"
di as txt "Employment (2018) distribution:"
tab inlbrf_2018, missing

* Save back to unified analysis dataset
di as txt "=== Saving updated analysis dataset (with 2020 flows and returns) ==="

* Simple N diagnostics for included/excl-res returns (2022 and 2020)
di as txt "=== N diagnostics (included vs excl-res; 2022 and 2020) ==="
capture confirm variable r_period
if _rc di as txt "  Note: 2022 returns not in memory (run 2022 returns first if needed)"
quietly count if !missing(r_period)
di as txt "  2022 included:   N r_period = " %9.0f r(N)
quietly count if !missing(r_annual_2022)
di as txt "                    N r_annual_2022 = " %9.0f r(N)
quietly count if !missing(r_period_excl_res)
di as txt "  2022 excl-res:   N r_period_excl_res = " %9.0f r(N)
quietly count if !missing(r_annual_2022_excl_res)
di as txt "                    N r_annual_2022_excl_res = " %9.0f r(N)

* Both annual and trimmed available (2022 included/excl-res)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2022_trimmed)
di as txt "  2022 included:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)
quietly count if !missing(r_annual_2022_excl_res) & !missing(r_annual_2022_excl_res_trim)
di as txt "  2022 excl-res:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)

quietly count if !missing(r_period_2020)
di as txt "  2020 included:   N r_period_2020 = " %9.0f r(N)
quietly count if !missing(r_annual_2020)
di as txt "                    N r_annual_2020 = " %9.0f r(N)
quietly count if !missing(r_period_2020_excl_res)
di as txt "  2020 excl-res:   N r_period_2020_excl_res = " %9.0f r(N)
quietly count if !missing(r_annual_2020_excl_res)
di as txt "                    N r_annual_2020_excl_res = " %9.0f r(N)

* Both annual and trimmed available (2020 included/excl-res)
quietly count if !missing(r_annual_2020) & !missing(r_annual_2020_trim)
di as txt "  2020 included:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)
quietly count if !missing(r_annual_2020_excl_res) & !missing(r_annual_2020_excl_res_trim)
di as txt "  2020 excl-res:   N with BOTH r_annual & r_annual_trim = " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close

