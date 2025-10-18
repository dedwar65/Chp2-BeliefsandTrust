*----------------------------------------------------------------------
* RAND_2004_merge_and_returns.do
* Merge 2004 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2004; mirrors 2006/2008/2010/... pipeline)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2004_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2004  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2004/h04f1c_STATA/h04f1c.dta"
local out_ana   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Load unified dataset and check key
* ---------------------------------------------------------------------
di as txt "=== Loading unified analysis dataset ==="
capture confirm file `"`long_file'"'
if _rc {
    di as error "ERROR: unified analysis dataset not found -> `long_file'"
    exit 198
}
use "`long_file'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in unified dataset"
    exit 198
}

* ---------------------------------------------------------------------
* Load 2004 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2004 RAND fat file ==="
preserve
capture confirm file `"`raw_2004'"'
if _rc {
    di as error "ERROR: RAW 2004 file not found -> `raw_2004'"
    exit 198
}
use "`raw_2004'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2004"
    exit 198
}

* 2004 flow variables per notes (JR* + JQ IRA triplet)
local flow04 "jr050 jr055 jr063 jr064 jr072 jr030 jr035 jr045 jq171_1 jq171_2 jq171_3 jr007 jr013 jr024"

di as txt "Checking presence of 2004 flow variables..."
foreach v of local flow04 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2004 RAW: `v'"
    else  di as txt  "  OK in 2004 RAW: `v'"
}

keep hhidpn `flow04'
tempfile raw04_flows
save "`raw04_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2004 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw04_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99
foreach v of local flow04 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2004 flow aggregates (suffix _2004)
* ---------------------------------------------------------------------
* jr063 direction and magnitude
capture drop jr063_dir04
gen byte jr063_dir04 = .
replace jr063_dir04 = -1 if jr063 == 1
replace jr063_dir04 =  1 if jr063 == 2
replace jr063_dir04 =  0 if jr063 == 3

capture drop flow_bus_2004
gen double flow_bus_2004 = .
replace flow_bus_2004 = jr055 - jr050 if !missing(jr055) & !missing(jr050)
replace flow_bus_2004 = jr055 if  missing(jr050) & !missing(jr055)
replace flow_bus_2004 = -jr050 if !missing(jr050) &  missing(jr055)

capture drop flow_stk_private_2004
gen double flow_stk_private_2004 = jr063_dir04 * jr064 if !missing(jr063_dir04) & !missing(jr064)

capture drop flow_stk_public_2004
gen double flow_stk_public_2004 = jr072 if !missing(jr072)

capture drop flow_stk_2004
gen double flow_stk_2004 = cond(!missing(flow_stk_private_2004), flow_stk_private_2004, 0) + ///
                           cond(!missing(flow_stk_public_2004),  flow_stk_public_2004,  0)
replace flow_stk_2004 = . if missing(flow_stk_private_2004) & missing(flow_stk_public_2004)

capture drop flow_re_2004
gen double flow_re_2004 = .
replace flow_re_2004 = cond(missing(jr035),0,jr035) - ( cond(missing(jr030),0,jr030) + cond(missing(jr045),0,jr045) ) if !missing(jr035) | !missing(jr030) | !missing(jr045)

capture drop flow_ira_2004
egen double flow_ira_2004 = rowtotal(jq171_1 jq171_2 jq171_3)
replace flow_ira_2004 = . if missing(jq171_1) & missing(jq171_2) & missing(jq171_3)

capture drop flow_residences_2004
gen double flow_residences_2004 = .
replace flow_residences_2004 = cond(missing(jr013),0,jr013) - ( cond(missing(jr007),0,jr007) + cond(missing(jr024),0,jr024) ) if !missing(jr013) | !missing(jr007) | !missing(jr024)
replace flow_residences_2004 = . if missing(jr013) & missing(jr007) & missing(jr024)

capture drop flow_total_2004
gen double flow_total_2004 = .
egen byte any_flow_present04 = rownonmiss(flow_bus_2004 flow_re_2004 flow_stk_2004 flow_ira_2004 flow_residences_2004)
replace flow_total_2004 = cond(missing(flow_bus_2004),0,flow_bus_2004) + ///
                          cond(missing(flow_re_2004),0,flow_re_2004) + ///
                          cond(missing(flow_stk_2004),0,flow_stk_2004) + ///
                          cond(missing(flow_ira_2004),0,flow_ira_2004) + ///
                          cond(missing(flow_residences_2004),0,flow_residences_2004) ///
                          if any_flow_present04 > 0
