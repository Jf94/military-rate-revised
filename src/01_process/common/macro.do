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

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/windfalls.dta", nogen keep(master matched)

save "${DIR_DATA_PROCESSED}/common/macro.dta", replace
