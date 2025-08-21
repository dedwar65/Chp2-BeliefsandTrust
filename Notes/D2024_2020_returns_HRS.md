1. Replicate measure of returns to net worth using PSID 2019
$$ r_t = \frac{y^c_t + cg_t -y^d_t}{A_{t-1} + .5F_t} $$

NOTE: Capital gains $cg_t$ need to be annualized, so divide by 2 for each asset class. 

* F_t net investment flows per asset class (that are available for 2022) 
- **GO FIND THESE**
    * private business: SR050 (invest), SR055 (sell)
    * stocks: SR063 (net buyer or net seller), SR064 (magnitude)
        * public stocks: SR072 (sold)
    * real estate: SR030 (buy), SR035 (sold), SR045 (improvement costs)
    * IRA: SQ171_1, SQ171_2, SQ171_3
    * primary/secondary residence(s): SR007 (buy), SR013 (sell), SR024 (improvement costs)

* $y^c_t$ interest income and dividends per asset class for 2020:
    * real estate (other than main home)
        * RQ139 (frequency), RQ141 (amount)
    * private business
        * RQ153 (frequency), RQ155 (amount)
    * IRA
        * RQ190 (amount), RQ194 (frequency)
    * stocks
        * RQ322 (frequency), RQ324 (amount)
    * bonds 
        * RQ336 (frequency), RQ338 (amount)
    * checking/savings
        * RQ350 (frequency), RQ352 (amount)
    * CDS, t-bills
        * RQ362 (frquency), RQ364 (amount)


* $cg_t$ from business, rents,  stocks,  real  estate,  IRA 
$$ cg_t^{class} = (V_t^{class} - V_{t-1}^{class}) - F_t^{class}  $$ 
**- GO FIND THESE**

    * private business
    V_{2020}: SQ148
    V_{2018}: RQ148
    F_{2020}: 

    * real estate (other than main home)
    V_{2020}: SQ134
    V_{2018}: RQ134
    F_{2020}: 

    * stocks
    V_{2020}: SQ317
    V_{2018}: RQ317
    F_{2020}:

    * IRA
    V_{2020}: SQ166_1, SQ166_2, SQ166_3
    V_{2018}: RQ166_1 , RQ166_2 , RQ166_3 
    F_{2020}:

    * bonds
    V_{2020}: SQ331
    V_{2018}: RQ331
    F_{2020}:

    * primary residence:
    V_{2020}: SH020
    V_{2018}: RH020
    F_{2020}:

    * secondary residence: 
    V_{2020}: SH162
    V_{2018}: RH162
    F_{2020}:


* y^d_t payments on debt (reported payments)
    * primary residence:
    * first mortgage
        * RH025 (amount), RH029 (frequency)
    * second mortgage
        * RH036 (amount), RH040 (frquency)

    * secondary residence:
    * first mortgage
        * RH175 (amount), RH179 (frequency)

* A_{t-1} total net wealth at beginning of previous period (A_{2018} to compute r_{2020}) 
**- GO FIND THESE**
    Assets:
        primary residence: RH020
        secondary residence: RH162
        real estate: RQ134
        private business: RQ148
        stocks: RQ317
        IRA: RQ166_1, RQ166_2, RQ166_3
        bonds: RQ331
        checking/savings: RQ345
        CDs: RQ357
        vehicles: RQ371
        other: RQ381

    Liabilities:
        primary residence: RH032
        secondary residence: RH171
        other debts: RQ478
        