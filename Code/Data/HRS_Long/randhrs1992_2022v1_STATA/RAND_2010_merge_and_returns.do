*----------------------------------------------------------------------
* RAND_2010_merge_and_returns.do
* Merge 2010 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2010; mirrors 2012/2014/2016/2018/2020 pipeline with 2010 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2010_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
* Note: Provided path is a ZIP; ensure you point to the extracted .dta inside.
local raw_2010  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2010/hd10f6b_STATA/hd10f6b.dta"
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
* Load 2010 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2010 RAND fat file ==="
preserve
capture confirm file `"`raw_2010'"'
if _rc {
    di as error "ERROR: RAW 2010 file not found or not extracted -> `raw_2010'"
    di as error "       Please extract the ZIP and set raw_2010 to the .dta path."
    exit 198
}
use "`raw_2010'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2010"
    exit 198
}

* 2010 flow variables per notes (MR*). IRA triplet is MQ in 2010.
local flow10 "mr050 mr055 mr063 mr064 mr072 mr030 mr035 mr045 mq171_1 mq171_2 mq171_3 mr007 mr013 mr024"

di as txt "Checking presence of 2010 flow variables..."
foreach v of local flow10 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2010 RAW: `v'"
    else  di as txt  "  OK in 2010 RAW: `v'"
}

keep hhidpn `flow10'
tempfile raw10_flows
save "`raw10_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2010 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw10_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (follow expanded list used in 2012/2016)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998 98 99
foreach v of local flow10 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2010 flow aggregates (suffix _2010)
* ---------------------------------------------------------------------
* mr063 direction and magnitude
capture drop mr063_dir10
gen byte mr063_dir10 = .
replace mr063_dir10 = -1 if mr063 == 1
replace mr063_dir10 =  1 if mr063 == 2
replace mr063_dir10 =  0 if mr063 == 3

capture drop flow_bus_2010
gen double flow_bus_2010 = .
replace flow_bus_2010 = mr055 - mr050 if !missing(mr055) & !missing(mr050)
replace flow_bus_2010 = mr055 if  missing(mr050) & !missing(mr055)
replace flow_bus_2010 = -mr050 if !missing(mr050) &  missing(mr055)

capture drop flow_stk_private_2010
gen double flow_stk_private_2010 = mr063_dir10 * mr064 if !missing(mr063_dir10) & !missing(mr064)

capture drop flow_stk_public_2010
gen double flow_stk_public_2010 = mr072 if !missing(mr072)

capture drop flow_stk_2010
gen double flow_stk_2010 = cond(!missing(flow_stk_private_2010), flow_stk_private_2010, 0) + ///
                           cond(!missing(flow_stk_public_2010),  flow_stk_public_2010,  0)
replace flow_stk_2010 = . if missing(flow_stk_private_2010) & missing(flow_stk_public_2010)

capture drop flow_re_2010
gen double flow_re_2010 = .
replace flow_re_2010 = cond(missing(mr035),0,mr035) - ( cond(missing(mr030),0,mr030) + cond(missing(mr045),0,mr045) ) if !missing(mr035) | !missing(mr030) | !missing(mr045)

capture drop flow_ira_2010
egen double flow_ira_2010 = rowtotal(mq171_1 mq171_2 mq171_3)
replace flow_ira_2010 = . if missing(mq171_1) & missing(mq171_2) & missing(mq171_3)

capture drop flow_residences_2010
gen double flow_residences_2010 = .
replace flow_residences_2010 = cond(missing(mr013),0,mr013) - ( cond(missing(mr007),0,mr007) + cond(missing(mr024),0,mr024) ) if !missing(mr013) | !missing(mr007) | !missing(mr024)
replace flow_residences_2010 = . if missing(mr013) & missing(mr007) & missing(mr024)

