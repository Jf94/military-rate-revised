* Preprocess US CPI time series used to convert current USD to constant USD
import delimited "${DIR_DATA_RAW}/worldbank/API_MS.MIL.XPND.CD_DS2_en_csv_v2_29592/API_MS.MIL.XPND.CD_DS2_en_csv_v2_29592.csv", clear rowrange(5:) varnames(5)

foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso

drop y
keep iso y*

reshape long y, i(iso) j(year)
rename y milex_cur

merge m:1 year using "${DIR_DATA_PROCESSED}/deflator.dta", nogen keep(master matched)
gen milex = milex_cur * factor_cur_to_2011const

drop milex_cur

save "${DIR_DATA_PROCESSED}/milex.dta", replace
