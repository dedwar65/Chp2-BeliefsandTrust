---
title: Replication Notes for "Returns Heterogeneity and Consumption Inequality over the life cycle"
---

# Key results to replicate in the HRS data

1. There is a regression of net returns to wealth with various controls including age, education, employment, year and state dummies, share of wealth allocated to different asset classes, leverage of mortgage and other debt, wealth percentiles using data from 1999-2019 waves of the PSID. I would like to replicate this regression (as closely as possible) with various measures of trust as the dependent variable for the two waves of the HRS (2020 and 2022) which have tracked this variable in the survey. I also want to allow for individual fixed effects in the regressions.

# 1. Variables needed from HRS waves (where trust is measured)

* Age: RA019
* Education: RZ216 (different from PSID)
* Employment: RJ005M1, RJ020
* Year and state dummies: 0,1 for year if I want to consolidate waves and "the HRS uses a national area probability sample of US households, so not every state will have HRS respondents"
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
        * housing and other real estate: RQ134
        * vehicles: omitted for now
    * debt (not including mortgages): RQ478

* Trust: RV557, RV558, RV559, RV560, RV561, RV562, RV563, RV564

Note: Able to reach a cleaned, final version of the dataset

# 2. Variables from the PSID 2019 wave (where returns can be calculated)

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
            * pensions/IRA: ER73246 (non-va) + ER73262 (annuity) + ER73278 (other) + ER73294 (IRA)
                * ER73600 (non-va-SP) + ER73616 (ann-SP) + ER73632 (other-SP) + ER73648 (IRA-SP)
            * private busines wealth: ER72995 (farm) + ER73010 (B1) + ER73024 (B2) + ER73038 (B3) + ER73052 (B4) + ER73066 (B5)
    * real assets
        * housing and other real estate: ER72031
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
            * bonds: ER73854
        * risky assets
            * stocks: ER73821
            * pensions/IRA: ER73842 (IRA) + ER74036 (pension) + ER74243 (pension-SP)
            * private busines wealth: ER73812 (farm) , ER73815 (farm-debt)
    * real assets
        * housing and other real estate: ER73799, ER73803 (housing debt)
        * vehicles: omitted for now
    * debt (not including mortgages): ER73880 (credit) + ER73890 (student) + ER73895 (medical) + ER73900 (legal) + ER73905 (personal) + ER73911 (other)
    
    * flows (to compute returns)
        * interest income: ER73860
        * dividends: ER73826

Note: There are imputed versions of these variables starting on ER77448

## 2.1 Issues with PSID:

1. Household level only (versus respondent level)
2. Not clear where the variables to compute "returns to net worth" are located
    * capital gains/losses requires multiple waves, which I am trying to avoid since I only have a single wave of HRS data containing trust measures
    * debt payments
    * total household net worth at the beginning of previous period
    * net investment flows into the risky assets
3. Number of observation compared to HRS data
