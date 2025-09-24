* World Bank data in constant 2015USD
import delimited "${DIR_DATA_RAW}/worldbank/API_SP.POP.TOTL_DS2_en_csv_v2_569241/API_SP.POP.TOTL_DS2_en_csv_v2_569241.csv", clear varnames(4)


foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso
drop y
keep iso y*

reshape long y, i(iso) j(year)
rename y pop

save "${DIR_DATA_PROCESSED}/pop.dta", replace
