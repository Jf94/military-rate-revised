capture program drop build_panel_firststage
program define build_panel_firststage
	

	egen cid = group(iso)
	xtset cid year

	forvalues h=0/16 {
		gen milex`h' = f`h'.milex - l.milex
		gen milex_gdp`h' = (f`h'.milex - l.milex) / l.gdp
		
		*winsor2 milex_gdp`h', cuts(5 95) replace
	}


	gen windfall_gdp = windfall / l.gdp
	*winsor2 windfall_gdp, cuts(5 95) replace
	
	
	winsor2 milex_gdp0, cuts(1 99)

	reghdfe milex_gdp0_w windfall_gdp, absorb(iso year) cluster(year) nocons

	predict milex_gdp_pred
	gen milex_exog = milex_gdp_pred * gdp
	drop milex_gdp_pred



end
