// From PoW
use "${DIR_DATA_PROCESSED}/shortrun/gdp.dta", clear

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/milex.dta", nogen keep(master matched)
sort iso year

keep iso year gdp milex
gen milex_gdp = milex / gdp


merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/windfalls.dta", nogen keep(master matched)


merge 1:1 iso year using "${DIR_DATA_PROCESSED}/common/gprc.dta", nogen keep(master matched)

bysort year: egen gdp_avg = mean(gdp)

// Prepare sample
egen cid = group(iso)
xtset cid year

gen ldgdp = l.d.gdp
gen ldgdp_avg = l.d.gdp_avg
gen milex1 = f1.milex - l.milex
gen dmilex = d.milex
gen l1dmilex = l1.d.milex
gen l2dmilex = l2.d.milex


gen windfall_gdp = windfall / l.gdp
gen milex1_gdp = (f.milex - l.milex) / l.gdp
gen l1gdp = l.gdp

winsor2 windfall, cuts(5 95) replace
winsor2 windfall_01, cuts(5 95) replace
winsor2 windfall_05, cuts(5 95) replace
winsor2 windfall_10, cuts(5 95) replace
winsor2 milex1, cuts(5 95) replace


merge 1:1 iso year using "${DIR_DATA_PROCESSED}/common/conflicts.dta", nogen keep(master matched)
replace war = 0 if war == .
gen war_bn = war * 1e9
gen war_gdp = war * gdp


save "${DIR_DATA_PROCESSED}/shortrun/macro.dta", replace
