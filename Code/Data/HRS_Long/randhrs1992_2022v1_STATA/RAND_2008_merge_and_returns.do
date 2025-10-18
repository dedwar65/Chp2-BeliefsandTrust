*----------------------------------------------------------------------
* RAND_2008_merge_and_returns.do
* Merge 2008 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2008; mirrors 2010/2012/2014/2016/2018/2020 pipeline)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2008_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2008  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2008/h08f3b_STATA/h08f3b.dta"
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
* Load 2008 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2008 RAND fat file ==="
preserve
capture confirm file `"`raw_2008'"'
if _rc {
    di as error "ERROR: RAW 2008 file not found -> `raw_2008'"
    exit 198
}
use "`raw_2008'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2008"
    exit 198
}

* 2008 flow variables per notes (LR* + LQ IRA triplet)
local flow08 "lr050 lr055 lr063 lr064 lr072 lr030 lr035 lr045 lq171_1 lq171_2 lq171_3 lr007 lr013 lr024"

di as txt "Checking presence of 2008 flow variables..."
foreach v of local flow08 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2008 RAW: `v'"
    else  di as txt  "  OK in 2008 RAW: `v'"
}

keep hhidpn `flow08'
tempfile raw08_flows
save "`raw08_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2008 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw08_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (match later-year rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99
foreach v of local flow08 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2008 flow aggregates (suffix _2008)
* ---------------------------------------------------------------------
* lr063 direction and magnitude
capture drop lr063_dir08
gen byte lr063_dir08 = .
replace lr063_dir08 = -1 if lr063 == 1
replace lr063_dir08 =  1 if lr063 == 2
replace lr063_dir08 =  0 if lr063 == 3

capture drop flow_bus_2008
gen double flow_bus_2008 = .
replace flow_bus_2008 = lr055 - lr050 if !missing(lr055) & !missing(lr050)
replace flow_bus_2008 = lr055 if  missing(lr050) & !missing(lr055)
replace flow_bus_2008 = -lr050 if !missing(lr050) &  missing(lr055)

capture drop flow_stk_private_2008
gen double flow_stk_private_2008 = lr063_dir08 * lr064 if !missing(lr063_dir08) & !missing(lr064)

capture drop flow_stk_public_2008
gen double flow_stk_public_2008 = lr072 if !missing(lr072)

capture drop flow_stk_2008
gen double flow_stk_2008 = cond(!missing(flow_stk_private_2008), flow_stk_private_2008, 0) + ///
                           cond(!missing(flow_stk_public_2008),  flow_stk_public_2008,  0)
replace flow_stk_2008 = . if missing(flow_stk_private_2008) & missing(flow_stk_public_2008)

capture drop flow_re_2008
gen double flow_re_2008 = .
replace flow_re_2008 = cond(missing(lr035),0,lr035) - ( cond(missing(lr030),0,lr030) + cond(missing(lr045),0,lr045) ) if !missing(lr035) | !missing(lr030) | !missing(lr045)

capture drop flow_ira_2008
egen double flow_ira_2008 = rowtotal(lq171_1 lq171_2 lq171_3)
replace flow_ira_2008 = . if missing(lq171_1) & missing(lq171_2) & missing(lq171_3)

capture drop flow_residences_2008
gen double flow_residences_2008 = .
replace flow_residences_2008 = cond(missing(lr013),0,lr013) - ( cond(missing(lr007),0,lr007) + cond(missing(lr024),0,lr024) ) if !missing(lr013) | !missing(lr007) | !missing(lr024)
replace flow_residences_2008 = . if missing(lr013) & missing(lr007) & missing(lr024)

capture drop flow_total_2008
gen double flow_total_2008 = .
egen byte any_flow_present08 = rownonmiss(flow_bus_2008 flow_re_2008 flow_stk_2008 flow_ira_2008 flow_residences_2008)
replace flow_total_2008 = cond(missing(flow_bus_2008),0,flow_bus_2008) + ///
                          cond(missing(flow_re_2008),0,flow_re_2008) + ///
                          cond(missing(flow_stk_2008),0,flow_stk_2008) + ///
                          cond(missing(flow_ira_2008),0,flow_ira_2008) + ///
                          cond(missing(flow_residences_2008),0,flow_residences_2008) ///
                          if any_flow_present08 > 0
drop any_flow_present08

di as txt "Flows 2008 summaries:"
summarize flow_bus_2008 flow_re_2008 flow_stk_2008 flow_ira_2008 flow_residences_2008 flow_total_2008

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2008 (period 2006-2008)
* ---------------------------------------------------------------------
di as txt "=== Computing 2008 returns (2006-2008) ==="

* Denominator base: A_{2006}
capture drop a_2006
gen double a_2006 = h8atotb
label var a_2006 "Total net assets (A_2006 = h8atotb)"

* Capital income y^c_2008
capture drop y_c_2008
gen double y_c_2008 = h9icap
label var y_c_2008 "Capital income 2008 (h9icap)"

* Capital gains per class: cg_class = V_2008 - V_2006
capture drop cg_pri_res_2008 cg_sec_res_2008 cg_re_2008 cg_bus_2008 cg_ira_2008 cg_stk_2008 cg_bond_2008 cg_chck_2008 cg_cd_2008 cg_veh_2008 cg_oth_2008
gen double cg_pri_res_2008 = h9atoth - h8atoth
gen double cg_sec_res_2008 = h9anethb - h8anethb
gen double cg_re_2008      = h9arles - h8arles
gen double cg_bus_2008     = h9absns - h8absns
gen double cg_ira_2008     = h9aira  - h8aira
gen double cg_stk_2008     = h9astck - h8astck
gen double cg_bond_2008    = h9abond - h8abond
gen double cg_chck_2008    = h9achck - h8achck
gen double cg_cd_2008      = h9acd   - h8acd
gen double cg_veh_2008     = h9atran - h8atran
gen double cg_oth_2008     = h9aothr - h8aothr

di as txt "Capital gains components (2006->2008) summaries:"
summarize cg_pri_res_2008 cg_sec_res_2008 cg_re_2008 cg_bus_2008 cg_ira_2008 cg_stk_2008 cg_bond_2008 cg_chck_2008 cg_cd_2008 cg_veh_2008 cg_oth_2008

* Total capital gains with missing logic (missing only if all components missing)
capture drop cg_total_2008
egen byte any_cg_2008 = rownonmiss(cg_pri_res_2008 cg_sec_res_2008 cg_re_2008 cg_bus_2008 cg_ira_2008 cg_stk_2008 cg_bond_2008 cg_chck_2008 cg_cd_2008 cg_veh_2008 cg_oth_2008)
gen double cg_total_2008 = .
replace cg_total_2008 = cond(missing(cg_pri_res_2008),0,cg_pri_res_2008) + ///
                        cond(missing(cg_sec_res_2008),0,cg_sec_res_2008) + ///
                        cond(missing(cg_re_2008),0,cg_re_2008) + ///
                        cond(missing(cg_bus_2008),0,cg_bus_2008) + ///
                        cond(missing(cg_ira_2008),0,cg_ira_2008) + ///
                        cond(missing(cg_stk_2008),0,cg_stk_2008) + ///
                        cond(missing(cg_bond_2008),0,cg_bond_2008) + ///
                        cond(missing(cg_chck_2008),0,cg_chck_2008) + ///
                        cond(missing(cg_cd_2008),0,cg_cd_2008) + ///
                        cond(missing(cg_veh_2008),0,cg_veh_2008) + ///
                        cond(missing(cg_oth_2008),0,cg_oth_2008) if any_cg_2008>0
drop any_cg_2008

di as txt "[summarize] y_c_2008, cg_total_2008, flow_total_2008"
summarize y_c_2008 cg_total_2008 flow_total_2008

* Base: A_2006 + 0.5 * F_2008 (treat flows as 0 only when A_2006 is non-missing)
capture drop base_2008
gen double base_2008 = .
replace base_2008 = a_2006 + 0.5 * cond(missing(flow_total_2008),0,flow_total_2008) if !missing(a_2006)
label var base_2008 "Base for 2008 returns (A_2006 + 0.5*F_2008)"

di as txt "[summarize] base_2008"
summarize base_2008, detail

* Period return and annualization (2-year)
capture drop num_period_2008 r_period_2008 r_annual_2008 r_annual_trim_2008
gen double num_period_2008 = cond(missing(y_c_2008),0,y_c_2008) + ///
                             cond(missing(cg_total_2008),0,cg_total_2008) - ///
                             cond(missing(flow_total_2008),0,flow_total_2008)
egen byte __num08_has = rownonmiss(y_c_2008 cg_total_2008 flow_total_2008)
replace num_period_2008 = . if __num08_has == 0
drop __num08_has

gen double r_period_2008 = num_period_2008 / base_2008
replace r_period_2008 = . if base_2008 < 10000

gen double r_annual_2008 = (1 + r_period_2008)^(1/2) - 1
replace r_annual_2008 = . if missing(r_period_2008)

* Trim 5% tails
capture drop r_annual_trim_2008
xtile __p_2008 = r_annual_2008 if !missing(r_annual_2008), n(100)
gen double r_annual_trim_2008 = r_annual_2008
replace r_annual_trim_2008 = . if __p_2008 <= 5 | __p_2008 > 95
drop __p_2008

di as txt "[summarize] r_period_2008, r_annual_2008, r_annual_trim_2008"
summarize r_period_2008 r_annual_2008 r_annual_trim_2008

* Excluding residential housing
capture drop cg_total_2008_excl_res flow_total_2008_excl_res
gen double flow_total_2008_excl_res = .
egen byte any_flow08_excl = rownonmiss(flow_bus_2008 flow_re_2008 flow_stk_2008 flow_ira_2008)
replace flow_total_2008_excl_res = cond(missing(flow_bus_2008),0,flow_bus_2008) + ///
                                   cond(missing(flow_re_2008),0,flow_re_2008) + ///
                                   cond(missing(flow_stk_2008),0,flow_stk_2008) + ///
                                   cond(missing(flow_ira_2008),0,flow_ira_2008) if any_flow08_excl>0
drop any_flow08_excl

gen double cg_total_2008_excl_res = .
egen byte any_cg08_excl = rownonmiss(cg_re_2008 cg_bus_2008 cg_ira_2008 cg_stk_2008 cg_bond_2008 cg_chck_2008 cg_cd_2008 cg_veh_2008 cg_oth_2008)
replace cg_total_2008_excl_res = cond(missing(cg_re_2008),0,cg_re_2008) + ///
                                 cond(missing(cg_bus_2008),0,cg_bus_2008) + ///
                                 cond(missing(cg_ira_2008),0,cg_ira_2008) + ///
                                 cond(missing(cg_stk_2008),0,cg_stk_2008) + ///
                                 cond(missing(cg_bond_2008),0,cg_bond_2008) + ///
                                 cond(missing(cg_chck_2008),0,cg_chck_2008) + ///
                                 cond(missing(cg_cd_2008),0,cg_cd_2008) + ///
                                 cond(missing(cg_veh_2008),0,cg_veh_2008) + ///
                                 cond(missing(cg_oth_2008),0,cg_oth_2008) if any_cg08_excl>0
drop any_cg08_excl

di as txt "EXCL-RES: cg_total_2008_excl_res and flow_total_2008_excl_res summaries:"
summarize cg_total_2008_excl_res flow_total_2008_excl_res

* Use SAME base_2008
capture drop num_period_2008_excl_res r_period_2008_excl_res r_annual_excl_2008 r_annual_excl_trim_2008
gen double num_period_2008_excl_res = cond(missing(y_c_2008),0,y_c_2008) + ///
                                      cond(missing(cg_total_2008_excl_res),0,cg_total_2008_excl_res) - ///
                                      cond(missing(flow_total_2008_excl_res),0,flow_total_2008_excl_res)
egen byte __num08ex_has = rownonmiss(y_c_2008 cg_total_2008_excl_res flow_total_2008_excl_res)
replace num_period_2008_excl_res = . if __num08ex_has == 0
drop __num08ex_has

gen double r_period_2008_excl_res = num_period_2008_excl_res / base_2008
replace r_period_2008_excl_res = . if base_2008 < 10000
gen double r_annual_excl_2008 = (1 + r_period_2008_excl_res)^(1/2) - 1
replace r_annual_excl_2008 = . if missing(r_period_2008_excl_res)

* Trim 5% for excl-res
xtile __p_ex08 = r_annual_excl_2008 if !missing(r_annual_excl_2008), n(100)
gen double r_annual_excl_trim_2008 = r_annual_excl_2008
replace r_annual_excl_trim_2008 = . if __p_ex08 <= 5 | __p_ex08 > 95
drop __p_ex08

di as txt "[summarize] r_period_2008_excl_res, r_annual_excl_2008, r_annual_excl_trim_2008"
summarize r_period_2008_excl_res r_annual_excl_2008 r_annual_excl_trim_2008

* ---------------------------------------------------------------------
* Prepare 2006 controls inline (married_2006, wealth_*_2006, age_2006, inlbrf_2006)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2006 controls (inline) ==="

* Marital status (2006): r8mstat -> married_2006
capture confirm variable r8mstat
if _rc {
    di as error "ERROR: r8mstat not found"
    exit 198
}

capture drop married_2006
gen byte married_2006 = .
replace married_2006 = 1 if inlist(r8mstat, 1, 2)
replace married_2006 = 0 if inlist(r8mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2006 yesno
label var married_2006 "Married (r8mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2006) summary:"
tab married_2006, missing

* Wealth percentile/deciles for 2006 using h8atotb
capture confirm variable h8atotb
if _rc {
    di as error "ERROR: h8atotb not found"
    exit 198
}

capture drop wealth_rank_2006 wealth_pct_2006
quietly count if !missing(h8atotb)
local N_wealth06 = r(N)
egen double wealth_rank_2006 = rank(h8atotb) if !missing(h8atotb)
gen double wealth_pct_2006 = .
replace wealth_pct_2006 = 100 * (wealth_rank_2006 - 1) / (`N_wealth06' - 1) if `N_wealth06' > 1 & !missing(wealth_rank_2006)
replace wealth_pct_2006 = 50 if `N_wealth06' == 1 & !missing(wealth_rank_2006)
label variable wealth_pct_2006 "Wealth percentile (based on h8atotb)"

di as txt "Wealth percentile (2006) summary:"
summarize wealth_pct_2006

capture drop wealth_decile_2006
xtile wealth_decile_2006 = h8atotb if !missing(h8atotb), n(10)
label var wealth_decile_2006 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2006):"
tab wealth_decile_2006, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2006
    gen byte wealth_d`d'_2006 = wealth_decile_2006 == `d' if !missing(wealth_decile_2006)
    label values wealth_d`d'_2006 yesno
    label var wealth_d`d'_2006 "Wealth decile `d' (2006)"
}

* Age (2006): r8agey_b -> age_2006
capture confirm variable r8agey_b
if _rc {
    di as error "ERROR: r8agey_b not found"
    exit 198
}

capture drop age_2006
gen double age_2006 = r8agey_b
label var age_2006 "Respondent age in 2006 (r8agey_b)"

di as txt "Age (2006) summary:"
summarize age_2006

* Employment (2006): r8inlbrf -> inlbrf_2006
capture confirm variable r8inlbrf
if _rc {
    di as error "ERROR: r8inlbrf not found"
    exit 198
}

capture drop inlbrf_2006
clonevar inlbrf_2006 = r8inlbrf
label var inlbrf_2006 "Labor force status in 2006 (r8inlbrf)"

di as txt "Employment (2006) distribution:"
tab inlbrf_2006, missing

* ---------------------------------------------------------------------
* Save back and print only overlap counts for all 8 years
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset (with 2008 flows and returns) ==="

* Overlap only: All 8-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010) & !missing(r_annual_2008)
di as txt "  All 8 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010) & !missing(r_annual_excl_2008)
di as txt "  All 8 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010) & !missing(r_annual_trim_2008)
di as txt "  All 8 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010) & !missing(r_annual_excl_trim_2008)
di as txt "  All 8 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


