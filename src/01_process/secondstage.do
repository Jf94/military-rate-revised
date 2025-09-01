capture program drop build_panel_secondstage
program define build_panel_secondstage
	syntax, ///
		[custom_alliances(string)] ///

	tempfile firststage
	save `firststage'
	
	// Prepare windfalls
	if "`custom_alliances'" == "" {
		use "${DIR_DATA_PROCESSED}/alliances.dta", clear
	}
	else {
		use `custom_alliances', clear
	}
	keep year iso iso_ally
	rename iso iso_protected
	rename iso_ally iso

	* bring in ALLIES' actual & predicted changes
	joinby iso year using `firststage'

	rename iso iso_ally
	rename iso_protected iso

	drop if windfall == . | milex0 == .
	gen n_allies = 1
	

	* sum across all allies j of i in year t
	collapse (sum) TMA = milex0 (sum) ALLY_windfall = windfall ALLY_pred_change=milex_chg_pred n_allies, by(iso year)
	tempfile tmas
	save `tmas'
	
	
	// Bring in rivals
	use "${DIR_DATA_PROCESSED}/rivalries.dta", clear
	rename isoa iso_rivaled
	rename isob iso

	// Sum over spending of rivals
	joinby iso year using `firststage'

	rename iso iso_rival
	rename iso_rivaled iso

	drop if windfall == . | milex0 == .
	gen n_allies = 1

	collapse (sum) TRA = milex0 (sum) TRA_windfall = windfall RIVAL_pred_change=milex_chg_pred n_allies, by(iso year)
	tempfile tras
	save `tras'


	* Final dataset
	use `firststage', clear
	merge m:1 iso year using `tmas', nogen keep(master matched)
	merge m:1 iso year using `tras', nogen keep(master matched)

	replace n_allies = 0 if n_allies == .
	gsort year -n_allies
	bysort year: gen n_allies_rank = _n

	egen cid = group(iso)

	merge m:1 year using "${DIR_DATA_PROCESSED}/gprc_global.dta", nogen keep(master matched)
end
