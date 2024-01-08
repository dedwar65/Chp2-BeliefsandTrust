* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\WIDOWED.DCT 
 
replace V3 =. if V3 ==00000
replace V7002 =. if V7002 ==0
replace V7002 =. if V7002>=8
replace V7003 =. if V7003 ==0
replace V7003 =. if V7003>=99980
replace V7004 =. if V7004 ==0
replace V7004 =. if V7004>=9
replace V7005 =. if V7005 ==0
replace V7005 =. if V7005>=99980
replace V7006 =. if V7006 ==0
replace V7006 =. if V7006>=9
replace V7007 =. if V7007 ==0
replace V7007 =. if V7007>=8
replace V7008 =. if V7008 ==0
replace V7008 =. if V7008>=99980
replace V7009 =. if V7009 ==0
replace V7009 =. if V7009>=9
replace V7010 =. if V7010 ==0
replace V7010 =. if V7010>=99980
replace V7011 =. if V7011 ==0
replace V7011 =. if V7011>=9
replace V7012 =. if V7012 ==0
replace V7012 =. if V7012>=8
replace V7013 =. if V7013 ==0
replace V7013 =. if V7013>=99980
replace V7014 =. if V7014 ==0
replace V7014 =. if V7014>=9
replace V7015 =. if V7015 ==0
replace V7015 =. if V7015>=99980
replace V7016 =. if V7016 ==0
replace V7016 =. if V7016>=9
replace V7017 =. if V7017 ==0
replace V7017 =. if V7017>=8
replace V7018 =. if V7018 ==0
replace V7018 =. if V7018>=99980
replace V7019 =. if V7019 ==0
replace V7019 =. if V7019>=9
replace V7020 =. if V7020 ==0
replace V7020 =. if V7020>=99980
replace V7021 =. if V7021 ==0
replace V7021 =. if V7021>=9
replace V7022 =. if V7022 ==0
replace V7022 =. if V7022>=8
replace V7023 =. if V7023 ==0
replace V7023 =. if V7023>=99980
replace V7024 =. if V7024 ==0
replace V7024 =. if V7024>=9
replace V7025 =. if V7025 ==0
replace V7025 =. if V7025>=99980
replace V7026 =. if V7026 ==0
replace V7026 =. if V7026>=9
replace V7027 =. if V7027 ==0
replace V7027 =. if V7027>=98
replace V7028 =. if V7028 ==0
replace V7028 =. if V7028>=98
replace V7029 =. if V7029 ==0
replace V7029 =. if V7029>=8
replace V7030 =. if V7030 ==0
replace V7030 =. if V7030>=98
replace V7031 =. if V7031 ==0
replace V7031 =. if V7031>=98
replace V7032 =. if V7032 ==0
replace V7032 =. if V7032>=8
replace V7033 =. if V7033 ==0
replace V7033 =. if V7033>=999980
replace V7034 =. if V7034 ==0
replace V7034 =. if V7034>=8
replace V7035 =. if V7035 ==0
replace V7035 =. if V7035>=999980
replace V7036 =. if V7036>=999980

save c:\hrs1992\stata\WIDOWED.DTA 
