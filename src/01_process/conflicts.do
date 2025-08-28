use "${DIR_DATA_RAW}/ucdp/UcdpPrioConflict_v25_1.dta", clear

sort start_date

destring year intensity_level, replace
keep if year >= 1946
keep year gwno_a gwno_b intensity_level

* Establish country-year-intensity sample
expand 2
replace gwno_a = gwno_b if _n > _N / 2
drop gwno_b
rename gwno_a gwno
collapse (max) intensity_level, by(gwno year)
destring gwno, replace

// Account for multiple gwnos
gen n = length(gwno) - length(subinstr(gwno, ",", "", .)) + 1
expand n

bysort year gwno: gen id = _n

local N = _N
split gwno, p(",")
forvalues n = 1/`N' {
	local gwnonum = id[`n']
	replace gwno = gwno`gwnonum' if _n == `n'
}
destring gwno, replace
drop gwno1 gwno2 gwno3 gwno4 gwno5

gen byte conflict_low = intensity_level == 1
gen byte conflict_high = intensity_level == 2

rcallcountrycode gwno, from(gwn) to(iso3c) gen(iso)

collapse (max) conflict_*, by(iso year)

save "${DIR_DATA_PROCESSED}/conflicts.dta", replace
