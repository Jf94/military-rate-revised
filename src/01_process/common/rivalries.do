import delimited "${DIR_DATA_RAW}/thompson/strategic_rivalry_data_list_of_rivalries_by_type.csv", clear

keep if spatial == 1 | interv == 1

gen rivalry = 1
replace end = 2023 if ongoing2020==1
replace start = 1494 if pre1494 == 1
replace start = 1816 if pre1816 == 1 & pre1494 == 0
drop if end < 1812

replace start = 1812 if start < 1812
gen dups = end - start + 1


gen id = _n
expand dups

bysort id: gen year = start + _n - 1

keep year ccode1 ccode2 rivalry

rcallcountrycode ccode1, from(cown) to(iso3c) gen(isoa)
rcallcountrycode ccode2, from(cown) to(iso3c) gen(isob)

drop if isoa == "" | isob == ""
keep isoa isob year rivalry

expand 2
gen isoa_old = isoa
replace isoa = isob if _n > _N/2
replace isob = isoa_old if _n > _N/2
drop isoa_old
collapse (sum) rivalry, by(year isoa isob)


// Alliance in t are pre-determined in t-1
replace year = year + 1


save "${DIR_DATA_PROCESSED}/common/rivalries.dta", replace
