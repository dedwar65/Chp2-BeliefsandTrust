* F_t net investment flows per asset class (that are available for 2022)
    * private business: SR050 (invest), SR055 (sell)
    * stocks: SR063 (net buyer or net seller), SR064 (magnitude)
        * public stocks: SR072 (sold)
    * real estate: SR030 (buy), SR035 (sold), SR045 (improvement costs)
    * IRA: SQ171_1, SQ171_2, SQ171_3
    * primary/secondary residence(s): SR007 (buy), SR013 (sell), SR024 (improvement costs)

NOTE: Just import these from the RAND fat file, use the total we already computed in the first attempt. 

A) Denominator — A_{t-1} (total net wealth at start of period, use 2020 / H15)
   - H15ATOTB   (Total of all assets net of debt, Wave 15 = 2020)
   - alternative (exclude IRAs): H15ATOTW

B) Capital income — y^c_t (aggregate capital/investment income in 2022 / H16)
   - H16ICAP    (Household capital income, Wave 16 = 2022)

C) Asset values for capital gains (use H16 - H15 by class; compute cg_class = V_2022 - V_2020)
   - Primary residence (net):
       H16ATOTH   (Primary residence net value, 2022)
       H15ATOTH   (Primary residence net value, 2020)
   - Secondary residence (net):
       H16ANETHB  (Secondary residence net value, 2022)
       H15ANETHB  (Secondary residence net value, 2020)
   - Other real estate:
       H16ARLES   (Other real estate, 2022)
       H15ARLES   (Other real estate, 2020)
   - Private business:
       H16ABSNS   (Private business, 2022)
       H15ABSNS   (Private business, 2020)
   - IRA / Keogh:
       H16AIRA    (IRA/Keogh, 2022)
       H15AIRA    (IRA/Keogh, 2020)
   - Stocks / mutual funds:
       H16ASTCK   (Stocks/mutual funds, 2022)
       H15ASTCK   (Stocks/mutual funds, 2020)
   - Bonds:
       H16ABOND   (Bonds, 2022)
       H15ABOND   (Bonds, 2020)
   - Checking / savings / money market:
       H16ACHCK   (Checking/savings, 2022)
       H15ACHCK   (Checking/savings, 2020)
   - CDs / T-bills:
       H16ACD     (CDs/T-bills, 2022)
       H15ACD     (CDs/T-bills, 2020)
   - Vehicles:
       H16ATRAN   (Vehicles, 2022)
       H15ATRAN   (Vehicles, 2020)
   - Other assets:
       H16AOTHR   (Other assets, 2022)
       H15AOTHR   (Other assets, 2020)

   - Debts / mortgages (if you use gross asset values you must subtract these to get net):
       H16AMORT   (All mortgages on primary residence, 2022)
       H15AMORT   (All mortgages on primary residence, 2020)
       H16AMRTB   (Mortgage on 2nd home, 2022)
       H15AMRTB   (Mortgage on 2nd home, 2020)
       H16AHMLN   (Other home loans, 2022)
       H15AHMLN   (Other home loans, 2020)
       H16ADEBT   (Total other debt, 2022)
       H15ADEBT   (Total other debt, 2020)

CG formula (per class):
   cg_class = (V_2022_class - V_2020_class)

Overall period numerator and annualization:
   num_period = y^c_2022 + sum_c(cg_class) - F_total_period - debt_payments_2022
   base = A_{2020} + 0.5 * F_total_period
   R_period = num_period / base
   r_annual = (1 + R_period)^(1/2) - 1
