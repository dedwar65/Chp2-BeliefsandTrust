*----------------------------------------------------------------------
* reg_panel_ret.do
* Compute asset shares for panel regression analysis (2000-2020)
* Based on RAND HRS longitudinal file variables and literature practices
*----------------------------------------------------------------------
clear all
capture log close
cd "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA"
log using "reg_panel_ret.log", replace text

set more off

* ---------------------------------------------------------------------
* File paths
* ---------------------------------------------------------------------
local long_file "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"
local out_ana   "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/HRS_Long/randhrs1992_2022v1_STATA/_randhrs1992_2022v1_analysis.dta"

* ---------------------------------------------------------------------
* Load unified analysis dataset
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
* Drop all existing asset share variables to allow re-running
* ---------------------------------------------------------------------
di as txt "=== Dropping existing asset share variables ==="
forvalues year = 2000(2)2020 {
    capture drop share_pri_res_`year' share_sec_res_`year' share_re_`year' share_vehicles_`year' share_bus_`year' share_ira_`year' share_stk_`year' share_chck_`year' share_cd_`year' share_bond_`year' share_other_`year' risky_share_`year'
}

* ---------------------------------------------------------------------
* Compute asset shares for each wave (2000-2020)
* Using exact variable names from returns computation files
* ---------------------------------------------------------------------
di as txt "=== Computing asset shares for waves 2000-2020 ==="

* 2000 (H5 variables)
di as txt "Computing asset shares for 2000 (Wave 5)"

gen double share_pri_res_2000 = h5atoth / h5atotb if !missing(h5atoth) & !missing(h5atotb) & h5atotb != 0
gen double share_sec_res_2000 = h5anethb / h5atotb if !missing(h5anethb) & !missing(h5atotb) & h5atotb != 0
gen double share_re_2000 = h5arles / h5atotb if !missing(h5arles) & !missing(h5atotb) & h5atotb != 0
gen double share_vehicles_2000 = h5atran / h5atotb if !missing(h5atran) & !missing(h5atotb) & h5atotb != 0
gen double share_bus_2000 = h5absns / h5atotb if !missing(h5absns) & !missing(h5atotb) & h5atotb != 0
gen double share_ira_2000 = h5aira / h5atotb if !missing(h5aira) & !missing(h5atotb) & h5atotb != 0
gen double share_stk_2000 = h5astck / h5atotb if !missing(h5astck) & !missing(h5atotb) & h5atotb != 0
gen double share_chck_2000 = h5achck / h5atotb if !missing(h5achck) & !missing(h5atotb) & h5atotb != 0
gen double share_cd_2000 = h5acd / h5atotb if !missing(h5acd) & !missing(h5atotb) & h5atotb != 0
gen double share_bond_2000 = h5abond / h5atotb if !missing(h5abond) & !missing(h5atotb) & h5atotb != 0
gen double share_other_2000 = h5aothr / h5atotb if !missing(h5aothr) & !missing(h5atotb) & h5atotb != 0
gen double risky_share_2000 = (h5astck + h5absns) / h5atotb if !missing(h5astck) & !missing(h5absns) & !missing(h5atotb) & h5atotb != 0
replace risky_share_2000 = h5astck / h5atotb if missing(h5absns) & !missing(h5astck) & !missing(h5atotb) & h5atotb != 0
replace risky_share_2000 = h5absns / h5atotb if missing(h5astck) & !missing(h5absns) & !missing(h5atotb) & h5atotb != 0

* 2002 (H6 variables)
di as txt "Computing asset shares for 2002 (Wave 6)"

gen double share_pri_res_2002 = h6atoth / h6atotb if !missing(h6atoth) & !missing(h6atotb) & h6atotb != 0
gen double share_sec_res_2002 = h6anethb / h6atotb if !missing(h6anethb) & !missing(h6atotb) & h6atotb != 0
gen double share_re_2002 = h6arles / h6atotb if !missing(h6arles) & !missing(h6atotb) & h6atotb != 0
gen double share_vehicles_2002 = h6atran / h6atotb if !missing(h6atran) & !missing(h6atotb) & h6atotb != 0
gen double share_bus_2002 = h6absns / h6atotb if !missing(h6absns) & !missing(h6atotb) & h6atotb != 0
gen double share_ira_2002 = h6aira / h6atotb if !missing(h6aira) & !missing(h6atotb) & h6atotb != 0
gen double share_stk_2002 = h6astck / h6atotb if !missing(h6astck) & !missing(h6atotb) & h6atotb != 0
gen double share_chck_2002 = h6achck / h6atotb if !missing(h6achck) & !missing(h6atotb) & h6atotb != 0
gen double share_cd_2002 = h6acd / h6atotb if !missing(h6acd) & !missing(h6atotb) & h6atotb != 0
gen double share_bond_2002 = h6abond / h6atotb if !missing(h6abond) & !missing(h6atotb) & h6atotb != 0
gen double share_other_2002 = h6aothr / h6atotb if !missing(h6aothr) & !missing(h6atotb) & h6atotb != 0
gen double risky_share_2002 = (h6astck + h6absns) / h6atotb if !missing(h6astck) & !missing(h6absns) & !missing(h6atotb) & h6atotb != 0
replace risky_share_2002 = h6astck / h6atotb if missing(h6absns) & !missing(h6astck) & !missing(h6atotb) & h6atotb != 0
replace risky_share_2002 = h6absns / h6atotb if missing(h6astck) & !missing(h6absns) & !missing(h6atotb) & h6atotb != 0

* 2004 (H7 variables)
di as txt "Computing asset shares for 2004 (Wave 7)"

