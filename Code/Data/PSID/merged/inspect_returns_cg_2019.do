*******************************************************
* compute_returns.do
* Inspect why 2019 returns seem so off, starting with capital gains
*******************************************************

// Flag extreme values for each capital gain component
gen extreme_cg_bus     = cg_bus < -1e7 | cg_bus > 1e7
gen extreme_cg_rents   = cg_rents < -1e7 | cg_rents > 1e7
gen extreme_cg_home    = cg_home < -1e7 | cg_home > 1e7
gen extreme_cg_stocks  = cg_stocks < -1e7 | cg_stocks > 1e7
gen extreme_cg_pens    = cg_pens < -1e7 | cg_pens > 1e7

gen any_extreme_cg = extreme_cg_bus | extreme_cg_rents | extreme_cg_home | ///
                     extreme_cg_stocks | extreme_cg_pens

// Optional: visually inspect rows with any extreme capital gains
browse hid cg_bus cg_rents cg_home cg_stocks cg_pens if any_extreme_cg

// Print summaries and list extreme values for each capital gain component
foreach var in cg_bus cg_rents cg_home cg_stocks cg_pens {
    di "Summary for `var'"
    count if `var' < -1e7
    count if `var' > 1e7
    summarize `var' if `var' < -1e7 | `var' > 1e7, detail
    list hid `var' if `var' < -1e7 | `var' > 1e7, sepby(`var')
    di "---------------------------"
}

foreach pair in business rents home stocks pens {
    if "`pair'" == "business" {
        local var19 ER77451
        local var17 ER67789
    }
    else if "`pair'" == "rents" {
        local var19 ER77465
        local var17 ER67776
    }
    else if "`pair'" == "home" {
        local var19 ER77507
        local var17 ER71481
    }
    else if "`pair'" == "stocks" {
        local var19 ER77471
        local var17 ER67798
    }
    else if "`pair'" == "pens" {
        local var19 ER77481
        local var17 ER67819
    }

    di "Summarizing raw variables for `pair'"
    summarize `var19' `var17', detail

    di "Listing suspiciously low values for `pair'"
    list hid `var19' `var17' if inrange(`var19', -1.01e9, -9.9e8) | inrange(`var17', -1.01e9, -9.9e8)
    di "--------------------------------------------"
}



