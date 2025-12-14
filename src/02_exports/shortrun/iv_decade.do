
cap program drop run_firststage 
program define run_firststage, rclass
	winsor2 windfall_gdp, cuts(1 99) replace
	winsor2 dmilex_gdp, cuts(1 99) replace
	reghdfe dmilex_gdp windfall_gdp, vce(robust) noabsorb
	gen dmilex_exog = windfall_gdp * _b[windfall_gdp] * l1gdp
	
	keep iso decade dmilex_exog
end

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
	tostring year, gen(year_str)
	gen decade = substr(year_str, 1, 3)
	destring decade, replace
	
	sort iso1 iso2 year
	collapse (lastnm) F_*, by(iso* decade)
	
	
	* Generate lagged alliance / rival structure
	egen gid = group(iso1 iso2)
	xtset gid decade
	gen lF_ally = l.F_ally
	gen lF_rival = l.F_rival
	xtset, clear

	* Join windfalls and compute aggregate windfalls of allies/rivals
	rename iso2 iso 
	joinby iso decade using `windfalls'
	gen ALLY_dmilex_exog = dmilex_exog * lF_ally
	gen RIVAL_dmilex_exog = dmilex_exog * lF_rival
	collapse (sum) ALLY_dmilex_exog RIVAL_dmilex_exog, by(iso1 decade)
	rename iso1 iso
	
	* Tempoerarily save windfalls of allies/rivals
	tempfile TMATRA
	save `TMATRA'
	
	** Prepare second-stage panel
	use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear
	
	tostring year, gen(year_str)
	gen decade = substr(year_str, 1, 3)
	destring decade, replace
	
	
	drop if windfall == .
	
	collapse (sum) milex windfall windfall_* (lastnm) gdp, by(iso decade)
	
	
	
	merge 1:1 iso decade using `TMATRA', nogen keep(master matched)
	
	* Make sure to not include years thrown out in first stage bootstrap
	bysort decade: egen maxALLY = max(ALLY_dmilex_exog)
	bysort decade: egen maxRIVAL = max(RIVAL_dmilex_exog)
	drop if maxALLY == 0 & maxRIVAL == 0
	
	egen cid = group(iso)
	
	

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

use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear
tostring year, gen(year_str)
gen decade = substr(year_str, 1, 3)
destring decade, replace

drop if windfall == .

collapse (sum) milex windfall windfall_* (lastnm) gdp, by(iso decade)

egen cid = group(iso)
xtset cid decade
drop windfall_gdp

gen l1gdp = l.gdp
gen dmilex_gdp = d.milex / l.gdp
gen windfall_gdp = windfall / l.gdp


run_firststage
qq

cap program drop bootstrap_wrapper 
program define bootstrap_wrapper, rclass
	syntax, ///
		[secondstage(string)] ///
		[eststo(string)]
		
	*preserve
	run_firststage
	run_secondstage, secondstage(`secondstage') eststo(`eststo')
	return add
	*restore
end


bootstrap_wrapper, ///
	secondstage(milex ALLY_dmilex_exog RIVAL_dmilex_exog gdp windfall, noabsorb cluster(iso))
