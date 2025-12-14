import delimited "${DIR_DATA_RAW}/worldbank/API_MS.MIL.XPND.GD.ZS_DS2_en_csv_v2_129790/API_MS.MIL.XPND.GD.ZS_DS2_en_csv_v2_129790.csv", clear varnames(4)


foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso
drop y
keep iso y*


reshape long y, i(iso) j(year)
rename y milex_gdp

egen cid = group(iso)

tempfile milex_gdp
save `milex_gdp'


use `milex_gdp'
xtset cid year

gen milex_gdp_diff2y = f2.milex_gdp - milex_gdp
keep if year == 2021

xtile qtl = milex_gdp_diff2y, nquantiles(25)

rename iso ISO_A3_EH

tempfile spending
save `spending', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `spending', keep(master matched)


drop if REGION_WB == "Antarctica"


geoplot ///
    (area countries milex_gdp_diff2y, ///
        color(gs14 purple) ///
        levels(25) ///
        lcolor(%0) ) /// optional: remove borders in the fill layer
    , tight ///
      clegend( ///
          position(6)        /// same corner you were using with legend(position(6))
          height(30)         /// taller color bar; tweak as you like
          title("Δ military exp. (% GDP, 2021→2023)") ///
      ) ///
      zlabel(-2(1)4, format(%4.1f)) /// tick marks along the bar
      graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) ///
                  margin(0.2 1 2 0.3))


geoplot ///
	(area countries qtl, color(gs14 purple) levels(25)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	


/** World Bank data in constant 2015USD
import delimited "${DIR_DATA_RAW}/worldbank/API_MS.MIL.XPND.GD.ZS_DS2_en_csv_v2_129790/API_MS.MIL.XPND.GD.ZS_DS2_en_csv_v2_129790.csv", clear varnames(4)


foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso
drop y
keep iso y*


reshape long y, i(iso) j(year)
rename y milex_gdp

egen cid = group(iso)

tempfile milex_gdp
save `milex_gdp'


use `milex_gdp'
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

winsor2 milex_gdp_diff2y, cuts(5 95) replace


geoplot ///
	(area countries milex_gdp_diff2y, color(gs14 purple) levels(20)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	
graph export "${DIR_DATA_EXPORTS}/descriptives/milworldmap/2021_2023.pdf", as(pdf) replace
graph close	


// 2011 - 2021
use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

xtset cid year

gen milex_gdp_diff10y = f10.milex_gdp - milex_gdp
keep if year == 2013


rename iso ISO_A3_EH

tempfile spending
save `spending', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `spending', keep(master matched)


drop if REGION_WB == "Antarctica"

winsor2 milex_gdp_diff10y, cuts(5 95) replace


geoplot ///
	(area countries milex_gdp_diff10y, color(gs14 purple) levels(20)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	
graph export "${DIR_DATA_EXPORTS}/descriptives/milworldmap/2011_2021.pdf", as(pdf) replace
graph close	





// 2000 - 2010
use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

xtset cid year

gen milex_gdp_diff10y = f10.milex_gdp - milex_gdp
keep if year == 2000


rename iso ISO_A3_EH

tempfile spending
save `spending', replace

clear
spshape2dta "${DIR_RESSOURCES}/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp", replace saving(countries)
geoframe create countries, replace

frame change countries

merge m:1 ISO_A3_EH using `spending', keep(master matched)


drop if REGION_WB == "Antarctica"

winsor2 milex_gdp_diff10y, cuts(5 95) replace


geoplot ///
	(area countries milex_gdp_diff10y, color(gs14 purple) levels(20)) ///
	, tight graphregion(lstyle(solid) lcolor("gray%90") lwidth(vvvthin) margin(0.2 1 2 0.3)) legend(order(1 "Smallest buildup" 20 "Largest buildup") rows(1) position(6) size(large))
	
graph export "${DIR_DATA_EXPORTS}/descriptives/milworldmap/2000_2010.pdf", as(pdf) replace
graph close	
*/
