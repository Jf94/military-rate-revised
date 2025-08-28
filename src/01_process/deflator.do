* Preprocess US CPI time series used to convert current USD to constant USD
import delimited "${DIR_DATA_RAW}/worldbank/API_FP.CPI.TOTL_DS2_en_csv_v2_450251/API_FP.CPI.TOTL_DS2_en_csv_v2_450251.csv", clear rowrange(5:) varnames(5)

foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso
keep iso y*
drop y

keep if iso == "USA"

reshape long y, i(iso) j(year)
rename y cpi

egen reference = total(cpi * (year == 2011))
gen factor_cur_to_2011const = reference / cpi

keep year factor_cur_to_2011const
drop if factor_cur_to_2011const == .

save "${DIR_DATA_PROCESSED}/deflator.dta", replace
