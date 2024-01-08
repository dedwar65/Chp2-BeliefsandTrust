* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\SIBLINGS.DCT 
 
replace V3 =. if V3 ==00000
replace V8102 =. if V8102 ==0
replace V8102 =. if V8102>=98
replace V8103 =. if V8103 ==0
replace V8103 =. if V8103>=998
replace V8104 =. if V8104 ==0
replace V8104 =. if V8104>=8
replace V8105 =. if V8105 ==0
replace V8105 =. if V8105>=98
replace V8106 =. if V8106 ==0
replace V8106 =. if V8106>=8
replace V8107 =. if V8107 ==0
replace V8107 =. if V8107>=98
replace V8108 =. if V8108 ==0
replace V8108 =. if V8108>=8
replace V8109 =. if V8109 ==0
replace V8109 =. if V8109>=8
replace V8110 =. if V8110 ==0
replace V8110 =. if V8110>=8
replace V8111 =. if V8111 ==0
replace V8111 =. if V8111>=8
replace V8112 =. if V8112 ==0
replace V8112 =. if V8112>=8
replace V8113 =. if V8113 ==0
replace V8113 =. if V8113>=8

save c:\hrs1992\stata\SIBLINGS.DTA 
