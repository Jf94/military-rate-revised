use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

xtset cid year

gen milex_gdp_diff2y = f2.milex_gdp - milex_gdp
keep if year == 2021

rename iso ISO_A3_EH

tempfile spending
save `spending', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `spending', keep(master matched)


drop if REGION_WB == "Antarctica"

winsor2 milex_gdp_diff2y, cuts(1 99) replace


geoplot ///
	(area countries milex_gdp_diff2y, color(gs14 purple) levels(20)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	
graph export "${DIR_DATA_EXPORTS}/descriptives/ukraine.pdf", as(pdf) replace
graph close	


// 2013 - 2023
use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

xtset cid year

gen milex_gdp_diff10y = f10.milex_gdp - milex_gdp
keep if year == 2013

xtset cid year

gen milex_gdp_diff2y = f2.milex_gdp - milex_gdp
keep if year == 2021

rename iso ISO_A3_EH

tempfile spending
save `spending', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `spending', keep(master matched)


drop if REGION_WB == "Antarctica"

winsor2 milex_gdp_diff2y, cuts(1 99) replace


geoplot ///
	(area countries milex_gdp_diff2y, color(gs14 purple) levels(20)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	
graph export "${DIR_DATA_EXPORTS}/descriptives/ukraine_.pdf", as(pdf) replace
graph close	