gen double share_pri_res_2004 = h7atoth / h7atotb if !missing(h7atoth) & !missing(h7atotb) & h7atotb != 0
gen double share_sec_res_2004 = h7anethb / h7atotb if !missing(h7anethb) & !missing(h7atotb) & h7atotb != 0
gen double share_re_2004 = h7arles / h7atotb if !missing(h7arles) & !missing(h7atotb) & h7atotb != 0
gen double share_vehicles_2004 = h7atran / h7atotb if !missing(h7atran) & !missing(h7atotb) & h7atotb != 0
gen double share_bus_2004 = h7absns / h7atotb if !missing(h7absns) & !missing(h7atotb) & h7atotb != 0
gen double share_ira_2004 = h7aira / h7atotb if !missing(h7aira) & !missing(h7atotb) & h7atotb != 0
gen double share_stk_2004 = h7astck / h7atotb if !missing(h7astck) & !missing(h7atotb) & h7atotb != 0
gen double share_chck_2004 = h7achck / h7atotb if !missing(h7achck) & !missing(h7atotb) & h7atotb != 0
gen double share_cd_2004 = h7acd / h7atotb if !missing(h7acd) & !missing(h7atotb) & h7atotb != 0
gen double share_bond_2004 = h7abond / h7atotb if !missing(h7abond) & !missing(h7atotb) & h7atotb != 0
gen double share_other_2004 = h7aothr / h7atotb if !missing(h7aothr) & !missing(h7atotb) & h7atotb != 0
gen double risky_share_2004 = (h7astck + h7absns) / h7atotb if !missing(h7astck) & !missing(h7absns) & !missing(h7atotb) & h7atotb != 0
replace risky_share_2004 = h7astck / h7atotb if missing(h7absns) & !missing(h7astck) & !missing(h7atotb) & h7atotb != 0
replace risky_share_2004 = h7absns / h7atotb if missing(h7astck) & !missing(h7absns) & !missing(h7atotb) & h7atotb != 0

* 2006 (H8 variables)
di as txt "Computing asset shares for 2006 (Wave 8)"

gen double share_pri_res_2006 = h8atoth / h8atotb if !missing(h8atoth) & !missing(h8atotb) & h8atotb != 0
gen double share_sec_res_2006 = h8anethb / h8atotb if !missing(h8anethb) & !missing(h8atotb) & h8atotb != 0
gen double share_re_2006 = h8arles / h8atotb if !missing(h8arles) & !missing(h8atotb) & h8atotb != 0
gen double share_vehicles_2006 = h8atran / h8atotb if !missing(h8atran) & !missing(h8atotb) & h8atotb != 0
gen double share_bus_2006 = h8absns / h8atotb if !missing(h8absns) & !missing(h8atotb) & h8atotb != 0
gen double share_ira_2006 = h8aira / h8atotb if !missing(h8aira) & !missing(h8atotb) & h8atotb != 0
gen double share_stk_2006 = h8astck / h8atotb if !missing(h8astck) & !missing(h8atotb) & h8atotb != 0
gen double share_chck_2006 = h8achck / h8atotb if !missing(h8achck) & !missing(h8atotb) & h8atotb != 0
gen double share_cd_2006 = h8acd / h8atotb if !missing(h8acd) & !missing(h8atotb) & h8atotb != 0
gen double share_bond_2006 = h8abond / h8atotb if !missing(h8abond) & !missing(h8atotb) & h8atotb != 0
gen double share_other_2006 = h8aothr / h8atotb if !missing(h8aothr) & !missing(h8atotb) & h8atotb != 0
gen double risky_share_2006 = (h8astck + h8absns) / h8atotb if !missing(h8astck) & !missing(h8absns) & !missing(h8atotb) & h8atotb != 0
replace risky_share_2006 = h8astck / h8atotb if missing(h8absns) & !missing(h8astck) & !missing(h8atotb) & h8atotb != 0
replace risky_share_2006 = h8absns / h8atotb if missing(h8astck) & !missing(h8absns) & !missing(h8atotb) & h8atotb != 0

* 2008 (H9 variables)
di as txt "Computing asset shares for 2008 (Wave 9)"

gen double share_pri_res_2008 = h9atoth / h9atotb if !missing(h9atoth) & !missing(h9atotb) & h9atotb != 0
gen double share_sec_res_2008 = h9anethb / h9atotb if !missing(h9anethb) & !missing(h9atotb) & h9atotb != 0
gen double share_re_2008 = h9arles / h9atotb if !missing(h9arles) & !missing(h9atotb) & h9atotb != 0
gen double share_vehicles_2008 = h9atran / h9atotb if !missing(h9atran) & !missing(h9atotb) & h9atotb != 0
gen double share_bus_2008 = h9absns / h9atotb if !missing(h9absns) & !missing(h9atotb) & h9atotb != 0
gen double share_ira_2008 = h9aira / h9atotb if !missing(h9aira) & !missing(h9atotb) & h9atotb != 0
gen double share_stk_2008 = h9astck / h9atotb if !missing(h9astck) & !missing(h9atotb) & h9atotb != 0
gen double share_chck_2008 = h9achck / h9atotb if !missing(h9achck) & !missing(h9atotb) & h9atotb != 0
gen double share_cd_2008 = h9acd / h9atotb if !missing(h9acd) & !missing(h9atotb) & h9atotb != 0
gen double share_bond_2008 = h9abond / h9atotb if !missing(h9abond) & !missing(h9atotb) & h9atotb != 0
gen double share_other_2008 = h9aothr / h9atotb if !missing(h9aothr) & !missing(h9atotb) & h9atotb != 0
gen double risky_share_2008 = (h9astck + h9absns) / h9atotb if !missing(h9astck) & !missing(h9absns) & !missing(h9atotb) & h9atotb != 0
replace risky_share_2008 = h9astck / h9atotb if missing(h9absns) & !missing(h9astck) & !missing(h9atotb) & h9atotb != 0
replace risky_share_2008 = h9absns / h9atotb if missing(h9astck) & !missing(h9absns) & !missing(h9atotb) & h9atotb != 0

* 2010 (H10 variables)
di as txt "Computing asset shares for 2010 (Wave 10)"

