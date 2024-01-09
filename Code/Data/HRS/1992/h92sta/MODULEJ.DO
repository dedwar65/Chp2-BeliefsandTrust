* Note: activate this do file from within STATA
infile using c:\hrs1992\stata\MODULEJ.DCT 
 
replace V3 =. if V3 ==00000
replace V9119 =. if V9119 ==0
replace V9119 =. if V9119>=98
replace V9120 =. if V9120 ==0
replace V9121 =. if V9121>=96
replace V9122 =. if V9122>=96
replace V9123 =. if V9123>=96
replace V9124 =. if V9124 ==0
replace V9124 =. if V9124>=8
replace V9125 =. if V9125 ==0
replace V9125 =. if V9125>=8
replace V9126 =. if V9126 ==0
replace V9126 =. if V9126>=8
replace V9127 =. if V9127 ==0
replace V9127 =. if V9127>=8
replace V9128 =. if V9128 ==0
replace V9128 =. if V9128>=8
replace V9129 =. if V9129 ==0
replace V9129 =. if V9129>=8
replace V9130 =. if V9130 ==0
replace V9130 =. if V9130>=8
replace V9131 =. if V9131 ==0
replace V9131 =. if V9131>=9
replace V9132 =. if V9132 ==0
replace V9132 =. if V9132>=8
replace V9133 =. if V9133 ==0
replace V9133 =. if V9133>=9
replace V9134 =. if V9134 ==0
replace V9134 =. if V9134>=8
replace V9135 =. if V9135 ==0
replace V9135 =. if V9135>=9
replace V9136 =. if V9136 ==0
replace V9136 =. if V9136>=8
replace V9137 =. if V9137 ==0
replace V9137 =. if V9137>=9
replace V9138 =. if V9138 ==0
replace V9138 =. if V9138>=8
replace V9139 =. if V9139 ==0
replace V9139 =. if V9139>=9
replace V9140 =. if V9140 ==0
replace V9141 =. if V9141 ==0
replace V9142 =. if V9142 ==0
replace V9142 =. if V9142>=8
replace V9143 =. if V9143 ==0
replace V9143 =. if V9143>=995
replace V9144 =. if V9144 ==0
replace V9144 =. if V9144>=8
replace V9145 =. if V9145 ==0
replace V9145 =. if V9145>=995
replace V9146 =. if V9146 ==0
replace V9146 =. if V9146>=8
replace V9147 =. if V9147 ==0
replace V9147 =. if V9147>=8
replace V9148 =. if V9148 ==0
replace V9148 =. if V9148>=8
replace V9149 =. if V9149 ==0
replace V9149 =. if V9149>=8
replace V9150 =. if V9150 ==0
replace V9150 =. if V9150>=8
replace V9151 =. if V9151 ==0
replace V9151 =. if V9151>=8
replace V9152 =. if V9152 ==0
replace V9152 =. if V9152>=8
replace V9153 =. if V9153 ==0
replace V9153 =. if V9153>=8
replace V9154 =. if V9154 ==0
replace V9154 =. if V9154>=8
replace V9155 =. if V9155 ==0
replace V9155 =. if V9155>=8

save c:\hrs1992\stata\MODULEJ.DTA 
