//////////////  //////////////////////////////////////////
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
 encode state, gen(state2)
 replace rpi = rpi/100
 egen panelid = group(state  hcpcs_cd), label
 xtset panelid year

global control1 "year state2  hcpcs_cd "
global cluster1 " state2"

reghdfe tot_bene_day_srvcs treat  rpi age65_percent_below_poverty , absorb($control1) cluster($cluster1)
 
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt


//regression with different fix effect
foreach var in `variables' {
    reghdfe `var' treat rpi age65_percent_below_poverty, absorb($control1) cluster($cluster1)
	outreg2 using "reg_results1'.csv"  , nor2 tstat bdec(3) tdec(2) ctitle(`var' ) addtext (Year FE, Yes,State FE, Yes, Code FE, Yes) append

	}
  
foreach var in `variables' {
reghdfe `var' treat rpi age65_percent_below_poverty, absorb(year state2 ) cluster($cluster1)
outreg2 using  "reg_results2'.csv",  nor2 tstat bdec(3) tdec(2) ctitle(`var') addtext (Year FE, Yes,State FE, Yes, Code FE, No) append

}


foreach var in `variables' {
	reghdfe `var' treat rpi age65_percent_below_poverty, absorb(year  hcpcs_cd ) cluster($cluster1)
	outreg2 using  "reg_results_`var'.csv"  ,  nor2 tstat bdec(3) tdec(2) ctitle(`var') addtext (Year FE, Yes,State FE, No, Code FE, Yes) append

}
	
foreach var in `variables' {
		reghdfe `var' treat rpi age65_percent_below_poverty, absorb(state2 hcpcs_cd ) cluster($cluster1)
	outreg2 using  "reg_results_`var'.csv"  , nor2  tstat bdec(3) tdec(2) ctitle( `var') addtext (Year FE, No,State FE, Yes, Code FE, Yes) append
 
}	
 
 
 
 
 
 
 
 
 /////////////log transform
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
encode state, gen(state2)
replace rpi = rpi/100

egen panelid = group(state  hcpcs_cd), label
xtset panelid year

global control1 "year state2"
global cluster1 " state2"

reghdfe tot_bene_day_srvcs treat  rpi age65_percent_below_poverty , absorb($control1) cluster($cluster1)
 
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
 
foreach var in `variables' {
		gen log_`var' = log(`var')//log transform
}	
 
local log_var log_tot_rndrng_prvdrs log_tot_benes log_tot_srvcs log_tot_bene_day_srvcs log_avg_sbmtd_chrg log_avg_mdcr_alowd_amt log_avg_mdcr_pymt_amt log_avg_mdcr_stdzd_amt

// regression with log and different fix effect
foreach logvar in `log_var' {
		reghdfe `logvar' treat rpi age65_percent_below_poverty, absorb($control1 ) cluster($cluster1)
	outreg2 using  "log_reg_results1'.csv"  ,  nor2 tstat bdec(3) tdec(2) ctitle( `logvar') addtext (Year FE, Yes,State FE, Yes, Code FE, Yes) append
 
}	


foreach logvar in `log_var' {
		reghdfe `logvar' treat rpi age65_percent_below_poverty, absorb(state2 year ) cluster($cluster1)
	outreg2 using  "log_reg_results2'.csv"  ,  nor2 tstat bdec(3) tdec(2) ctitle(`logvar') addtext (Year FE, Yes,State FE, Yes, Code FE, No) append
 
}	
 
 foreach logvar in `log_var' {
		reghdfe `logvar' treat rpi age65_percent_below_poverty, absorb(year hcpcs_cd ) cluster($cluster1)
	outreg2 using  "log_reg_results3'.csv"  , nor2  tstat bdec(3) tdec(2) ctitle(`logvar') addtext (Year FE, Yes,State FE, No, Code FE, Yes) append
 
}	
 
 
foreach logvar in `log_var' {
		reghdfe `logvar' treat rpi age65_percent_below_poverty, absorb(state2 hcpcs_cd ) cluster($cluster1)
	outreg2 using  "log_reg_results4'.csv"  , tstat bdec(3) tdec(2) ctitle( log_`var') addtext (Year FE, No,State FE, Yes, Code FE, Yes) append
 
}	
 

/////////////Parallel test for significant variables: 
//log_tot_srvcs log_tot_bene_day_srvcs log_avg_sbmtd_chrg log_avg_mdcr_alowd_amt log_avg_mdcr_pymt_amt log_avg_mdcr_stdzd_amt

cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    
xtreg log_tot_srvcs rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_tot_srvcs", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)	 

graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel1.png", replace







cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    
    
xtreg log_tot_bene_day_srvcs rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
	 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_tot_bene_day_srvcs", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)	 


graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel2.png", replace




cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    	    
xtreg log_avg_sbmtd_chrg rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
	 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_avg_sbmtd_chrg", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)
graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel3.png", replace







cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    
xtreg log_avg_mdcr_alowd_amt rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
	 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_avg_mdcr_alowd_amt", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)
graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel4.png", replace



cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    		    
xtreg log_avg_mdcr_pymt_amt rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
	 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_avg_mdcr_alowd_amt", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)
graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel5.png", replace





cls
import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, clear
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   
	    
xtreg log_avg_mdcr_stdzd_amt rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
eststo m	  

outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle1.txt", clear
gen year =substr( v1,10,10)
destring, replace force
drop if year ==.
drop v1
replace year = year -2
rename (v2 v3) (coef se)
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
sort year // ensure the correct line
twoway line lb year , lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub  year, lpattern(dash) lcolor(gs8) ///
|| line coef  year, lwidth(thin) lcolor(black) yaxis(1) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
	 xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
	 ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
	 xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
	 title("Parallel Test for Significant Variable:log_avg_mdcr_alowd_amt", size(small) margin(small)) ///
	  yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)
graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel6.png", replace



















******************************

cls
clear
local log_var log_tot_srvcs log_tot_bene_day_srvcs log_avg_sbmtd_chrg log_avg_mdcr_alowd_amt log_avg_mdcr_pymt_amt log_avg_mdcr_stdzd_amt


foreach y in `log_var' {
	import delimited D:\UMich\STAT506\final_proj\data\processed_data.csv, replace
egen panelid = group(state  hcpcs_cd), label
replace rpi = rpi/100
global control1 "year state2  hcpcs_cd "
global cluster1 " state2"
// parallel test: only　for expansion group
destring act_year , replace force
drop if act_year == . 
rename year year2
gen year = year - act_year
xtset panelid year
tabulate year , gen(year_dumm) //time fe
drop year_dumm6
tabulate panelid , gen(id_dumm) //individual fe
local variables tot_rndrng_prvdrs tot_benes tot_srvcs tot_bene_day_srvcs avg_sbmtd_chrg avg_mdcr_alowd_amt avg_mdcr_pymt_amt avg_mdcr_stdzd_amt
foreach var in `variables' {
		gen log_`var' = log(`var')
}		   


    xtreg `y' rpi age65_percent_below_poverty year_dumm*, fe i(panelid) cluster(panelid)
    eststo m
    
    outreg2 using "D:\UMich\STAT506\final_proj\graphs\reg_paralle_loop_`y'.xls", replace sideway noparen se nonotes nocons noaster nolabel sortvar(year_dumm1-year_dumm5)
    insheet using "D:\UMich\STAT506\final_proj\graphs\reg_paralle_loop_`y'.txt", clear
    gen year = substr(v1, 10, 10)
    destring, replace force
    drop if year == .
    drop v1
    replace year = year - 2
    rename (v2 v3) (coef se)
    gen lb = coef - 1.96 * se
    gen ub = coef + 1.96 * se
    sort year // ensure the correct line
    
    twoway (line lb year, lpattern(dash) lcolor(gs8) yaxis(1)) ///
           (line ub year, lpattern(dash) lcolor(gs8)) ///
           (line coef year, lwidth(thin) lcolor(black) yaxis(1)) ///
           , graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
           xlabel(-1(1)3, labsize(small)) xtick(-1(1)3) xtitle("Year", size(small)) ///
           ylabel(-0.3(0.2)0.3, labsize(small)) xtick(-1(1)3) ytitle("coefficient", size(small)) ///
           xline(0, lpattern(solid) lwidth(thin) lcolor(blue)) ///
           title("Parallel Test for Significant Variable: `y'", size(small) margin(small)) ///
           yline(0, lpattern(dash_dot_dot) lwidth(thin) lcolor(blue)) legend(off) fxsize(70) fysize(60)
    
    graph export "D:\UMich\STAT506\final_proj\graphs\reg_parallel_loop_`y'.png", replace
}

