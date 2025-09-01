use "${DIR_DATA_PROCESSED}/panel.dta", clear

levelsof iso, local(isos)


cap mat drop sims_b
cap mat drop sims_ll
cap mat drop sims_ul

foreach iso in `isos' {
	preserve
	
	qui {
		drop if iso == "`iso'"
		build_panel_firststage
		build_panel_secondstage
		
		xtset cid year
		
		xtscc milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp i.year, fe level(90)
		matrix sims_b = nullmat(sims_b) \ r(table)["b", "ALLY_pred_change"]
		matrix sims_ll = nullmat(sims_ll) \ r(table)["ll", "ALLY_pred_change"]
		matrix sims_ul = nullmat(sims_ul) \ r(table)["ul", "ALLY_pred_change"]
	}
	restore	
}

svmat sims_b
svmat sims_ll
svmat sims_ul

gen x = _n if sims_b != .


preserve
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]
restore

twoway ///
	(rcap sims_ll sims_ul x, msize(0.1) lwidth(0.2) color(stblue)) ///
	(scatter sims_b x, mcolor(stred) msize(0.125)) ///
	, legend(off) yline(0) xsize(20) ysize(9) yla(-0.05(0.05)0.15) scale(1.4) xtitle("") ytitle("Estimated coefficient")
graph export "${DIR_DATA_EXPORTS}/jackknife_country.pdf", as(pdf) replace








use "${DIR_DATA_PROCESSED}/panel.dta", clear

levelsof year, local(years)


cap mat drop sims_b
cap mat drop sims_ll
cap mat drop sims_ul

foreach year in `years' {
	preserve
	
	qui {
		drop if year == `year'
		build_panel_firststage
		build_panel_secondstage
		
		xtset cid year
		
		reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, level(90) absorb(iso year) cluster(iso year)
		matrix sims_b = nullmat(sims_b) \ r(table)["b", "ALLY_pred_change"]
		matrix sims_ll = nullmat(sims_ll) \ r(table)["ll", "ALLY_pred_change"]
		matrix sims_ul = nullmat(sims_ul) \ r(table)["ul", "ALLY_pred_change"]
	}
	restore	
}

svmat sims_b
svmat sims_ll
svmat sims_ul

gen x = _n if sims_b != .

preserve
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]
restore



twoway ///
	(rcap sims_ll sims_ul x, msize(0.1) lwidth(0.2) color(stblue)) ///
	(scatter sims_b x, mcolor(stred) msize(0.125)) ///
	, legend(off) yline(`coeff_baseline', lcolor(red)) xsize(20) ysize(9) scale(1.4) xtitle("") ytitle("Estimated coefficient")
graph export "${DIR_DATA_EXPORTS}/jackknife_year.pdf", as(pdf) replace
