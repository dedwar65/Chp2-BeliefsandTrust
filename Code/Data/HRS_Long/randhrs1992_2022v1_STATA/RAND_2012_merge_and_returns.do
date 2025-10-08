*----------------------------------------------------------------------
* RAND_2012_merge_and_returns.do
* Merge 2012 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2012; mirrors 2014/2016/2018/2020 pipeline with 2012 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2012_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2012  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2012/h12f3a_STATA/h12f3a.dta"
local out_ana   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Load unified dataset and check key
* ---------------------------------------------------------------------
di as txt "=== Loading unified analysis dataset ==="
capture confirm file "`long_file'"
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
* Load 2012 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2012 RAND fat file ==="
preserve
capture confirm file "`raw_2012'"
if _rc {
    di as error "ERROR: RAW 2012 file not found -> `raw_2012'"
    exit 198
}
use "`raw_2012'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2012"
    exit 198
}

* 2012 flow variables per notes
local flow12 "nr050 nr055 nr063 nr064 nr072 nr030 nr035 nr045 nq171_1 nq171_2 nq171_3 nr007 nr013 nr024"

di as txt "Checking presence of 2012 flow variables..."
foreach v of local flow12 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2012 RAW: `v'"
    else  di as txt  "  OK in 2012 RAW: `v'"
}