gen double share_pri_res_2010 = h10atoth / h10atotb if !missing(h10atoth) & !missing(h10atotb) & h10atotb != 0
gen double share_sec_res_2010 = h10anethb / h10atotb if !missing(h10anethb) & !missing(h10atotb) & h10atotb != 0
gen double share_re_2010 = h10arles / h10atotb if !missing(h10arles) & !missing(h10atotb) & h10atotb != 0
gen double share_vehicles_2010 = h10atran / h10atotb if !missing(h10atran) & !missing(h10atotb) & h10atotb != 0
gen double share_bus_2010 = h10absns / h10atotb if !missing(h10absns) & !missing(h10atotb) & h10atotb != 0
gen double share_ira_2010 = h10aira / h10atotb if !missing(h10aira) & !missing(h10atotb) & h10atotb != 0
gen double share_stk_2010 = h10astck / h10atotb if !missing(h10astck) & !missing(h10atotb) & h10atotb != 0
gen double share_chck_2010 = h10achck / h10atotb if !missing(h10achck) & !missing(h10atotb) & h10atotb != 0
gen double share_cd_2010 = h10acd / h10atotb if !missing(h10acd) & !missing(h10atotb) & h10atotb != 0
gen double share_bond_2010 = h10abond / h10atotb if !missing(h10abond) & !missing(h10atotb) & h10atotb != 0
gen double share_other_2010 = h10aothr / h10atotb if !missing(h10aothr) & !missing(h10atotb) & h10atotb != 0
gen double risky_share_2010 = (h10astck + h10absns) / h10atotb if !missing(h10astck) & !missing(h10absns) & !missing(h10atotb) & h10atotb != 0
replace risky_share_2010 = h10astck / h10atotb if missing(h10absns) & !missing(h10astck) & !missing(h10atotb) & h10atotb != 0
replace risky_share_2010 = h10absns / h10atotb if missing(h10astck) & !missing(h10absns) & !missing(h10atotb) & h10atotb != 0

* 2012 (H11 variables)
di as txt "Computing asset shares for 2012 (Wave 11)"

gen double share_pri_res_2012 = h11atoth / h11atotb if !missing(h11atoth) & !missing(h11atotb) & h11atotb != 0
gen double share_sec_res_2012 = h11anethb / h11atotb if !missing(h11anethb) & !missing(h11atotb) & h11atotb != 0
gen double share_re_2012 = h11arles / h11atotb if !missing(h11arles) & !missing(h11atotb) & h11atotb != 0
gen double share_vehicles_2012 = h11atran / h11atotb if !missing(h11atran) & !missing(h11atotb) & h11atotb != 0
gen double share_bus_2012 = h11absns / h11atotb if !missing(h11absns) & !missing(h11atotb) & h11atotb != 0
gen double share_ira_2012 = h11aira / h11atotb if !missing(h11aira) & !missing(h11atotb) & h11atotb != 0
gen double share_stk_2012 = h11astck / h11atotb if !missing(h11astck) & !missing(h11atotb) & h11atotb != 0
gen double share_chck_2012 = h11achck / h11atotb if !missing(h11achck) & !missing(h11atotb) & h11atotb != 0
gen double share_cd_2012 = h11acd / h11atotb if !missing(h11acd) & !missing(h11atotb) & h11atotb != 0
gen double share_bond_2012 = h11abond / h11atotb if !missing(h11abond) & !missing(h11atotb) & h11atotb != 0
gen double share_other_2012 = h11aothr / h11atotb if !missing(h11aothr) & !missing(h11atotb) & h11atotb != 0
gen double risky_share_2012 = (h11astck + h11absns) / h11atotb if !missing(h11astck) & !missing(h11absns) & !missing(h11atotb) & h11atotb != 0
replace risky_share_2012 = h11astck / h11atotb if missing(h11absns) & !missing(h11astck) & !missing(h11atotb) & h11atotb != 0
replace risky_share_2012 = h11absns / h11atotb if missing(h11astck) & !missing(h11absns) & !missing(h11atotb) & h11atotb != 0

* 2014 (H12 variables)
di as txt "Computing asset shares for 2014 (Wave 12)"

gen double share_pri_res_2014 = h12atoth / h12atotb if !missing(h12atoth) & !missing(h12atotb) & h12atotb != 0
gen double share_sec_res_2014 = h12anethb / h12atotb if !missing(h12anethb) & !missing(h12atotb) & h12atotb != 0
gen double share_re_2014 = h12arles / h12atotb if !missing(h12arles) & !missing(h12atotb) & h12atotb != 0
gen double share_vehicles_2014 = h12atran / h12atotb if !missing(h12atran) & !missing(h12atotb) & h12atotb != 0
gen double share_bus_2014 = h12absns / h12atotb if !missing(h12absns) & !missing(h12atotb) & h12atotb != 0
gen double share_ira_2014 = h12aira / h12atotb if !missing(h12aira) & !missing(h12atotb) & h12atotb != 0
gen double share_stk_2014 = h12astck / h12atotb if !missing(h12astck) & !missing(h12atotb) & h12atotb != 0
gen double share_chck_2014 = h12achck / h12atotb if !missing(h12achck) & !missing(h12atotb) & h12atotb != 0
gen double share_cd_2014 = h12acd / h12atotb if !missing(h12acd) & !missing(h12atotb) & h12atotb != 0
gen double share_bond_2014 = h12abond / h12atotb if !missing(h12abond) & !missing(h12atotb) & h12atotb != 0
gen double share_other_2014 = h12aothr / h12atotb if !missing(h12aothr) & !missing(h12atotb) & h12atotb != 0
gen double risky_share_2014 = (h12astck + h12absns) / h12atotb if !missing(h12astck) & !missing(h12absns) & !missing(h12atotb) & h12atotb != 0
replace risky_share_2014 = h12astck / h12atotb if missing(h12absns) & !missing(h12astck) & !missing(h12atotb) & h12atotb != 0
replace risky_share_2014 = h12absns / h12atotb if missing(h12astck) & !missing(h12absns) & !missing(h12atotb) & h12atotb != 0

* 2016 (H13 variables)
di as txt "Computing asset shares for 2016 (Wave 13)"

