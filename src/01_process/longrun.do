// MIDs
use "${DIR_DATA_RAW}/cow/Dyadic-MIDs-4.02/dyadic_mid_4.02.dta", clear
collapse (max) hihost, by(statea year)
rename statea ccode
tempfile mids
save `mids', replace

// 
import delimited "${DIR_DATA_RAW}/gleditsch/mindist.csv", clear
rcallcountrycode gwcode1, gen(ccode1) from(gwn) to(cown)
rcallcountrycode gwcode2, gen(ccode2) from(gwn) to(cown)

rename ccode1 ccode
merge m:1 ccode year using `mids', nogen keep(master matched)
drop ccode
rename ccode2 ccode


replace mindist = 1000 if mindist > 1000
sum mindist
gen proximity = 1 - (mindist - r(min)) / (r(max) - r(min))

gen byte war_ind = hihost >= 3 & hihost != .
gen war_nearby = proximity * war_ind

collapse (sum) war_nearby, by(ccode year)
tempfile war_geo
save `war_geo', replace



// Compute TMR
use "${DIR_DATA_PROCESSED}/rivalries_ccode.dta", replace

rename ccode2 ccode
merge m:1 ccode year using "${DIR_DATA_PROCESSED}/milex_longrun.dta", nogen keep(master matched)
collapse (sum) milex cinc, by(ccode1 year)
rename milex TMR
rename cinc TMR_cinc
rename ccode1 ccode

tempfile TMR
save `TMR', replace


// Compute TMA
use "${DIR_DATA_PROCESSED}/alliances.dta", clear
rename stateA ccode_ally
rename stateB ccode

merge m:1 ccode year using "${DIR_DATA_PROCESSED}/milex_longrun.dta", nogen keep(master matched)

collapse (sum) milex cinc, by(ccode_ally year)
rename ccode_ally ccode
rename milex TMA
rename cinc TMA_cinc

tempfile TMA
save `TMA', replace


use "${DIR_DATA_PROCESSED}/milex_longrun.dta", clear
keep ccode year milex tpop

merge 1:1 ccode year using `TMA', nogen keep(master matched)
merge 1:1 ccode year using `TMR', nogen keep(master matched)

replace TMA = 0 if TMA == .
replace TMR = 0 if TMR == .
replace TMR_cinc = 0 if TMR_cinc == .
replace TMA_cinc = 0 if TMA_cinc == .

bysort ccode: egen TMA_max = max(TMA)
bysort ccode: egen TMR_max = max(TMR)
drop if TMA_max == 0 | TMR_max == 0

rcallcountrycode ccode, from(cown) to(iso3c) gen(iso)
drop if iso == ""

// Merge prepared stuff
merge 1:1 iso year using "${DIR_DATA_PROCESSED}/gprc.dta", nogen keep(master matched)

merge 1:1 ccode year using `mids', nogen keep(master matched)
replace hihost = 0 if hihost == . & year <= 2014

merge 1:1 ccode year using `war_geo', nogen keep(master matched)
replace war_nearby = 0 if war_nearby == .


reghdfe milex TMA TMR, absorb(ccode year)


gen lmilex = log(1 + milex)
gen lTMA = log(1 + TMA)
gen lTMR = log(1 + TMR)
gen ltpop = log(1 + tpop)

xtset ccode year

reghdfe milex TMA TMR gprc, absorb(ccode year) cluster(iso year)


bysort iso: egen gprc_min = min(gprc)
bysort iso: egen gprc_max = max(gprc)
gen F = (gprc - gprc_min) / (gprc_max - gprc_min)
gen F_inv = 1 - F

xtset ccode year
reghdfe lmilex l.lTMA l.lTMR ltpop gprc, absorb(ccode year) cluster(iso year)

reghdfe lmilex l.lTMA  l.lTMR, absorb(ccode year) cluster(iso year)
reghdfe lmilex l.TMA_cinc  l.TMR_cinc, absorb(ccode year) cluster(iso year)


eststo: reghdfe lmilex l.lTMR, noabsorb cluster(ccode year)
eststo: reghdfe lmilex l.lTMR l.lTMA, noabsorb cluster(ccode year)
eststo: reghdfe lmilex l.lTMR l.lTMA ltpop, noabsorb cluster(ccode year)
eststo: reghdfe lmilex l.lTMR l.lTMA ltpop gprc, noabsorb cluster(ccode year)
eststo: reghdfe lmilex l.lTMR l.lTMA ltpop gprc, absorb(ccode) cluster(ccode year)
eststo: reghdfe lmilex l.lTMR l.lTMA l.i.hihost, absorb(ccode year) cluster(ccode year)
eststo clear


cap drop FE1 FE2 
cap drop lmilex_lin lmilex_hat
reghdfe lmilex l.lTMR l.lTMA l.i.hihost, absorb(FE1=ccode FE2=year) cluster(ccode year) nocons
predict lmilex_lin, xb
gen lmilex_hat = lmilex_lin + FE1 + FE2
drop lmilex_lin

twoway (line lmilex year if iso == "USA") (line lmilex_hat  year if iso == "USA")
twoway (line lmilex year if iso == "FRA") (line lmilex_hat  year if iso == "FRA")


// Detrend Milex
foreach var in lmilex lmilex_hat {
	cap drop `var'_dtrd
	cap drop t
	gen `var'_dtrd = .
	levelsof ccode, local(ccodes)

	gen t = year - 1870

	foreach ccode in `ccodes' {
		reg `var' t if ccode == `ccode'
		predict tmp, resid
		replace `var'_dtrd = tmp if ccode == `ccode'
		drop tmp
	}
}
twoway (line lmilex_dtrd year if iso == "USA") (line lmilex_hat_dtrd  year if iso == "USA")
twoway (line lmilex_dtrd year if iso == "DEU") (line lmilex_hat_dtrd  year if iso == "DEU")