drop any_flow_present04

di as txt "Flows 2004 summaries:"
summarize flow_bus_2004 flow_re_2004 flow_stk_2004 flow_ira_2004 flow_residences_2004 flow_total_2004

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2004 (period 2002-2004)
* ---------------------------------------------------------------------
di as txt "=== Computing 2004 returns (2002-2004) ==="

* Denominator base: A_{2002}
capture drop a_2002
gen double a_2002 = h6atotb
label var a_2002 "Total net assets (A_2002 = h6atotb)"

* Capital income y^c_2004
capture drop y_c_2004
gen double y_c_2004 = h7icap
label var y_c_2004 "Capital income 2004 (h7icap)"

* Capital gains per class: cg_class = V_2004 - V_2002
capture drop cg_pri_res_2004 cg_sec_res_2004 cg_re_2004 cg_bus_2004 cg_ira_2004 cg_stk_2004 cg_bond_2004 cg_chck_2004 cg_cd_2004 cg_veh_2004 cg_oth_2004
gen double cg_pri_res_2004 = h7atoth - h6atoth
gen double cg_sec_res_2004 = h7anethb - h6anethb
gen double cg_re_2004      = h7arles - h6arles
gen double cg_bus_2004     = h7absns - h6absns
gen double cg_ira_2004     = h7aira  - h6aira
gen double cg_stk_2004     = h7astck - h6astck
gen double cg_bond_2004    = h7abond - h6abond
gen double cg_chck_2004    = h7achck - h6achck
gen double cg_cd_2004      = h7acd   - h6acd
gen double cg_veh_2004     = h7atran - h6atran
gen double cg_oth_2004     = h7aothr - h6aothr

di as txt "Capital gains components (2002->2004) summaries:"
summarize cg_pri_res_2004 cg_sec_res_2004 cg_re_2004 cg_bus_2004 cg_ira_2004 cg_stk_2004 cg_bond_2004 cg_chck_2004 cg_cd_2004 cg_veh_2004 cg_oth_2004

* Total capital gains with missing logic (missing only if all components missing)
capture drop cg_total_2004
egen byte any_cg_2004 = rownonmiss(cg_pri_res_2004 cg_sec_res_2004 cg_re_2004 cg_bus_2004 cg_ira_2004 cg_stk_2004 cg_bond_2004 cg_chck_2004 cg_cd_2004 cg_veh_2004 cg_oth_2004)
gen double cg_total_2004 = .
replace cg_total_2004 = cond(missing(cg_pri_res_2004),0,cg_pri_res_2004) + ///
                        cond(missing(cg_sec_res_2004),0,cg_sec_res_2004) + ///
                        cond(missing(cg_re_2004),0,cg_re_2004) + ///
                        cond(missing(cg_bus_2004),0,cg_bus_2004) + ///
                        cond(missing(cg_ira_2004),0,cg_ira_2004) + ///
                        cond(missing(cg_stk_2004),0,cg_stk_2004) + ///
                        cond(missing(cg_bond_2004),0,cg_bond_2004) + ///
                        cond(missing(cg_chck_2004),0,cg_chck_2004) + ///
                        cond(missing(cg_cd_2004),0,cg_cd_2004) + ///
                        cond(missing(cg_veh_2004),0,cg_veh_2004) + ///
                        cond(missing(cg_oth_2004),0,cg_oth_2004) if any_cg_2004>0
drop any_cg_2004

di as txt "[summarize] y_c_2004, cg_total_2004, flow_total_2004"
summarize y_c_2004 cg_total_2004 flow_total_2004

* Base: A_2002 + 0.5 * F_2004 (treat flows as 0 only when A_2002 is non-missing)
capture drop base_2004
gen double base_2004 = .
replace base_2004 = a_2002 + 0.5 * cond(missing(flow_total_2004),0,flow_total_2004) if !missing(a_2002)
label var base_2004 "Base for 2004 returns (A_2002 + 0.5*F_2004)"

