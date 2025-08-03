*******************************************************
* Inspect extreme values in 2019 net investment flows
*******************************************************

local flow_vars F_bus19 F_stk19 F_re19 F_pen19 Ftot19

foreach var of local flow_vars {
    di "Summary for `var'"
    
    count if `var' < -1e7
    di as txt "Observations with `var' < -1e7: " r(N)
    
    count if `var' > 1e7
    di as txt "Observations with `var' > 1e7: " r(N)
    
    summarize `var' if `var' < -1e7 | `var' > 1e7, detail
    
    di "Listing extreme values for `var'"
    sort `var'
    list hid `var' if `var' < -1e7 | `var' > 1e7 in 1/20
    
    di "---------------------------"
}

