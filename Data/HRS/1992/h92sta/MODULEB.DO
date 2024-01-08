* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEB.DCT 
 
replace V3 =. if V3 ==00000
replace V9016 =. if V9016 ==0
replace V9016 =. if V9016>=6
replace V9017 =. if V9017 ==0
replace V9017 =. if V9017>=8
replace V9018 =. if V9018 ==0
replace V9018 =. if V9018>=8
replace V9019 =. if V9019 ==0
replace V9019 =. if V9019>=6
replace V9020 =. if V9020 ==0
replace V9020 =. if V9020>=8
replace V9021 =. if V9021 ==0
replace V9021 =. if V9021>=8
replace V9022 =. if V9022 ==0
replace V9022 =. if V9022>=6
replace V9023 =. if V9023 ==0
replace V9023 =. if V9023>=8
replace V9024 =. if V9024 ==0
replace V9024 =. if V9024>=8
replace V9025 =. if V9025 ==0
replace V9025 =. if V9025>=6
replace V9026 =. if V9026 ==0
replace V9026 =. if V9026>=8
replace V9027 =. if V9027 ==0
replace V9027 =. if V9027>=8
replace V9028 =. if V9028 ==0
replace V9028 =. if V9028>=6
replace V9029 =. if V9029 ==0
replace V9029 =. if V9029>=8
replace V9030 =. if V9030 ==0
replace V9030 =. if V9030>=8
replace V9031 =. if V9031 ==0
replace V9031 =. if V9031>=6
replace V9032 =. if V9032 ==0
replace V9032 =. if V9032>=8
replace V9033 =. if V9033 ==0
replace V9033 =. if V9033>=8
replace V9034 =. if V9034 ==0
replace V9034 =. if V9034>=6
replace V9035 =. if V9035 ==0
replace V9035 =. if V9035>=8
replace V9036 =. if V9036 ==0
replace V9036 =. if V9036>=8
replace V9037 =. if V9037 ==0
replace V9037 =. if V9037>=8
replace V9038 =. if V9038 ==0
replace V9038 =. if V9038>=8

save c:\hrs1992\stata\MODULEB.DTA 
