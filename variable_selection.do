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
gen time_elapsed = 8 if (emplx1_1 == 0 & emplx1_2 == 0 & emplx1_3 == 0 ///
	& emplx1_4 == 0 & emplx2_1 == 0 & emplx2_2 == 0 & emplx2_3 == 0 ///
	& emplx2_4 == 0)
replace time_elapsed = 7 if (emplx1_2 == 0 & emplx1_3 == 0 & emplx1_4 == 0 ///
	& emplx2_1 == 0 & emplx2_2 == 0 & emplx2_3 == 0 & emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 6 if ( emplx1_3 == 0 & emplx1_4 == 0 & emplx2_1 == 0 ///
	& emplx2_2 == 0 & emplx2_3 == 0 & emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 5 if (emplx1_4 == 0 & emplx2_1 == 0 & emplx2_2 == 0 ///
	& emplx2_3 == 0 & emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 4 if (emplx2_1 == 0 & emplx2_2 == 0 & emplx2_3 == 0 ///
	& emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 3 if (emplx2_2 == 0 & emplx2_3 == 0 & emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 2 if (emplx2_3 == 0 & emplx2_4 == 0 & missing(time_elapsed))
replace time_elapsed = 1 if (emplx2_4 == 0 & missing(time_elapsed))
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
	if treated == 1, selection($selection_method , folds($k_fold )) rseed(12345) stop(1e-5)			

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
local max_bound "5"
gen not_yet_treated = 1 if inrange(selection_criterion,0,`max_bound') & !missing(selection_criterion)
replace not_yet_treated = 0 if selection_criterion < 0 
label var not_yet_treated "1 if variable is chosen for not yet treated group"



*** plot a histogram which shows how many observations are dropped / chosen
hist selection_criterion, color(gray) title("Selection: {it:not yet treated}") ///
	start(-12) width(0.5) ///
	xtitle("difference between predicted elapased time until treatment" "and last unemployment spell before treatment (in quarters)")
forval i=1/20{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(red))))
}
forval i=21/30{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(blue))))
}
forval i=31/44{
      gr_edit .plotregion1.plot1.EditCustomStyle , j(`i') style(area(shadestyle(color(red))))
}
graph export "$data\Lasso\selection_not_yet_treated_hist.png", replace





***	save as csv
outsheet * using "$data\Lasso\north_cleaned_selected.csv", replace comma 











