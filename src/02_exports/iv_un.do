use "${DIR_DATA_RAW}/atop/atop-sscore.dta", clear

keep if year >= 1977

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
merge m:1 iso year using "${DIR_DATA_PROCESSED}/windfalls.dta", nogen keep(master matched)
merge m:1 iso year using "${DIR_DATA_PROCESSED}/milex.dta", nogen keep(master matched)

egen cid = group(iso1 iso)
xtset cid year

foreach var in windfall windfall_10 windfall_05 windfall_01 milex {
	gen ALLY_`var' = l.ally * `var'
	gen RIVAL_`var' = l.rival * `var'
}

drop iso
rename iso1 iso

collapse (sum) ALLY_* RIVAL_*, by(iso year)


merge m:1 iso year using "${DIR_DATA_PROCESSED}/milex.dta", nogen keep(master matched)
merge m:1 iso year using "${DIR_DATA_PROCESSED}/windfalls.dta", nogen keep(master matched)
merge m:1 iso year using "${DIR_DATA_PROCESSED}/gprc.dta", nogen keep(master matched)

egen cid = group(iso)
xtset cid year

gen dALLY_milex = d.ALLY_milex
gen dRIVAL_milex = d.RIVAL_milex

label var ALLY_windfall "Ally Windfall"
label var RIVAL_windfall "Rival Windfall"

label var dALLY_milex "\(\widehat{\Delta TMA}\)"
label var dRIVAL_milex "\(\widehat{\Delta TRA}\)"



gen dmilex = d.milex
winsor2 dmilex, cuts(5 95)

local se_1 iso
local se_2 iso year

foreach se in se_1 se_2 {
	foreach depvar in dALLY_milex dRIVAL_milex {
		eststo: reghdfe `depvar' ALLY_windfall RIVAL_windfall windfall, cluster(``se'') noabsorb
		eststo: reghdfe `depvar' ALLY_windfall RIVAL_windfall windfall, cluster(``se'') absorb(iso)
		estadd local hascfe "\checkmark"
		eststo: reghdfe `depvar' ALLY_windfall RIVAL_windfall windfall, cluster(``se'') absorb(iso year)
		estadd local hascfe "\checkmark"
		estadd local hasyfe "\checkmark"

		esttab using "${DIR_DATA_EXPORTS}/iv_un/firststage_depvar[`depvar']_se[``se''].tex", tex fragment nonumber nomtitle keep(ALLY_windfall RIVAL_windfall) posthead("") label stats(hascfe hasyfe F r2 N, fmt(1 1 1 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01)
		eststo clear
	}
	
	eststo: ivreghdfe dmilex_w (dALLY_milex dRIVAL_milex = ALLY_windfall RIVAL_windfall) windfall, cluster(``se'') first
	eststo: ivreghdfe dmilex_w (dALLY_milex dRIVAL_milex = ALLY_windfall RIVAL_windfall) windfall, cluster(``se'') absorb(iso) first
	estadd local hascfe "\checkmark"
	eststo: ivreghdfe dmilex_w (dALLY_milex dRIVAL_milex = ALLY_windfall RIVAL_windfall) windfall, cluster(``se'') absorb(iso year) first
	estadd local hascfe "\checkmark"
	estadd local hasyfe "\checkmark"

	esttab using "${DIR_DATA_EXPORTS}/iv_un/secondstage_se[``se''].tex", tex fragment nonumber nomtitle keep(dALLY_milex dRIVAL_milex) posthead("") label stats(hascfe hasyfe F N, fmt(1 1 1 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01) se
	eststo clear
}
