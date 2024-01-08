* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEH.DCT 
 
replace V3 =. if V3 ==00000
replace V9096 =. if V9096 ==0
replace V9097 =. if V9097 ==0
replace V9097 =. if V9097>=8
replace V9098 =. if V9098 ==0
replace V9098 =. if V9098>=98
replace V9099 =. if V9099 ==0
replace V9099 =. if V9099>=98
replace V9100 =. if V9100 ==0
replace V9100 =. if V9100>=8
replace V9101 =. if V9101 ==0
replace V9101 =. if V9101>=98
replace V9102 =. if V9102 ==0
replace V9102 =. if V9102>=98
replace V9103 =. if V9103 ==0
replace V9103 =. if V9103>=8
replace V9104 =. if V9104 ==0
replace V9104 =. if V9104>=98
replace V9105 =. if V9105 ==0
replace V9105 =. if V9105>=98
replace V9106 =. if V9106 ==0
replace V9106 =. if V9106>=8
replace V9107 =. if V9107 ==0
replace V9107 =. if V9107>=98
replace V9108 =. if V9108 ==0
replace V9108 =. if V9108>=98
replace V9109 =. if V9109 ==0
replace V9109 =. if V9109>=8
replace V9110 =. if V9110 ==0
replace V9110 =. if V9110>=9
replace V9111 =. if V9111 ==0
replace V9111 =. if V9111>=98
replace V9112 =. if V9112 ==0
replace V9112 =. if V9112>=98
replace V9113 =. if V9113 ==0
replace V9113 =. if V9113>=8
replace V9114 =. if V9114 ==0
replace V9114 =. if V9114>=8
replace V9115 =. if V9115 ==0
replace V9115 =. if V9115>=8
replace V9116 =. if V9116 ==0
replace V9116 =. if V9116>=8
replace V9117 =. if V9117 ==0
replace V9117 =. if V9117>=8
replace V9118 =. if V9118 ==0
replace V9118 =. if V9118>=8

save c:\hrs1992\stata\MODULEH.DTA 
