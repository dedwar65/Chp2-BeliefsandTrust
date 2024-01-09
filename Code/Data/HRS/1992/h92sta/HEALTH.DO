* Note: activate this do file from within STATA
infile using /Users/dc/Library/CloudStorage/OneDrive-JohnsHopkins/research/GitHub/dedwar65/Chp2-BeliefsandTrust/Data/HRS/1992/h92sta/HEALTH.DCT 
 
replace V3 =. if V3 ==00000
replace V21 =. if V21>=9999
replace V23 =. if V23>=99
replace V24 =. if V24>=99
replace V25 =. if V25>=9999
replace V26 =. if V26>=99
replace V27 =. if V27>=99
replace V28 =. if V28>=9999
replace V29 =. if V29>=999
replace V30 =. if V30>=9
replace V31 =. if V31>=9
replace V32 =. if V32>=9
replace V33 =. if V33 ==0
replace V33 =. if V33>=9
replace V34 =. if V34 ==0
replace V34 =. if V34>=99
replace V42 =. if V42>=98
replace V43 =. if V43 ==0
replace V43 =. if V43>=98
replace V44 =. if V44>=9998
replace V45 =. if V45>=9
replace V46 =. if V46>=998
replace V47 =. if V47>=8
replace V50 =. if V50 ==0
replace V61 =. if V61 ==0
replace V61 =. if V61>=9
replace V62 =. if V62 ==0
replace V62 =. if V62>=98
replace V63 =. if V63 ==0
replace V63 =. if V63>=98
replace V64 =. if V64 ==0
replace V64 =. if V64>=9998
replace V65 =. if V65 ==0
replace V65 =. if V65>=9
replace V66 =. if V66 ==0
replace V66 =. if V66>=998
replace V67 =. if V67 ==0
replace V67 =. if V67>=8
replace V81 =. if V81>=9
replace V101 =. if V101 ==0
replace V101 =. if V101>=999
replace V102 =. if V102 ==0
replace V102 =. if V102>=999
replace V106 =. if V106>=9999
replace V108 =. if V108>=9999
replace V109 =. if V109>=9999
replace V111 =. if V111>=9999
replace V112 =. if V112 ==0
replace V113 =. if V113 ==0
replace V114 =. if V114 ==0
replace V115 =. if V115 ==0
replace V116 =. if V116 ==0
replace V117 =. if V117 ==0
replace V118 =. if V118 ==0
replace V119 =. if V119 ==0
replace V120 =. if V120 ==0
replace V121 =. if V121 ==0
replace V122 =. if V122 ==0
replace V123 =. if V123 ==0
replace V123 =. if V123>=999
replace V124 =. if V124 ==0
replace V124 =. if V124>=999
replace V125 =. if V125 ==0
replace V125 =. if V125>=9
replace V126 =. if V126 ==0
replace V126 =. if V126>=99
replace V131 =. if V131 ==0
replace V131 =. if V131>=9
replace V132 =. if V132 ==0
replace V132 =. if V132>=9
replace V133 =. if V133 ==0
replace V133 =. if V133>=9
replace V134 =. if V134 ==0
replace V134 =. if V134>=99
replace V135 =. if V135 ==0
replace V135 =. if V135>=999
replace V138 =. if V138 ==0
replace V138 =. if V138>=9
replace V139 =. if V139 ==0
replace V139 =. if V139>=9
replace V143 =. if V143>=9
replace V201 =. if V201>=98
replace V203 =. if V203>=9998
replace V204 =. if V204>=8
replace V205 =. if V205>=98
replace V206 =. if V206 ==0
replace V206 =. if V206>=9998
replace V208 =. if V208 ==0
replace V208 =. if V208>=8
replace V209 =. if V209 ==0
replace V209 =. if V209>=8
replace V210 =. if V210 ==0
replace V210 =. if V210>=8
replace V211 =. if V211 ==0
replace V211 =. if V211>=8
replace V212 =. if V212>=98
replace V213 =. if V213>=98
replace V215 =. if V215 ==0
replace V215 =. if V215>=8
replace V216 =. if V216>=8
replace V222 =. if V222>=8
replace V223 =. if V223 ==0
replace V223 =. if V223>=9998
replace V224 =. if V224 ==0
replace V224 =. if V224>=9998
replace V225 =. if V225>=9
replace V226 =. if V226 ==0
replace V226 =. if V226>=98
replace V227 =. if V227 ==0
replace V227 =. if V227>=9998
replace V228 =. if V228 ==0
replace V228 =. if V228>=8
replace V229 =. if V229 ==0
replace V229 =. if V229>=8
replace V230 =. if V230 ==0
replace V230 =. if V230>=98
replace V231 =. if V231 ==0
replace V231 =. if V231>=9998
replace V232 =. if V232 ==0
replace V232 =. if V232>=98
replace V233 =. if V233 ==0
replace V233 =. if V233>=9998
replace V234 =. if V234 ==0
replace V234 =. if V234>=9
replace V235 =. if V235 ==0
replace V235 =. if V235>=98
replace V236 =. if V236 ==0
replace V236 =. if V236>=9998
replace V237 =. if V237 ==0
replace V237 =. if V237>=98
replace V238 =. if V238 ==0
replace V238 =. if V238>=9998
replace V239 =. if V239 ==0
replace V239 =. if V239>=8
replace V240 =. if V240 ==0
replace V240 =. if V240>=98
replace V241 =. if V241 ==0
replace V241 =. if V241>=9998
replace V242 =. if V242 ==0
replace V242 =. if V242>=8
replace V243 =. if V243 ==0
replace V243 =. if V243>=9998
replace V244 =. if V244 ==0
replace V244 =. if V244>=9998
replace V245 =. if V245 ==0
replace V245 =. if V245>=8
replace V246 =. if V246 ==0
replace V246 =. if V246>=9998
replace V247 =. if V247 ==0
replace V247 =. if V247>=9998
replace V248 =. if V248 ==0
replace V248 =. if V248>=8
replace V249 =. if V249 ==0
replace V249 =. if V249>=9998
replace V326 =. if V326 ==0
replace V327 =. if V327 ==0
replace V329 =. if V329 ==0
replace V330 =. if V330 ==0
replace V331 =. if V331 ==0
replace V332 =. if V332 ==0
replace V333 =. if V333 ==0
replace V334 =. if V334 ==0
replace V335 =. if V335 ==0
replace V336 =. if V336 ==0
replace V338 =. if V338 ==0
replace V339 =. if V339 ==0
replace V340 =. if V340 ==0
replace V341 =. if V341 ==0
replace V342 =. if V342 ==0
replace V343 =. if V343 ==0
replace V344 =. if V344 ==0
replace V345 =. if V345 ==0
replace V346 =. if V346 ==0
replace V347 =. if V347 ==0
replace V348 =. if V348 ==0
replace V349 =. if V349 ==0
replace V350 =. if V350 ==0
replace V351 =. if V351 ==0
replace V352 =. if V352 ==0
replace V402 =. if V402 ==0
replace V403 =. if V403 ==0
replace V404 =. if V404 ==0
replace V405 =. if V405 ==0
replace V407 =. if V407 ==0
replace V408 =. if V408 ==0
replace V409 =. if V409 ==0
replace V410 =. if V410 ==0
replace V411 =. if V411 ==0
replace V412 =. if V412 ==0
replace V413 =. if V413 ==0
replace V414 =. if V414 ==0
replace V415 =. if V415 ==0
replace V416 =. if V416 ==0
replace V418 =. if V418 ==0
replace V419 =. if V419 ==0
replace V420 =. if V420 ==0
replace V421 =. if V421 ==0
replace V424 =. if V424 ==0
replace V425 =. if V425 ==0
replace V427 =. if V427 ==0
replace V428 =. if V428 ==0
replace V429 =. if V429 ==0
replace V437 =. if V437 ==0
replace V438 =. if V438 ==0
replace V441 =. if V441 ==0
replace V442 =. if V442 ==0
replace V443 =. if V443 ==0
replace V444 =. if V444 ==0
replace V445 =. if V445 ==0
replace V446 =. if V446 ==0
replace V446 =. if V446>=98
replace V448 =. if V448 ==0
replace V452 =. if V452 ==0
replace V502 =. if V502 ==0
replace V503 =. if V503 ==0
replace V504 =. if V504>=96
replace V505 =. if V505 ==0
replace V507 =. if V507 ==0
replace V534 =. if V534 ==0
replace V535 =. if V535 ==0
replace V537 =. if V537 ==0
replace V538 =. if V538 ==0
replace V542 =. if V542 ==0
replace V902 =. if V902 ==0
replace V902 =. if V902>=8
replace V903 =. if V903 ==0
replace V903 =. if V903>=8
replace V904 =. if V904 ==0
replace V905 =. if V905 ==0
replace V905 =. if V905>=99
replace V948 =. if V948 ==0
replace V1001 =. if V1001 ==0
replace V1001 =. if V1001>=99
replace V1201 =. if V1201 ==0
replace V1201 =. if V1201>=8
replace V1202 =. if V1202 ==0
replace V1202 =. if V1202>=8
replace V1203 =. if V1203 ==0
replace V1203 =. if V1203>=99
replace V1204 =. if V1204 ==0
replace V1204 =. if V1204>=99
replace V1501 =. if V1501 ==0
replace V1501 =. if V1501>=9
replace V1502 =. if V1502 ==0
replace V1502 =. if V1502>=8
replace V1503 =. if V1503 ==0
replace V1503 =. if V1503>=8
replace V1504 =. if V1504 ==0
replace V1504 =. if V1504>=8
replace V1505 =. if V1505 ==0
replace V1505 =. if V1505>=99
replace V1506 =. if V1506 ==0
replace V1506 =. if V1506>=999
replace V1507 =. if V1507 ==0
replace V1507 =. if V1507>=99980
replace V1508 =. if V1508 ==0
replace V1508 =. if V1508>=8
replace V1509 =. if V1509 ==0
replace V1509 =. if V1509>=8
replace V1510 =. if V1510 ==0
replace V1510 =. if V1510>=999
replace V1511 =. if V1511 ==0
replace V1511 =. if V1511>=99980
replace V1512 =. if V1512 ==0
replace V1512 =. if V1512>=8
replace V1513 =. if V1513 ==0
replace V1513 =. if V1513>=8
replace V1514 =. if V1514 ==0
replace V1514 =. if V1514>=999
replace V1515 =. if V1515 ==0
replace V1515 =. if V1515>=99980
replace V1516 =. if V1516 ==0
replace V1516 =. if V1516>=8
replace V1517 =. if V1517 ==0
replace V1517 =. if V1517>=8
replace V1518 =. if V1518 ==0
replace V1518 =. if V1518>=999
replace V1519 =. if V1519 ==0
replace V1519 =. if V1519>=99980
replace V1520 =. if V1520 ==0
replace V1520 =. if V1520>=8
replace V1521 =. if V1521 ==0
replace V1521 =. if V1521>=8
replace V1522 =. if V1522 ==0
replace V1522 =. if V1522>=999
replace V1523 =. if V1523 ==0
replace V1523 =. if V1523>=99980
replace V1524 =. if V1524 ==0
replace V1524 =. if V1524>=8
replace V1525 =. if V1525 ==0
replace V1525 =. if V1525>=8
replace V1526 =. if V1526 ==0
replace V1526 =. if V1526>=999
replace V1527 =. if V1527 ==0
replace V1527 =. if V1527>=99980
replace V1528 =. if V1528 ==0
replace V1528 =. if V1528>=8
replace V1529 =. if V1529 ==0
replace V1529 =. if V1529>=8
replace V1530 =. if V1530 ==0
replace V1530 =. if V1530>=999
replace V1531 =. if V1531 ==0
replace V1531 =. if V1531>=99980
replace V1532 =. if V1532 ==0
replace V1532 =. if V1532>=8
replace V1533 =. if V1533 ==0
replace V1533 =. if V1533>=8
replace V1534 =. if V1534 ==0
replace V1534 =. if V1534>=999
replace V1535 =. if V1535 ==0
replace V1535 =. if V1535>=99980
replace V1536 =. if V1536 ==0
replace V1536 =. if V1536>=8
replace V1537 =. if V1537 ==0
replace V1537 =. if V1537>=8
replace V1538 =. if V1538>=9999996
replace V1539 =. if V1539>=96
replace V1540 =. if V1540 ==0
replace V1540 =. if V1540>=8
replace V1541 =. if V1541>=9995
replace V1542 =. if V1542>=9995
replace V1701 =. if V1701 ==0
replace V1701 =. if V1701>=8
replace V1702 =. if V1702 ==0
replace V1702 =. if V1702>=99
replace V1901 =. if V1901 ==0
replace V1901 =. if V1901>=9
replace V1903 =. if V1903 ==0
replace V1903 =. if V1903>=99
replace V2001 =. if V2001 ==0
replace V2001 =. if V2001>=8
replace V2002 =. if V2002 ==0
replace V2002 =. if V2002>=98
replace V2003 =. if V2003 ==0
replace V2003 =. if V2003>=99980
replace V2004 =. if V2004 ==0
replace V2004 =. if V2004>=98
replace V2005 =. if V2005 ==0
replace V2005 =. if V2005>=99980
replace V2006 =. if V2006 ==0
replace V2006 =. if V2006>=8
replace V2007 =. if V2007 ==0
replace V2007 =. if V2007>=98
replace V2008 =. if V2008 ==0
replace V2008 =. if V2008>=998
replace V2009 =. if V2009 ==0
replace V2009 =. if V2009>=98
replace V2010 =. if V2010 ==0
replace V2010 =. if V2010>=998
replace V2011 =. if V2011 ==0
replace V2011 =. if V2011>=8
replace V2012 =. if V2012 ==0
replace V2012 =. if V2012>=98
replace V2013 =. if V2013>=9996
replace V2014 =. if V2014>=9996
replace V2015 =. if V2015 ==0
replace V2015 =. if V2015>=98
replace V2016 =. if V2016>=9996
replace V2017 =. if V2017>=9996
replace V2018 =. if V2018 ==0
replace V2018 =. if V2018>=8
replace V2019 =. if V2019 ==0
replace V2019 =. if V2019>=98
replace V2020 =. if V2020 ==0
replace V2020 =. if V2020>=998
replace V2021 =. if V2021 ==0
replace V2021 =. if V2021>=998
replace V2022 =. if V2022 ==0
replace V2022 =. if V2022>=998
replace V2023 =. if V2023 ==0
replace V2023 =. if V2023>=998
replace V2024 =. if V2024 ==0
replace V2024 =. if V2024>=998
replace V2025 =. if V2025 ==0
replace V2025 =. if V2025>=98
replace V2026 =. if V2026 ==0
replace V2026 =. if V2026>=998
replace V2027 =. if V2027 ==0
replace V2027 =. if V2027>=998
replace V2028 =. if V2028 ==0
replace V2028 =. if V2028>=998
replace V2029 =. if V2029 ==0
replace V2029 =. if V2029>=998
replace V2030 =. if V2030 ==0
replace V2030 =. if V2030>=998
replace V2100 =. if V2100 ==0
replace V2100 =. if V2100>=9
replace V2119 =. if V2119 ==0
replace V2119 =. if V2119>=9
replace V2201 =. if V2201 ==0
replace V2201 =. if V2201>=8
replace V2202 =. if V2202 ==0
replace V2202 =. if V2202>=99
replace V2401 =. if V2401 ==0
replace V2401 =. if V2401>=9
replace V2403 =. if V2403 ==0
replace V2403 =. if V2403>=99
replace V2501 =. if V2501 ==0
replace V2501 =. if V2501>=8
replace V2502 =. if V2502 ==0
replace V2502 =. if V2502>=98
replace V2503 =. if V2503 ==0
replace V2503 =. if V2503>=99980
replace V2504 =. if V2504 ==0
replace V2504 =. if V2504>=98
replace V2505 =. if V2505 ==0
replace V2505 =. if V2505>=99980
replace V2506 =. if V2506 ==0
replace V2506 =. if V2506>=8
replace V2507 =. if V2507 ==0
replace V2507 =. if V2507>=98
replace V2508 =. if V2508 ==0
replace V2508 =. if V2508>=998
replace V2509 =. if V2509 ==0
replace V2509 =. if V2509>=98
replace V2510 =. if V2510 ==0
replace V2510 =. if V2510>=998
replace V2511 =. if V2511 ==0
replace V2511 =. if V2511>=8
replace V2512 =. if V2512 ==0
replace V2512 =. if V2512>=98
replace V2513 =. if V2513>=9996
replace V2514 =. if V2514>=9996
replace V2515 =. if V2515 ==0
replace V2515 =. if V2515>=98
replace V2516 =. if V2516>=9996
replace V2517 =. if V2517>=9996
replace V2518 =. if V2518 ==0
replace V2518 =. if V2518>=8
replace V2519 =. if V2519 ==0
replace V2519 =. if V2519>=98
replace V2520 =. if V2520 ==0
replace V2520 =. if V2520>=998
replace V2521 =. if V2521 ==0
replace V2521 =. if V2521>=998
replace V2522 =. if V2522 ==0
replace V2522 =. if V2522>=998
replace V2523 =. if V2523 ==0
replace V2523 =. if V2523>=998
replace V2524 =. if V2524 ==0
replace V2524 =. if V2524>=998
replace V2525 =. if V2525 ==0
replace V2525 =. if V2525>=98
replace V2526 =. if V2526 ==0
replace V2526 =. if V2526>=998
replace V2527 =. if V2527 ==0
replace V2527 =. if V2527>=998
replace V2528 =. if V2528 ==0
replace V2528 =. if V2528>=998
replace V2529 =. if V2529 ==0
replace V2529 =. if V2529>=998
replace V2530 =. if V2530 ==0
replace V2530 =. if V2530>=998
replace V2601 =. if V2601 ==0
replace V2601 =. if V2601>=8
replace V2602 =. if V2602 ==0
replace V2602 =. if V2602>=9998
replace V2603 =. if V2603 ==0
replace V2603 =. if V2603>=8
replace V2604 =. if V2604 ==0
replace V2604 =. if V2604>=8
replace V2605 =. if V2605 ==0
replace V2605 =. if V2605>=8
replace V2606 =. if V2606 ==0
replace V2606 =. if V2606>=8
replace V2607 =. if V2607 ==0
replace V2607 =. if V2607>=8
replace V2608 =. if V2608 ==0
replace V2608 =. if V2608>=8
replace V2609 =. if V2609 ==0
replace V2609 =. if V2609>=8
replace V2610 =. if V2610 ==0
replace V2610 =. if V2610>=8
replace V2611 =. if V2611 ==0
replace V2611 =. if V2611>=8
replace V2612 =. if V2612 ==0
replace V2612 =. if V2612>=8
replace V2613 =. if V2613 ==0
replace V2613 =. if V2613>=8
replace V2614 =. if V2614 ==0
replace V2614 =. if V2614>=8
replace V2615 =. if V2615 ==0
replace V2615 =. if V2615>=8
replace V2616 =. if V2616 ==0
replace V2616 =. if V2616>=8
replace V2617 =. if V2617 ==0
replace V2617 =. if V2617>=8
replace V2618 =. if V2618 ==0
replace V2618 =. if V2618>=9
replace V2619 =. if V2619 ==0
replace V2619 =. if V2619>=8
replace V2620 =. if V2620 ==0
replace V2620 =. if V2620>=8
replace V2621 =. if V2621 ==0
replace V2621 =. if V2621>=8
replace V2622 =. if V2622 ==0
replace V2622 =. if V2622>=8
replace V5101 =. if V5101 ==0
replace V5101 =. if V5101>=8
replace V5102 =. if V5102 ==0
replace V5102 =. if V5102>=8
replace V5103 =. if V5103 ==0
replace V5103 =. if V5103>=8
replace V5104 =. if V5104 ==0
replace V5104 =. if V5104>=9999
replace V5105 =. if V5105>=96
replace V5106 =. if V5106>=6
replace V5107 =. if V5107>=6
replace V5108 =. if V5108>=6
replace V5109 =. if V5109>=6
replace V5110 =. if V5110>=6
replace V5111 =. if V5111>=6
replace V5112 =. if V5112>=6
replace V5113 =. if V5113>=96
replace V5114 =. if V5114>=96
replace V5115 =. if V5115>=96
replace V5116 =. if V5116>=96
replace V5117 =. if V5117>=96
replace V5118 =. if V5118>=96
replace V5119 =. if V5119>=96
replace V5120 =. if V5120>=96
replace V5121 =. if V5121>=96
replace V5122 =. if V5122 ==0
replace V5122 =. if V5122>=8
replace V5123 =. if V5123 ==0
replace V5123 =. if V5123>=8
replace V5124 =. if V5124 ==0
replace V5124 =. if V5124>=8
replace V5125 =. if V5125 ==0
replace V5125 =. if V5125>=9999
replace V5126 =. if V5126>=96
replace V5127 =. if V5127>=96
replace V7101 =. if V7101>=9
replace V7102 =. if V7102 ==0
replace V7102 =. if V7102>=99
replace V7103 =. if V7103>=8
replace V7104 =. if V7104 ==0
replace V7104 =. if V7104>=8
replace V7105 =. if V7105>=8
replace V7106 =. if V7106 ==0
replace V7106 =. if V7106>=8
replace V7107 =. if V7107>=8
replace V7108 =. if V7108 ==0
replace V7108 =. if V7108>=8
replace V7109 =. if V7109>=8
replace V7110 =. if V7110>=8
replace V7111 =. if V7111>=8
replace V7112 =. if V7112>=8
replace V7113 =. if V7113>=8
replace V7114 =. if V7114>=8
replace V7115 =. if V7115 ==0
replace V7115 =. if V7115>=8
replace V7116 =. if V7116 ==0
replace V7116 =. if V7116>=8
replace V7117 =. if V7117 ==0
replace V7117 =. if V7117>=8
replace V7118 =. if V7118>=98
replace V7119 =. if V7119 ==0
replace V7119 =. if V7119>=8
replace V7120 =. if V7120 ==0
replace V7120 =. if V7120>=98
replace V7121 =. if V7121 ==0
replace V7121 =. if V7121>=98
replace V7122 =. if V7122 ==0
replace V7122 =. if V7122>=8
replace V7123 =. if V7123 ==0
replace V7123 =. if V7123>=8
replace V7124 =. if V7124 ==0
replace V7124 =. if V7124>=8
replace V7125 =. if V7125 ==0
replace V7125 =. if V7125>=8
replace V7126 =. if V7126>=8
replace V7127 =. if V7127>=8
replace V7128 =. if V7128>=8
replace V7129 =. if V7129>=8
replace V7130 =. if V7130>=8
replace V7131 =. if V7131>=8
replace V7132 =. if V7132>=8
replace V7133 =. if V7133>=8
replace V7134 =. if V7134>=8
replace V7135 =. if V7135>=8
replace V7136 =. if V7136>=8
replace V7137 =. if V7137>=8
replace V7138 =. if V7138>=8
replace V7139 =. if V7139>=8
replace V7140 =. if V7140>=8
replace V7141 =. if V7141>=8
replace V7142 =. if V7142>=9
replace V7143 =. if V7143>=9
replace V7144 =. if V7144>=9

save /Users/dc/Library/CloudStorage/OneDrive-JohnsHopkins/research/GitHub/dedwar65/Chp2-BeliefsandTrust/Data/HRS/1992/h92sta/HEALTH.DTA 
