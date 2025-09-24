use "${DIR_DATA_RAW}/federle/4digit/trade.dta", clear
merge m:1 cmdcode year using "${DIR_DATA_RAW}/federle/4digit/prices.dta", nogen keep(master matched)


*gen cmdcode_1 = substr(cmdcode, 1, 1)
*keep if cmdcode_1 == "3"
gen ret = price / l1price - 1

egen gid = group(iso cmdcode)
xtset gid year

cap drop global_market_share
cap drop export_value_world
bysort year cmdcode: egen export_value_world = total(export_value)
gen global_market_share = (export_value - import_value) / export_value_world


*winsor2 ret, cuts(0.1 99.9) replace
cap drop gid
egen gid = group(iso cmdcode)
xtset gid year
gen windfall = (l.export_value - l.import_value) * ret
gen windfall_10 = windfall if l.global_market_share < 0.10 & l.global_market_share > -0.10
gen windfall_05 = windfall if l.global_market_share < 0.05 & l.global_market_share > -0.05
gen windfall_01 = windfall if l.global_market_share < 0.01 & l.global_market_share > -0.01
drop gid


save "${DIR_DATA_PROCESSED}/windfalls_disaggregated.dta", replace

collapse (sum) windfall windfall_* (count) n=windfall, by(iso year)
replace windfall = . if n == 0
replace windfall_10 = . if n == 0
replace windfall_05 = . if n == 0
replace windfall_01 = . if n == 0
drop n

save "${DIR_DATA_PROCESSED}/windfalls.dta", replace