gen double share_pri_res_2016 = h13atoth / h13atotb if !missing(h13atoth) & !missing(h13atotb) & h13atotb != 0
gen double share_sec_res_2016 = h13anethb / h13atotb if !missing(h13anethb) & !missing(h13atotb) & h13atotb != 0
gen double share_re_2016 = h13arles / h13atotb if !missing(h13arles) & !missing(h13atotb) & h13atotb != 0
gen double share_vehicles_2016 = h13atran / h13atotb if !missing(h13atran) & !missing(h13atotb) & h13atotb != 0
gen double share_bus_2016 = h13absns / h13atotb if !missing(h13absns) & !missing(h13atotb) & h13atotb != 0
gen double share_ira_2016 = h13aira / h13atotb if !missing(h13aira) & !missing(h13atotb) & h13atotb != 0
gen double share_stk_2016 = h13astck / h13atotb if !missing(h13astck) & !missing(h13atotb) & h13atotb != 0
gen double share_chck_2016 = h13achck / h13atotb if !missing(h13achck) & !missing(h13atotb) & h13atotb != 0
gen double share_cd_2016 = h13acd / h13atotb if !missing(h13acd) & !missing(h13atotb) & h13atotb != 0
gen double share_bond_2016 = h13abond / h13atotb if !missing(h13abond) & !missing(h13atotb) & h13atotb != 0
gen double share_other_2016 = h13aothr / h13atotb if !missing(h13aothr) & !missing(h13atotb) & h13atotb != 0
gen double risky_share_2016 = (h13astck + h13absns) / h13atotb if !missing(h13astck) & !missing(h13absns) & !missing(h13atotb) & h13atotb != 0
replace risky_share_2016 = h13astck / h13atotb if missing(h13absns) & !missing(h13astck) & !missing(h13atotb) & h13atotb != 0
replace risky_share_2016 = h13absns / h13atotb if missing(h13astck) & !missing(h13absns) & !missing(h13atotb) & h13atotb != 0

* 2018 (H14 variables)
di as txt "Computing asset shares for 2018 (Wave 14)"

gen double share_pri_res_2018 = h14atoth / h14atotb if !missing(h14atoth) & !missing(h14atotb) & h14atotb != 0
gen double share_sec_res_2018 = h14anethb / h14atotb if !missing(h14anethb) & !missing(h14atotb) & h14atotb != 0
gen double share_re_2018 = h14arles / h14atotb if !missing(h14arles) & !missing(h14atotb) & h14atotb != 0
gen double share_vehicles_2018 = h14atran / h14atotb if !missing(h14atran) & !missing(h14atotb) & h14atotb != 0
gen double share_bus_2018 = h14absns / h14atotb if !missing(h14absns) & !missing(h14atotb) & h14atotb != 0
gen double share_ira_2018 = h14aira / h14atotb if !missing(h14aira) & !missing(h14atotb) & h14atotb != 0
gen double share_stk_2018 = h14astck / h14atotb if !missing(h14astck) & !missing(h14atotb) & h14atotb != 0
gen double share_chck_2018 = h14achck / h14atotb if !missing(h14achck) & !missing(h14atotb) & h14atotb != 0
gen double share_cd_2018 = h14acd / h14atotb if !missing(h14acd) & !missing(h14atotb) & h14atotb != 0
gen double share_bond_2018 = h14abond / h14atotb if !missing(h14abond) & !missing(h14atotb) & h14atotb != 0
gen double share_other_2018 = h14aothr / h14atotb if !missing(h14aothr) & !missing(h14atotb) & h14atotb != 0
gen double risky_share_2018 = (h14astck + h14absns) / h14atotb if !missing(h14astck) & !missing(h14absns) & !missing(h14atotb) & h14atotb != 0
replace risky_share_2018 = h14astck / h14atotb if missing(h14absns) & !missing(h14astck) & !missing(h14atotb) & h14atotb != 0
replace risky_share_2018 = h14absns / h14atotb if missing(h14astck) & !missing(h14absns) & !missing(h14atotb) & h14atotb != 0

* 2020 (H15 variables)
di as txt "Computing asset shares for 2020 (Wave 15)"

gen double share_pri_res_2020 = h15atoth / h15atotb if !missing(h15atoth) & !missing(h15atotb) & h15atotb != 0
gen double share_sec_res_2020 = h15anethb / h15atotb if !missing(h15anethb) & !missing(h15atotb) & h15atotb != 0
gen double share_re_2020 = h15arles / h15atotb if !missing(h15arles) & !missing(h15atotb) & h15atotb != 0
gen double share_vehicles_2020 = h15atran / h15atotb if !missing(h15atran) & !missing(h15atotb) & h15atotb != 0
gen double share_bus_2020 = h15absns / h15atotb if !missing(h15absns) & !missing(h15atotb) & h15atotb != 0
gen double share_ira_2020 = h15aira / h15atotb if !missing(h15aira) & !missing(h15atotb) & h15atotb != 0
gen double share_stk_2020 = h15astck / h15atotb if !missing(h15astck) & !missing(h15atotb) & h15atotb != 0
gen double share_chck_2020 = h15achck / h15atotb if !missing(h15achck) & !missing(h15atotb) & h15atotb != 0
gen double share_cd_2020 = h15acd / h15atotb if !missing(h15acd) & !missing(h15atotb) & h15atotb != 0
gen double share_bond_2020 = h15abond / h15atotb if !missing(h15abond) & !missing(h15atotb) & h15atotb != 0
gen double share_other_2020 = h15aothr / h15atotb if !missing(h15aothr) & !missing(h15atotb) & h15atotb != 0
gen double risky_share_2020 = (h15astck + h15absns) / h15atotb if !missing(h15astck) & !missing(h15absns) & !missing(h15atotb) & h15atotb != 0
replace risky_share_2020 = h15astck / h15atotb if missing(h15absns) & !missing(h15astck) & !missing(h15atotb) & h15atotb != 0
replace risky_share_2020 = h15absns / h15atotb if missing(h15astck) & !missing(h15absns) & !missing(h15atotb) & h15atotb != 0


* ---------------------------------------------------------------------
* Compute liability shares for each wave (2000-2020)
* Liability share = other debt / total net wealth
* ---------------------------------------------------------------------
di as txt "=== Computing liability shares for waves 2000-2020 ==="

