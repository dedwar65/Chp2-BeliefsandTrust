---
title: Notes for 2 sample IV estimation, following the baseline regression from "Returns Heterogeneity and Consumption Inequality over the life cycle"
---

# Description of the 2 sample IV procedure 

I want to perform a two-sample IV procedure in the following way.

1. Run a regression with trust as the dependent variable (LHS) and demographic variables as the independent variables (RHS)as an analogy to the regression used to produce table 1 in the paper “Returns Heterogeneity and Consumption Inequality over the Life Cycle”  by Daminato and Pistaferri (2014). 

	The trust and demographic variables come from the 2020 wave of the Household Retirement Survey (HRS). I made an effort to match the following variables described by the paper: age, education, employment, shares of wealth allocated to different asset classes, amounts of debt to compute total debt to wealth (if relevant for my uses), computed wealth percentiles after constructing a wealth variable. 

2. Use the estimated relationship between trust and demographics to impute a measure of trust in the PSID data. I started with the 2019 wave and located the imputed version of each of the variables described above (since it was the initial reference point).

	However, I had difficulty locating the following variables, which are needed to compute returns to wealth (eq. 1 in the paper): capital gains/losses, payments on debt, estimate of net investment flows. Also, the HRS only started measuring trust in 2020 but DP2024 uses panel data to estimate fixed effects in the regression with returns as the dependent variables.  

	My first thought was that, if I can compute returns for 2019, and then do the same for more PSID waves, I can use the same imputed trust variable for each wave (implicitly assuming that individuals had the same level of trust across the years). 

A final, minor concern is that the years of the survey don’t exactly line up (although they are more conducted every two years). 

# 1 - Variables needed from HRS waves (where trust is measured)

Note: Controls are a combination of DP2024 and G2008

* Age: RA019
* Education: RZ216 (different from PSID)
* Employment: RJ005M1, RJ020
* Gender: RX060_R
* Marital status: RX065_R 
* Immigration status: ommitted for now (from G2008)
* Year and state dummies: 0,1 for year if I want to consolidate waves and "the HRS uses a national area probability sample of US households, so not every state will have HRS respondents" (from DP2024)
* Share of wealth allocated to different asset classes: 
    * financial assets
        * safe assets
            * cash: RQ345
            * bonds: RQ331
        * risky assets
            * stocks: RQ317
            * pensions/IRA: RQ166_1 + RQ166_2 + RQ166_3 (IRA) + RQ227_1 + RQ227_2 (pensions)
            * private busines wealth: RQ148
    * real assets
        * housing and other real estate: RQ134, RQ376
        * vehicles: omitted for now
    * debt (not including mortgages): RQ478

* Trust: RV557, RV558, RV559, RV560, RV561, RV562, RV563, RV564


# 1.2 - Question: for now, no
Is it possible to compute returns here as is done in PSID?

So far, HRS 2020 has
1. interest income and dividends
    * real estate: RQ139 (how often), RQ141 (last period)
    * private business or farm: RQ155, RQ156
    * stock: RQ322, RQ324
    * bonds: RQ336, RQ338 
    * cash: RQ350, RQ352
2. capital gains and losses (i.e. used reported values for the previous wave's asset classes and take the difference)
3. payments on debt: ??
4. total net wealth at beginning of previous period (i.e. same as 2)
5. net investment flows
    * real estate: RR007 (buy). RR013 (sell), RR024 (major improvements)
    * private business: RR050 (private funds in), RR055 (sell) 

    

# 2 - Variables from the PSID 2019 wave (where returns can be calculated)

INCOME MODULE
* Age: ER72017
* Employment: ER72164, ER72168

* Share of wealth allocated to different asset classes: 
    * financial assets
        * safe assets
            * cash: 
            * bonds: 
        * risky assets
            * stocks: 
            * pensions/IRA: ER7320, ER73246 (non-va) + ER73262 (annuity) + ER73278 (other) + ER73294 (IRA)
                * ER73600 (non-va-SP) + ER73616 (ann-SP) + ER73632 (other-SP) + ER73648 (IRA-SP)
            * private busines wealth: ER72995 (farm) + ER73010 (B1) + ER73024 (B2) + ER73038 (B3) + ER73052 (B4) + ER73066 (B5)
    * real assets
        * main housing/real estate: ER72031, ER72051 (first mortgage), ER72053 (mt. payments),  ER72072 (second mortgage), ER72074 (mt. payments),  
        * vehicles: omitted for now
    
    * flows (to compute returns)
        * interest income: ER73143 + ER73498 (SP)
        * dividends: ER73126 + ER73481 (SP) 


WEALTH MODULE (use this one for now -- see note below)
* Education: ER76908 (HS/GED), ER76919 (college), ER76922 (yrs of college)
* Share of wealth allocated to different asset classes: 
    * financial assets
        * safe assets
            * cash: ER73848
            * bonds: ER73854, ER73875
        * risky assets
            * stocks: ER73821
            * pensions/IRA: ER73842 (IRA) + ER74036 (pension) + ER74243 (pension-SP)
            * private busines wealth: ER73812 (farm) , ER73816 (farm-debt)
    * real assets
        * housing and other real estate: ER73799, ER73803 (housing debt)
        * vehicles: omitted for now
    * debt (not including mortgages): ER73880 (credit) + ER73890 (student) + ER73895 (medical) + ER73900 (legal) + ER73905 (personal) + ER73911 (other)
    
    * flows (to compute returns)
        * interest income: ER73860
        * dividends: ER73826

        * net investment flows
            * pensions/IRA: ER73917, ER73922 (cash in)
            * real estate: ER7392 (main), ER73933 (otr) 

Note: There are imputed versions of these variables starting on ER77448

* Share of wealth allocated to different asset classes: 
    * financial assets
        * safe assets
            * cash: ER77457
            * bonds: ER77461
        * risky assets
            * stocks: ER77471
            * pensions/IRA: ER77481 (IRA) + ER74036 (pension-non imputed) + ER74243 (pension-SP-non imputed)
            * private busines wealth: ER77451 (farm) , ER77453 (farm-debt) , ER77477 (other)
    * real assets
        * housing and other real estate: ER77465, ER77467 (housing debt)
        * vehicles: omitted for now
    * debt (not including mortgages): ER77485 (credit) + ER77489 (student) + ER77493 (medical) + ER77497 (legal) + ER77501 (personal) + ER77505 (other)
    
* imputed wealth variable ER77509 (no housing), ER77511 (housing)
* education (# of years) ER77599

    * flows (to compute returns)
        * interest income: ER73860
        * dividends: ER73826

## 2.1 - Issues with PSID:

2. Not clear where the variables to compute "returns to net worth" are located
    * capital gains/losses requires multiple waves, which I am trying to avoid since I only have a single wave of HRS data containing trust measures
    * debt payments
    * total household net worth at the beginning of previous period
    * net investment flows into the risky assets
3. Number of observation compared to HRS data
