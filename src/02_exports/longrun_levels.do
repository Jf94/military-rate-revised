use "${DIR_DATA_RAW}/cow/Dyadic-MIDs-4.02/dyadic_mid_4.02.dta", clear
rcallcountrycode statea, from(cown) to(iso3c) gen(iso)
collapse (max) hihost, by(iso year)
tempfile mids
save `mids', replace


import delimited "${DIR_DATA_RAW}/ourworldindata/military-spending-as-a-share-of-gdp-gmsd/military-spending-as-a-share-of-gdp-gmsd.csv", clear
rename code iso
gen milex_gdp = militaryexpenditureofgdp / 100
keep iso year milex_gdp 


duplicates tag iso year, gen(dup)
drop if dup > 0

tempfile milex
save `milex', replace

use "${DIR_DATA_PROCESSED}/milex_longrun.dta", clear
rcallcountrycode ccode, from(cown) to(iso3c) gen(iso)
drop if iso == ""
merge 1:1 iso year using `milex', nogen keep(master matched)

gen gdp = milex / milex_gdp
gen milex_pop = milex / (tpop * 1000)

tempfile panel
save `panel', replace



use "${DIR_DATA_RAW}/atop/atop-sscore.dta", clear

// Fill alliances 2019 - 2024
gen ndups = 0
replace ndups = 7 if year == 2018
gen id = _n
expand ndups
bysort id: replace year = year + _n - 1


local var s_un_atop

sum `var'
gen ally = (`var' - r(min)) / (r(max) - r(min))
gen rival = (1 - ally)

rcallcountrycode ccode1, from(cown) to(iso3c) gen(iso1)
rcallcountrycode ccode2, from(cown) to(iso3c) gen(iso2)

drop if iso1 == "" | iso2 == ""
drop if iso1 == iso2

rename iso2 iso 
merge m:1 iso year using `panel', nogen keep(master matched)


egen cid = group(iso1 iso)
xtset cid year

foreach var in milex milex_gdp milex_pop {
	gen ALLY_`var' = l.ally * `var'
	gen RIVAL_`var' = l.rival * `var'
}

drop iso
rename iso1 iso

collapse (sum) ALLY_* RIVAL_*, by(iso year)

replace ALLY_milex = . if ALLY_milex == 0
replace RIVAL_milex = . if RIVAL_milex == 0

replace ALLY_milex_gdp = . if ALLY_milex_gdp == 0
replace RIVAL_milex_gdp = . if RIVAL_milex_gdp == 0

replace ALLY_milex_pop = . if ALLY_milex_pop == 0
replace RIVAL_milex_pop = . if RIVAL_milex_pop == 0


merge m:1 iso year using `panel', nogen keep(master matched)
merge m:1 iso year using `mids', nogen keep(master matched)
replace hihost = 0 if hihost == .
merge m:1 iso year using "${DIR_DATA_PROCESSED}/gprc.dta", nogen keep(master matched)

egen cid = group(iso)
xtset cid year

gen byte war_large = hihost == 5
gen byte war_small = hihost == 4

xtscc milex l.ALLY_milex l.RIVAL_milex l.gprc l.c.gprc#l.c.gdp l.gdp war_small war_small#c.l.gdp war_large war_large#c.l.gdp, fe

gen gprc_gdp = gprc * gdp
gen war_small_gdp = war_small * gdp
gen war_large_gdp = war_large * gdp

label var ALLY_milex "Allies' spending"
label var RIVAL_milex "Rivals' spending"
label var gdp "GDP"
label var gprc "GPRC"
label var gprc_gdp "GPRC \(\times\) L.GDP"
label var war_small "Small war"
label var war_large "Large war"
label var war_small_gdp "Small war \(\times\) L.GDP"
label var war_large_gdp "Large war \(\times\) L.GDP"


local n_specs 6
local spec_1_xvars l.ALLY_milex l.RIVAL_milex
local spec_2_xvars l.ALLY_milex l.RIVAL_milex l.gdp l.gprc
local spec_3_xvars l.ALLY_milex l.RIVAL_milex l.gdp l.gprc l.gprc_gdp
local spec_4_xvars l.ALLY_milex l.RIVAL_milex l.gdp l.gprc l.gprc_gdp war_small war_large
local spec_5_xvars l.ALLY_milex l.RIVAL_milex l.gdp l.gprc l.gprc_gdp war_small war_large c.war_small#c.l.gdp c.war_large#c.l.gdp
local spec_6_xvars l.ALLY_milex l.RIVAL_milex l.gdp l.gprc l.gprc_gdp war_small war_large c.war_small#c.l.gdp c.war_large#c.l.gdp

local spec_5_cfe 1
local spec_6_cfe 1
local spec_6_yfe 1


forvalues n_spec = 1/`n_specs' {
	local x_vars `spec_`n_spec'_xvars'
	local fe_xtscc
	local fe_reghdfe noabsorb
	
	if "`spec_`n_spec'_yfe'" == "1" {
		local x_vars `x_vars' i.year
	}	
	if "`spec_`n_spec'_cfe'" == "1" {
		local fe_reghdfe absorb(iso)
		local fe_xtscc fe
	}
	reghdfe milex `x_vars', `fe_reghdfe'
	local r2: display %9.3fc e(r2)
	local r2_within: display %9.3fc e(r2_within)
	
	eststo: xtscc milex `x_vars', `fe_xtscc'
	estadd local r2_overall `r2'
	estadd local r2_within `r2_within'
	
	if "`spec_`n_spec'_yfe'" == "1" {
		estadd local hasyfe "\checkmark"
	}
	if "`spec_`n_spec'_cfe'" == "1" {
		estadd local hascfe "\checkmark"
	}
}

esttab using "${DIR_DATA_EXPORTS}/longrun_levels.tex", drop(*.year) star(* 0.1 ** 0.05  *** 0.01) stats(hascfe hasyfe r2_overall r2_within F N, fmt(1 1 1 1 1 "%9.0fc") label("Country fixed effects" "Year fixed effects" "\(R^2\)" "Within-\(R^2\)" "F-Statistic" "\$N\$")) fragment tex nonumber nomtitle posthead("") se replace label

eststo clear
