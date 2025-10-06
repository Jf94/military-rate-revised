import excel "${DIR_DATA_RAW}/caldara/data_gpr_export.xls", clear firstrow

rename GPRH GPRHC_global

keep month GPRHC_*
gen year = year(month)

collapse (mean) GPRHC_*, by(year)

reshape long GPRHC_, i(year) j(iso) string

rename GPRHC_ gprc

tempfile orig
save `orig', replace

keep if iso == "global"
drop iso
rename gprc gprc_global

merge 1:m year using `orig', nogen
order iso year gprc gprc_global

drop if iso == "global"

// Z-Score deviation of country average
gen _mean = .
gen _sd = .
levelsof iso, local(isos)

foreach iso in `isos' {
	sum gprc if iso == "`iso'", d
	replace _mean = r(p50) if iso == "`iso'"
	replace _sd = r(sd) if iso == "`iso'"
	
}
replace gprc = (gprc - _mean) / _sd
drop _mean _sd

*reghdfe gprc, absorb(iso) resid
*drop gprc
*predict gprc, resid

save "${DIR_DATA_PROCESSED}/common/gprc.dta", replace

import excel "${DIR_DATA_RAW}/caldara/data_gpr_export.xls", clear firstrow
gen year = year(month)

collapse (mean) SHAREH_* GPRH GPRHT GPRHA, by(year)

save "${DIR_DATA_PROCESSED}/common/gprc_global.dta", replace
