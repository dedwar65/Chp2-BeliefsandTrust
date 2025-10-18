*----------------------------------------------------------------------
* RAND_2002_merge_and_returns.do
* Merge 2002 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2002; mirrors 2004/2006/... pipeline)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2002_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2002  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2002/h02f2c_STATA/h02f2c.dta"
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
* Load 2002 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2002 RAND fat file ==="
preserve
capture confirm file `"`raw_2002'"'
if _rc {
    di as error "ERROR: RAW 2002 file not found -> `raw_2002'"
    exit 198
}
use "`raw_2002'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2002"
    exit 198
}

* 2002 flow variables per notes (HR* + HQ IRA triplet)
local flow02 "hr050 hr055 hr063 hr064 hr072 hr030 hr035 hr045 hq171_1 hq171_2 hq171_3 hr007 hr013 hr024"

di as txt "Checking presence of 2002 flow variables..."
foreach v of local flow02 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2002 RAW: `v'"
    else  di as txt  "  OK in 2002 RAW: `v'"
}

keep hhidpn `flow02'
tempfile raw02_flows
save "`raw02_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2002 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw02_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99
foreach v of local flow02 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2002 flow aggregates (suffix _2002)
* ---------------------------------------------------------------------
* hr063 direction and magnitude
capture drop hr063_dir02
gen byte hr063_dir02 = .
replace hr063_dir02 = -1 if hr063 == 1
replace hr063_dir02 =  1 if hr063 == 2
replace hr063_dir02 =  0 if hr063 == 3

capture drop flow_bus_2002
gen double flow_bus_2002 = .
replace flow_bus_2002 = hr055 - hr050 if !missing(hr055) & !missing(hr050)
replace flow_bus_2002 = hr055 if  missing(hr050) & !missing(hr055)
replace flow_bus_2002 = -hr050 if !missing(hr050) &  missing(hr055)

capture drop flow_stk_private_2002
gen double flow_stk_private_2002 = hr063_dir02 * hr064 if !missing(hr063_dir02) & !missing(hr064)

capture drop flow_stk_public_2002
gen double flow_stk_public_2002 = hr072 if !missing(hr072)

capture drop flow_stk_2002
gen double flow_stk_2002 = cond(!missing(flow_stk_private_2002), flow_stk_private_2002, 0) + ///
                           cond(!missing(flow_stk_public_2002),  flow_stk_public_2002,  0)
replace flow_stk_2002 = . if missing(flow_stk_private_2002) & missing(flow_stk_public_2002)

capture drop flow_re_2002
gen double flow_re_2002 = .
replace flow_re_2002 = cond(missing(hr035),0,hr035) - ( cond(missing(hr030),0,hr030) + cond(missing(hr045),0,hr045) ) if !missing(hr035) | !missing(hr030) | !missing(hr045)

capture drop flow_ira_2002
egen double flow_ira_2002 = rowtotal(hq171_1 hq171_2 hq171_3)
replace flow_ira_2002 = . if missing(hq171_1) & missing(hq171_2) & missing(hq171_3)

capture drop flow_residences_2002
gen double flow_residences_2002 = .
replace flow_residences_2002 = cond(missing(hr013),0,hr013) - ( cond(missing(hr007),0,hr007) + cond(missing(hr024),0,hr024) ) if !missing(hr013) | !missing(hr007) | !missing(hr024)
replace flow_residences_2002 = . if missing(hr013) & missing(hr007) & missing(hr024)

capture drop flow_total_2002
gen double flow_total_2002 = .
egen byte any_flow_present02 = rownonmiss(flow_bus_2002 flow_re_2002 flow_stk_2002 flow_ira_2002 flow_residences_2002)
replace flow_total_2002 = cond(missing(flow_bus_2002),0,flow_bus_2002) + ///
                          cond(missing(flow_re_2002),0,flow_re_2002) + ///
                          cond(missing(flow_stk_2002),0,flow_stk_2002) + ///
                          cond(missing(flow_ira_2002),0,flow_ira_2002) + ///
                          cond(missing(flow_residences_2002),0,flow_residences_2002) ///
                          if any_flow_present02 > 0
drop any_flow_present02