di as txt "[summarize] base_2004"
summarize base_2004, detail

* Period return and annualization (2-year)
capture drop num_period_2004 r_period_2004 r_annual_2004 r_annual_trim_2004
gen double num_period_2004 = cond(missing(y_c_2004),0,y_c_2004) + ///
                             cond(missing(cg_total_2004),0,cg_total_2004) - ///
                             cond(missing(flow_total_2004),0,flow_total_2004)
egen byte __num04_has = rownonmiss(y_c_2004 cg_total_2004 flow_total_2004)
replace num_period_2004 = . if __num04_has == 0
drop __num04_has

gen double r_period_2004 = num_period_2004 / base_2004
replace r_period_2004 = . if base_2004 < 10000

gen double r_annual_2004 = (1 + r_period_2004)^(1/2) - 1
replace r_annual_2004 = . if missing(r_period_2004)

* Trim 5% tails
capture drop r_annual_trim_2004
xtile __p_2004 = r_annual_2004 if !missing(r_annual_2004), n(100)
gen double r_annual_trim_2004 = r_annual_2004
replace r_annual_trim_2004 = . if __p_2004 <= 5 | __p_2004 > 95
drop __p_2004

di as txt "[summarize] r_period_2004, r_annual_2004, r_annual_trim_2004"
summarize r_period_2004 r_annual_2004 r_annual_trim_2004

* Excluding residential housing
capture drop cg_total_2004_excl_res flow_total_2004_excl_res
gen double flow_total_2004_excl_res = .
egen byte any_flow04_excl = rownonmiss(flow_bus_2004 flow_re_2004 flow_stk_2004 flow_ira_2004)
replace flow_total_2004_excl_res = cond(missing(flow_bus_2004),0,flow_bus_2004) + ///
                                   cond(missing(flow_re_2004),0,flow_re_2004) + ///
                                   cond(missing(flow_stk_2004),0,flow_stk_2004) + ///
                                   cond(missing(flow_ira_2004),0,flow_ira_2004) if any_flow04_excl>0
drop any_flow04_excl

gen double cg_total_2004_excl_res = .
egen byte any_cg04_excl = rownonmiss(cg_re_2004 cg_bus_2004 cg_ira_2004 cg_stk_2004 cg_bond_2004 cg_chck_2004 cg_cd_2004 cg_veh_2004 cg_oth_2004)
replace cg_total_2004_excl_res = cond(missing(cg_re_2004),0,cg_re_2004) + ///
                                 cond(missing(cg_bus_2004),0,cg_bus_2004) + ///
                                 cond(missing(cg_ira_2004),0,cg_ira_2004) + ///
                                 cond(missing(cg_stk_2004),0,cg_stk_2004) + ///
                                 cond(missing(cg_bond_2004),0,cg_bond_2004) + ///
                                 cond(missing(cg_chck_2004),0,cg_chck_2004) + ///
                                 cond(missing(cg_cd_2004),0,cg_cd_2004) + ///
                                 cond(missing(cg_veh_2004),0,cg_veh_2004) + ///
                                 cond(missing(cg_oth_2004),0,cg_oth_2004) if any_cg04_excl>0
drop any_cg04_excl

di as txt "EXCL-RES: cg_total_2004_excl_res and flow_total_2004_excl_res summaries:"
summarize cg_total_2004_excl_res flow_total_2004_excl_res

* Use SAME base_2004
capture drop num_period_2004_excl_res r_period_2004_excl_res r_annual_excl_2004 r_annual_excl_trim_2004
gen double num_period_2004_excl_res = cond(missing(y_c_2004),0,y_c_2004) + ///
                                      cond(missing(cg_total_2004_excl_res),0,cg_total_2004_excl_res) - ///
                                      cond(missing(flow_total_2004_excl_res),0,flow_total_2004_excl_res)
egen byte __num04ex_has = rownonmiss(y_c_2004 cg_total_2004_excl_res flow_total_2004_excl_res)
replace num_period_2004_excl_res = . if __num04ex_has == 0
drop __num04ex_has

gen double r_period_2004_excl_res = num_period_2004_excl_res / base_2004
replace r_period_2004_excl_res = . if base_2004 < 10000
gen double r_annual_excl_2004 = (1 + r_period_2004_excl_res)^(1/2) - 1
replace r_annual_excl_2004 = . if missing(r_period_2004_excl_res)

