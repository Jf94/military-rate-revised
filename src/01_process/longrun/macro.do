// From PoW
use "${DIR_DATA_PROCESSED}/common/gdp.dta", clear

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/common/milex.dta", nogen keep(master matched)


// Until 2016 use these sources (milex does not run longe)
keep if year <= 2016 

// Append new data 2016+
preserve

keep iso
duplicates drop
gen year = 2017
gen dups = 7
expand dups
bysort iso: gen year_cur = year + _n - 1
drop year
rename year_cur year

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/gdp.dta", nogen keep(master matched)

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/milex.dta", nogen keep(master matched)

keep iso year milex gdp

tempfile recent
save `recent'
restore
append using `recent'

sort iso year

gen milex_gdp = milex / gdp

tempfile panel
save `panel', replace


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
merge m:1 iso year using `panel', nogen keep(master matched)

egen cid = group(iso1 iso)
xtset cid year

foreach var in milex {
	gen ALLY_`var' = l.F_ally * `var'
	gen RIVAL_`var' = l.F_rival * `var'
	
	* Need to balance
	drop if `var' == .
	drop if l.F_ally == .
}

drop iso
rename iso1 iso

collapse (sum) ALLY_* RIVAL_*, by(iso year)

foreach var of varlist ALLY_* RIVAL_* {
	replace `var' = . if `var' == 0
}
tempfile TMATRA
save `TMATRA'

use `panel', clear
merge 1:1 iso year using `TMATRA', nogen keep(master matched)


merge 1:1 iso year using "${DIR_DATA_PROCESSED}/common/conflicts.dta", nogen keep(master matched)
replace war = 0 if war == .

replace ALLY_milex = 0 if ALLY_milex == .
replace RIVAL_milex = 0 if RIVAL_milex == .

bysort iso: egen maxALLY = max(ALLY_milex)
bysort iso: egen maxRIVAL = max(RIVAL_milex)


save "${DIR_DATA_PROCESSED}/longrun/macro.dta", replace
