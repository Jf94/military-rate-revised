use "${DIR_DATA_PROCESSED}/panel.dta", clear

forvalues h=0/20 {
	gen milex`h' = f`h'.milex - l.milex
	gen cmilex`h' = log(f`h'.milex) - log(l.milex)
	gen lmilex`h' = log(f`h'.milex) - log(l.milex)
}

*drop windfall
*rename windfall_1 windfall
*winsor2 windfall, cuts(0.1 99.9) replace
reghdfe milex0 windfall, absorb(iso year) cluster(iso year) nocons

//// DO IT IN CHANGES
predict double milex_chg_pred, xb

keep iso year milex* cmilex* windfall* gdp conflict*
tempfile base
save `base', replace



// Prepare windfalls
use "${DIR_DATA_PROCESSED}/alliances.dta", clear
keep year iso iso_ally
rename iso iso_protected
rename iso_ally iso

* bring in ALLIES' actual & predicted changes
merge m:1 iso year using `base', nogen keep(match) keepusing(milex* windfall)

rename iso iso_ally
rename iso_protected iso

drop if windfall == . | milex0 == .
gen n_allies = 1

* sum across all allies j of i in year t
collapse (sum) TMA = milex0 (sum) ALLY_windfall = windfall ALLY_pred_change=milex_chg_pred n_allies, by(iso year)
tempfile tmas
save `tmas'


* Final dataset
use `base', clear
merge 1:1 iso year using `tmas', nogen keep(master matched)

replace n_allies = 0 if n_allies == .
gsort year -n_allies
bysort year: gen n_allies_rank = _n

egen cid = group(iso)
xtset cid year

// First stage regression
eststo clear
label var windfall "Windfall"
eststo: reghdfe milex0 windfall, noabsorb cluster(iso)

eststo: reghdfe milex0 windfall, absorb(iso) cluster(iso)
estadd local hascfe "\checkmark"

eststo: reghdfe milex0 windfall, absorb(iso year) cluster(iso)
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/firststage.tex", star(* 0.1 ** 0.05  *** 0.01) keep(windfall) r2 label fragment se tex nomtitles nonumbers replace  stats(hascfe hasyfe F r2 N, fmt(1 1 3 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$"))
eststo clear


label var ALLY_pred_change "\(\widehat{\Delta TMA}\)"

/*eststo: xtscc milex0 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low i.year, fe
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"*/

eststo: xtscc milex1 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low i.year, fe
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

eststo: xtscc milex5 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low i.year, fe
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

eststo: xtscc milex10 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low i.year, fe
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/secondstage.tex", star(* 0.1 ** 0.05  *** 0.01) keep(ALLY_pred_change) r2 label fragment se tex nomtitles nonumbers replace  stats(hasctrl hascfe hasyfe N, fmt(1 3 "%9.0fc") label("Controls" "Country fixed effects" "Year fixed effects" "\$N\$")) prefoot(\hline\noalign{\vskip 1.3mm}) posthead("") prehead("")
eststo clear




local h_max 15
cap drop b* ll* ul* h
gen b_instr = .
gen ll_instr = .
gen ul_instr = .

gen b_endog = .
gen ll_endog = .
gen ul_endog = .
gen h = _n-1 if _n <= `h_max' + 1

forvalues h=0/`h_max' {
	xtscc milex`h' l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(1/2).d.gdp i.year, fe level(90)
	lincom 100 * ALLY_pred_change, level(90)
	
	replace b_instr = r(estimate) if h == `h'
	replace ll_instr = r(lb) if h == `h'
	replace ul_instr = r(ub) if h == `h'
	
	
	xtscc milex`h' l(0/2).TMA l(0/2).windfall l(1/2).milex0 l(1/2).d.gdp i.year, fe level(90)
	lincom 100 * TMA, level(90)
	
	replace b_endog = r(estimate) if h == `h'
	replace ll_endog = r(lb) if h == `h'
	replace ul_endog = r(ub) if h == `h'
	
	
}


twoway ///
	(line b_instr h, color(stred)) ///
	(rarea ll_instr ul_instr h, color(stred%50) lwidth(0)) ///
	, yline(0) xtitle("Year after ally spending shock") ytitle("Military expenditures (in USD)") title("Response to 100 USD increase of allied military spending") legend(off) scale(1.4) ysize(9) xsize(20) xla(0(5)15)
	
graph export "${DIR_DATA_EXPORTS}/lp.pdf", as(pdf) replace



twoway ///
	(line b_endog h, color(stgreen)) ///
	(rarea ll_endog ul_endog h, color(stgreen%50) lwidth(0)) ///
	, yline(0) xtitle("Year after ally spending shock") ytitle("Military expenditures (in USD)") title("Response to endog 100 USD increase of allied military spending") legend(off) scale(1.4) ysize(9) xsize(20) xla(0(5)15)
	
graph export "${DIR_DATA_EXPORTS}/lp_endog.pdf", as(pdf) replace
graph close



// Larger countries have lower spending/gdp ratio than smaller countries
gen milgdp = milex / gdp
gen lgdp = log(gdp)
keep if milex0 != .
reghdfe milgdp lgdp, absorb(iso year) cluster(iso year)

binscatter milgdp lgdp, xtitle("Log of GDP") ytitle("Military spending in p.p. of GDP") name(noabsorb, replace) title("Without country fixed effects")
binscatter milgdp lgdp, absorb(iso) xtitle("Log of GDP") xtitle("Log of GDP") ytitle("Military spending in p.p. of GDP") name(absorb, replace) title("With country fixed effects")
grc1leg2 noabsorb absorb, loff ysize(9) xsize(20) scale(1.4)
graph export "${DIR_DATA_EXPORTS}/size.pdf", as(pdf) replace
graph close





merge m:1 year using "${DIR_DATA_PROCESSED}/gprc_global.dta", nogen keep(master matched)
xtset cid year

gen ALLY_pred_change_pos = -ALLY_pred_change

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
		
		* [rebuild any regressors that depend on beta here, e.g., RGP(beta)]
		gen enumerator = (1 + beta * n_allies) ^ -1
		bysort year: egen denominator = total(enumerator)
		
		gen RGP = enumerator / denominator
		
		xtset cid year
		
		gen term = GPRHT * RGP
		
		xtscc cmilex`h' l(0/2).ALLY_pred_change_pos l(0/2).term l(0/2).windfall l(1/2).milex0 l(1/2).d.gdp i.year, fe level(90)
		*reghdfe milex5 l(0/3).ALLY_pred_change_pos l(0/3).term l(0/3).windfall l(1/3).milex0 l(1/3).d.gdp, absorb(iso year) cluster(iso year)


		* pull the coefficient on the endogenous regressor
		scalar bhat = r(table)["b", "ALLY_pred_change_pos"]

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



twoway ///
	(line b h, color(stgreen)) ///
	(rarea ll ul h, color(stgreen%50) lwidth(0)) ///
	, yline(0) legend(off) scale(1.4) ysize(9) xsize(20) xla(0(1)5)
	