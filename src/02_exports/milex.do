do "${DIR_SRC_PROCESS}/firststage.do"
use "${DIR_DATA_PROCESSED}/panel.dta", clear

build_panel_firststage

egen cid = group(iso)
xtset cid year

local h_max 15
gen h = _n - 1 if _n <= `h_max' + 1
gen b = .
gen ll = .
gen ul = .

forvalues h=0/`h_max' {
	// Response to 100USD shock
	replace milex`h' = milex`h' * 100
	xtscc milex`h' l(0/3).windfall l(1/3).milex0 i.year, fe
	
	replace b = r(table)["b", "windfall"] if h == `h'
	replace ll = r(table)["ll", "windfall"] if h == `h'
	replace ul = r(table)["ul", "windfall"] if h == `h'
}

twoway ///
	(line b h, color(stred)) ///
	(rarea ll ul h, color(stred%50) lwidth(0)) ///
	, xtitle("Years after windfall") ytitle("Military expenditures (in USD)") title("Response to 100 USD windfall") yline(0) xsize(20) ysize(9) legend(off) scale(1.4)
graph export "${DIR_DATA_EXPORTS}/milex.pdf", as(pdf) replace
