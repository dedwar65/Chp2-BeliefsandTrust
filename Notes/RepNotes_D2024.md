---
title: Replication Notes for "Returns Heterogeneity and Consumption Inequality over the life cycle"
---

# Key results to replicate in the HRS data

1. There is a regression of net returns to wealth with various controls including age, education, employment, year and state dummies, share of wealth allocated to different asset classes, leverage of mortgage and other debt, wealth percentiles using data from 1999-2019 waves of the PSID. I would like to replicate this regression (as closely as possible) with various measures of trust as the dependent variable for the two waves of the HRS (2020 and 2022) which have tracked this variable in the survey. I also want to allow for individual fixed effects in the regressions.

# Variables needed from HRS waves

* Age: RA019
* Education: RZ216
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

# Statistical model

