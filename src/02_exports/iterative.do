use "${DIR_DATA_PROCESSED}/panel.dta", clear

build_panel_firststage
build_panel_secondstage

local h_max 5
cap drop h 
cap drop b ll ul
gen h = _n-1 if _n <= `h_max' + 1
gen b = .
gen ll = .
gen ul = .

forvalues h = 0/`h_max' {	
	scalar beta = 0.30      // initial guess
	scalar mu   = 0.50      // damping [0,1]
	scalar tol  = 1e-4      // tolerance
	scalar maxit = 50

	local i = 0
	while (`i' < `=maxit') {
		local ++i
		
		cap drop enumerator denominator RGP term
		cap drop dgprc
		
		
		gen enumerator = (1 + beta * n_allies) ^ -1
		bysort year: egen denominator = total(enumerator)
		
		gen RGP = enumerator / denominator
		
		xtset cid year
		
		gen term = GPRHT * RGP
		
		xtscc milex`h' ALLY_pred_change term windfall i.year, fe level(90)


		* pull the coefficient on the endogenous regressor
		scalar bhat = r(table)["b", "ALLY_pred_change"]

		* damped update
		scalar newbeta = (1-mu)*beta + mu*bhat

		* check convergence
		di as txt "iter " %02.0f `i' "  beta=" %9.5f beta "  bhat=" %9.5f bhat "  |Δ|=" %9.3e abs(newbeta-beta)
		if (abs(newbeta - beta) < tol) {
			scalar beta = newbeta
			continue, break
		}
		scalar beta = newbeta
	}
	
	replace b = r(table)["b", "term"] if h == `h'
	replace ll = r(table)["ll", "term"] if h == `h'
	replace ul = r(table)["ul", "term"] if h == `h'
	
	di as res "Converged beta = " %9.5f beta
}

sort h
twoway ///
	(line b h, color(stgreen)) ///
	(rarea ll ul h, color(stgreen%50) lwidth(0)) ///
	, yline(0) legend(off) scale(1.4) ysize(9) xsize(20) xla(0(1)5)

graph export "${DIR_DATA_EXPORTS}/iterative.pdf", as(pdf) replace

