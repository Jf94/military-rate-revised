** Network graph
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year == 2023 & F_rival == 1
netplot iso1 iso2, type(circle) label


use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year == 2023 & F_rival == 1


nwfromedge iso1 iso2, name(G) undirected
nwplot G, layout(circle) lab labelopt(mlabsize(vsmall) msize(0.1) mlabposition(0)) xlab(,nogrid) xsize(16) ysize(9) edgefactor(0.45) edgecolorpalette(purple)
graph export "${DIR_DATA_EXPORTS}/descriptives/network_rivals.pdf", as(pdf) replace
graph close




use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year == 2023 & F_ally == 1
netplot iso1 iso2, type(circle) label



xx
** Woprld Map
// Create directory for automatic deployment
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
collapse (sum) F_*, by(iso1)
rename iso ISO_A3_EH

tempfile network
save `network', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `network', keep(master matched)


drop if REGION_WB == "Antarctica"


geoplot ///
	(area countries F_ally, color(gs14 navy) levels(9)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Least allies" 9 "Most allies") rows(1) position(6) size(large))
graph export "${DIR_DATA_EXPORTS}/descriptives/worldmap_allies.pdf", as(pdf) replace
graph close

	

replace F_rival = log(1 + F_rival / 100)
geoplot ///
	(area countries F_rival, color(gs14 purple) levels(9)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Least rivals" 9 "Most rivals") rows(1) position(6) size(large))
graph export "${DIR_DATA_EXPORTS}/descriptives/worldmap_rivals.pdf", as(pdf) replace
graph close	



* Corrrelation allies rivals
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
collapse (sum) F_*, by(iso1)
pwcorr F_ally F_rival

* Most allies in sample
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
collapse (sum) F_*, by(iso1)





* Number of allies in sample
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year >= 1870
keep if F_ally == 1
keep if year == 2023


* Number of rivals in sample
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year >= 1870
keep if F_rival == 1





use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if year == 2023
collapse (sum) F_*, by(iso1)
* World Map 1
gsort -F_ally

* World Map 2
gsort -F_rival



use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

collapse (sum) F_*, by(iso1)

* World Map 1
gsort -F_ally


* World Map 2
gsort -F_rival


use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
keep if iso1 == "IRN"
keep if year == 2020
keep if F_rival == 1


use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

keep if iso1 == "DEU" & year == 2018
