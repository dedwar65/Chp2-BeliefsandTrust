*----------------------------------------------------------------------
* RAND_2014_merge_and_returns.do
* Merge 2014 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2014; mirrors 2016/2018/2020 pipeline with 2014 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2014_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2014  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2014/h14f2b_STATA/h14f2b.dta"
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
* Load 2014 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2014 RAND fat file ==="
preserve
capture confirm file "`raw_2014'"
if _rc {
    di as error "ERROR: RAW 2014 file not found -> `raw_2014'"
    exit 198
}
use "`raw_2014'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2014"
    exit 198
}

* 2014 flow variables per notes
local flow14 "or050 or055 or063 or064 or072 or030 or035 or045 oq171_1 oq171_2 oq171_3 or007 or013 or024"

di as txt "Checking presence of 2014 flow variables..."
foreach v of local flow14 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2014 RAW: `v'"
    else  di as txt  "  OK in 2014 RAW: `v'"
}

keep hhidpn `flow14'
tempfile raw14_flows
save "`raw14_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2014 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw14_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (mirror prior rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 9999998 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of local flow14 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2014 flow aggregates (suffix _2014)
* ---------------------------------------------------------------------
* or063 direction and magnitude
capture drop or063_dir14
gen byte or063_dir14 = .
replace or063_dir14 = -1 if or063 == 1
replace or063_dir14 =  1 if or063 == 2
replace or063_dir14 =  0 if or063 == 3

capture drop flow_bus_2014
gen double flow_bus_2014 = .
replace flow_bus_2014 = or055 - or050 if !missing(or055) & !missing(or050)
replace flow_bus_2014 = or055 if  missing(or050) & !missing(or055)
replace flow_bus_2014 = -or050 if !missing(or050) &  missing(or055)

capture drop flow_stk_private_2014
gen double flow_stk_private_2014 = or063_dir14 * or064 if !missing(or063_dir14) & !missing(or064)

capture drop flow_stk_public_2014
gen double flow_stk_public_2014 = or072 if !missing(or072)

capture drop flow_stk_2014
gen double flow_stk_2014 = cond(!missing(flow_stk_private_2014), flow_stk_private_2014, 0) + ///
                           cond(!missing(flow_stk_public_2014),  flow_stk_public_2014,  0)
replace flow_stk_2014 = . if missing(flow_stk_private_2014) & missing(flow_stk_public_2014)

capture drop flow_re_2014
gen double flow_re_2014 = .
replace flow_re_2014 = cond(missing(or035),0,or035) - ( cond(missing(or030),0,or030) + cond(missing(or045),0,or045) ) if !missing(or035) | !missing(or030) | !missing(or045)

capture drop flow_ira_2014
egen double flow_ira_2014 = rowtotal(oq171_1 oq171_2 oq171_3)
replace flow_ira_2014 = . if missing(oq171_1) & missing(oq171_2) & missing(oq171_3)

capture drop flow_residences_2014
gen double flow_residences_2014 = .
replace flow_residences_2014 = cond(missing(or013),0,or013) - ( cond(missing(or007),0,or007) + cond(missing(or024),0,or024) ) if !missing(or013) | !missing(or007) | !missing(or024)
replace flow_residences_2014 = . if missing(or013) & missing(or007) & missing(or024)

capture drop flow_total_2014
gen double flow_total_2014 = .
egen byte any_flow_present14 = rownonmiss(flow_bus_2014 flow_re_2014 flow_stk_2014 flow_ira_2014 flow_residences_2014)
replace flow_total_2014 = cond(missing(flow_bus_2014),0,flow_bus_2014) + ///
                          cond(missing(flow_re_2014),0,flow_re_2014) + ///
                          cond(missing(flow_stk_2014),0,flow_stk_2014) + ///
                          cond(missing(flow_ira_2014),0,flow_ira_2014) + ///
                          cond(missing(flow_residences_2014),0,flow_residences_2014) ///
                          if any_flow_present14 > 0
drop any_flow_present14

di as txt "Flows 2014 summaries:"
summarize flow_bus_2014 flow_re_2014 flow_stk_2014 flow_ira_2014 flow_residences_2014 flow_total_2014

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2014 (period 2012-2014)
* ---------------------------------------------------------------------
di as txt "=== Computing 2014 returns (2012-2014) ==="

* Denominator base: A_{2012}
capture drop a_2012
gen double a_2012 = h11atotb
label var a_2012 "Total net assets (A_2012 = h11atotb)"

* Capital income y^c_2014
capture drop y_c_2014
gen double y_c_2014 = h12icap
label var y_c_2014 "Capital income 2014 (h12icap)"

* Capital gains per class: cg_class = V_2014 - V_2012
capture drop cg_pri_res_2014 cg_sec_res_2014 cg_re_2014 cg_bus_2014 cg_ira_2014 cg_stk_2014 cg_bond_2014 cg_chck_2014 cg_cd_2014 cg_veh_2014 cg_oth_2014
gen double cg_pri_res_2014 = h12atoth - h11atoth

gen double cg_sec_res_2014 = h12anethb - h11anethb

gen double cg_re_2014      = h12arles - h11arles

gen double cg_bus_2014     = h12absns - h11absns

gen double cg_ira_2014     = h12aira  - h11aira

gen double cg_stk_2014     = h12astck - h11astck

gen double cg_bond_2014    = h12abond - h11abond

gen double cg_chck_2014    = h12achck - h11achck

gen double cg_cd_2014      = h12acd   - h11acd

gen double cg_veh_2014     = h12atran - h11atran

gen double cg_oth_2014     = h12aothr - h11aothr

* Summaries of each capital gains component
di as txt "Capital gains components (2012->2014) summaries:"
summarize cg_pri_res_2014 cg_sec_res_2014 cg_re_2014 cg_bus_2014 cg_ira_2014 cg_stk_2014 cg_bond_2014 cg_chck_2014 cg_cd_2014 cg_veh_2014 cg_oth_2014

* Total capital gains with missing logic
capture drop cg_total_2014
egen byte any_cg_2014 = rownonmiss(cg_pri_res_2014 cg_sec_res_2014 cg_re_2014 cg_bus_2014 cg_ira_2014 cg_stk_2014 cg_bond_2014 cg_chck_2014 cg_cd_2014 cg_veh_2014 cg_oth_2014)


gen double cg_total_2014 = .
replace cg_total_2014 = cond(missing(cg_pri_res_2014),0,cg_pri_res_2014) + ///
                        cond(missing(cg_sec_res_2014),0,cg_sec_res_2014) + ///
                        cond(missing(cg_re_2014),0,cg_re_2014) + ///
                        cond(missing(cg_bus_2014),0,cg_bus_2014) + ///
                        cond(missing(cg_ira_2014),0,cg_ira_2014) + ///
                        cond(missing(cg_stk_2014),0,cg_stk_2014) + ///
                        cond(missing(cg_bond_2014),0,cg_bond_2014) + ///
                        cond(missing(cg_chck_2014),0,cg_chck_2014) + ///
                        cond(missing(cg_cd_2014),0,cg_cd_2014) + ///
                        cond(missing(cg_veh_2014),0,cg_veh_2014) + ///
                        cond(missing(cg_oth_2014),0,cg_oth_2014) if any_cg_2014>0

drop any_cg_2014

* Diagnostics
di as txt "[summarize] y_c_2014, cg_total_2014, flow_total_2014"
summarize y_c_2014 cg_total_2014 flow_total_2014

* Base: A_2012 + 0.5 * F_2014 (treat flows as 0 only when A_2012 is non-missing)
capture drop base_2014
gen double base_2014 = .
replace base_2014 = a_2012 + 0.5 * cond(missing(flow_total_2014),0,flow_total_2014) if !missing(a_2012)
label var base_2014 "Base for 2014 returns (A_2012 + 0.5*F_2014)"

di as txt "[summarize] base_2014"
summarize base_2014, detail

* Period return and annualization (2-year)
capture drop num_period_2014 r_period_2014 r_annual_2014 r_annual_trim_2014
gen double num_period_2014 = cond(missing(y_c_2014),0,y_c_2014) + ///
                             cond(missing(cg_total_2014),0,cg_total_2014) - ///
                             cond(missing(flow_total_2014),0,flow_total_2014)

egen byte __num14_has = rownonmiss(y_c_2014 cg_total_2014 flow_total_2014)
replace num_period_2014 = . if __num14_has == 0

drop __num14_has

gen double r_period_2014 = num_period_2014 / base_2014
replace r_period_2014 = . if base_2014 < 10000

gen double r_annual_2014 = (1 + r_period_2014)^(1/2) - 1
replace r_annual_2014 = . if missing(r_period_2014)

* Trim 5% tails
capture drop r_annual_trim_2014
xtile __p_2014 = r_annual_2014 if !missing(r_annual_2014), n(100)

gen double r_annual_trim_2014 = r_annual_2014
replace r_annual_trim_2014 = . if __p_2014 <= 5 | __p_2014 > 95

drop __p_2014

di as txt "[summarize] r_period_2014, r_annual_2014, r_annual_trim_2014"
summarize r_period_2014 r_annual_2014 r_annual_trim_2014

* Excluding residential housing
capture drop cg_total_2014_excl_res flow_total_2014_excl_res

gen double flow_total_2014_excl_res = .
egen byte any_flow14_excl = rownonmiss(flow_bus_2014 flow_re_2014 flow_stk_2014 flow_ira_2014)
replace flow_total_2014_excl_res = cond(missing(flow_bus_2014),0,flow_bus_2014) + ///
                                   cond(missing(flow_re_2014),0,flow_re_2014) + ///
                                   cond(missing(flow_stk_2014),0,flow_stk_2014) + ///
                                   cond(missing(flow_ira_2014),0,flow_ira_2014) if any_flow14_excl>0

drop any_flow14_excl

gen double cg_total_2014_excl_res = .
egen byte any_cg14_excl = rownonmiss(cg_re_2014 cg_bus_2014 cg_ira_2014 cg_stk_2014 cg_bond_2014 cg_chck_2014 cg_cd_2014 cg_veh_2014 cg_oth_2014)
replace cg_total_2014_excl_res = cond(missing(cg_re_2014),0,cg_re_2014) + ///
                                 cond(missing(cg_bus_2014),0,cg_bus_2014) + ///
                                 cond(missing(cg_ira_2014),0,cg_ira_2014) + ///
                                 cond(missing(cg_stk_2014),0,cg_stk_2014) + ///
                                 cond(missing(cg_bond_2014),0,cg_bond_2014) + ///
                                 cond(missing(cg_chck_2014),0,cg_chck_2014) + ///
                                 cond(missing(cg_cd_2014),0,cg_cd_2014) + ///
                                 cond(missing(cg_veh_2014),0,cg_veh_2014) + ///
                                 cond(missing(cg_oth_2014),0,cg_oth_2014) if any_cg14_excl>0

drop any_cg14_excl


di as txt "EXCL-RES: cg_total_2014_excl_res and flow_total_2014_excl_res summaries:"
summarize cg_total_2014_excl_res flow_total_2014_excl_res

* Use SAME base_2014
capture drop num_period_2014_excl_res r_period_2014_excl_res r_annual_excl_2014 r_annual_excl_trim_2014

gen double num_period_2014_excl_res = cond(missing(y_c_2014),0,y_c_2014) + ///
                                      cond(missing(cg_total_2014_excl_res),0,cg_total_2014_excl_res) - ///
                                      cond(missing(flow_total_2014_excl_res),0,flow_total_2014_excl_res)

egen byte __num14ex_has = rownonmiss(y_c_2014 cg_total_2014_excl_res flow_total_2014_excl_res)
replace num_period_2014_excl_res = . if __num14ex_has == 0

drop __num14ex_has

gen double r_period_2014_excl_res = num_period_2014_excl_res / base_2014
replace r_period_2014_excl_res = . if base_2014 < 10000

gen double r_annual_excl_2014 = (1 + r_period_2014_excl_res)^(1/2) - 1
replace r_annual_excl_2014 = . if missing(r_period_2014_excl_res)

* Trim 5% for excl-res
xtile __p_ex14 = r_annual_excl_2014 if !missing(r_annual_excl_2014), n(100)

gen double r_annual_excl_trim_2014 = r_annual_excl_2014
replace r_annual_excl_trim_2014 = . if __p_ex14 <= 5 | __p_ex14 > 95

drop __p_ex14

di as txt "[summarize] r_period_2014_excl_res, r_annual_excl_2014, r_annual_excl_trim_2014"
summarize r_period_2014_excl_res r_annual_excl_2014 r_annual_excl_trim_2014

* ---------------------------------------------------------------------
* Prepare 2012 controls inline (married_2012, wealth_*_2012, age_2012, inlbrf_2012)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2012 controls (inline) ==="

* Marital status (2012): r11mstat -> married_2012
capture confirm variable r11mstat
if _rc {
    di as error "ERROR: r11mstat not found"
    exit 198
}

capture drop married_2012
gen byte married_2012 = .
replace married_2012 = 1 if inlist(r11mstat, 1, 2)
replace married_2012 = 0 if inlist(r11mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2012 yesno
label var married_2012 "Married (r11mstat: 1 or 2) vs not married (3-8)"

di as txt "Marital status (2012) summary:"
tab married_2012, missing

* Wealth percentile/deciles for 2012 using h11atotb
capture confirm variable h11atotb
if _rc {
    di as error "ERROR: h11atotb not found"
    exit 198
}

capture drop wealth_rank_2012 wealth_pct_2012
quietly count if !missing(h11atotb)
local N_wealth12 = r(N)


egen double wealth_rank_2012 = rank(h11atotb) if !missing(h11atotb)

gen double wealth_pct_2012 = .
replace wealth_pct_2012 = 100 * (wealth_rank_2012 - 1) / (`N_wealth12' - 1) if `N_wealth12' > 1 & !missing(wealth_rank_2012)
replace wealth_pct_2012 = 50 if `N_wealth12' == 1 & !missing(wealth_rank_2012)

label variable wealth_pct_2012 "Wealth percentile (based on h11atotb)"

di as txt "Wealth percentile (2012) summary:"
summarize wealth_pct_2012

capture drop wealth_decile_2012
xtile wealth_decile_2012 = h11atotb if !missing(h11atotb), n(10)
label var wealth_decile_2012 "Wealth decile (1=lowest,10=highest)"

di as txt "Wealth decile distribution (2012):"
tab wealth_decile_2012, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2012
    gen byte wealth_d`d'_2012 = wealth_decile_2012 == `d' if !missing(wealth_decile_2012)
    label values wealth_d`d'_2012 yesno
    label var wealth_d`d'_2012 "Wealth decile `d' (2012)"
}

* Age (2012): carry r11agey_b to age_2012
capture confirm variable r11agey_b
if _rc {
    di as error "ERROR: r11agey_b not found"
    exit 198
}

capture drop age_2012
gen double age_2012 = r11agey_b
label var age_2012 "Respondent age in 2012 (r11agey_b)"

di as txt "Age (2012) summary:"
summarize age_2012

* Employment (2012): carry r11inlbrf to inlbrf_2012
capture confirm variable r11inlbrf
if _rc {
    di as error "ERROR: r11inlbrf not found"
    exit 198
}

capture drop inlbrf_2012
clonevar inlbrf_2012 = r11inlbrf
label var inlbrf_2012 "Labor force status in 2012 (r11inlbrf)"

di as txt "Employment (2012) distribution:"
tab inlbrf_2012, missing

* Save back to unified analysis dataset

di as txt "=== Saving updated analysis dataset (with 2014 flows and returns) ==="

* Overlap only: All 5-year overlap (included/excl-res and trimmed)
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014)

di as txt "  All 5 years (included): " %9.0f r(N)

quietly count if !missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014)

di as txt "  All 5 years (excl-res): " %9.0f r(N)

quietly count if !missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014)

di as txt "  All 5 years (included, trimmed): " %9.0f r(N)

quietly count if !missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014)

di as txt "  All 5 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace

di as txt "Saved: `out_ana'"

log close
