********************************************************************************
********************************************************************************
*************** Predictions of the pseudo durations for the NOP ****************
********************************************************************************
********************************************************************************

*	set seed
set seed 12345



*	load dataset
global data "D:\Studium\Economics M.Res Mannheim\Summer Courses\Causal Machine Learning\Case study MA 2021\north"
import delimited "$data\Output\north_cleaned.csv", clear
save "$data\Lasso\north_cleaned.dta", replace
use "$data\Lasso\north_cleaned.dta", clear



***	compute quarters until programm start

*	compute treatment dummy
gen treated = 1 if (ptype == 1 | ptype == 2)
replace treated = 0 if ptype == 0



/*	compute a variable that indicates the time until the treatment start,
	i.e. length of the last unemployment spell until 19X3_Q1 */
gen time_elapsed = 8 if (emplx1_1 == 2 & emplx1_2 == 2 & emplx1_3 == 2 ///
	& emplx1_4 == 2 & emplx2_1 == 2 & emplx2_2 == 2 & emplx2_3 == 2 ///
	& emplx2_4 == 2)
replace time_elapsed = 7 if (emplx1_2 == 2 & emplx1_3 == 2 & emplx1_4 == 2 ///
	& emplx2_1 == 2 & emplx2_2 == 2 & emplx2_3 == 2 & emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 6 if ( emplx1_3 == 2 & emplx1_4 == 2 & emplx2_1 == 2 ///
	& emplx2_2 == 2 & emplx2_3 == 2 & emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 5 if (emplx1_4 == 2 & emplx2_1 == 2 & emplx2_2 == 2 ///
	& emplx2_3 == 2 & emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 4 if (emplx2_1 == 2 & emplx2_2 == 2 & emplx2_3 == 2 ///
	& emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 3 if (emplx2_2 == 2 & emplx2_3 == 2 & emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 2 if (emplx2_3 == 2 & emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 1 if (emplx2_4 == 2 & missing(time_elapsed))
replace time_elapsed = 0 if missing(time_elapsed)
label var time_elapsed "quarters until treatment start"





***	set globals for the later estimations

*	selection methods
global selection_methods "cv"
global k_fold "10"

*	outcome variable
global outcome_variable "time_elapsed"

*	explanatory variables (distinguish between continuous and categorial variables)
global aux_1 "c.earn_x0 c.unem_x0 c.em_x0 c.olf_x0 c.age i.sex c.school i.voc_deg i.nation"
global aux_2 "$aux_1 i.lmp_cw c.shp_cw_1 c.shp_cw_2 c.shp_cw_3 c.shp_cw_4 i.specia_c i.region"
global aux_3 "$aux_2 c.reg_al c.reg_prg c.reg_ser c.reg_pro c.reg_agri c.sect_al"
global explanatory_variables "$aux_3 c.prof_al i.prof_xl"
	
		

		
	
********************************************************************************
********************************************************************************
***************** Lasso Variable Selection + OLS (Post LASSO) ******************
********************************************************************************
********************************************************************************

***	run the LASSO (may have to install it beforehand)
lasso linear $outcome_variable $explanatory_variables ($explanatory_variables )##i.sex ///
	if treated == 1, selection($selection_method , folds($k_fold )) rseed(12345) stop(1e-6)			

*	save the selected variables in a global "selected_variables"
global selected_variables `e(allvars_sel)'



***	run the Post LASSO with the selected variables
reg time_elapsed $selected_variables



***	compute the residuals for the treated
predict residuals_treated if treated == 1, resid
label var residuals_treated "residuals of the treated (post LASSO)"

*	save the standard deviation of the residuals of the treated in a global "standard_deviation"
sum residuals_treated
global standard_deviation `r(sd)'



/**	compute the fitted values for the untreated based on the coefficients of the
	post LASSO */
predict fitted_untreated if treated == 0
label var fitted_untreated "fitted values of the untreated (post LASSO)"



***	generate a random error term ~N(0, $standard_deviation)
gen error_term = rnormal(0,$standard_deviation ) if treated == 0
label var error_term "error_term for prediction_time_elapsed"



*** final prediction_time_elapsed for untreated 
gen prediction_time_elapsed = fitted_untreated + error_term
label var prediction_time_elapsed "predicted quarters until treatment start for untreated"



*** difference between predicted time and time elapsed
gen selection_criterion = prediction_time_elapsed - time_elapsed
label var selection_criterion "difference between prediction_time_elapsed and time_elapsed"



*** count number of dropped / chosen observations

*	generate a dummy for "not yet treated group"
local max_bound "7"
gen not_yet_treated = 1 if inrange(selection_criterion,0,`max_bound') & !missing(selection_criterion)
replace not_yet_treated = 0 if !inrange(selection_criterion,0,`max_bound') & !missing(selection_criterion)
label var not_yet_treated "1 if variable is chosen for not yet treated group"



*** plot a histogram which shows how many observations are dropped / chosen
set scheme plotplain
hist selection_criterion, color(gray) title("Selection: {it:not yet treated}") ///
	start(-12) width(0.5) ///
	xtitle("difference between predicted elapsed time until treatment" "and last unemployment spell before treatment (in quarters)")
forval i=1/18{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(red))))
}
forval i=19/32{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(blue))))
}
forval i=33/44{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(red))))
}
graph export "$data\Lasso\selection_not_yet_treated_hist.png", replace



