import delimited "${DIR_DATA_RAW}/cow/Inter-StateWarData_v4.0.csv", clear

rcallcountrycode ccode, from(cown) to(iso3c) gen(iso)
drop if iso == ""

gen start = startyear1
gen end = endyear1

keep warname iso start end

tempfile inter
save `inter', replace



import delimited "${DIR_DATA_RAW}/cow/Intra-StateWarData_v4.1.csv", clear
replace ccodea = ccodeb if ccodea == -8
rcallcountrycode ccodea, from(cown) to(iso3c) gen(iso)
drop if iso == ""
gen start = startyear1 
gen end = endyear1
keep warname iso start end

append using `inter'

gen id = _n

gen dup = end - start + 1
expand dup

sort warname iso

bysort warname iso: gen year = start + _n - 1

gen war = 1

keep iso year war
duplicates drop
save "${DIR_DATA_PROCESSED}/common/conflicts.dta", replace
