use "${DIR_DATA_PROCESSED}/gdp.dta", clear

// Merge military expenditures
merge 1:1 iso year using "${DIR_DATA_PROCESSED}/milex.dta", nogen keep(master matched using)

// Merge windfalls
merge 1:1 iso year using "${DIR_DATA_PROCESSED}/windfalls.dta", nogen keep(master matched using)

// Merge conflicts
merge 1:1 iso year using "${DIR_DATA_PROCESSED}/conflicts.dta", nogen keep(master matched using)
replace conflict_low = 0 if conflict_low == .
replace conflict_high = 0 if conflict_high == .


// Drop countries with unrealistic high SD of windfalls
gen windfall_gdp = windfall / gdp
bysort iso: egen sd_windfalls = sd(windfall_gdp)
drop sd_windfalls
drop if iso == "MHL" | iso == "LBR"

egen cid = group(iso)
xtset cid year

keep if year >= 1977

drop if iso == ""

forvalues h=0/20 {
	gen milex`h' = f`h'.milex - l.milex
	gen cmilex`h' = log(f`h'.milex) - log(l.milex)
	gen lmilex`h' = log(f`h'.milex) - log(l.milex)
}

rename iso iso_wb
rcallcountrycode iso_wb, from(wb) to(iso3c) gen(iso)
drop if iso == ""
drop iso_wb

save "${DIR_DATA_PROCESSED}/panel.dta", replace
