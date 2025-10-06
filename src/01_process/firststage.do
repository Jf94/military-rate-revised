capture program drop build_panel_firststage
program define build_panel_firststage
	syntax, ///
		[save(real 0)] ///
		[conflict_file(string)] ///
		[dropcmdcodes(string)] ///
		[dropcmdgroup(string)]
	
	*drop windfall
	*gen windfall = windfall_1
	
	drop windfall_gdp
	gen windfall_gdp = windfall_1 / l1gdp
	
	
	
	winsor2 milex_gdp_chg0, cuts(1 99)
	*winsor2 windfall_gdp, cuts(1 99) replace
	
	reghdfe milex_gdp_chg0_w windfall_gdp, absorb(iso year) cluster(iso year) nocons
	
	predict double milex_exog, xb
	replace milex_exog = milex_exog * l1gdp
	
	
	*reghdfe milex1 windfall, absorb(iso year) cluster(iso year) nocons
	*predict double milex_chg_pred, xb
	
	
	drop cid
	
	*winsor2 milex_chg_pred, cuts(1 99) replace
	*keep iso year milex* windfall* gdp conflict* lmilex*
end
