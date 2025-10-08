*----------------------------------------------------------------------
* RAND_2016_merge_and_returns.do
* Merge 2016 flow variables from HRS RAND raw fat file and prepare for returns
* (Single-file workflow for 2016; mirrors 2018/2020 pipeline with 2016 naming)
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "RAND_2016_merge_and_returns.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local raw_2016  "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_RAND/_raw/2016/h16f2c_STATA/h16f2c.dta"
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
* Load 2016 RAND fat file and extract flows
* ---------------------------------------------------------------------
di as txt "=== Loading 2016 RAND fat file ==="
preserve
capture confirm file "`raw_2016'"
if _rc {
    di as error "ERROR: RAW 2016 file not found -> `raw_2016'"
    exit 198
}
use "`raw_2016'", clear
capture confirm variable hhidpn
if _rc {
    di as error "ERROR: hhidpn not found in RAW 2016"
    exit 198
}

* 2016 flow variables per notes
local flow16 "pr050 pr055 pr063 pr064 pr072 pr030 pr035 pr045 pq171_1 pq171_2 pq171_3 pr007 pr013 pr024"

di as txt "Checking presence of 2016 flow variables..."
foreach v of local flow16 {
    capture confirm variable `v'
    if _rc di as warn "  MISSING in 2016 RAW: `v'"
    else  di as txt  "  OK in 2016 RAW: `v'"
}

keep hhidpn `flow16'
tempfile raw16_flows
save "`raw16_flows'", replace
restore

* ---------------------------------------------------------------------
* Merge flows into unified dataset
* ---------------------------------------------------------------------
di as txt "=== Merging 2016 flows into unified dataset ==="
merge 1:1 hhidpn using "`raw16_flows'", keep(master match)
tab _merge
drop _merge