* Drop existing liability share variables to allow re-running
forvalues year = 2000(2)2020 {
    capture drop liability_share_`year'
}

* 2000 (H5 variables)
di as txt "Computing liability share for 2000 (Wave 5)"
gen double liability_share_2000 = h5adebt / h5atotb if !missing(h5adebt) & !missing(h5atotb) & h5atotb != 0
label var liability_share_2000 "Liability share (other debt / total wealth) 2000"

* 2002 (H6 variables)
di as txt "Computing liability share for 2002 (Wave 6)"
gen double liability_share_2002 = h6adebt / h6atotb if !missing(h6adebt) & !missing(h6atotb) & h6atotb != 0
label var liability_share_2002 "Liability share (other debt / total wealth) 2002"

* 2004 (H7 variables)
di as txt "Computing liability share for 2004 (Wave 7)"
gen double liability_share_2004 = h7adebt / h7atotb if !missing(h7adebt) & !missing(h7atotb) & h7atotb != 0
label var liability_share_2004 "Liability share (other debt / total wealth) 2004"

* 2006 (H8 variables)
di as txt "Computing liability share for 2006 (Wave 8)"
gen double liability_share_2006 = h8adebt / h8atotb if !missing(h8adebt) & !missing(h8atotb) & h8atotb != 0
label var liability_share_2006 "Liability share (other debt / total wealth) 2006"

* 2008 (H9 variables)
di as txt "Computing liability share for 2008 (Wave 9)"
gen double liability_share_2008 = h9adebt / h9atotb if !missing(h9adebt) & !missing(h9atotb) & h9atotb != 0
label var liability_share_2008 "Liability share (other debt / total wealth) 2008"

* 2010 (H10 variables)
di as txt "Computing liability share for 2010 (Wave 10)"
gen double liability_share_2010 = h10adebt / h10atotb if !missing(h10adebt) & !missing(h10atotb) & h10atotb != 0
label var liability_share_2010 "Liability share (other debt / total wealth) 2010"

* 2012 (H11 variables)
di as txt "Computing liability share for 2012 (Wave 11)"
gen double liability_share_2012 = h11adebt / h11atotb if !missing(h11adebt) & !missing(h11atotb) & h11atotb != 0
label var liability_share_2012 "Liability share (other debt / total wealth) 2012"

* 2014 (H12 variables)
di as txt "Computing liability share for 2014 (Wave 12)"
gen double liability_share_2014 = h12adebt / h12atotb if !missing(h12adebt) & !missing(h12atotb) & h12atotb != 0
label var liability_share_2014 "Liability share (other debt / total wealth) 2014"

* 2016 (H13 variables)
di as txt "Computing liability share for 2016 (Wave 13)"
gen double liability_share_2016 = h13adebt / h13atotb if !missing(h13adebt) & !missing(h13atotb) & h13atotb != 0
label var liability_share_2016 "Liability share (other debt / total wealth) 2016"

* 2018 (H14 variables)
di as txt "Computing liability share for 2018 (Wave 14)"
gen double liability_share_2018 = h14adebt / h14atotb if !missing(h14adebt) & !missing(h14atotb) & h14atotb != 0
label var liability_share_2018 "Liability share (other debt / total wealth) 2018"

* 2020 (H15 variables)
di as txt "Computing liability share for 2020 (Wave 15)"
gen double liability_share_2020 = h15adebt / h15atotb if !missing(h15adebt) & !missing(h15atotb) & h15atotb != 0
label var liability_share_2020 "Liability share (other debt / total wealth) 2020"


* ---------------------------------------------------------------------
* Note: Wave dummy variables are not needed in wide-format dataset
* ---------------------------------------------------------------------
di as txt "=== Note: Wave dummies not needed in wide-format dataset ==="
di as txt "The current dataset is in wide format (one row per person)"
di as txt "Wave dummies are only needed when converting to long format for panel analysis"
di as txt "Skipping wave dummy creation for now"

* ---------------------------------------------------------------------
* Compute non-residential wealth and deciles for each wave (2000-2020)
* ---------------------------------------------------------------------
di as txt "=== Computing non-residential wealth and deciles ==="

* Drop existing non-residential wealth variables
forvalues year = 2000(2)2020 {
    capture drop wealth_nonres_`year' wealth_nonres_decile_`year'
    forvalues d = 1/10 {
        capture drop wealth_nonres_d`d'_`year'
    }
}

* 2000 (H5 variables)
di as txt "Computing non-residential wealth for 2000 (Wave 5)"
gen double wealth_nonres_2000 = h5arles + h5absns + h5aira + h5astck + h5abond + h5achck + h5acd + h5atran + h5aothr - h5adebt if !missing(h5arles) | !missing(h5absns) | !missing(h5aira) | !missing(h5astck) | !missing(h5abond) | !missing(h5achck) | !missing(h5acd) | !missing(h5atran) | !missing(h5aothr) | !missing(h5adebt)
replace wealth_nonres_2000 = 0 if missing(wealth_nonres_2000) & (!missing(h5arles) | !missing(h5absns) | !missing(h5aira) | !missing(h5astck) | !missing(h5abond) | !missing(h5achck) | !missing(h5acd) | !missing(h5atran) | !missing(h5aothr) | !missing(h5adebt))

* 2002 (H6 variables)
di as txt "Computing non-residential wealth for 2002 (Wave 6)"
gen double wealth_nonres_2002 = h6arles + h6absns + h6aira + h6astck + h6abond + h6achck + h6acd + h6atran + h6aothr - h6adebt if !missing(h6arles) | !missing(h6absns) | !missing(h6aira) | !missing(h6astck) | !missing(h6abond) | !missing(h6achck) | !missing(h6acd) | !missing(h6atran) | !missing(h6aothr) | !missing(h6adebt)
replace wealth_nonres_2002 = 0 if missing(wealth_nonres_2002) & (!missing(h6arles) | !missing(h6absns) | !missing(h6aira) | !missing(h6astck) | !missing(h6abond) | !missing(h6achck) | !missing(h6acd) | !missing(h6atran) | !missing(h6aothr) | !missing(h6adebt))

* 2004 (H7 variables)
di as txt "Computing non-residential wealth for 2004 (Wave 7)"
gen double wealth_nonres_2004 = h7arles + h7absns + h7aira + h7astck + h7abond + h7achck + h7acd + h7atran + h7aothr - h7adebt if !missing(h7arles) | !missing(h7absns) | !missing(h7aira) | !missing(h7astck) | !missing(h7abond) | !missing(h7achck) | !missing(h7acd) | !missing(h7atran) | !missing(h7aothr) | !missing(h7adebt)
replace wealth_nonres_2004 = 0 if missing(wealth_nonres_2004) & (!missing(h7arles) | !missing(h7absns) | !missing(h7aira) | !missing(h7astck) | !missing(h7abond) | !missing(h7achck) | !missing(h7acd) | !missing(h7atran) | !missing(h7aothr) | !missing(h7adebt))

