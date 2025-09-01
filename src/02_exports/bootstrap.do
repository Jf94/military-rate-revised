capture program drop bootprog
program define bootprog, rclass   
    version 17.0
	preserve
    
	build_panel_firststage
	build_panel_secondstage
	
	xtset bootclust year

	return scalar a = 1
	forvalues h=0/15 {
		reghdfe milex`h' l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
		return scalar b_ALLY_pred_change`h' = _b["ALLY_pred_change"]
	}
	
	xtset, clear
	restore
end

use "${DIR_DATA_PROCESSED}/panel.dta", clear
local expr

forvalues h=0/15 {
	local expr `expr' ALLY_pred_change`h' = r(b_ALLY_pred_change`h')
}

* Prepare expression for parallel bootstrap call
xtset, clear
bootstrap `expr', level(90) reps(1000) seed(0) cluster(iso) idcluster(bootclust): bootprog


local h_max 15
cap drop h b ll ul
gen h = _n - 1 if _n <= `h_max' + 1
gen b = .
gen ll = .
gen ul = .

forvalues h=0/`h_max' {			
	replace b = e(b)["y1", "ALLY_pred_change`h'"] * 100 if h == `h'
	replace ll = e(ci_bc)["ll", "ALLY_pred_change`h'"] * 100 if h == `h'
	replace ul = e(ci_bc)["ul", "ALLY_pred_change`h'"] * 100 if h == `h'
}
	
twoway ///
	(line b h, lcolor("stred")) ///
	(rarea ll ul h, color("stred%50") lwidth(0)) ///
	, ytitle("Military expenditures (in USD)") xtitle("Year after ally spending shock") title("Response to 100 USD decrease of allied military spending") legend(off) scale(1.4) ysize(9) xsize(20) xla(0(5)15) yline(0)
graph export "${DIR_DATA_EXPORTS}/bootstrap_country.pdf", as(pdf) replace




// Product-year level bootstrap
capture program drop bootprog_prodyear
program define bootprog_prodyear, rclass   
    version 17.0
	preserve
	
	collapse (sum) windfall (count) n=windfall, by(iso year)
	replace windfall = . if n == 0
	
	tempfile windfalls
	save `windfalls'
	
	use "${DIR_DATA_PROCESSED}/panel.dta", clear
	drop windfall*
	merge 1:1 iso year using `windfalls', nogen keep(master matched)
	
	
	build_panel_firststage
	build_panel_secondstage
	
	xtset cid year
	
	forvalues h=0/15 {
		reghdfe milex`h' l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
		return scalar b_ALLY_pred_change`h' = _b["ALLY_pred_change"]
	}
	
	restore
end

use "${DIR_DATA_PROCESSED}/windfalls_disaggregated.dta", clear

egen prodyear = group(cmdcode year)


xtset, clear

local expr
forvalues h=0/15 {
	local expr `expr' ALLY_pred_change`h' = r(b_ALLY_pred_change`h')
}
bootstrap `expr', level(90) reps(100) seed(0) cluster(prodyear): bootprog_prodyear



local h_max 15
cap drop h b ll ul
gen h = _n - 1 if _n <= `h_max' + 1
gen b = .
gen ll = .
gen ul = .

forvalues h=0/`h_max' {			
	replace b = e(b)["y1", "ALLY_pred_change`h'"] * 100 if h == `h'
	replace ll = e(ci_bc)["ll", "ALLY_pred_change`h'"] * 100 if h == `h'
	replace ul = e(ci_bc)["ul", "ALLY_pred_change`h'"] * 100 if h == `h'
}
	
twoway ///
	(line b h, lcolor("stred")) ///
	(rarea ll ul h, color("stred%50") lwidth(0)) ///
	, ytitle("Military expenditures (in USD)") xtitle("Year after ally spending shock") title("Response to 100 USD decrease of allied military spending") legend(off) scale(1.4) ysize(9) xsize(20) xla(0(5)15) yline(0)
graph export "${DIR_DATA_EXPORTS}/bootstrap_prodyear.pdf", as(pdf) replace

