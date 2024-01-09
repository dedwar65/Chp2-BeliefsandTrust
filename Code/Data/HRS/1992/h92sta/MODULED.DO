* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULED.DCT 
 
replace V3 =. if V3 ==00000
replace V9052 =. if V9052 ==0
replace V9052 =. if V9052>=8
replace V9053 =. if V9053 ==0
replace V9053 =. if V9053>=8
replace V9054 =. if V9054 ==0
replace V9054 =. if V9054>=8
replace V9055 =. if V9055 ==0
replace V9055 =. if V9055>=8
replace V9056 =. if V9056 ==0
replace V9056 =. if V9056>=8
replace V9057 =. if V9057 ==0
replace V9057 =. if V9057>=8
replace V9058 =. if V9058 ==0
replace V9058 =. if V9058>=8
replace V9059 =. if V9059 ==0
replace V9059 =. if V9059>=8
replace V9060 =. if V9060 ==0
replace V9060 =. if V9060>=8
replace V9061 =. if V9061 ==0
replace V9061 =. if V9061>=8

save c:\hrs1992\stata\MODULED.DTA 
