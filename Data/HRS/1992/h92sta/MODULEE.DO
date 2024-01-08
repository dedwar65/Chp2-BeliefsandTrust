* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEE.DCT 
 
replace V3 =. if V3 ==00000
replace V9062 =. if V9062>=98
replace V9063 =. if V9063 ==0
replace V9063 =. if V9063>=98
replace V9064 =. if V9064>=98
replace V9065 =. if V9065>=98
replace V9066 =. if V9066>=98
replace V9067 =. if V9067>=98
replace V9068 =. if V9068>=98

save c:\hrs1992\stata\MODULEE.DTA 
