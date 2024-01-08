* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEK.DCT 
 
replace V3 =. if V3 ==00000
replace V9156 =. if V9156 ==0
replace V9156 =. if V9156>=8
replace V9157 =. if V9157 ==0
replace V9157 =. if V9157>=8
replace V9158 =. if V9158 ==0
replace V9158 =. if V9158>=8
replace V9159 =. if V9159 ==0
replace V9159 =. if V9159>=8
replace V9160 =. if V9160 ==0
replace V9160 =. if V9160>=8
replace V9161 =. if V9161 ==0
replace V9161 =. if V9161>=8
replace V9162 =. if V9162 ==0
replace V9162 =. if V9162>=8

save c:\hrs1992\stata\MODULEK.DTA 
