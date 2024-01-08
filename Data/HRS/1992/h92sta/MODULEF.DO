* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEF.DCT 
 
replace V3 =. if V3 ==00000
replace V9069 =. if V9069 ==0
replace V9070 =. if V9070 ==0
replace V9070 =. if V9070>=96
replace V9071 =. if V9071 ==0
replace V9071 =. if V9071>=96
replace V9072 =. if V9072 ==0
replace V9072 =. if V9072>=96
replace V9073 =. if V9073 ==0
replace V9073 =. if V9073>=96
replace V9074 =. if V9074 ==0
replace V9074 =. if V9074>=96
replace V9075 =. if V9075 ==0
replace V9075 =. if V9075>=96
replace V9076 =. if V9076 ==0
replace V9076 =. if V9076>=96
replace V9077 =. if V9077 ==0
replace V9077 =. if V9077>=96
replace V9078 =. if V9078 ==0
replace V9078 =. if V9078>=96
replace V9079 =. if V9079 ==0
replace V9079 =. if V9079>=8
replace V9080 =. if V9080 ==0
replace V9080 =. if V9080>=8
replace V9081 =. if V9081 ==0
replace V9081 =. if V9081>=8
replace V9082 =. if V9082 ==0
replace V9082 =. if V9082>=8
replace V9083 =. if V9083 ==0
replace V9083 =. if V9083>=8
replace V9084 =. if V9084 ==0
replace V9084 =. if V9084>=8

save c:\hrs1992\stata\MODULEF.DTA 
