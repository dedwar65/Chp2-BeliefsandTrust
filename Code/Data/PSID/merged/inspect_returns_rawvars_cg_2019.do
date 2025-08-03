*******************************************************
* inspect_raw_cg_variables.do
* Inspect extreme values in raw PSID components used 
* to construct capital gains in 2019
*******************************************************

// Define the list of raw asset variables
local raw_vars ER77451 ER67789 ER77465 ER67776 ER77507 ER71481 ER77471 ER67798 ER77481 ER67819

// Loop over each variable and print extreme values
foreach var of local raw_vars {
    di "Summary for `var'"
    count if `var' < -1e7
    count if `var' > 1e7
    summarize `var' if `var' < -1e7 | `var' > 1e7, detail
    list hid `var' if `var' < -1e7 | `var' > 1e7, sepby(`var')
    di "---------------------------"
}

