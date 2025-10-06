* World Bank data in constant 2015USD
import delimited "${DIR_DATA_RAW}/worldbank/API_NY.GDP.MKTP.KD_DS2_en_csv_v2_448269/API_NY.GDP.MKTP.KD_DS2_en_csv_v2_448269.csv", clear varnames(4)


foreach var of varlist v*{
    rename `var' y`:var lab `var''
}

rename countrycode iso
drop y
keep iso y*

reshape long y, i(iso) j(year)
rename y gdp

save "${DIR_DATA_PROCESSED}/shortrun/gdp.dta", replace
