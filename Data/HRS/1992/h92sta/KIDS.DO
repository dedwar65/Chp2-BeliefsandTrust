* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\KIDS.DCT 
 
replace V3 =. if V3 ==00000
replace V8002 =. if V8002 ==0
replace V8002 =. if V8002>=98
replace V8003 =. if V8003 ==0
replace V8003 =. if V8003>=998
replace V8004 =. if V8004 ==0
replace V8004 =. if V8004>=9
replace V8005 =. if V8005 ==0
replace V8005 =. if V8005>=98
replace V8006 =. if V8006 ==0
replace V8006 =. if V8006>=98
replace V8007 =. if V8007 ==0
replace V8007 =. if V8007>=98
replace V8008 =. if V8008 ==0
replace V8008 =. if V8008>=8
replace V8009 =. if V8009 ==0
replace V8009 =. if V8009>=98
replace V8010 =. if V8010 ==0
replace V8010 =. if V8010>=8
replace V8011 =. if V8011 ==0
replace V8011 =. if V8011>=8
replace V8012 =. if V8012 ==0
replace V8012 =. if V8012>=8
replace V8013 =. if V8013>=96
replace V8014 =. if V8014 ==0
replace V8014 =. if V8014>=8
replace V8015 =. if V8015 ==0
replace V8015 =. if V8015>=8
replace V8016 =. if V8016 ==0
replace V8016 =. if V8016>=9996
replace V8017 =. if V8017 ==0
replace V8017 =. if V8017>=8
replace V8018 =. if V8018 ==0
replace V8018 =. if V8018>=8
replace V8019 =. if V8019 ==0
replace V8019 =. if V8019>=8
replace V8020 =. if V8020 ==0
replace V8020 =. if V8020>=8

save c:\hrs1992\stata\KIDS.DTA 