capture drop flow_total_2010
gen double flow_total_2010 = .
egen byte any_flow_present10 = rownonmiss(flow_bus_2010 flow_re_2010 flow_stk_2010 flow_ira_2010 flow_residences_2010)
replace flow_total_2010 = cond(missing(flow_bus_2010),0,flow_bus_2010) + ///
                          cond(missing(flow_re_2010),0,flow_re_2010) + ///
                          cond(missing(flow_stk_2010),0,flow_stk_2010) + ///
                          cond(missing(flow_ira_2010),0,flow_ira_2010) + ///
                          cond(missing(flow_residences_2010),0,flow_residences_2010) ///
                          if any_flow_present10 > 0
drop any_flow_present10

di as txt "Flows 2010 summaries:"
summarize flow_bus_2010 flow_re_2010 flow_stk_2010 flow_ira_2010 flow_residences_2010 flow_total_2010

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2010 (period 2008-2010)
* ---------------------------------------------------------------------
di as txt "=== Computing 2010 returns (2008-2010) ==="

* Denominator base: A_{2008}
capture drop a_2008
gen double a_2008 = h9atotb
label var a_2008 "Total net assets (A_2008 = h9atotb)"

* Capital income y^c_2010
capture drop y_c_2010
gen double y_c_2010 = h10icap
label var y_c_2010 "Capital income 2010 (h10icap)"

* Capital gains per class: cg_class = V_2010 - V_2008
capture drop cg_pri_res_2010 cg_sec_res_2010 cg_re_2010 cg_bus_2010 cg_ira_2010 cg_stk_2010 cg_bond_2010 cg_chck_2010 cg_cd_2010 cg_veh_2010 cg_oth_2010
gen double cg_pri_res_2010 = h10atoth - h9atoth
gen double cg_sec_res_2010 = h10anethb - h9anethb
gen double cg_re_2010      = h10arles - h9arles
gen double cg_bus_2010     = h10absns - h9absns
gen double cg_ira_2010     = h10aira  - h9aira
gen double cg_stk_2010     = h10astck - h9astck
gen double cg_bond_2010    = h10abond - h9abond
gen double cg_chck_2010    = h10achck - h9achck
gen double cg_cd_2010      = h10acd   - h9acd
gen double cg_veh_2010     = h10atran - h9atran
gen double cg_oth_2010     = h10aothr - h9aothr

di as txt "Capital gains components (2008->2010) summaries:"
summarize cg_pri_res_2010 cg_sec_res_2010 cg_re_2010 cg_bus_2010 cg_ira_2010 cg_stk_2010 cg_bond_2010 cg_chck_2010 cg_cd_2010 cg_veh_2010 cg_oth_2010

* Total capital gains with missing logic (missing only if all components missing)
capture drop cg_total_2010
egen byte any_cg_2010 = rownonmiss(cg_pri_res_2010 cg_sec_res_2010 cg_re_2010 cg_bus_2010 cg_ira_2010 cg_stk_2010 cg_bond_2010 cg_chck_2010 cg_cd_2010 cg_veh_2010 cg_oth_2010)
gen double cg_total_2010 = .
replace cg_total_2010 = cond(missing(cg_pri_res_2010),0,cg_pri_res_2010) + ///
                        cond(missing(cg_sec_res_2010),0,cg_sec_res_2010) + ///
                        cond(missing(cg_re_2010),0,cg_re_2010) + ///
                        cond(missing(cg_bus_2010),0,cg_bus_2010) + ///
                        cond(missing(cg_ira_2010),0,cg_ira_2010) + ///
                        cond(missing(cg_stk_2010),0,cg_stk_2010) + ///
                        cond(missing(cg_bond_2010),0,cg_bond_2010) + ///
                        cond(missing(cg_chck_2010),0,cg_chck_2010) + ///
                        cond(missing(cg_cd_2010),0,cg_cd_2010) + ///
                        cond(missing(cg_veh_2010),0,cg_veh_2010) + ///
                        cond(missing(cg_oth_2010),0,cg_oth_2010) if any_cg_2010>0
drop any_cg_2010

di as txt "[summarize] y_c_2010, cg_total_2010, flow_total_2010"
summarize y_c_2010 cg_total_2010 flow_total_2010

* Base: A_2008 + 0.5 * F_2010 (treat flows as 0 only when A_2008 is non-missing)
capture drop base_2010
gen double base_2010 = .
replace base_2010 = a_2008 + 0.5 * cond(missing(flow_total_2010),0,flow_total_2010) if !missing(a_2008)
label var base_2010 "Base for 2010 returns (A_2008 + 0.5*F_2010)"

