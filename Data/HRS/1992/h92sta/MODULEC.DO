* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEC.DCT 
 
replace V3 =. if V3 ==00000
replace V9039 =. if V9039 ==0
replace V9039 =. if V9039>=8
replace V9040 =. if V9040 ==0
replace V9040 =. if V9040>=8
replace V9041 =. if V9041 ==0
replace V9041 =. if V9041>=8
replace V9042 =. if V9042 ==0
replace V9042 =. if V9042>=8
replace V9043 =. if V9043 ==0
replace V9043 =. if V9043>=8
replace V9044 =. if V9044 ==0
replace V9044 =. if V9044>=8
replace V9045 =. if V9045 ==0
replace V9045 =. if V9045>=8
replace V9046 =. if V9046 ==0
replace V9046 =. if V9046>=8
replace V9047 =. if V9047 ==0
replace V9047 =. if V9047>=8
replace V9048 =. if V9048 ==0
replace V9049 =. if V9049 ==0
replace V9049 =. if V9049>=8
replace V9050 =. if V9050 ==0
replace V9050 =. if V9050>=8
replace V9051 =. if V9051 ==0
replace V9051 =. if V9051>=8

save c:\hrs1992\stata\MODULEC.DTA 
