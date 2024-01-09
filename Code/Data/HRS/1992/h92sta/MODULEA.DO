* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEA.DCT 
 
replace V3 =. if V3 ==00000
replace V9001 =. if V9001 ==0
replace V9001 =. if V9001>=993
replace V9002 =. if V9002 ==0
replace V9002 =. if V9002>=993
replace V9003 =. if V9003 ==0
replace V9003 =. if V9003>=993
replace V9004 =. if V9004 ==0
replace V9004 =. if V9004>=6
replace V9005 =. if V9005 ==0
replace V9005 =. if V9005>=6
replace V9006 =. if V9006 ==0
replace V9006 =. if V9006>=6
replace V9007 =. if V9007 ==0
replace V9007 =. if V9007>=8
replace V9008 =. if V9008 ==0
replace V9008 =. if V9008>=8
replace V9009 =. if V9009 ==0
replace V9009 =. if V9009>=996
replace V9010 =. if V9010 ==0
replace V9010 =. if V9010>=996
replace V9011 =. if V9011 ==0
replace V9011 =. if V9011>=996
replace V9012 =. if V9012 ==0
replace V9012 =. if V9012>=6
replace V9013 =. if V9013 ==0
replace V9013 =. if V9013>=6
replace V9014 =. if V9014 ==0
replace V9014 =. if V9014>=6
replace V9015 =. if V9015 ==0
replace V9015 =. if V9015>=6

save c:\hrs1992\stata\MODULEA.DTA 