di as txt "[summarize] base_2010"
summarize base_2010, detail

* Period return and annualization (2-year)
capture drop num_period_2010 r_period_2010 r_annual_2010 r_annual_trim_2010
gen double num_period_2010 = cond(missing(y_c_2010),0,y_c_2010) + ///
                             cond(missing(cg_total_2010),0,cg_total_2010) - ///
                             cond(missing(flow_total_2010),0,flow_total_2010)
egen byte __num10_has = rownonmiss(y_c_2010 cg_total_2010 flow_total_2010)
replace num_period_2010 = . if __num10_has == 0
drop __num10_has

gen double r_period_2010 = num_period_2010 / base_2010
replace r_period_2010 = . if base_2010 < 10000

gen double r_annual_2010 = (1 + r_period_2010)^(1/2) - 1
replace r_annual_2010 = . if missing(r_period_2010)

* Trim 5% tails
capture drop r_annual_trim_2010
xtile __p_2010 = r_annual_2010 if !missing(r_annual_2010), n(100)
gen double r_annual_trim_2010 = r_annual_2010
replace r_annual_trim_2010 = . if __p_2010 <= 5 | __p_2010 > 95
drop __p_2010

di as txt "[summarize] r_period_2010, r_annual_2010, r_annual_trim_2010"
summarize r_period_2010 r_annual_2010 r_annual_trim_2010

* Excluding residential housing
capture drop cg_total_2010_excl_res flow_total_2010_excl_res
gen double flow_total_2010_excl_res = .
egen byte any_flow10_excl = rownonmiss(flow_bus_2010 flow_re_2010 flow_stk_2010 flow_ira_2010)
replace flow_total_2010_excl_res = cond(missing(flow_bus_2010),0,flow_bus_2010) + ///
                                   cond(missing(flow_re_2010),0,flow_re_2010) + ///
                                   cond(missing(flow_stk_2010),0,flow_stk_2010) + ///
                                   cond(missing(flow_ira_2010),0,flow_ira_2010) if any_flow10_excl>0
drop any_flow10_excl

gen double cg_total_2010_excl_res = .
egen byte any_cg10_excl = rownonmiss(cg_re_2010 cg_bus_2010 cg_ira_2010 cg_stk_2010 cg_bond_2010 cg_chck_2010 cg_cd_2010 cg_veh_2010 cg_oth_2010)
replace cg_total_2010_excl_res = cond(missing(cg_re_2010),0,cg_re_2010) + ///
                                 cond(missing(cg_bus_2010),0,cg_bus_2010) + ///
                                 cond(missing(cg_ira_2010),0,cg_ira_2010) + ///
                                 cond(missing(cg_stk_2010),0,cg_stk_2010) + ///
                                 cond(missing(cg_bond_2010),0,cg_bond_2010) + ///
                                 cond(missing(cg_chck_2010),0,cg_chck_2010) + ///
                                 cond(missing(cg_cd_2010),0,cg_cd_2010) + ///
                                 cond(missing(cg_veh_2010),0,cg_veh_2010) + ///
                                 cond(missing(cg_oth_2010),0,cg_oth_2010) if any_cg10_excl>0
drop any_cg10_excl

di as txt "EXCL-RES: cg_total_2010_excl_res and flow_total_2010_excl_res summaries:"
summarize cg_total_2010_excl_res flow_total_2010_excl_res

* Use SAME base_2010
capture drop num_period_2010_excl_res r_period_2010_excl_res r_annual_excl_2010 r_annual_excl_trim_2010
gen double num_period_2010_excl_res = cond(missing(y_c_2010),0,y_c_2010) + ///
                                      cond(missing(cg_total_2010_excl_res),0,cg_total_2010_excl_res) - ///
                                      cond(missing(flow_total_2010_excl_res),0,flow_total_2010_excl_res)
egen byte __num10ex_has = rownonmiss(y_c_2010 cg_total_2010_excl_res flow_total_2010_excl_res)
replace num_period_2010_excl_res = . if __num10ex_has == 0
drop __num10ex_has