* 2006 (H8 variables)
di as txt "Computing non-residential wealth for 2006 (Wave 8)"
gen double wealth_nonres_2006 = h8arles + h8absns + h8aira + h8astck + h8abond + h8achck + h8acd + h8atran + h8aothr - h8adebt if !missing(h8arles) | !missing(h8absns) | !missing(h8aira) | !missing(h8astck) | !missing(h8abond) | !missing(h8achck) | !missing(h8acd) | !missing(h8atran) | !missing(h8aothr) | !missing(h8adebt)
replace wealth_nonres_2006 = 0 if missing(wealth_nonres_2006) & (!missing(h8arles) | !missing(h8absns) | !missing(h8aira) | !missing(h8astck) | !missing(h8abond) | !missing(h8achck) | !missing(h8acd) | !missing(h8atran) | !missing(h8aothr) | !missing(h8adebt))

* 2008 (H9 variables)
di as txt "Computing non-residential wealth for 2008 (Wave 9)"
gen double wealth_nonres_2008 = h9arles + h9absns + h9aira + h9astck + h9abond + h9achck + h9acd + h9atran + h9aothr - h9adebt if !missing(h9arles) | !missing(h9absns) | !missing(h9aira) | !missing(h9astck) | !missing(h9abond) | !missing(h9achck) | !missing(h9acd) | !missing(h9atran) | !missing(h9aothr) | !missing(h9adebt)
replace wealth_nonres_2008 = 0 if missing(wealth_nonres_2008) & (!missing(h9arles) | !missing(h9absns) | !missing(h9aira) | !missing(h9astck) | !missing(h9abond) | !missing(h9achck) | !missing(h9acd) | !missing(h9atran) | !missing(h9aothr) | !missing(h9adebt))

* 2010 (H10 variables)
di as txt "Computing non-residential wealth for 2010 (Wave 10)"
gen double wealth_nonres_2010 = h10arles + h10absns + h10aira + h10astck + h10abond + h10achck + h10acd + h10atran + h10aothr - h10adebt if !missing(h10arles) | !missing(h10absns) | !missing(h10aira) | !missing(h10astck) | !missing(h10abond) | !missing(h10achck) | !missing(h10acd) | !missing(h10atran) | !missing(h10aothr) | !missing(h10adebt)
replace wealth_nonres_2010 = 0 if missing(wealth_nonres_2010) & (!missing(h10arles) | !missing(h10absns) | !missing(h10aira) | !missing(h10astck) | !missing(h10abond) | !missing(h10achck) | !missing(h10acd) | !missing(h10atran) | !missing(h10aothr) | !missing(h10adebt))

* 2012 (H11 variables)
di as txt "Computing non-residential wealth for 2012 (Wave 11)"
gen double wealth_nonres_2012 = h11arles + h11absns + h11aira + h11astck + h11abond + h11achck + h11acd + h11atran + h11aothr - h11adebt if !missing(h11arles) | !missing(h11absns) | !missing(h11aira) | !missing(h11astck) | !missing(h11abond) | !missing(h11achck) | !missing(h11acd) | !missing(h11atran) | !missing(h11aothr) | !missing(h11adebt)
replace wealth_nonres_2012 = 0 if missing(wealth_nonres_2012) & (!missing(h11arles) | !missing(h11absns) | !missing(h11aira) | !missing(h11astck) | !missing(h11abond) | !missing(h11achck) | !missing(h11acd) | !missing(h11atran) | !missing(h11aothr) | !missing(h11adebt))

* 2014 (H12 variables)
di as txt "Computing non-residential wealth for 2014 (Wave 12)"
gen double wealth_nonres_2014 = h12arles + h12absns + h12aira + h12astck + h12abond + h12achck + h12acd + h12atran + h12aothr - h12adebt if !missing(h12arles) | !missing(h12absns) | !missing(h12aira) | !missing(h12astck) | !missing(h12abond) | !missing(h12achck) | !missing(h12acd) | !missing(h12atran) | !missing(h12aothr) | !missing(h12adebt)
replace wealth_nonres_2014 = 0 if missing(wealth_nonres_2014) & (!missing(h12arles) | !missing(h12absns) | !missing(h12aira) | !missing(h12astck) | !missing(h12abond) | !missing(h12achck) | !missing(h12acd) | !missing(h12atran) | !missing(h12aothr) | !missing(h12adebt))

* 2016 (H13 variables)
di as txt "Computing non-residential wealth for 2016 (Wave 13)"
gen double wealth_nonres_2016 = h13arles + h13absns + h13aira + h13astck + h13abond + h13achck + h13acd + h13atran + h13aothr - h13adebt if !missing(h13arles) | !missing(h13absns) | !missing(h13aira) | !missing(h13astck) | !missing(h13abond) | !missing(h13achck) | !missing(h13acd) | !missing(h13atran) | !missing(h13aothr) | !missing(h13adebt)
replace wealth_nonres_2016 = 0 if missing(wealth_nonres_2016) & (!missing(h13arles) | !missing(h13absns) | !missing(h13aira) | !missing(h13astck) | !missing(h13abond) | !missing(h13achck) | !missing(h13acd) | !missing(h13atran) | !missing(h13aothr) | !missing(h13adebt))

* 2018 (H14 variables)
di as txt "Computing non-residential wealth for 2018 (Wave 14)"
gen double wealth_nonres_2018 = h14arles + h14absns + h14aira + h14astck + h14abond + h14achck + h14acd + h14atran + h14aothr - h14adebt if !missing(h14arles) | !missing(h14absns) | !missing(h14aira) | !missing(h14astck) | !missing(h14abond) | !missing(h14achck) | !missing(h14acd) | !missing(h14atran) | !missing(h14aothr) | !missing(h14adebt)
replace wealth_nonres_2018 = 0 if missing(wealth_nonres_2018) & (!missing(h14arles) | !missing(h14absns) | !missing(h14aira) | !missing(h14astck) | !missing(h14abond) | !missing(h14achck) | !missing(h14acd) | !missing(h14atran) | !missing(h14aothr) | !missing(h14adebt))

