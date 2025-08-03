*******************************************************
* Inspect raw 2017 variables used in A17 net wealth calculation
*******************************************************

* List of variables used in A17 (2017 assets and debts)
local A17_vars ER67789 ER67826 ER67798 ER67776 ER67784 ER67819 ER67847 ER71481 ///
               ER67793 ER67852 ER67862 ER67867 ER67872 ER67877 ER67883

* Loop over each variable to summarize and list suspicious extreme values
foreach var of local A17_vars {
    di "Summary for `var'"
    
    * Count how many observations equal each suspicious value
    count if `var' == 999999998
    di "Count of 999999998 in `var': " r(N)
    
    count if `var' == 999999999
    di "Count of 999999999 in `var': " r(N)
    
    count if `var' == 1000000000
    di "Count of 1e9 (1000000000) in `var': " r(N)
    
    summarize `var', detail
    
    di "Listing suspicious high values for `var'"
    list hid `var' if inlist(`var', 999999998, 999999999, 1000000000) in 1/20
    
    di "---------------------------"
}