* ---------------------------------------------------------------------
* Clean special/miscodes for flow inputs (mirror prior rules)
* ---------------------------------------------------------------------
local misscodes 999998 999999 9999999 99999998 99999999 999999999 999999998 9999999999 9999999998 -8 -9
foreach v of local flow16 {
    capture confirm numeric variable `v'
    if !_rc {
        foreach mc of local misscodes {
            quietly replace `v' = . if `v' == `mc'
        }
    }
}

* ---------------------------------------------------------------------
* Compute 2016 flow aggregates (suffix _2016)
* ---------------------------------------------------------------------
* pr063 direction and magnitude
capture drop pr063_dir16
gen byte pr063_dir16 = .
replace pr063_dir16 = -1 if pr063 == 1
replace pr063_dir16 =  1 if pr063 == 2
replace pr063_dir16 =  0 if pr063 == 3

capture drop flow_bus_2016
gen double flow_bus_2016 = .
replace flow_bus_2016 = pr055 - pr050 if !missing(pr055) & !missing(pr050)
replace flow_bus_2016 = pr055 if  missing(pr050) & !missing(pr055)
replace flow_bus_2016 = -pr050 if !missing(pr050) &  missing(pr055)

capture drop flow_stk_private_2016
gen double flow_stk_private_2016 = pr063_dir16 * pr064 if !missing(pr063_dir16) & !missing(pr064)

capture drop flow_stk_public_2016
gen double flow_stk_public_2016 = pr072 if !missing(pr072)

capture drop flow_stk_2016
gen double flow_stk_2016 = cond(!missing(flow_stk_private_2016), flow_stk_private_2016, 0) + ///
                           cond(!missing(flow_stk_public_2016),  flow_stk_public_2016,  0)
replace flow_stk_2016 = . if missing(flow_stk_private_2016) & missing(flow_stk_public_2016)

capture drop flow_re_2016
gen double flow_re_2016 = .
replace flow_re_2016 = cond(missing(pr035),0,pr035) - ( cond(missing(pr030),0,pr030) + cond(missing(pr045),0,pr045) ) if !missing(pr035) | !missing(pr030) | !missing(pr045)

capture drop flow_ira_2016
egen double flow_ira_2016 = rowtotal(pq171_1 pq171_2 pq171_3)
replace flow_ira_2016 = . if missing(pq171_1) & missing(pq171_2) & missing(pq171_3)

capture drop flow_residences_2016
gen double flow_residences_2016 = .
replace flow_residences_2016 = cond(missing(pr013),0,pr013) - ( cond(missing(pr007),0,pr007) + cond(missing(pr024),0,pr024) ) if !missing(pr013) | !missing(pr007) | !missing(pr024)
replace flow_residences_2016 = . if missing(pr013) & missing(pr007) & missing(pr024)

capture drop flow_total_2016
gen double flow_total_2016 = .
egen byte any_flow_present16 = rownonmiss(flow_bus_2016 flow_re_2016 flow_stk_2016 flow_ira_2016 flow_residences_2016)
replace flow_total_2016 = cond(missing(flow_bus_2016),0,flow_bus_2016) + ///
                          cond(missing(flow_re_2016),0,flow_re_2016) + ///
                          cond(missing(flow_stk_2016),0,flow_stk_2016) + ///
                          cond(missing(flow_ira_2016),0,flow_ira_2016) + ///
                          cond(missing(flow_residences_2016),0,flow_residences_2016) ///
                          if any_flow_present16 > 0
drop any_flow_present16

di as txt "Flows 2016 summaries:"
summarize flow_bus_2016 flow_re_2016 flow_stk_2016 flow_ira_2016 flow_residences_2016 flow_total_2016

* ---------------------------------------------------------------------
* Compute TOTAL RETURNS for 2016 (period 2014-2016)
* ---------------------------------------------------------------------
di as txt "=== Computing 2016 returns (2014-2016) ==="

* Denominator base: A_{2014}
capture drop a_2014
gen double a_2014 = h12atotb
label var a_2014 "Total net assets (A_2014 = h12atotb)"

* Capital income y^c_2016
capture drop y_c_2016
gen double y_c_2016 = h13icap
label var y_c_2016 "Capital income 2016 (h13icap)"

* Capital gains per class: cg_class = V_2016 - V_2014
capture drop cg_pri_res_2016 cg_sec_res_2016 cg_re_2016 cg_bus_2016 cg_ira_2016 cg_stk_2016 cg_bond_2016 cg_chck_2016 cg_cd_2016 cg_veh_2016 cg_oth_2016
gen double cg_pri_res_2016 = h13atoth - h12atoth
gen double cg_sec_res_2016 = h13anethb - h12anethb
gen double cg_re_2016      = h13arles - h12arles
gen double cg_bus_2016     = h13absns - h12absns
gen double cg_ira_2016     = h13aira  - h12aira
gen double cg_stk_2016     = h13astck - h12astck
gen double cg_bond_2016    = h13abond - h12abond
gen double cg_chck_2016    = h13achck - h12achck
gen double cg_cd_2016      = h13acd   - h12acd
gen double cg_veh_2016     = h13atran - h12atran
gen double cg_oth_2016     = h13aothr - h12aothr

di as txt "Capital gains components (2014->2016) summaries:"
summarize cg_pri_res_2016 cg_sec_res_2016 cg_re_2016 cg_bus_2016 cg_ira_2016 cg_stk_2016 cg_bond_2016 cg_chck_2016 cg_cd_2016 cg_veh_2016 cg_oth_2016

* Total capital gains with missing logic
capture drop cg_total_2016
egen byte any_cg_2016 = rownonmiss(cg_pri_res_2016 cg_sec_res_2016 cg_re_2016 cg_bus_2016 cg_ira_2016 cg_stk_2016 cg_bond_2016 cg_chck_2016 cg_cd_2016 cg_veh_2016 cg_oth_2016)
gen double cg_total_2016 = .
replace cg_total_2016 = cond(missing(cg_pri_res_2016),0,cg_pri_res_2016) + ///
                        cond(missing(cg_sec_res_2016),0,cg_sec_res_2016) + ///
                        cond(missing(cg_re_2016),0,cg_re_2016) + ///
                        cond(missing(cg_bus_2016),0,cg_bus_2016) + ///
                        cond(missing(cg_ira_2016),0,cg_ira_2016) + ///
                        cond(missing(cg_stk_2016),0,cg_stk_2016) + ///
                        cond(missing(cg_bond_2016),0,cg_bond_2016) + ///
                        cond(missing(cg_chck_2016),0,cg_chck_2016) + ///
                        cond(missing(cg_cd_2016),0,cg_cd_2016) + ///
                        cond(missing(cg_veh_2016),0,cg_veh_2016) + ///
                        cond(missing(cg_oth_2016),0,cg_oth_2016) if any_cg_2016>0
drop any_cg_2016

di as txt "[summarize] y_c_2016, cg_total_2016, flow_total_2016"
summarize y_c_2016 cg_total_2016 flow_total_2016

* Base: A_2014 + 0.5 * F_2016 (treat flows as 0 only when A_2014 is non-missing)
capture drop base_2016
gen double base_2016 = .
replace base_2016 = a_2014 + 0.5 * cond(missing(flow_total_2016),0,flow_total_2016) if !missing(a_2014)
label var base_2016 "Base for 2016 returns (A_2014 + 0.5*F_2016)"
di as txt "[summarize] base_2016"
summarize base_2016, detail

* Period return and annualization (2-year)
capture drop num_period_2016 r_period_2016 r_annual_2016 r_annual_2016_trim
gen double num_period_2016 = cond(missing(y_c_2016),0,y_c_2016) + ///
                             cond(missing(cg_total_2016),0,cg_total_2016) - ///
                             cond(missing(flow_total_2016),0,flow_total_2016)
egen byte __num16_has = rownonmiss(y_c_2016 cg_total_2016 flow_total_2016)
replace num_period_2016 = . if __num16_has == 0
drop __num16_has

gen double r_period_2016 = num_period_2016 / base_2016
replace r_period_2016 = . if base_2016 < 10000
gen double r_annual_2016 = (1 + r_period_2016)^(1/2) - 1
replace r_annual_2016 = . if missing(r_period_2016)

* Trim 5% tails
capture drop r_annual_2016_trim
xtile __p_2016 = r_annual_2016 if !missing(r_annual_2016), n(100)
gen double r_annual_2016_trim = r_annual_2016
replace r_annual_2016_trim = . if __p_2016 <= 5 | __p_2016 > 95
drop __p_2016

di as txt "[summarize] r_period_2016, r_annual_2016, r_annual_2016_trim"
summarize r_period_2016 r_annual_2016 r_annual_2016_trim

* Excluding residential housing
capture drop cg_total_2016_excl_res flow_total_2016_excl_res
gen double flow_total_2016_excl_res = .
egen byte any_flow16_excl = rownonmiss(flow_bus_2016 flow_re_2016 flow_stk_2016 flow_ira_2016)
replace flow_total_2016_excl_res = cond(missing(flow_bus_2016),0,flow_bus_2016) + ///
                                   cond(missing(flow_re_2016),0,flow_re_2016) + ///
                                   cond(missing(flow_stk_2016),0,flow_stk_2016) + ///
                                   cond(missing(flow_ira_2016),0,flow_ira_2016) if any_flow16_excl>0
drop any_flow16_excl

gen double cg_total_2016_excl_res = .
egen byte any_cg16_excl = rownonmiss(cg_re_2016 cg_bus_2016 cg_ira_2016 cg_stk_2016 cg_bond_2016 cg_chck_2016 cg_cd_2016 cg_veh_2016 cg_oth_2016)
replace cg_total_2016_excl_res = cond(missing(cg_re_2016),0,cg_re_2016) + ///
                                 cond(missing(cg_bus_2016),0,cg_bus_2016) + ///
                                 cond(missing(cg_ira_2016),0,cg_ira_2016) + ///
                                 cond(missing(cg_stk_2016),0,cg_stk_2016) + ///
                                 cond(missing(cg_bond_2016),0,cg_bond_2016) + ///
                                 cond(missing(cg_chck_2016),0,cg_chck_2016) + ///
                                 cond(missing(cg_cd_2016),0,cg_cd_2016) + ///
                                 cond(missing(cg_veh_2016),0,cg_veh_2016) + ///
                                 cond(missing(cg_oth_2016),0,cg_oth_2016) if any_cg16_excl>0
drop any_cg16_excl

di as txt "EXCL-RES: cg_total_2016_excl_res and flow_total_2016_excl_res summaries:"
summarize cg_total_2016_excl_res flow_total_2016_excl_res

* Use SAME base_2016
capture drop num_period_2016_excl_res r_period_2016_excl_res r_annual_2016_excl_res r_annual_2016_excl_res_trim
gen double num_period_2016_excl_res = cond(missing(y_c_2016),0,y_c_2016) + ///
                                      cond(missing(cg_total_2016_excl_res),0,cg_total_2016_excl_res) - ///
                                      cond(missing(flow_total_2016_excl_res),0,flow_total_2016_excl_res)
egen byte __num16ex_has = rownonmiss(y_c_2016 cg_total_2016_excl_res flow_total_2016_excl_res)
replace num_period_2016_excl_res = . if __num16ex_has == 0
drop __num16ex_has

gen double r_period_2016_excl_res = num_period_2016_excl_res / base_2016
replace r_period_2016_excl_res = . if base_2016 < 10000
gen double r_annual_2016_excl_res = (1 + r_period_2016_excl_res)^(1/2) - 1
replace r_annual_2016_excl_res = . if missing(r_period_2016_excl_res)

* Trim 5% for excl-res
xtile __p_ex16 = r_annual_2016_excl_res if !missing(r_annual_2016_excl_res), n(100)
gen double r_annual_2016_excl_res_trim = r_annual_2016_excl_res
replace r_annual_2016_excl_res_trim = . if __p_ex16 <= 5 | __p_ex16 > 95
drop __p_ex16

di as txt "[summarize] r_period_2016_excl_res, r_annual_2016_excl_res, r_annual_2016_excl_res_trim"
summarize r_period_2016_excl_res r_annual_2016_excl_res r_annual_2016_excl_res_trim

* ---------------------------------------------------------------------
* Prepare 2014 controls inline (married_2014, wealth_*_2014, age_2014, inlbrf_2014)
* ---------------------------------------------------------------------
di as txt "=== Preparing 2014 controls (inline) ==="

* Marital status (2014): r12mstat -> married_2014
capture confirm variable r12mstat
if _rc {
    di as error "ERROR: r12mstat not found"
    exit 198
}
capture drop married_2014
gen byte married_2014 = .
replace married_2014 = 1 if inlist(r12mstat, 1, 2)
replace married_2014 = 0 if inlist(r12mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2014 yesno
label var married_2014 "Married (r12mstat: 1 or 2) vs not married (3-8)"
di as txt "Marital status (2014) summary:"
tab married_2014, missing

* Wealth percentile/deciles for 2014 using h12atotb
capture confirm variable h12atotb
if _rc {
    di as error "ERROR: h12atotb not found"
    exit 198
}
capture drop wealth_rank_2014 wealth_pct_2014
quietly count if !missing(h12atotb)
local N_wealth14 = r(N)
egen double wealth_rank_2014 = rank(h12atotb) if !missing(h12atotb)
gen double wealth_pct_2014 = .
replace wealth_pct_2014 = 100 * (wealth_rank_2014 - 1) / (`N_wealth14' - 1) if `N_wealth14' > 1 & !missing(wealth_rank_2014)
replace wealth_pct_2014 = 50 if `N_wealth14' == 1 & !missing(wealth_rank_2014)
label variable wealth_pct_2014 "Wealth percentile (based on h12atotb)"
di as txt "Wealth percentile (2014) summary:"
summarize wealth_pct_2014

capture drop wealth_decile_2014
xtile wealth_decile_2014 = h12atotb if !missing(h12atotb), n(10)
label var wealth_decile_2014 "Wealth decile (1=lowest,10=highest)"
di as txt "Wealth decile distribution (2014):"
tab wealth_decile_2014, missing

forvalues d = 1/10 {
    capture drop wealth_d`d'_2014
    gen byte wealth_d`d'_2014 = wealth_decile_2014 == `d' if !missing(wealth_decile_2014)
    label values wealth_d`d'_2014 yesno
    label var wealth_d`d'_2014 "Wealth decile `d' (2014)"
}

