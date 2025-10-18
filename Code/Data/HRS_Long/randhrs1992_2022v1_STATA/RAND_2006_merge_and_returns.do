*----------------------------------------------------------------------
* RAND_2006_merge_and_returns.do
* Merge 2006 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2006; mirrors 2008/2010/2012/2014/2016/2018/2020 pipeline)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2006_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2006  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2006/h06f4b_STATA/h06f4b.dta"
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
* Load 2006 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2006 RAND fat file ==="
preserve
capture confirm file `"`raw_2006'"'
if _rc {
    di as error "ERROR: RAW 2006 file not found -> `raw_2006'"
    exit 198
}
use "`raw_2006'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2006"
    exit 198
}

* 2006 flow variables per notes (KR* + KQ IRA triplet)
local flow06 "kr050 kr055 kr063 kr064 kr072 kr030 kr035 kr045 kq171_1 kq171_2 kq171_3 kr007 kr013 kr024"

di as txt "Checking presence of 2006 flow variables..."
foreach v of local flow06 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2006 RAW: `v'"
    else  di as txt  "  OK in 2006 RAW: `v'"
}

keep hhidpn `flow06'
tempfile raw06_flows
save "`raw06_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2006 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw06_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (match later-year rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99
foreach v of local flow06 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2006 flow aggregates (suffix _2006)
* ---------------------------------------------------------------------
* kr063 direction and magnitude
capture drop kr063_dir06
gen byte kr063_dir06 = .
replace kr063_dir06 = -1 if kr063 == 1
replace kr063_dir06 =  1 if kr063 == 2
replace kr063_dir06 =  0 if kr063 == 3

capture drop flow_bus_2006
gen double flow_bus_2006 = .
replace flow_bus_2006 = kr055 - kr050 if !missing(kr055) & !missing(kr050)
replace flow_bus_2006 = kr055 if  missing(kr050) & !missing(kr055)
replace flow_bus_2006 = -kr050 if !missing(kr050) &  missing(kr055)

capture drop flow_stk_private_2006
gen double flow_stk_private_2006 = kr063_dir06 * kr064 if !missing(kr063_dir06) & !missing(kr064)

capture drop flow_stk_public_2006
gen double flow_stk_public_2006 = kr072 if !missing(kr072)

capture drop flow_stk_2006
gen double flow_stk_2006 = cond(!missing(flow_stk_private_2006), flow_stk_private_2006, 0) + ///
                           cond(!missing(flow_stk_public_2006),  flow_stk_public_2006,  0)
replace flow_stk_2006 = . if missing(flow_stk_private_2006) & missing(flow_stk_public_2006)

capture drop flow_re_2006
gen double flow_re_2006 = .
replace flow_re_2006 = cond(missing(kr035),0,kr035) - ( cond(missing(kr030),0,kr030) + cond(missing(kr045),0,kr045) ) if !missing(kr035) | !missing(kr030) | !missing(kr045)

capture drop flow_ira_2006
egen double flow_ira_2006 = rowtotal(kq171_1 kq171_2 kq171_3)
replace flow_ira_2006 = . if missing(kq171_1) & missing(kq171_2) & missing(kq171_3)

capture drop flow_residences_2006
gen double flow_residences_2006 = .
replace flow_residences_2006 = cond(missing(kr013),0,kr013) - ( cond(missing(kr007),0,kr007) + cond(missing(kr024),0,kr024) ) if !missing(kr013) | !missing(kr007) | !missing(kr024)
replace flow_residences_2006 = . if missing(kr013) & missing(kr007) & missing(kr024)

capture drop flow_total_2006
gen double flow_total_2006 = .
egen byte any_flow_present06 = rownonmiss(flow_bus_2006 flow_re_2006 flow_stk_2006 flow_ira_2006 flow_residences_2006)
replace flow_total_2006 = cond(missing(flow_bus_2006),0,flow_bus_2006) + ///
                          cond(missing(flow_re_2006),0,flow_re_2006) + ///
                          cond(missing(flow_stk_2006),0,flow_stk_2006) + ///
                          cond(missing(flow_ira_2006),0,flow_ira_2006) + ///
                          cond(missing(flow_residences_2006),0,flow_residences_2006) ///
                          if any_flow_present06 > 0
drop any_flow_present06

di as txt "Flows 2006 summaries:"
summarize flow_bus_2006 flow_re_2006 flow_stk_2006 flow_ira_2006 flow_residences_2006 flow_total_2006

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2006 (period 2004-2006)
* ---------------------------------------------------------------------
di as txt "=== Computing 2006 returns (2004-2006) ==="

* Denominator base: A_{2004}
capture drop a_2004
gen double a_2004 = h7atotb
label var a_2004 "Total net assets (A_2004 = h7atotb)"

* Capital income y^c_2006
capture drop y_c_2006
gen double y_c_2006 = h8icap
label var y_c_2006 "Capital income 2006 (h8icap)"

* Capital gains per class: cg_class = V_2006 - V_2004
capture drop cg_pri_res_2006 cg_sec_res_2006 cg_re_2006 cg_bus_2006 cg_ira_2006 cg_stk_2006 cg_bond_2006 cg_chck_2006 cg_cd_2006 cg_veh_2006 cg_oth_2006
gen double cg_pri_res_2006 = h8atoth - h7atoth
gen double cg_sec_res_2006 = h8anethb - h7anethb
gen double cg_re_2006      = h8arles - h7arles
gen double cg_bus_2006     = h8absns - h7absns
gen double cg_ira_2006     = h8aira  - h7aira
gen double cg_stk_2006     = h8astck - h7astck
gen double cg_bond_2006    = h8abond - h7abond
gen double cg_chck_2006    = h8achck - h7achck
gen double cg_cd_2006      = h8acd   - h7acd
gen double cg_veh_2006     = h8atran - h7atran
gen double cg_oth_2006     = h8aothr - h7aothr

di as txt "Capital gains components (2004->2006) summaries:"
summarize cg_pri_res_2006 cg_sec_res_2006 cg_re_2006 cg_bus_2006 cg_ira_2006 cg_stk_2006 cg_bond_2006 cg_chck_2006 cg_cd_2006 cg_veh_2006 cg_oth_2006

* Total capital gains with missing logic (missing only if all components missing)
capture drop cg_total_2006
egen byte any_cg_2006 = rownonmiss(cg_pri_res_2006 cg_sec_res_2006 cg_re_2006 cg_bus_2006 cg_ira_2006 cg_stk_2006 cg_bond_2006 cg_chck_2006 cg_cd_2006 cg_veh_2006 cg_oth_2006)
gen double cg_total_2006 = .
replace cg_total_2006 = cond(missing(cg_pri_res_2006),0,cg_pri_res_2006) + ///
                        cond(missing(cg_sec_res_2006),0,cg_sec_res_2006) + ///
                        cond(missing(cg_re_2006),0,cg_re_2006) + ///
                        cond(missing(cg_bus_2006),0,cg_bus_2006) + ///
                        cond(missing(cg_ira_2006),0,cg_ira_2006) + ///
                        cond(missing(cg_stk_2006),0,cg_stk_2006) + ///
                        cond(missing(cg_bond_2006),0,cg_bond_2006) + ///
                        cond(missing(cg_chck_2006),0,cg_chck_2006) + ///
                        cond(missing(cg_cd_2006),0,cg_cd_2006) + ///
                        cond(missing(cg_veh_2006),0,cg_veh_2006) + ///
                        cond(missing(cg_oth_2006),0,cg_oth_2006) if any_cg_2006>0
drop any_cg_2006

di as txt "[summarize] y_c_2006, cg_total_2006, flow_total_2006"
summarize y_c_2006 cg_total_2006 flow_total_2006

* Base: A_2004 + 0.5 * F_2006 (treat flows as 0 only when A_2004 is non-missing)
capture drop base_2006
gen double base_2006 = .
replace base_2006 = a_2004 + 0.5 * cond(missing(flow_total_2006),0,flow_total_2006) if !missing(a_2004)
label var base_2006 "Base for 2006 returns (A_2004 + 0.5*F_2006)"

di as txt "[summarize] base_2006"
summarize base_2006, detail

* Period return and annualization (2-year)
capture drop num_period_2006 r_period_2006 r_annual_2006 r_annual_trim_2006
gen double num_period_2006 = cond(missing(y_c_2006),0,y_c_2006) + ///
                             cond(missing(cg_total_2006),0,cg_total_2006) - ///
                             cond(missing(flow_total_2006),0,flow_total_2006)
egen byte __num06_has = rownonmiss(y_c_2006 cg_total_2006 flow_total_2006)
replace num_period_2006 = . if __num06_has == 0
drop __num06_has

gen double r_period_2006 = num_period_2006 / base_2006
replace r_period_2006 = . if base_2006 < 10000

gen double r_annual_2006 = (1 + r_period_2006)^(1/2) - 1
replace r_annual_2006 = . if missing(r_period_2006)

* Trim 5% tails
capture drop r_annual_trim_2006
xtile __p_2006 = r_annual_2006 if !missing(r_annual_2006), n(100)
gen double r_annual_trim_2006 = r_annual_2006
replace r_annual_trim_2006 = . if __p_2006 <= 5 | __p_2006 > 95
drop __p_2006

di as txt "[summarize] r_period_2006, r_annual_2006, r_annual_trim_2006"
summarize r_period_2006 r_annual_2006 r_annual_trim_2006

* Excluding residential housing
capture drop cg_total_2006_excl_res flow_total_2006_excl_res
gen double flow_total_2006_excl_res = .
egen byte any_flow06_excl = rownonmiss(flow_bus_2006 flow_re_2006 flow_stk_2006 flow_ira_2006)
replace flow_total_2006_excl_res = cond(missing(flow_bus_2006),0,flow_bus_2006) + ///
                                   cond(missing(flow_re_2006),0,flow_re_2006) + ///
                                   cond(missing(flow_stk_2006),0,flow_stk_2006) + ///
                                   cond(missing(flow_ira_2006),0,flow_ira_2006) if any_flow06_excl>0
drop any_flow06_excl

gen double cg_total_2006_excl_res = .
egen byte any_cg06_excl = rownonmiss(cg_re_2006 cg_bus_2006 cg_ira_2006 cg_stk_2006 cg_bond_2006 cg_chck_2006 cg_cd_2006 cg_veh_2006 cg_oth_2006)
replace cg_total_2006_excl_res = cond(missing(cg_re_2006),0,cg_re_2006) + ///
                                 cond(missing(cg_bus_2006),0,cg_bus_2006) + ///
                                 cond(missing(cg_ira_2006),0,cg_ira_2006) + ///
                                 cond(missing(cg_stk_2006),0,cg_stk_2006) + ///
                                 cond(missing(cg_bond_2006),0,cg_bond_2006) + ///
                                 cond(missing(cg_chck_2006),0,cg_chck_2006) + ///
                                 cond(missing(cg_cd_2006),0,cg_cd_2006) + ///
                                 cond(missing(cg_veh_2006),0,cg_veh_2006) + ///
                                 cond(missing(cg_oth_2006),0,cg_oth_2006) if any_cg06_excl>0
drop any_cg06_excl

di as txt "EXCL-RES: cg_total_2006_excl_res and flow_total_2006_excl_res summaries:"
summarize cg_total_2006_excl_res flow_total_2006_excl_res

* Use SAME base_2006
capture drop num_period_2006_excl_res r_period_2006_excl_res r_annual_excl_2006 r_annual_excl_trim_2006
gen double num_period_2006_excl_res = cond(missing(y_c_2006),0,y_c_2006) + ///
                                      cond(missing(cg_total_2006_excl_res),0,cg_total_2006_excl_res) - ///
                                      cond(missing(flow_total_2006_excl_res),0,flow_total_2006_excl_res)
egen byte __num06ex_has = rownonmiss(y_c_2006 cg_total_2006_excl_res flow_total_2006_excl_res)
replace num_period_2006_excl_res = . if __num06ex_has == 0
drop __num06ex_has

gen double r_period_2006_excl_res = num_period_2006_excl_res / base_2006
replace r_period_2006_excl_res = . if base_2006 < 10000
gen double r_annual_excl_2006 = (1 + r_period_2006_excl_res)^(1/2) - 1
replace r_annual_excl_2006 = . if missing(r_period_2006_excl_res)

* Trim 5% for excl-res
xtile __p_ex06 = r_annual_excl_2006 if !missing(r_annual_excl_2006), n(100)
gen double r_annual_excl_trim_2006 = r_annual_excl_2006
replace r_annual_excl_trim_2006 = . if __p_ex06 <= 5 | __p_ex06 > 95
drop __p_ex06

di as txt "[summarize] r_period_2006_excl_res, r_annual_excl_2006, r_annual_excl_trim_2006"
summarize r_period_2006_excl_res r_annual_excl_2006 r_annual_excl_trim_2006

* ---------------------------------------------------------------------
* Prepare 2004 controls inline (married_2004, wealth_*_2004, age_2004, inlbrf_2004)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2004 controls (inline) ==="

* Marital status (2004): r7mstat -> married_2004
capture confirm variable r7mstat
if _rc {
    di as error "ERROR: r7mstat not found"
    exit 198
}

capture drop married_2004
gen byte married_2004 = .
replace married_2004 = 1 if inlist(r7mstat, 1, 2)
replace married_2004 = 0 if inlist(r7mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2004 yesno
label var married_2004 "Married (r7mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2004) summary:"
tab married_2004, missing

* Wealth percentile/deciles for 2004 using h7atotb
capture confirm variable h7atotb
if _rc {
    di as error "ERROR: h7atotb not found"
    exit 198
}

capture drop wealth_rank_2004 wealth_pct_2004
quietly count if !missing(h7atotb)
local N_wealth04 = r(N)
egen double wealth_rank_2004 = rank(h7atotb) if !missing(h7atotb)
gen double wealth_pct_2004 = .
replace wealth_pct_2004 = 100 * (wealth_rank_2004 - 1) / (`N_wealth04' - 1) if `N_wealth04' > 1 & !missing(wealth_rank_2004)
replace wealth_pct_2004 = 50 if `N_wealth04' == 1 & !missing(wealth_rank_2004)
label variable wealth_pct_2004 "Wealth percentile (based on h7atotb)"

di as txt "Wealth percentile (2004) summary:"
summarize wealth_pct_2004

capture drop wealth_decile_2004
xtile wealth_decile_2004 = h7atotb if !missing(h7atotb), n(10)
label var wealth_decile_2004 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2004):"
tab wealth_decile_2004, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2004
    gen byte wealth_d`d'_2004 = wealth_decile_2004 == `d' if !missing(wealth_decile_2004)
    label values wealth_d`d'_2004 yesno
    label var wealth_d`d'_2004 "Wealth decile `d' (2004)"
}

* Age (2004): r7agey_b -> age_2004
capture confirm variable r7agey_b
if _rc {
    di as error "ERROR: r7agey_b not found"
    exit 198
}

capture drop age_2004
gen double age_2004 = r7agey_b
label var age_2004 "Respondent age in 2004 (r7agey_b)"

di as txt "Age (2004) summary:"
summarize age_2004

* Employment (2004): r7inlbrf -> inlbrf_2004
capture confirm variable r7inlbrf
if _rc {
    di as error "ERROR: r7inlbrf not found"
    exit 198
}

capture drop inlbrf_2004
clonevar inlbrf_2004 = r7inlbrf
label var inlbrf_2004 "Labor force status in 2004 (r7inlbrf)"

di as txt "Employment (2004) distribution:"
tab inlbrf_2004, missing

* ---------------------------------------------------------------------
* Save back and print only overlap counts for all 9 years
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset (with 2006 flows and returns) ==="

* Overlap only: All 9-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010) & !missing(r_annual_2008) & !missing(r_annual_2006)
di as txt "  All 9 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010) & !missing(r_annual_excl_2008) & !missing(r_annual_excl_2006)
di as txt "  All 9 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010) & !missing(r_annual_trim_2008) & !missing(r_annual_trim_2006)
di as txt "  All 9 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010) & !missing(r_annual_excl_trim_2008) & !missing(r_annual_excl_trim_2006)
di as txt "  All 9 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


