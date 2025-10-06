// From PoW
use "${DIR_DATA_RAW}/federle/macro.dta", clear

keep iso year gdp

save "${DIR_DATA_PROCESSED}/common/gdp.dta", replace