* Age (2014): carry r12agey_b to age_2014
capture confirm variable r12agey_b
if _rc {
    di as error "ERROR: r12agey_b not found"
    exit 198
}
capture drop age_2014
gen double age_2014 = r12agey_b
label var age_2014 "Respondent age in 2014 (r12agey_b)"
di as txt "Age (2014) summary:"
summarize age_2014

* Employment (2014): carry r12inlbrf to inlbrf_2014
capture confirm variable r12inlbrf
if _rc {
    di as error "ERROR: r12inlbrf not found"
    exit 198
}
capture drop inlbrf_2014
clonevar inlbrf_2014 = r12inlbrf
label var inlbrf_2014 "Labor force status in 2014 (r12inlbrf)"
di as txt "Employment (2014) distribution:"
tab inlbrf_2014, missing

* Save back to unified analysis dataset
di as txt "=== Saving updated analysis dataset (with 2016 flows and returns) ==="

* Overlap only: All 4-year overlap (included/excl-res)
di as txt "=== Overlap across years (counts) ==="
quietly count if !missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016)
di as txt "  All 4 years (included): " %9.0f r(N)
quietly count if !missing(r_annual_2022_excl_res) & !missing(r_annual_2020_excl_res) & !missing(r_annual_2018_excl_res) & !missing(r_annual_2016_excl_res)
di as txt "  All 4 years (excl-res): " %9.0f r(N)

* Trimmed overlaps
quietly count if !missing(r_annual_2022_trim) & !missing(r_annual_2020_trim) & !missing(r_annual_2018_trim) & !missing(r_annual_2016_trim)
di as txt "  All 4 years (included, trimmed): " %9.0f r(N)
quietly count if !missing(r_annual_2022_excl_res_trim) & !missing(r_annual_2020_excl_res_trim) & !missing(r_annual_2018_excl_res_trim) & !missing(r_annual_2016_excl_res_trim)
di as txt "  All 4 years (excl-res, trimmed): " %9.0f r(N)

save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close