di as txt "Flows 2002 summaries:"
summarize flow_bus_2002 flow_re_2002 flow_stk_2002 flow_ira_2002 flow_residences_2002 flow_total_2002

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2002 (period 2000-2002)
* ---------------------------------------------------------------------
di as txt "=== Computing 2002 returns (2000-2002) ==="

* Denominator base: A_{2000}
capture drop a_2000
gen double a_2000 = h5atotb
label var a_2000 "Total net assets (A_2000 = h5atotb)"

* Capital income y^c_2002
capture drop y_c_2002
gen double y_c_2002 = h6icap
label var y_c_2002 "Capital income 2002 (h6icap)"

* Capital gains per class: cg_class = V_2002 - V_2000
capture drop cg_pri_res_2002 cg_sec_res_2002 cg_re_2002 cg_bus_2002 cg_ira_2002 cg_stk_2002 cg_bond_2002 cg_chck_2002 cg_cd_2002 cg_veh_2002 cg_oth_2002
gen double cg_pri_res_2002 = h6atoth - h5atoth
gen double cg_sec_res_2002 = h6anethb - h5anethb
gen double cg_re_2002      = h6arles - h5arles
gen double cg_bus_2002     = h6absns - h5absns
gen double cg_ira_2002     = h6aira  - h5aira
gen double cg_stk_2002     = h6astck - h5astck
gen double cg_bond_2002    = h6abond - h5abond
gen double cg_chck_2002    = h6achck - h5achck
gen double cg_cd_2002      = h6acd   - h5acd
gen double cg_veh_2002     = h6atran - h5atran
gen double cg_oth_2002     = h6aothr - h5aothr

di as txt "Capital gains components (2000->2002) summaries:"
summarize cg_pri_res_2002 cg_sec_res_2002 cg_re_2002 cg_bus_2002 cg_ira_2002 cg_stk_2002 cg_bond_2002 cg_chck_2002 cg_cd_2002 cg_veh_2002 cg_oth_2002

* Total capital gains with missing logic (missing only if all components missing)
capture drop cg_total_2002
egen byte any_cg_2002 = rownonmiss(cg_pri_res_2002 cg_sec_res_2002 cg_re_2002 cg_bus_2002 cg_ira_2002 cg_stk_2002 cg_bond_2002 cg_chck_2002 cg_cd_2002 cg_veh_2002 cg_oth_2002)
gen double cg_total_2002 = .
replace cg_total_2002 = cond(missing(cg_pri_res_2002),0,cg_pri_res_2002) + ///
                        cond(missing(cg_sec_res_2002),0,cg_sec_res_2002) + ///
                        cond(missing(cg_re_2002),0,cg_re_2002) + ///
                        cond(missing(cg_bus_2002),0,cg_bus_2002) + ///
                        cond(missing(cg_ira_2002),0,cg_ira_2002) + ///
                        cond(missing(cg_stk_2002),0,cg_stk_2002) + ///
                        cond(missing(cg_bond_2002),0,cg_bond_2002) + ///
                        cond(missing(cg_chck_2002),0,cg_chck_2002) + ///
                        cond(missing(cg_cd_2002),0,cg_cd_2002) + ///
                        cond(missing(cg_veh_2002),0,cg_veh_2002) + ///
                        cond(missing(cg_oth_2002),0,cg_oth_2002) if any_cg_2002>0
drop any_cg_2002

di as txt "[summarize] y_c_2002, cg_total_2002, flow_total_2002"
summarize y_c_2002 cg_total_2002 flow_total_2002

* Base: A_2000 + 0.5 * F_2002 (treat flows as 0 only when A_2000 is non-missing)
capture drop base_2002
gen double base_2002 = .
replace base_2002 = a_2000 + 0.5 * cond(missing(flow_total_2002),0,flow_total_2002) if !missing(a_2000)
label var base_2002 "Base for 2002 returns (A_2000 + 0.5*F_2002)"

di as txt "[summarize] base_2002"
summarize base_2002, detail

* Period return and annualization (2-year)
capture drop num_period_2002 r_period_2002 r_annual_2002 r_annual_trim_2002
gen double num_period_2002 = cond(missing(y_c_2002),0,y_c_2002) + ///
                             cond(missing(cg_total_2002),0,cg_total_2002) - ///
                             cond(missing(flow_total_2002),0,flow_total_2002)