keep hhidpn `flow12'
tempfile raw12_flows
save "`raw12_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2012 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw12_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (mirror prior rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9 -9999999 -9999998
foreach v of local flow12 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2012 flow aggregates (suffix _2012)
* ---------------------------------------------------------------------
* nr063 direction and magnitude
capture drop nr063_dir12
gen byte nr063_dir12 = .
replace nr063_dir12 = -1 if nr063 == 1
replace nr063_dir12 =  1 if nr063 == 2
replace nr063_dir12 =  0 if nr063 == 3

capture drop flow_bus_2012
gen double flow_bus_2012 = .
replace flow_bus_2012 = nr055 - nr050 if !missing(nr055) & !missing(nr050)
replace flow_bus_2012 = nr055 if  missing(nr050) & !missing(nr055)
replace flow_bus_2012 = -nr050 if !missing(nr050) &  missing(nr055)

capture drop flow_stk_private_2012
gen double flow_stk_private_2012 = nr063_dir12 * nr064 if !missing(nr063_dir12) & !missing(nr064)

capture drop flow_stk_public_2012
gen double flow_stk_public_2012 = nr072 if !missing(nr072)

capture drop flow_stk_2012
gen double flow_stk_2012 = cond(!missing(flow_stk_private_2012), flow_stk_private_2012, 0) + ///
                           cond(!missing(flow_stk_public_2012),  flow_stk_public_2012,  0)
replace flow_stk_2012 = . if missing(flow_stk_private_2012) & missing(flow_stk_public_2012)

capture drop flow_re_2012
gen double flow_re_2012 = .
replace flow_re_2012 = cond(missing(nr035),0,nr035) - ( cond(missing(nr030),0,nr030) + cond(missing(nr045),0,nr045) ) if !missing(nr035) | !missing(nr030) | !missing(nr045)

capture drop flow_ira_2012
egen double flow_ira_2012 = rowtotal(nq171_1 nq171_2 nq171_3)
replace flow_ira_2012 = . if missing(nq171_1) & missing(nq171_2) & missing(nq171_3)

capture drop flow_residences_2012
gen double flow_residences_2012 = .
replace flow_residences_2012 = cond(missing(nr013),0,nr013) - ( cond(missing(nr007),0,nr007) + cond(missing(nr024),0,nr024) ) if !missing(nr013) | !missing(nr007) | !missing(nr024)
replace flow_residences_2012 = . if missing(nr013) & missing(nr007) & missing(nr024)

capture drop flow_total_2012
gen double flow_total_2012 = .
egen byte any_flow_present12 = rownonmiss(flow_bus_2012 flow_re_2012 flow_stk_2012 flow_ira_2012 flow_residences_2012)
replace flow_total_2012 = cond(missing(flow_bus_2012),0,flow_bus_2012) + ///
                          cond(missing(flow_re_2012),0,flow_re_2012) + ///
                          cond(missing(flow_stk_2012),0,flow_stk_2012) + ///
                          cond(missing(flow_ira_2012),0,flow_ira_2012) + ///
                          cond(missing(flow_residences_2012),0,flow_residences_2012) ///
                          if any_flow_present12 > 0
drop any_flow_present12

di as txt "Flows 2012 summaries:"
summarize flow_bus_2012 flow_re_2012 flow_stk_2012 flow_ira_2012 flow_residences_2012 flow_total_2012

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2012 (period 2010-2012)
* ---------------------------------------------------------------------
di as txt "=== Computing 2012 returns (2010-2012) ==="

* Denominator base: A_{2010}
capture drop a_2010
gen double a_2010 = h10atotb
label var a_2010 "Total net assets (A_2010 = h10atotb)"

* Capital income y^c_2012
capture drop y_c_2012
gen double y_c_2012 = h11icap
label var y_c_2012 "Capital income 2012 (h11icap)"

* Capital gains per class: cg_class = V_2012 - V_2010
capture drop cg_pri_res_2012 cg_sec_res_2012 cg_re_2012 cg_bus_2012 cg_ira_2012 cg_stk_2012 cg_bond_2012 cg_chck_2012 cg_cd_2012 cg_veh_2012 cg_oth_2012
gen double cg_pri_res_2012 = h11atoth - h10atoth

gen double cg_sec_res_2012 = h11anethb - h10anethb

gen double cg_re_2012      = h11arles - h10arles

gen double cg_bus_2012     = h11absns - h10absns

gen double cg_ira_2012     = h11aira  - h10aira

gen double cg_stk_2012     = h11astck - h10astck

gen double cg_bond_2012    = h11abond - h10abond

gen double cg_chck_2012    = h11achck - h10achck

gen double cg_cd_2012      = h11acd   - h10acd

gen double cg_veh_2012     = h11atran - h10atran

gen double cg_oth_2012     = h11aothr - h10aothr

* Summaries of each capital gains component
di as txt "Capital gains components (2010->2012) summaries:"
summarize cg_pri_res_2012 cg_sec_res_2012 cg_re_2012 cg_bus_2012 cg_ira_2012 cg_stk_2012 cg_bond_2012 cg_chck_2012 cg_cd_2012 cg_veh_2012 cg_oth_2012

* Total capital gains with missing logic
capture drop cg_total_2012
egen byte any_cg_2012 = rownonmiss(cg_pri_res_2012 cg_sec_res_2012 cg_re_2012 cg_bus_2012 cg_ira_2012 cg_stk_2012 cg_bond_2012 cg_chck_2012 cg_cd_2012 cg_veh_2012 cg_oth_2012)

gen double cg_total_2012 = .
replace cg_total_2012 = cond(missing(cg_pri_res_2012),0,cg_pri_res_2012) + ///
                        cond(missing(cg_sec_res_2012),0,cg_sec_res_2012) + ///
                        cond(missing(cg_re_2012),0,cg_re_2012) + ///
                        cond(missing(cg_bus_2012),0,cg_bus_2012) + ///
                        cond(missing(cg_ira_2012),0,cg_ira_2012) + ///
                        cond(missing(cg_stk_2012),0,cg_stk_2012) + ///
                        cond(missing(cg_bond_2012),0,cg_bond_2012) + ///
                        cond(missing(cg_chck_2012),0,cg_chck_2012) + ///
                        cond(missing(cg_cd_2012),0,cg_cd_2012) + ///
                        cond(missing(cg_veh_2012),0,cg_veh_2012) + ///
                        cond(missing(cg_oth_2012),0,cg_oth_2012) if any_cg_2012>0

drop any_cg_2012

* Diagnostics
di as txt "[summarize] y_c_2012, cg_total_2012, flow_total_2012"
summarize y_c_2012 cg_total_2012 flow_total_2012

* Base: A_2010 + 0.5 * F_2012 (treat flows as 0 only when A_2010 is non-missing)
capture drop base_2012
gen double base_2012 = .
replace base_2012 = a_2010 + 0.5 * cond(missing(flow_total_2012),0,flow_total_2012) if !missing(a_2010)
label var base_2012 "Base for 2012 returns (A_2010 + 0.5*F_2012)"

di as txt "[summarize] base_2012"
summarize base_2012, detail

* Period return and annualization (2-year)
capture drop num_period_2012 r_period_2012 r_annual_2012 r_annual_2012_trim
gen double num_period_2012 = cond(missing(y_c_2012),0,y_c_2012) + ///
                             cond(missing(cg_total_2012),0,cg_total_2012) - ///
                             cond(missing(flow_total_2012),0,flow_total_2012)

egen byte __num12_has = rownonmiss(y_c_2012 cg_total_2012 flow_total_2012)
replace num_period_2012 = . if __num12_has == 0

drop __num12_has

gen double r_period_2012 = num_period_2012 / base_2012
replace r_period_2012 = . if base_2012 < 10000

gen double r_annual_2012 = (1 + r_period_2012)^(1/2) - 1
replace r_annual_2012 = . if missing(r_period_2012)

* Trim 5% tails
capture drop r_annual_2012_trim
xtile __p_2012 = r_annual_2012 if !missing(r_annual_2012), n(100)

gen double r_annual_2012_trim = r_annual_2012
replace r_annual_2012_trim = . if __p_2012 <= 5 | __p_2012 > 95

drop __p_2012

di as txt "[summarize] r_period_2012, r_annual_2012, r_annual_2012_trim"
summarize r_period_2012 r_annual_2012 r_annual_2012_trim

* Excluding residential housing
capture drop cg_total_2012_excl_res flow_total_2012_excl_res

gen double flow_total_2012_excl_res = .
egen byte any_flow12_excl = rownonmiss(flow_bus_2012 flow_re_2012 flow_stk_2012 flow_ira_2012)
replace flow_total_2012_excl_res = cond(missing(flow_bus_2012),0,flow_bus_2012) + ///
                                   cond(missing(flow_re_2012),0,flow_re_2012) + ///
                                   cond(missing(flow_stk_2012),0,flow_stk_2012) + ///
                                   cond(missing(flow_ira_2012),0,flow_ira_2012) if any_flow12_excl>0

drop any_flow12_excl

gen double cg_total_2012_excl_res = .
egen byte any_cg12_excl = rownonmiss(cg_re_2012 cg_bus_2012 cg_ira_2012 cg_stk_2012 cg_bond_2012 cg_chck_2012 cg_cd_2012 cg_veh_2012 cg_oth_2012)
replace cg_total_2012_excl_res = cond(missing(cg_re_2012),0,cg_re_2012) + ///
                                 cond(missing(cg_bus_2012),0,cg_bus_2012) + ///
                                 cond(missing(cg_ira_2012),0,cg_ira_2012) + ///
                                 cond(missing(cg_stk_2012),0,cg_stk_2012) + ///
                                 cond(missing(cg_bond_2012),0,cg_bond_2012) + ///
                                 cond(missing(cg_chck_2012),0,cg_chck_2012) + ///
                                 cond(missing(cg_cd_2012),0,cg_cd_2012) + ///
                                 cond(missing(cg_veh_2012),0,cg_veh_2012) + ///
                                 cond(missing(cg_oth_2012),0,cg_oth_2012) if any_cg12_excl>0

drop any_cg12_excl


di as txt "EXCL-RES: cg_total_2012_excl_res and flow_total_2012_excl_res summaries:"
summarize cg_total_2012_excl_res flow_total_2012_excl_res

* Use SAME base_2012
capture drop num_period_2012_excl_res r_period_2012_excl_res r_annual_2012_excl_res r_annual_2012_excl_res_trim

gen double num_period_2012_excl_res = cond(missing(y_c_2012),0,y_c_2012) + ///
                                      cond(missing(cg_total_2012_excl_res),0,cg_total_2012_excl_res) - ///
                                      cond(missing(flow_total_2012_excl_res),0,flow_total_2012_excl_res)

egen byte __num12ex_has = rownonmiss(y_c_2012 cg_total_2012_excl_res flow_total_2012_excl_res)
replace num_period_2012_excl_res = . if __num12ex_has == 0

drop __num12ex_has

gen double r_period_2012_excl_res = num_period_2012_excl_res / base_2012
replace r_period_2012_excl_res = . if base_2012 < 10000

gen double r_annual_2012_excl_res = (1 + r_period_2012_excl_res)^(1/2) - 1
replace r_annual_2012_excl_res = . if missing(r_period_2012_excl_res)

* Trim 5% for excl-res
xtile __p_ex12 = r_annual_2012_excl_res if !missing(r_annual_2012_excl_res), n(100)

gen double r_annual_2012_excl_res_trim = r_annual_2012_excl_res
replace r_annual_2012_excl_res_trim = . if __p_ex12 <= 5 | __p_ex12 > 95

drop __p_ex12

di as txt "[summarize] r_period_2012_excl_res, r_annual_2012_excl_res, r_annual_2012_excl_res_trim"
summarize r_period_2012_excl_res r_annual_2012_excl_res r_annual_2012_excl_res_trim

* ---------------------------------------------------------------------
* Prepare 2010 controls inline (married_2010, wealth_*_2010, age_2010, inlbrf_2010)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2010 controls (inline) ==="

* Marital status (2010): r10mstat -> married_2010
capture confirm variable r10mstat
if _rc {
    di as error "ERROR: r10mstat not found"
    exit 198
}

capture drop married_2010
gen byte married_2010 = .
replace married_2010 = 1 if inlist(r10mstat, 1, 2)
replace married_2010 = 0 if inlist(r10mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2010 yesno
label var married_2010 "Married (r10mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2010) summary:"
tab married_2010, missing

* Wealth percentile/deciles for 2010 using h10atotb
capture confirm variable h10atotb
if _rc {
    di as error "ERROR: h10atotb not found"
    exit 198
}

capture drop wealth_rank_2010 wealth_pct_2010
quietly count if !missing(h10atotb)
local N_wealth10 = r(N)

egen double wealth_rank_2010 = rank(h10atotb) if !missing(h10atotb)

gen double wealth_pct_2010 = .
replace wealth_pct_2010 = 100 * (wealth_rank_2010 - 1) / (`N_wealth10' - 1) if `N_wealth10' > 1 & !missing(wealth_rank_2010)
replace wealth_pct_2010 = 50 if `N_wealth10' == 1 & !missing(wealth_rank_2010)

label variable wealth_pct_2010 "Wealth percentile (based on h10atotb)"

di as txt "Wealth percentile (2010) summary:"
summarize wealth_pct_2010

capture drop wealth_decile_2010
xtile wealth_decile_2010 = h10atotb if !missing(h10atotb), n(10)
label var wealth_decile_2010 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2010):"
tab wealth_decile_2010, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2010
    gen byte wealth_d`d'_2010 = wealth_decile_2010 == `d' if !missing(wealth_decile_2010)
    label values wealth_d`d'_2010 yesno
    label var wealth_d`d'_2010 "Wealth decile `d' (2010)"
}

* Age (2010): r10agey_b -> age_2010
capture confirm variable r10agey_b
if _rc {
    di as error "ERROR: r10agey_b not found"
    exit 198
}

capture drop age_2010
gen double age_2010 = r10agey_b
label var age_2010 "Respondent age in 2010 (r10agey_b)"

di as txt "Age (2010) summary:"
summarize age_2010

* Employment (2010): r10inlbrf -> inlbrf_2010
capture confirm variable r10inlbrf
if _rc {
    di as error "ERROR: r10inlbrf not found"
    exit 198
}

capture drop inlbrf_2010
clonevar inlbrf_2010 = r10inlbrf
label var inlbrf_2010 "Labor force status in 2010 (r10inlbrf)"

di as txt "Employment (2010) distribution:"
tab inlbrf_2010, missing

* Save back to unified analysis dataset

di as txt "=== Saving updated analysis dataset (with 2012 flows and returns) ==="

* Overlap only: All 6-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012)

di as txt "  All 6 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_2022_excl_res) & !missing(r_annual_2020_excl_res) & !missing(r_annual_2018_excl_res) & !missing(r_annual_2016_excl_res) & !missing(r_annual_2014_excl_res) & !missing(r_annual_2012_excl_res)

di as txt "  All 6 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_2022_trim) & !missing(r_annual_2020_trim) & !missing(r_annual_2018_trim) & !missing(r_annual_2016_trim) & !missing(r_annual_2014_trim) & !missing(r_annual_2012_trim)

di as txt "  All 6 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_2022_excl_res_trim) & !missing(r_annual_2020_excl_res_trim) & !missing(r_annual_2018_excl_res_trim) & !missing(r_annual_2016_excl_res_trim) & !missing(r_annual_2014_excl_res_trim) & !missing(r_annual_2012_excl_res_trim)

di as txt "  All 6 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace

di as txt "Saved: `out_ana'"

log close