*** drop all never participating
drop if not_yet_treated == 0 & ptype == 0



*** drop all observations with missing values (was done for troubleshooting)
gen any_missing = missing(v1, unnamed0, pers, ptype, durat, earn_x0, earnx1_1, earnx1_2, earnx1_3, earnx1_4, earnx2_1, earnx2_2, earnx2_3, earnx2_4, earnx3_1, earnx3_2, ///
 earnx3_3, earnx3_4, earnx4_1, earnx4_2, earnx4_3, earnx4_4, earnx5_1, earnx5_2, earnx5_3, earnx5_4, earnx6_1, earnx6_2, earnx6_3, earnx6_4, earnx7_1, earnx7_2, earnx7_3, ///
 earnx7_4, earnx8_1, earnx8_2, earnx8_3, earnx8_4, earnx9_1, earnx9_2, earnx9_3, earnx9_4, unem_x0, em_x0, olf_x0, emplx1_1, emplx1_2, emplx1_3, emplx1_4, emplx2_1, emplx2_2, ///
 emplx2_3, emplx2_4, emplx3_1, emplx3_2, emplx3_3, emplx3_4, emplx4_1, emplx4_2, emplx4_3, emplx4_4, emplx5_1, emplx5_2, emplx5_3, emplx5_4, emplx6_1, emplx6_2, emplx6_3, ///
 emplx6_4, emplx7_1, emplx7_2, emplx7_3, emplx7_4, emplx8_1, emplx8_2, emplx8_3, emplx8_4, emplx9_1, emplx9_2, emplx9_3, emplx9_4, age, c_t1, c_t2, c_e1, c_e2, sex, school, ///
 voc_deg, nation, lmp_cw, shp_cw_1, shp_cw_2, shp_cw_3, shp_cw_4, specia_c, region, reg_al, reg_prg, reg_ser, reg_pro, reg_agri, sect_al, prof_al, prof_xl, noprog, t1, t2, e1, ///
 e2, lmp_1, lmp_2, lmp_3, lmp_4, voc_deg_0, voc_deg_1, voc_deg_2, school_bin, school_use, emplx_cum_9, emplx_cum_30, emplx_cum_84, earnx_mean_9, earnx_mean_30, ///
 earnx_mean_84)
drop if any_missing == 1
drop any_missing



***	generate dummies
gen age_under_40 = 1 if inrange(age,30,39)
replace age_under_40 = 1 if inrange(age,40,50)
label var age_under_40 "1 if individual is younger than 40"


gen olf_more_than_one_year = 1 if inrange(olf_x0,13,80)
replace olf_more_than_one_year = 1 if inrange(olf_x0,0,12)



***	draw small random sample
sample 50



***	save as csv
outsheet * using "$data\Lasso\north_cleaned_selected.csv", replace comma 











