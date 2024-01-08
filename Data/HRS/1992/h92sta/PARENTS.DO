* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\PARENTS.DCT 
 
replace V3 =. if V3 ==00000
replace V8203 =. if V8203 ==0
replace V8203 =. if V8203>=8
replace V8204 =. if V8204 ==0
replace V8204 =. if V8204>=999
replace V8205 =. if V8205 ==0
replace V8205 =. if V8205>=98
replace V8206 =. if V8206 ==0
replace V8206 =. if V8206>=8
replace V8207 =. if V8207 ==0
replace V8207 =. if V8207>=8
replace V8208 =. if V8208 ==0
replace V8208 =. if V8208>=9998
replace V8209 =. if V8209 ==0
replace V8209 =. if V8209>=98
replace V8210 =. if V8210 ==0
replace V8210 =. if V8210>=8
replace V8211 =. if V8211 ==0
replace V8211 =. if V8211>=8
replace V8212 =. if V8212>=9
replace V8213 =. if V8213 ==0
replace V8213 =. if V8213>=8
replace V8214 =. if V8214 ==0
replace V8214 =. if V8214>=8
replace V8215 =. if V8215 ==0
replace V8215 =. if V8215>=8
replace V8216 =. if V8216 ==0
replace V8216 =. if V8216>=98
replace V8217 =. if V8217 ==0
replace V8217 =. if V8217>=8
replace V8218 =. if V8218 ==0
replace V8218 =. if V8218>=8
replace V8219 =. if V8219 ==0
replace V8219 =. if V8219>=9998
replace V8220 =. if V8220 ==0
replace V8220 =. if V8220>=8
replace V8221 =. if V8221 ==0
replace V8221 =. if V8221>=8
replace V8222 =. if V8222 ==0
replace V8222 =. if V8222>=8
replace V8223 =. if V8223 ==0
replace V8223 =. if V8223>=8
replace V8224 =. if V8224 ==0
replace V8224 =. if V8224>=8

save c:\hrs1992\stata\PARENTS.DTA 
