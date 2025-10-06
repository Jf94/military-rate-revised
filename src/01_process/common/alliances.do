use "${DIR_DATA_RAW}/atop/atop5_1ddyr.dta", clear
*keep if defense == 1

// Fixed exogenous 1976 alliances
/*keep if year == 1976
gen ndup = 2024 - 1976 + 1
gen id = _n
expand ndup
bysort id: replace year = year + _n - 1*/

// Fill alliances 2019 - 2024
gen ndups = 0
replace ndups = 7 if year == 2018
gen id = _n
expand ndups
bysort id: replace year = year + _n - 1

// Alliance in t are pre-determined in t-1
*replace year = year + 1


save "${DIR_DATA_PROCESSED}/alliances_ccode.dta", replace

rcallcountrycode stateA, from(cown) to(iso3c) gen(iso_ally)
rcallcountrycode stateB, from(cown) to(iso3c) gen(iso)
replace iso = "DEU" if stateA == 260
replace iso_ally = "DEU" if stateB == 260
drop if iso == iso_ally
drop if iso == ""
drop if iso_ally == ""

*keep if year >= 1975

save "${DIR_DATA_PROCESSED}/common/alliances.dta", replace
