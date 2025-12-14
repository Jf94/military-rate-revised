*** First stage
cap program drop run_firststage 
program define run_firststage, rclass
	syntax, ///
		[pricetaker(real 0)]

	* milex_{it}/gdp_{it-1} = windfall_{it}/gdp_{it-1}
	*reghdfe milex1_gdp windfall_gdp_w, absorb(iso year)
	*gen dmilex_exog = windfall_gdp_w * _b[windfall_gdp_w] * l1gdp
	
	if `pricetaker' == 1 {
		replace windfall = windfall_05
	}
	
	reghdfe milex1 windfall l1dmilex l2dmilex, noabsorb cluster(iso)
	gen dmilex_exog = _b[windfall] * windfall
	
	
	rename milex1 dmilex_raw
	keep iso year dmilex_exog dmilex_raw
end

*** Second stage
cap program drop run_secondstage 
program define run_secondstage, rclass
	syntax, ///
		[secondstage(string)] ///
		[eststo(string)]
		
	** Assume results from first stage fn in memory
	tempfile windfalls
	save `windfalls'
	
	** Compute windfall-implied variation in TMA/TRA
	use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
	
	* Generate lagged alliance / rival structure
	egen gid = group(iso1 iso2)
	xtset gid year
	gen lF_ally = l.F_ally
	gen lF_rival = l.F_rival
	xtset, clear

	* Join windfalls and compute aggregate windfalls of allies/rivals
	rename iso2 iso 
	joinby iso year using `windfalls'
	gen ALLY_dmilex_exog = dmilex_exog * lF_ally
	gen RIVAL_dmilex_exog = dmilex_exog * lF_rival
	
	gen ALLY_dmilex_raw = dmilex_raw * lF_ally
	gen RIVAL_dmilex_raw = dmilex_raw * lF_rival
	collapse (sum) ALLY_dmilex_exog RIVAL_dmilex_exog ALLY_dmilex_raw RIVAL_dmilex_raw, by(iso1 year)
	rename iso1 iso
	
	* Tempoerarily save windfalls of allies/rivals
	tempfile TMATRA
	save `TMATRA'
	
	** Prepare second-stage panel
	use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear
	merge 1:1 iso year using `TMATRA', nogen keep(master matched)
	
	* Make sure to not include years thrown out in first stage bootstrap
	bysort year: egen maxALLY = max(ALLY_dmilex_exog)
	bysort year: egen maxRIVAL = max(RIVAL_dmilex_exog)
	drop if maxALLY == 0 & maxRIVAL == 0
	
	

	* Run second-stage regression
	if "`eststo'" == "1" {
		eststo: reghdfe `secondstage'
	}
	else {
		reghdfe `secondstage'
	}
	
	cap return scalar b_TMA  		= _b[ALLY_dmilex_exog]
	cap return scalar b_TMR  		= _b[RIVAL_dmilex_exog]
	cap return scalar b_ldGDP 		= _b[ldgdp]
	cap return scalar b_ldGDP_avg 	= _b[ldgdp_avg]
	cap return scalar b_windfall 	= _b[windfall]
end

**** Bootstrap wrapper
cap program drop bootstrap_wrapper 
program define bootstrap_wrapper, rclass
	syntax, ///
		[secondstage(string)] ///
		[eststo(string)] ///
		[pricetaker(real 0)]
		
	preserve
	run_firststage, pricetaker(`pricetaker')
	run_secondstage, secondstage(`secondstage') eststo(`eststo')
	return add
	restore
end


use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

eststo clear
eststo: reghdfe milex1 windfall l1dmilex l2dmilex, noabsorb cluster(iso)
estadd local controls "\checkmark"

label var windfall "Windfall"

esttab using "${DIR_DATA_EXPORTS}/shortrun/iv/firststage.tex", ///
	keep(windfall) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	tex fragment nonumbers nomtitle posthead("")  se label  ///
	stats(controls F  r2 N, fmt(1 2 2 "%9.0fc") ///
	label("Controls" "F-Statistic" "\(R^2\)" "\$N\$")) ///
	replace


xtset, clear

eststo clear

// Col 0: uninstrumented
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_raw RIVAL_dmilex_raw ldgdp windfall, noabsorb cluster(iso)) ///
	eststo(1)

// Col 1
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp windfall, noabsorb cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
	
// Col 2
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp ldgdp_avg windfall, noabsorb cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
	
// Col 3:
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp windfall, absorb(year) cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
estadd local yfe "\checkmark"
	
// Col 4: + war
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp windfall war_bn, absorb(year) cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
estadd local yfe "\checkmark"
	
// Col 5: + war x gdp
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp windfall war_bn war_gdp, absorb(year) cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
estadd local yfe "\checkmark"
	
// Col 6: + war x gdp
bootstrap_wrapper, ///
	secondstage(milex1 ALLY_dmilex_exog RIVAL_dmilex_exog windfall war_bn war_gdp c.ldgdp#i.cid c.ldgdp_avg#i.cid, absorb(year) cluster(iso)) ///
	eststo(1)
estadd local controls "\checkmark"
estadd local yfe "\checkmark"
estadd local csslopes "\checkmark"
	
	
gen ALLY_dmilex_exog = .
gen RIVAL_dmilex_exog = .
gen ALLY_dmilex_raw = .
gen RIVAL_dmilex_raw = .

label var ALLY_dmilex_raw "\(\Delta TMA\)"
label var RIVAL_dmilex_raw "\(\Delta TMR\)"
label var ALLY_dmilex_exog "\(\Delta \widehat{TMA}\)"
label var RIVAL_dmilex_exog "\(\Delta \widehat{TMR}\)"
label var ldgdp "\(\Delta GDP\)"
label var ldgdp_avg "\(\Delta GDP^{avg}\)"
label var war_bn "\(War\) (USD bn)"
label var war_gdp "\(War \times GDP \)"
	
	
esttab using "${DIR_DATA_EXPORTS}/shortrun/iv/secondstage.tex", ///
	keep(ALLY_dmilex_raw RIVAL_dmilex_raw ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp ldgdp_avg war_bn war_gdp) ///
	order(ALLY_dmilex_raw RIVAL_dmilex_raw ALLY_dmilex_exog RIVAL_dmilex_exog ldgdp ldgdp_avg war_bn war_gdp) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	tex fragment nonumbers nomtitle posthead("")  se label  ///
	stats(controls yfe csslopes r2 N, fmt(1 1 1 2 "%9.0fc") ///
	label("Controls" "Year FE" "Country-specific \(\lambda\)" "\(R^2\)" "\$N\$")) ///
	replace