gen double r_period_2010_excl_res = num_period_2010_excl_res / base_2010
replace r_period_2010_excl_res = . if base_2010 < 10000
gen double r_annual_excl_2010 = (1 + r_period_2010_excl_res)^(1/2) - 1
replace r_annual_excl_2010 = . if missing(r_period_2010_excl_res)

* Trim 5% for excl-res
xtile __p_ex10 = r_annual_excl_2010 if !missing(r_annual_excl_2010), n(100)
gen double r_annual_excl_trim_2010 = r_annual_excl_2010
replace r_annual_excl_trim_2010 = . if __p_ex10 <= 5 | __p_ex10 > 95
drop __p_ex10

di as txt "[summarize] r_period_2010_excl_res, r_annual_excl_2010, r_annual_excl_trim_2010"
summarize r_period_2010_excl_res r_annual_excl_2010 r_annual_excl_trim_2010

* ---------------------------------------------------------------------
* Prepare 2008 controls inline (married_2008, wealth_*_2008, age_2008, inlbrf_2008)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2008 controls (inline) ==="

* Marital status (2008): r9mstat -> married_2008
capture confirm variable r9mstat
if _rc {
    di as error "ERROR: r9mstat not found"
    exit 198
}

capture drop married_2008
gen byte married_2008 = .
replace married_2008 = 1 if inlist(r9mstat, 1, 2)
replace married_2008 = 0 if inlist(r9mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2008 yesno
label var married_2008 "Married (r9mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2008) summary:"
tab married_2008, missing

* Wealth percentile/deciles for 2008 using h9atotb
capture confirm variable h9atotb
if _rc {
    di as error "ERROR: h9atotb not found"
    exit 198
}

capture drop wealth_rank_2008 wealth_pct_2008
quietly count if !missing(h9atotb)
local N_wealth08 = r(N)
egen double wealth_rank_2008 = rank(h9atotb) if !missing(h9atotb)
gen double wealth_pct_2008 = .
replace wealth_pct_2008 = 100 * (wealth_rank_2008 - 1) / (`N_wealth08' - 1) if `N_wealth08' > 1 & !missing(wealth_rank_2008)
replace wealth_pct_2008 = 50 if `N_wealth08' == 1 & !missing(wealth_rank_2008)
label variable wealth_pct_2008 "Wealth percentile (based on h9atotb)"

di as txt "Wealth percentile (2008) summary:"
summarize wealth_pct_2008

capture drop wealth_decile_2008
xtile wealth_decile_2008 = h9atotb if !missing(h9atotb), n(10)
label var wealth_decile_2008 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2008):"
tab wealth_decile_2008, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2008
    gen byte wealth_d`d'_2008 = wealth_decile_2008 == `d' if !missing(wealth_decile_2008)
    label values wealth_d`d'_2008 yesno
    label var wealth_d`d'_2008 "Wealth decile `d' (2008)"
}

* Age (2008): r9agey_b -> age_2008
capture confirm variable r9agey_b
if _rc {
    di as error "ERROR: r9agey_b not found"
    exit 198
}

capture drop age_2008
gen double age_2008 = r9agey_b
label var age_2008 "Respondent age in 2008 (r9agey_b)"

di as txt "Age (2008) summary:"
summarize age_2008

* Employment (2008): r9inlbrf -> inlbrf_2008
capture confirm variable r9inlbrf
if _rc {
    di as error "ERROR: r9inlbrf not found"
    exit 198
}

capture drop inlbrf_2008
clonevar inlbrf_2008 = r9inlbrf
label var inlbrf_2008 "Labor force status in 2008 (r9inlbrf)"

di as txt "Employment (2008) distribution:"
tab inlbrf_2008, missing

* ---------------------------------------------------------------------
* Save back and print only overlap counts for all 7 years
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset (with 2010 flows and returns) ==="

* Overlap only: All 7-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010)
di as txt "  All 7 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010)
di as txt "  All 7 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010)
di as txt "  All 7 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010)
di as txt "  All 7 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


