* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\HHLIST.DCT 
 
replace V3 =. if V3 ==00000
replace V8301 =. if V8301 ==0
replace V8301 =. if V8301>=99
replace V8302 =. if V8302 ==0
replace V8302 =. if V8302>=991
replace V8303 =. if V8303>=98
replace V8304 =. if V8304>=9
replace V8305 =. if V8305>=99
replace V8306 =. if V8306 ==0
replace V8308 =. if V8308 ==0
replace V8308 =. if V8308>=98
replace V8309 =. if V8309 ==0
replace V8309 =. if V8309>=98
replace V8310 =. if V8310 ==0
replace V8310 =. if V8310>=9998

save c:\hrs1992\stata\HHLIST.DTA 
