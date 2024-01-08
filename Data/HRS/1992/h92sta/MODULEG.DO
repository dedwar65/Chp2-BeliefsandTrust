* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEG.DCT 
 
replace V3 =. if V3 ==00000
replace V9085 =. if V9085 ==0
replace V9086 =. if V9086 ==0
replace V9087 =. if V9087 ==0
replace V9087 =. if V9087>=9
replace V9088 =. if V9088 ==0
replace V9088 =. if V9088>=8
replace V9089 =. if V9089 ==0
replace V9089 =. if V9089>=9999998
replace V9090 =. if V9090 ==0
replace V9090 =. if V9090>=8
replace V9091 =. if V9091 ==0
replace V9091 =. if V9091>=9999998
replace V9092 =. if V9092 ==0
replace V9092 =. if V9092>=8
replace V9093 =. if V9093 ==0
replace V9093 =. if V9093>=9999998
replace V9094 =. if V9094 ==0
replace V9094 =. if V9094>=98
replace V9095 =. if V9095 ==0
replace V9095 =. if V9095>=98

save c:\hrs1992\stata\MODULEG.DTA 