* 2020 (H15 variables)
di as txt "Computing non-residential wealth for 2020 (Wave 15)"
gen double wealth_nonres_2020 = h15arles + h15absns + h15aira + h15astck + h15abond + h15achck + h15acd + h15atran + h15aothr - h15adebt if !missing(h15arles) | !missing(h15absns) | !missing(h15aira) | !missing(h15astck) | !missing(h15abond) | !missing(h15achck) | !missing(h15acd) | !missing(h15atran) | !missing(h15aothr) | !missing(h15adebt)
replace wealth_nonres_2020 = 0 if missing(wealth_nonres_2020) & (!missing(h15arles) | !missing(h15absns) | !missing(h15aira) | !missing(h15astck) | !missing(h15abond) | !missing(h15achck) | !missing(h15acd) | !missing(h15atran) | !missing(h15aothr) | !missing(h15adebt))


* ---------------------------------------------------------------------
* Create deciles for non-residential wealth for each wave
* ---------------------------------------------------------------------
di as txt "=== Creating non-residential wealth deciles ==="

forvalues year = 2000(2)2020 {
    di as txt "Creating deciles for `year'"
    
    * Create deciles (1-10) for non-residential wealth
    capture drop wealth_nonres_decile_`year'
    xtile wealth_nonres_decile_`year' = wealth_nonres_`year', nq(10)
    
    * Create dummy variables for each decile
    forvalues d = 1/10 {
        capture drop wealth_nonres_d`d'_`year'
        gen wealth_nonres_d`d'_`year' = (wealth_nonres_decile_`year' == `d') if !missing(wealth_nonres_decile_`year')
        label var wealth_nonres_d`d'_`year' "Non-residential wealth decile `d' (`year')"
    }
    
    * Label the decile variable
    label var wealth_nonres_decile_`year' "Non-residential wealth decile (`year')"
    label var wealth_nonres_`year' "Non-residential wealth (`year')"
}

* ---------------------------------------------------------------------
* Create wealth decile dummies for all years (2000-2020) to match wealth variables
* ---------------------------------------------------------------------
di as txt "=== Creating wealth decile dummies for all years (2000-2020) ==="

* Drop existing wealth decile dummies to allow re-running
forvalues year = 2000(2)2020 {
    forvalues d = 1/10 {
        capture drop wealth_d`d'_`year'
    }
}

* Create wealth decile dummies for each year (2000-2020)
forvalues year = 2000(2)2020 {
    di as txt "Creating wealth decile dummies for `year'"
    
    * Create dummy variables for each decile
    forvalues d = 1/10 {
        gen wealth_d`d'_`year' = (wealth_nonres_decile_`year' == `d') if !missing(wealth_nonres_decile_`year')
        label var wealth_d`d'_`year' "Wealth decile `d' (`year')"
    }
}

* ---------------------------------------------------------------------
* Create missing 2020 demographic variables
* ---------------------------------------------------------------------
di as txt "=== Creating missing 2020 demographic variables ==="

* Age (2020): r15agey_b -> age_2020
capture confirm variable r15agey_b
if _rc {
    di as error "ERROR: r15agey_b not found"
    exit 198
}
capture drop age_2020
gen double age_2020 = r15agey_b
label var age_2020 "Respondent age in 2020 (r15agey_b)"
di as txt "Age (2020) summary:"
summarize age_2020

* Employment (2020): r15inlbrf -> inlbrf_2020
capture confirm variable r15inlbrf
if _rc {
    di as error "ERROR: r15inlbrf not found"
    exit 198
}
capture drop inlbrf_2020
clonevar inlbrf_2020 = r15inlbrf
label var inlbrf_2020 "Labor force status in 2020 (r15inlbrf)"
di as txt "Employment (2020) distribution:"
tab inlbrf_2020, missing

* Marital status (2020): r15mstat -> married_2020
capture confirm variable r15mstat
if _rc {
    di as error "ERROR: r15mstat not found"
    exit 198
}
capture drop married_2020
gen byte married_2020 = .
replace married_2020 = 1 if inlist(r15mstat, 1, 2)
replace married_2020 = 0 if inlist(r15mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2020 yesno
label var married_2020 "Married (r15mstat: 1 or 2) vs not married (3-8)"
di as txt "Marital status (2020) summary:"
tab married_2020, missing

* Note: Immigration status is time-invariant - using original rabplace variable

* Create missing 2022 demographic variables to match return years (2022)
* Age (2022): r15agey_b -> age_2022
capture confirm variable r15agey_b
if _rc {
    di as error "ERROR: r15agey_b not found"
    exit 198
}
capture drop age_2022
gen double age_2022 = r15agey_b
label var age_2022 "Respondent age in 2022 (r15agey_b)"
di as txt "Age (2022) summary:"
summarize age_2022

* Employment (2022): r15inlbrf -> inlbrf_2022
capture confirm variable r15inlbrf
if _rc {
    di as error "ERROR: r15inlbrf not found"
    exit 198
}
capture drop inlbrf_2022
clonevar inlbrf_2022 = r15inlbrf
label var inlbrf_2022 "Labor force status in 2022 (r15inlbrf)"
di as txt "Employment (2022) distribution:"
tab inlbrf_2022, missing

* Marital status (2022): r15mstat -> married_2022
capture confirm variable r15mstat
if _rc {
    di as error "ERROR: r15mstat not found"
    exit 198
}
capture drop married_2022
gen byte married_2022 = .
replace married_2022 = 1 if inlist(r15mstat, 1, 2)
replace married_2022 = 0 if inlist(r15mstat, 3, 4, 5, 6, 7, 8)
label define yesno 0 "no" 1 "yes", replace
label values married_2022 yesno
label var married_2022 "Married (r15mstat: 1 or 2) vs not married (3-8)"
di as txt "Marital status (2022) summary:"
tab married_2022, missing

* ---------------------------------------------------------------------
* Compute average returns across all 11 years (2002-2022) for complete observations
* ---------------------------------------------------------------------
di as txt "=== Computing average returns across all 11 years (2002-2022) ==="

* Drop existing average return variables to allow re-running
capture drop r_annual_avg r_annual_excl_avg r_annual_trim_avg r_annual_excl_trim_avg

* Create indicator for complete 11-year overlap (included returns)
gen byte complete_11yr_incl = (!missing(r_annual_2022) & !missing(r_annual_2020) & !missing(r_annual_2018) & !missing(r_annual_2016) & !missing(r_annual_2014) & !missing(r_annual_2012) & !missing(r_annual_2010) & !missing(r_annual_2008) & !missing(r_annual_2006) & !missing(r_annual_2004) & !missing(r_annual_2002))

* Create indicator for complete 11-year overlap (excluded residential returns)
gen byte complete_11yr_excl = (!missing(r_annual_excl_2022) & !missing(r_annual_excl_2020) & !missing(r_annual_excl_2018) & !missing(r_annual_excl_2016) & !missing(r_annual_excl_2014) & !missing(r_annual_excl_2012) & !missing(r_annual_excl_2010) & !missing(r_annual_excl_2008) & !missing(r_annual_excl_2006) & !missing(r_annual_excl_2004) & !missing(r_annual_excl_2002))

* Create indicator for complete 11-year overlap (included, trimmed returns)
gen byte complete_11yr_trim = (!missing(r_annual_trim_2022) & !missing(r_annual_trim_2020) & !missing(r_annual_trim_2018) & !missing(r_annual_trim_2016) & !missing(r_annual_trim_2014) & !missing(r_annual_trim_2012) & !missing(r_annual_trim_2010) & !missing(r_annual_trim_2008) & !missing(r_annual_trim_2006) & !missing(r_annual_trim_2004) & !missing(r_annual_trim_2002))

* Create indicator for complete 11-year overlap (excluded residential, trimmed returns)
gen byte complete_11yr_excl_trim = (!missing(r_annual_excl_trim_2022) & !missing(r_annual_excl_trim_2020) & !missing(r_annual_excl_trim_2018) & !missing(r_annual_excl_trim_2016) & !missing(r_annual_excl_trim_2014) & !missing(r_annual_excl_trim_2012) & !missing(r_annual_excl_trim_2010) & !missing(r_annual_excl_trim_2008) & !missing(r_annual_excl_trim_2006) & !missing(r_annual_excl_trim_2004) & !missing(r_annual_excl_trim_2002))

* Report overlap counts
quietly count if complete_11yr_incl
di as txt "  Complete 11-year overlap (included): " r(N)
quietly count if complete_11yr_excl
di as txt "  Complete 11-year overlap (excl-res): " r(N)
quietly count if complete_11yr_trim
di as txt "  Complete 11-year overlap (included, trimmed): " r(N)
quietly count if complete_11yr_excl_trim
di as txt "  Complete 11-year overlap (excl-res, trimmed): " r(N)

* Compute average returns (arithmetic mean) for complete observations
di as txt "Computing average returns for complete 11-year observations..."

* Average included returns
gen double r_annual_avg = (r_annual_2022 + r_annual_2020 + r_annual_2018 + r_annual_2016 + r_annual_2014 + r_annual_2012 + r_annual_2010 + r_annual_2008 + r_annual_2006 + r_annual_2004 + r_annual_2002) / 11 if complete_11yr_incl
label var r_annual_avg "Average annual return (included residential) 2002-2022"

* Average excluded residential returns
gen double r_annual_excl_avg = (r_annual_excl_2022 + r_annual_excl_2020 + r_annual_excl_2018 + r_annual_excl_2016 + r_annual_excl_2014 + r_annual_excl_2012 + r_annual_excl_2010 + r_annual_excl_2008 + r_annual_excl_2006 + r_annual_excl_2004 + r_annual_excl_2002) / 11 if complete_11yr_excl
label var r_annual_excl_avg "Average annual return (excluded residential) 2002-2022"

* Average included, trimmed returns
gen double r_annual_trim_avg = (r_annual_trim_2022 + r_annual_trim_2020 + r_annual_trim_2018 + r_annual_trim_2016 + r_annual_trim_2014 + r_annual_trim_2012 + r_annual_trim_2010 + r_annual_trim_2008 + r_annual_trim_2006 + r_annual_trim_2004 + r_annual_trim_2002) / 11 if complete_11yr_trim
label var r_annual_trim_avg "Average annual return (included residential, trimmed) 2002-2022"

* Average excluded residential, trimmed returns
gen double r_annual_excl_trim_avg = (r_annual_excl_trim_2022 + r_annual_excl_trim_2020 + r_annual_excl_trim_2018 + r_annual_excl_trim_2016 + r_annual_excl_trim_2014 + r_annual_excl_trim_2012 + r_annual_excl_trim_2010 + r_annual_excl_trim_2008 + r_annual_excl_trim_2006 + r_annual_excl_trim_2004 + r_annual_excl_trim_2002) / 11 if complete_11yr_excl_trim
label var r_annual_excl_trim_avg "Average annual return (excluded residential, trimmed) 2002-2022"

* Summary statistics for average returns
di as txt "Summary statistics for average returns:"
summarize r_annual_avg r_annual_excl_avg r_annual_trim_avg r_annual_excl_trim_avg

* Count non-missing average returns
quietly count if !missing(r_annual_avg)
di as txt "Non-missing r_annual_avg: " r(N)
quietly count if !missing(r_annual_excl_avg)
di as txt "Non-missing r_annual_excl_avg: " r(N)
quietly count if !missing(r_annual_trim_avg)
di as txt "Non-missing r_annual_trim_avg: " r(N)
quietly count if !missing(r_annual_excl_trim_avg)
di as txt "Non-missing r_annual_excl_trim_avg: " r(N)

* ---------------------------------------------------------------------
* Save updated dataset
* ---------------------------------------------------------------------
di as txt "=== Saving updated analysis dataset with asset shares, non-residential wealth, 2020 demographics, and average returns ==="
save "`out_ana'", replace
di as txt "Saved: `out_ana'"

log close