// Smooth series
foreach var in lmilex_dtrd lmilex_hat_dtrd {
	gen `var'_smt = (`var' + l.`var' + l2.`var' + l3.`var' + l4.`var') / 5
}


twoway (line lmilex_dtrd_smt year if iso == "USA") (line lmilex_hat_dtrd_smt  year if iso == "USA")
twoway (line lmilex_dtrd_smt year if iso == "FRA") (line lmilex_hat_dtrd_smt  year if iso == "FRA")
twoway (line lmilex_dtrd_smt year if iso == "GBR") (line lmilex_hat_dtrd_smt  year if iso == "GBR")

reghdfe lmilex l.lTMR l.lTMA l.i.hihost, absorb(ccode year) cluster(ccode year)


ppmlhdfe lmilex l.lTMR l.lTMA l.i.hihost, absorb(ccode year) cluster(ccode year)



ppmlhdfe milex l.lTMR l.lTMA l.i.hihost, absorb(ccode year) cluster(ccode year)
predict milex_hat, xb


reghdfe lmilex l.lTMA l.lTMR war_nearby l.5.hihost ltpop, noabsorb
reghdfe lmilex l.lTMA l.lTMR war_nearby l.5.hihost ltpop, absorb(ccode)
reghdfe lmilex l.lTMA l.lTMR war_nearby l.5.hihost ltpop, absorb(ccode year)

gen byte war_big = hihost == 5
gen byte war_small = hihost >= 3 & hihost < 5


local specs 7

local spec1_xvars l.lTMA l.lTMR
local spec2_xvars l.lTMA l.lTMR l.war_nearby
local spec3_xvars l.lTMA l.lTMR l.war_nearby l.war_big l.war_small
local spec4_xvars l.lTMA l.lTMR l.war_nearby l.war_big l.war_small ltpop
local spec5_xvars l.lTMA l.lTMR l.war_nearby l.war_big l.war_small ltpop gprc
local spec6_xvars l.lTMA l.lTMR l.war_nearby l.war_big l.war_small ltpop
local spec7_xvars l.lTMA l.lTMR l.war_nearby l.war_big l.war_small ltpop

local spec6_cfe 1
local spec7_cfe 1
local spec7_yfe 1


forvalues spec=1/`specs' {
	local xvars `spec`spec'_xvars'
	
	local reghdfe_absorb
	if "`spec`spec'_cfe'" == "1" {
		local reghdfe_absorb `reghdfe_absorb' ccode
	}
	if "`spec`spec'_yfe'" == "1" {
		local reghdfe_absorb `reghdfe_absorb' year
	}
	if "`reghdfe_absorb'" == "" {
		local reghdfe_absorb noabsorb
	}
	else {
		local reghdfe_absorb absorb(`reghdfe_absorb')
	}
	reghdfe lmilex `xvars', `reghdfe_absorb'
	local r2: display %9.3fc e(r2)
	local r2_within: display %9.3fc e(r2_within)
	
	local xtscc_cfe
	local xtscc_yfe
	if "`spec`spec'_cfe'" == "1" {
		local xtscc_cfe fe
	}
	if "`spec`spec'_yfe'" == "1" {
		local xtscc_yfe i.year
	}
	
	eststo: xtscc lmilex `xvars' `xtscc_yfe', `xtscc_cfe'
	estadd local r2_overall `r2'
	estadd local r2_within `r2_within'
	
	if "`spec`spec'_cfe'" == "1" {
		estadd local hascfe "\checkmark"
	}	
	if "`spec`spec'_yfe'" == "1" {
		estadd local hasyfe "\checkmark"
	}
}

esttab using "${DIR_DATA_EXPORTS}/longrun.tex", keep(L.lTMA L.lTMR *war_nearby *war_big *war_small *ltpop gprc _cons) star(* 0.1 ** 0.05  *** 0.01) stats(hascfe hasyfe r2_overall r2_within F N, fmt(1 1 1 1 1 "%9.0fc") label("Country fixed effects" "Year fixed effects" "\(R^2\)" "Within-\(R^2\)" "F-Statistic" "\$N\$")) fragment tex nonumber nomtitle posthead("") se replace
eststo clear


cap drop lmilex_*
cap drop FE*
reghdfe lmilex l.lTMA l.lTMR l.war_nearby l.war_big l.war_small ltpop, absorb(FE1=ccode FE2=year)
predict lmilex_hat, xb
replace lmilex_hat = lmilex_hat + FE1 + FE2

twoway ///
	(line lmilex year if iso == "POL") ///
	(line lmilex_hat year if iso == "POL")
