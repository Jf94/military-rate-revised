capture program drop build_panel_secondstage
program define build_panel_secondstage
	syntax, ///
		[custom_alliances(string)] ///

	tempfile firststage
	save `firststage'
	

	use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
	/*
	// Fill alliances 2019 - 2024
	gen ndups = 0
	replace ndups = 7 if year == 2018
	gen id = _n
	expand ndups
	bysort id: replace year = year + _n - 1
	
	rcallcountrycode ccode1, from(cown) to(iso3c) gen(iso1)
	rcallcountrycode ccode2, from(cown) to(iso3c) gen(iso2)

	drop if iso1 == "" | iso2 == ""
	drop if iso1 == iso2*/
	
	rename iso2 iso
	merge m:1 iso year using `firststage', nogen keep(master matched)
	
	drop cid
	egen cid = group(iso1 iso)
	xtset cid year

	foreach var in milex windfall windfall_05 windfall_10 windfall_01 {
		gen ALLY_`var' = l.F_ally * `var'
		gen RIVAL_`var' = l.F_rival * `var'
		
		* Need to balance
		drop if `var' == .
		drop if l.F_ally == .
	}

	drop iso
	rename iso1 iso
	
	replace ALLY_milex = . if ALLY_windfall == . | ALLY_windfall == 0
	replace ALLY_windfall = . if ALLY_milex == . | ALLY_milex == 0
	
	replace RIVAL_milex = . if RIVAL_windfall == . | RIVAL_windfall == 0
	replace RIVAL_windfall = . if RIVAL_milex == . | RIVAL_milex == 0

	collapse (sum) ALLY_* RIVAL_*, by(iso year)
	
	foreach var of varlist ALLY_* RIVAL_* {
		replace `var' = . if `var' == 0
	}
	
	tempfile TMATRA
	save `TMATRA'
	
	use `firststage', clear
	merge 1:1 iso year using `TMATRA', nogen keep(master matched)
	
	

	replace ALLY_milex = 0 if ALLY_milex == .
	replace RIVAL_milex = 0 if RIVAL_milex == .

	replace ALLY_windfall = 0 if ALLY_windfall == .
	replace RIVAL_windfall = 0 if RIVAL_windfall == .

	*bysort iso: egen maxALLY = max(ALLY_milex)
	*bysort iso: egen maxRIVAL = max(RIVAL_milex)
	
	merge m:1 year using "${DIR_DATA_PROCESSED}/common/gprc_global.dta", nogen keep(master matched)
end
