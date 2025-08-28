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

* World Bank 24-08-29
* CPI (2015): 108.7
* CPI (2011): 103.2
* Deflate to GDP in 2011USD
replace gdp = gdp * (103.2 / 108.7)

save "${DIR_DATA_PROCESSED}/gdp.dta", replace
