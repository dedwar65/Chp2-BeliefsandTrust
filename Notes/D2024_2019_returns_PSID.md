1. Replicate measure of returns to net worth using PSID 2019
$$ r_t = \frac{y^c_t + cg_t -y^d_t}{A_{t-1} + .5F_t} $$

* $y^c_t$ interest income and dividends (reported)
interest income: ER73143  
dividends: ER73126 

* $cg_t$ from business, rents,  stocks,  real  estate,  pension/IRA (imputed valuations, reported investment flows)
$$ cg_t^{class} = (V_t^{class} - V_{t-1}^{class}) - F_t^{class}  $$

    * business
    V_{2019}: ER77451
    V_{2017}: ER67789
    F_{2019}: (ER73947 - ER73952)

    * rents
    V_{2019}: ER77465
    V_{2017}: ER67776
    F_{2019}: (ER73933 - ER73938)

    * real estate
    V_{2019}: ER77507
    V_{2017}: ER71481 
    F_{2019}: N/A

    * stocks
    V_{2019}: ER77471
    V_{2017}: ER67798
    F_{2019}: (ER73957 - ER73963)

    * pension/IRA
    V_{2019}: ER77481
    V_{2017}: ER67819
    F_{2019}: (ER73917 - ER73922)

* y^d_t payments on debt (reported payments)
    for mortgages, use  $$ Annual payment \equiv 12 * Payment = principal * \frac{r (1+r)^n}{(1+r)^n - 1}$$ , where n is number of months and r is the monthly interest rate
    first mortgage payments:
        remaining principal: ER72051
        interest rate (annual): ER72058
        remaining term: ER72061
        **monthly payments**: ER72053
    second mortgage payments: 
        remaining principal: ER72072
        interest rate (annual): ER72079
        remaining term: ER72082
        **monthly payments**: ER72074
    remaining reported (consumer) debts - (left out of .dta file):
        credit card: ER73880
        student loans: ER73890
        medical: ER73895
        legal: ER73900
        relatives: ER73905
        other: ER73911

    remaining imputed debts:
        credit card: ER77485
        student loans: ER77489
        medical debt: ER77493
        legal debt: ER77497
        family loans: ER77501
        other debts: ER77505

* A_{t-1} total net wealth at beginning of previous period (all imputed)
    Assets:
        private business: ER67789
        checking/savings: ER67826
        stocks: ER67798
        bonds:
        other real estate: ER67776
        vehicles: ER67784
        pensions/IRAs: ER67819
        Other assets: ER67847
        home net value: ER71481 
    Liabilities:
        private business: ER67793
        credit card: ER67852
        student loans: ER67862
        medical debt: ER67867
        legal debt: ER67872
        family loans: ER67877
        other debts: ER67883

* F_t net investment flows per asset class (reported)
    * private business: (ER74947 - ER74952)
    * rents: (ER73933 - ER73938)
    * stocks: (ER73957 - ER73963)
    * pensions/IRAs: (ER73917 - ER73922)
        


    

    