egen byte __num02_has = rownonmiss(y_c_2002 cg_total_2002 flow_total_2002)
replace num_period_2002 = . if __num02_has == 0
drop __num02_has

gen double r_period_2002 = num_period_2002 / base_2002
replace r_period_2002 = . if base_2002 < 10000

gen double r_annual_2002 = (1 + r_period_2002)^(1/2) - 1
replace r_annual_2002 = . if missing(r_period_2002)

* Trim 5% tails
capture drop r_annual_trim_2002
xtile __p_2002 = r_annual_2002 if !missing(r_annual_2002), n(100)
gen double r_annual_trim_2002 = r_annual_2002
replace r_annual_trim_2002 = . if __p_2002 <= 5 | __p_2002 > 95
drop __p_2002

di as txt "[summarize] r_period_2002, r_annual_2002, r_annual_trim_2002"
summarize r_period_2002 r_annual_2002 r_annual_trim_2002

* Excluding residential housing
capture drop cg_total_2002_excl_res flow_total_2002_excl_res
gen double flow_total_2002_excl_res = .
egen byte any_flow02_excl = rownonmiss(flow_bus_2002 flow_re_2002 flow_stk_2002 flow_ira_2002)
replace flow_total_2002_excl_res = cond(missing(flow_bus_2002),0,flow_bus_2002) + ///
                                   cond(missing(flow_re_2002),0,flow_re_2002) + ///
                                   cond(missing(flow_stk_2002),0,flow_stk_2002) + ///
                                   cond(missing(flow_ira_2002),0,flow_ira_2002) if any_flow02_excl>0
drop any_flow02_excl

gen double cg_total_2002_excl_res = .
egen byte any_cg02_excl = rownonmiss(cg_re_2002 cg_bus_2002 cg_ira_2002 cg_stk_2002 cg_bond_2002 cg_chck_2002 cg_cd_2002 cg_veh_2002 cg_oth_2002)
replace cg_total_2002_excl_res = cond(missing(cg_re_2002),0,cg_re_2002) + ///
                                 cond(missing(cg_bus_2002),0,cg_bus_2002) + ///
                                 cond(missing(cg_ira_2002),0,cg_ira_2002) + ///
                                 cond(missing(cg_stk_2002),0,cg_stk_2002) + ///
                                 cond(missing(cg_bond_2002),0,cg_bond_2002) + ///
                                 cond(missing(cg_chck_2002),0,cg_chck_2002) + ///
                                 cond(missing(cg_cd_2002),0,cg_cd_2002) + ///
                                 cond(missing(cg_veh_2002),0,cg_veh_2002) + ///
                                 cond(missing(cg_oth_2002),0,cg_oth_2002) if any_cg02_excl>0
drop any_cg02_excl

di as txt "EXCL-RES: cg_total_2002_excl_res and flow_total_2002_excl_res summaries:"
summarize cg_total_2002_excl_res flow_total_2002_excl_res

* Use SAME base_2002
capture drop num_period_2002_excl_res r_period_2002_excl_res r_annual_excl_2002 r_annual_excl_trim_2002
gen double num_period_2002_excl_res = cond(missing(y_c_2002),0,y_c_2002) + ///
                                      cond(missing(cg_total_2002_excl_res),0,cg_total_2002_excl_res) - ///
                                      cond(missing(flow_total_2002_excl_res),0,flow_total_2002_excl_res)
egen byte __num02ex_has = rownonmiss(y_c_2002 cg_total_2002_excl_res flow_total_2002_excl_res)
replace num_period_2002_excl_res = . if __num02ex_has == 0
drop __num02ex_has

gen double r_period_2002_excl_res = num_period_2002_excl_res / base_2002
replace r_period_2002_excl_res = . if base_2002 < 10000
gen double r_annual_excl_2002 = (1 + r_period_2002_excl_res)^(1/2) - 1
replace r_annual_excl_2002 = . if missing(r_period_2002_excl_res)

