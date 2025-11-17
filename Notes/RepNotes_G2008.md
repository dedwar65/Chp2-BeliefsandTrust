---
title: Replication Notes for "Trusting the Stock Market"
---

## Household Retirement Survey (HRS) variable counterparts

Trust module is only present in 2020.

Here are the variables on the RHS of the regression for the income-trust relationship:

* Education: RZ216, rb014
* Age: RA019
* Gender: RX060_R
* Employment: RJ005M1, RJ005M2, RJ005M3, RJ005M4, RJ005M5, RJ020
* marital status RA034, RZ080
* immigration status RB085, rz230
    * "are you a US citizen"

* Note: May need to use Preload variables from 2022, for now, keep it like this/

Here are the variables on the RHS of the regression for returrns to identify the persistent component from D2024:

* age
* education,
* employment
* year and state dummies (tentative)  
* share of wealth allocated to different asset classes
* leverage of mortgage and other debt
* wealth percentiles.

Here are the variables on the RHS of the regression for returrns to identify the persistent component from F2020:

* age
* years of education
* marital status
* employment status
* Dummies for individual wealth percentiles
* dummies for county and time

After collecting these controls, we need to add trust to the RHS and possibly allow for fixed effects if we use multiple years of data. 

* trust: 
    * rv557 - Trust in others
    * rv558 - Trust in Social Security
    * rv559 - Trust in Medicare/Medicaid
    * rv560 - Trust in Banks
    * rv561 - Trust in Financial Advisors
    * rv562 - Trust in Mutual Funds
    * rv563 - Trust in Insurance Companies
    * rv564 - Trust in Mass Media

    r15govmr - Covered by Medicare
    r15govmd - Covered by Medicaid
    r15lifein - Has life insurance
    r15beqany - Prob. of leaving any bequest
    r15mdiv - Number of reported divorces
    r15mid - Number of reported times being widowed

# Statistical model