* Trim 5% for excl-res
xtile __p_ex04 = r_annual_excl_2004 if !missing(r_annual_excl_2004), n(100)
gen double r_annual_excl_trim_2004 = r_annual_excl_2004
replace r_annual_excl_trim_2004 = . if __p_ex04 <= 5 | __p_ex04 > 95
drop __p_ex04

di as txt "[summarize] r_period_2004_excl_res, r_annual_excl_2004, r_annual_excl_trim_2004"
summarize r_period_2004_excl_res r_annual_excl_2004 r_annual_excl_trim_2004

* ---------------------------------------------------------------------
* Prepare 2002 controls inline (married_2002, wealth_*_2002, age_2002, inlbrf_2002)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2002 controls (inline) ==="

* Marital status (2002): r6mstat -> married_2002
capture confirm variable r6mstat
if _rc {
    di as error "ERROR: r6mstat not found"
    exit 198
}

capture drop married_2002
gen byte married_2002 = .
replace married_2002 = 1 if inlist(r6mstat, 1, 2)
replace married_2002 = 0 if inlist(r6mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2002 yesno
label var married_2002 "Married (r6mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2002) summary:"
tab married_2002, missing

* Wealth percentile/deciles for 2002 using h6atotb
capture confirm variable h6atotb
if _rc {
    di as error "ERROR: h6atotb not found"
    exit 198
}

capture drop wealth_rank_2002 wealth_pct_2002
quietly count if !missing(h6atotb)
local N_wealth02 = r(N)
egen double wealth_rank_2002 = rank(h6atotb) if !missing(h6atotb)
gen double wealth_pct_2002 = .
replace wealth_pct_2002 = 100 * (wealth_rank_2002 - 1) / (`N_wealth02' - 1) if `N_wealth02' > 1 & !missing(wealth_rank_2002)
replace wealth_pct_2002 = 50 if `N_wealth02' == 1 & !missing(wealth_rank_2002)
label variable wealth_pct_2002 "Wealth percentile (based on h6atotb)"

di as txt "Wealth percentile (2002) summary:"
summarize wealth_pct_2002

capture drop wealth_decile_2002
xtile wealth_decile_2002 = h6atotb if !missing(h6atotb), n(10)
label var wealth_decile_2002 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2002):"
tab wealth_decile_2002, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2002
    gen byte wealth_d`d'_2002 = wealth_decile_2002 == `d' if !missing(wealth_decile_2002)
    label values wealth_d`d'_2002 yesno
    label var wealth_d`d'_2002 "Wealth decile `d' (2002)"
}

* Age (2002): r6agey_b -> age_2002
capture confirm variable r6agey_b
if _rc {
    di as error "ERROR: r6agey_b not found"
    exit 198
}

capture drop age_2002
gen double age_2002 = r6agey_b
label var age_2002 "Respondent age in 2002 (r6agey_b)"

di as txt "Age (2002) summary:"
summarize age_2002

* Employment (2002): r6inlbrf -> inlbrf_2002
capture confirm variable r6inlbrf
if _rc {
    di as error "ERROR: r6inlbrf not found"
    exit 198
}

capture drop inlbrf_2002
clonevar inlbrf_2002 = r6inlbrf
label var inlbrf_2002 "Labor force status in 2002 (r6inlbrf)"

di as txt "Employment (2002) distribution:"
tab inlbrf_2002, missing

* ---------------------------------------------------------------------
* Save back and print only overlap counts for all 10 years
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset (with 2004 flows and returns) ==="

* Overlap only: All 10-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010) & !missing(r_annual_2008) & !missing(r_annual_2006) & !missing(r_annual_2004)
di as txt "  All 10 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010) & !missing(r_annual_excl_2008) & !missing(r_annual_excl_2006) & !missing(r_annual_excl_2004)
di as txt "  All 10 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010) & !missing(r_annual_trim_2008) & !missing(r_annual_trim_2006) & !missing(r_annual_trim_2004)
di as txt "  All 10 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010) & !missing(r_annual_excl_trim_2008) & !missing(r_annual_excl_trim_2006) & !missing(r_annual_excl_trim_2004)
di as txt "  All 10 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


