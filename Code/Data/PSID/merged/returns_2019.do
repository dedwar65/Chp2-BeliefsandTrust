*******************************************************
* compute_returns.do
* Compute 2019 returns from merged 2017–2019 PSID data
*******************************************************

clear

* 1) Load the merged file
use "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/PSID/merged/rep_DP2024_2017_2019.dta", clear

* ----------------------------------------------------------------------------
* 2) Interest income (y_c): reported interest + dividends
gen int_income  = ER73143   // interest income (2019)
gen div_income  = ER73126   // dividend income (2019)
gen yc19        = int_income + div_income
label var yc19  "Interest + dividends (y_c_2019)"

summarize yc19

* ----------------------------------------------------------------------------
* 3) Net investment flows (F_t):
*    Sum across asset classes: (invest – divest) for business, stocks, RE, pensions

* Clean extreme values in net investment flow variables (2019)
local flow_vars ER73947 ER73952 ER73957 ER73963 ER73933 ER73938 ER73917 ER73922

foreach var of local flow_vars {
    replace `var' = . if inlist(`var', 999999997, 999999998, 999999999, -999999998, -999999999)
}

gen F_bus19    = ER73947  - ER73952    // business
gen F_stk19    = ER73957  - ER73963    // stocks
gen F_re19     = ER73933  - ER73938    // real estate (non-primary)
gen F_pen19    = ER73917  - ER73922    // pensions/IRAs
gen Ftot19     = F_bus19 + F_stk19 + F_re19 + F_pen19

summarize F_bus19
summarize F_stk19
summarize F_re19
summarize F_pen19

label var Ftot19 "Net investment flows (F_2019)"

summarize Ftot19

* ----------------------------------------------------------------------------
* 4) Capital gains by asset class per Daminato (2024):
*    cg_class = V2019 - V2017  (flows ignored)
* ----------------------------------------------------------------------------

foreach var in ER67789 ER67826 ER67798 ER67776 ER67784 ER67819 ER67847 ER71481 ER67793 ER67852 ER67862 ER67867 ER67872 ER67877 ER67883 {
    replace `var' = . if inlist(`var', 999999998, 999999999, 1000000000)
}


* Business
gen cg_bus = ER77451 - ER67789
label var cg_bus "Capital gains: business (no flow adjustment)"
summarize cg_bus
gen neg_cg_bus = cg_bus < 0 if !missing(cg_bus)
count if neg_cg_bus

* Rents (other real estate)
gen cg_rents = ER77465 - ER67776
label var cg_rents "Capital gains: other RE (no flow adj.)"
summarize cg_rents
gen neg_cg_rents = cg_rents < 0 if !missing(cg_rents)
count if neg_cg_rents

* Home equity
gen cg_home = ER77507 - ER71481
label var cg_home "Capital gains: home equity"
summarize cg_home
gen neg_cg_home = cg_home < 0 if !missing(cg_home)
count if neg_cg_home

* Stocks
gen cg_stocks = ER77471 - ER67798
label var cg_stocks "Capital gains: stocks (no flow adj.)"
summarize cg_stocks
gen neg_cg_stocks = cg_stocks < 0 if !missing(cg_stocks)
count if neg_cg_stocks

* Pensions/IRAs
gen cg_pens = ER77481 - ER67819
label var cg_pens "Capital gains: pensions/IRAs (no flow adj.)"
summarize cg_pens
gen neg_cg_pens = cg_pens < 0 if !missing(cg_pens)
count if neg_cg_pens

* Total capital gains
gen cg19 = cg_bus + cg_rents + cg_home + cg_stocks + cg_pens
label var cg19 "Total capital gains (2017→2019, per paper)"
summarize cg19
gen neg_cg19 = cg19 < 0 if !missing(cg19)
count if neg_cg19


* ----------------------------------------------------------------------------
* 5) Debt payments (y_d): annual mortgage P&I
*    Here we use reported monthly payments ER72064 & ER72118; if you compute via formula, replace
gen mort1_mo = ER72053  // first‐mortgage monthly P&I
gen mort2_mo = ER72074  // second‐mortgage monthly P&I
gen yd19     = 12*(mort1_mo + mort2_mo)
label var yd19 "Annual mortgage payments (y_d_2019)"

summarize yd19

* ----------------------------------------------------------------------------
* 6) Beginning‐period net wealth (A_{t-1})
*    From 2017 imputed asset components minus debts:
gen A17 = (ER67789 + ER67826 + ER67798 + ER67776 + ER67784 + ER67819 + ER67847 + ER71481) - (ER67793 + ER67852 + ER67862 + ER67867 + ER67872 + ER67877 + ER67883)
label var A17 "Imputed net wealth excl. equity (2017)"

summarize A17

* ----------------------------------------------------------------------------
* 7) Prepare & inspect denominator for return
* ----------------------------------------------------------------------------

* 7a) Compute the denominator explicitly
gen denom19 = A17 + 0.5*Ftot19
label var denom19 "Denominator for ret19: A17 + .5*Ftot19"

* How many denominators are missing?
count if missing(denom19)
di as txt "Missing denominators: " as res r(N)

* How many denominators are zero or negative?
count if denom19 <= 0
di as txt "Zero or negative denominators: " as res r(N)

* List a few to inspect why
list hid A17 Ftot19 denom19 in 1/20 if denom19 <= 0 | missing(denom19)

summarize denom19

* ----------------------------------------------------------------------------
* 8) Compute the return for 2017→2019, only when denom19 > 0
* ----------------------------------------------------------------------------

gen ret19 = .  
replace ret19 = (yc19 + cg19 - yd19) / denom19 ///
    if denom19 > 0 & denom19 < .

label var ret19 "Return to net wealth 2017-19"

* ----------------------------------------------------------------------------
* 9) Quick diagnostics on ret19
* ----------------------------------------------------------------------------

di _newline "=== Return summary ==="
summarize ret19, detail

di _newline "=== Missing count for ret19 ==="
count if missing(ret19)
di as txt r(N) " observations missing ret19"

di _newline "=== Distribution of ret19 ==="
histogram ret19, normal width(.05) ///
    title("Distribution of ret19") subtitle("2017→2019")

* 10) Spot‐check some households
di _newline "=== Spot‐check first 10 obs ==="
list hid A17 Ftot19 yc19 cg19 yd19 denom19 ret19 in 1/10

* 11) Save a working copy
save "/Volumes/SSD PRO/Github-forks/Chp2-BeliefsandTrust/Code/Data/PSID/merged/rep_DP2024_2017_2019_with_ret.dta", replace