* Trim 5% for excl-res
xtile __p_ex02 = r_annual_excl_2002 if !missing(r_annual_excl_2002), n(100)
gen double r_annual_excl_trim_2002 = r_annual_excl_2002
replace r_annual_excl_trim_2002 = . if __p_ex02 <= 5 | __p_ex02 > 95
drop __p_ex02

di as txt "[summarize] r_period_2002_excl_res, r_annual_excl_2002, r_annual_excl_trim_2002"
summarize r_period_2002_excl_res r_annual_excl_2002 r_annual_excl_trim_2002

* ---------------------------------------------------------------------
* Prepare 2000 controls inline (married_2000, wealth_*_2000, age_2000, inlbrf_2000)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2000 controls (inline) ==="

* Marital status (2000): r5mstat -> married_2000
capture confirm variable r5mstat
if _rc {
    di as error "ERROR: r5mstat not found"
    exit 198
}

capture drop married_2000
gen byte married_2000 = .
replace married_2000 = 1 if inlist(r5mstat, 1, 2)
replace married_2000 = 0 if inlist(r5mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2000 yesno
label var married_2000 "Married (r5mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2000) summary:"
tab married_2000, missing

* Wealth percentile/deciles for 2000 using h5atotb
capture confirm variable h5atotb
if _rc {
    di as error "ERROR: h5atotb not found"
    exit 198
}

capture drop wealth_rank_2000 wealth_pct_2000
quietly count if !missing(h5atotb)
local N_wealth00 = r(N)
egen double wealth_rank_2000 = rank(h5atotb) if !missing(h5atotb)
gen double wealth_pct_2000 = .
replace wealth_pct_2000 = 100 * (wealth_rank_2000 - 1) / (`N_wealth00' - 1) if `N_wealth00' > 1 & !missing(wealth_rank_2000)
replace wealth_pct_2000 = 50 if `N_wealth00' == 1 & !missing(wealth_rank_2000)
label variable wealth_pct_2000 "Wealth percentile (based on h5atotb)"

di as txt "Wealth percentile (2000) summary:"
summarize wealth_pct_2000

capture drop wealth_decile_2000
xtile wealth_decile_2000 = h5atotb if !missing(h5atotb), n(10)
label var wealth_decile_2000 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2000):"
tab wealth_decile_2000, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2000
    gen byte wealth_d`d'_2000 = wealth_decile_2000 == `d' if !missing(wealth_decile_2000)
    label values wealth_d`d'_2000 yesno
    label var wealth_d`d'_2000 "Wealth decile `d' (2000)"
}

* Age (2000): r5agey_b -> age_2000
capture confirm variable r5agey_b
if _rc {
    di as error "ERROR: r5agey_b not found"
    exit 198
}

capture drop age_2000
gen double age_2000 = r5agey_b
label var age_2000 "Respondent age in 2000 (r5agey_b)"

di as txt "Age (2000) summary:"
summarize age_2000

* Employment (2000): r5inlbrf -> inlbrf_2000
capture confirm variable r5inlbrf
if _rc {
    di as error "ERROR: r5inlbrf not found"
    exit 198
}

capture drop inlbrf_2000
clonevar inlbrf_2000 = r5inlbrf
label var inlbrf_2000 "Labor force status in 2000 (r5inlbrf)"

di as txt "Employment (2000) distribution:"
tab inlbrf_2000, missing

* ---------------------------------------------------------------------
* Save back and print only overlap counts for all 11 years
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset (with 2002 flows and returns) ==="

* Overlap only: All 11-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010) & !missing(r_annual_2008) & !missing(r_annual_2006) & !missing(r_annual_2004) & !missing(r_annual_2002)
di as txt "  All 11 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010) & !missing(r_annual_excl_2008) & !missing(r_annual_excl_2006) & !missing(r_annual_excl_2004) & !missing(r_annual_excl_2002)
di as txt "  All 11 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010) & !missing(r_annual_trim_2008) & !missing(r_annual_trim_2006) & !missing(r_annual_trim_2004) & !missing(r_annual_trim_2002)
di as txt "  All 11 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010) & !missing(r_annual_excl_trim_2008) & !missing(r_annual_excl_trim_2006) & !missing(r_annual_excl_trim_2004) & !missing(r_annual_excl_trim_2002)
di as txt "  All 11 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


