1. Replicate measure of returns to net worth using PSID 2019
$$ r_t = \frac{y^c_t + cg_t -y^d_t}{A_{t-1} + .5F_t} $$

NOTE: Capital gains $cg_t$ need to be annualized, so divide by 2 for each asset class. 

* F_t net investment flows per asset class (that are available for 2022)
    * private business: SR050 (invest), SR055 (sell)
    * stocks: SR063 (net buyer or net seller), SR064 (magnitude)
        * public stocks: SR072 (sold)
    * real estate: SR030 (buy), SR035 (sold), SR045 (improvement costs)
    * IRA: SQ171_1, SQ171_2, SQ171_3
    * primary/secondary residence(s): SR007 (buy), SR013 (sell), SR024 (improvement costs)

* $y^c_t$ interest income and dividends per asset class for 2022: 
    * real estate (other than main home)
        * SQ139 (frequency), SQ141 (amount)
    * private business
        * SQ153 (frequency), SQ155 (amount)
    * IRA
        * SQ190 (amount), SQ194 (frequency)
    * stocks
        * SQ322 (frequency), SQ324 (amount)
    * bonds 
        * SQ336 (frequency), SQ338 (amount)
    * checking/savings
        * SQ350 (frequency), SQ352 (amount)
    * CDS, t-bills
        * SQ362 (frquency), SQ364 (amount)


* $cg_t$ from business, rents,  stocks,  real  estate,  IRA 
$$ cg_t^{class} = (V_t^{class} - V_{t-1}^{class}) - F_t^{class}  $$

    * private business
    V_{2022}: SQ148
    V_{2020}: RQ148
    F_{2022}: 

    * real estate (other than main home)
    V_{2022}: SQ134
    V_{2020}: RQ134
    F_{2022}: 

    * stocks
    V_{2022}: SQ317
    V_{2020}: RQ317
    F_{2022}:

    * IRA
    V_{2022}: SQ166_1, SQ166_2, SQ166_3
    V_{2020}: RQ166_1 , RQ166_2 , RQ166_3 
    F_{2022}:

    * bonds
    V_{2022}: SQ331
    V_{2020}: RQ331
    F_{2022}:

    * primary residence:
    V_{2022}: SH020
    V_{2020}: RH020
    F_{2022}:

    * secondary residence: 
    V_{2022}: SH162
    V_{2020}: RH162
    F_{2022}:


* y^d_t payments on debt (reported payments)
    * primary residence:
    * first mortgage
        * SH025 (amount), SH029 (frequency)
    * second mortgage
        * SH036 (amount), SH040 (frquency)

    * secondary residence:
    * first mortgage
        * SH175 (amount), SH179 (frequency)

* A_{t-1} total net wealth at beginning of previous period (A_{2020} to compute r_{2022})
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
        

