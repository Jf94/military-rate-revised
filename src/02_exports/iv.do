do "${DIR_SRC_PROCESS}/firststage.do"
do "${DIR_SRC_PROCESS}/secondstage.do"
use "${DIR_DATA_PROCESSED}/panel.dta", clear

build_panel_firststage
build_panel_secondstage
xtset cid year

*replace RIVAL_pred_change = . if RIVAL_pred_change == 0
*replace ALLY_pred_change = . if ALLY_pred_change == 0
replace RIVAL_pred_change = 0 if RIVAL_pred_change == .
replace ALLY_pred_change = 0 if ALLY_pred_change == .
replace TRA = 0 if TRA == .
replace TMA = 0 if TMA == .
replace ALLY_windfall = 0 if ALLY_windfall == .
replace TRA_windfall = 0 if TRA_windfall == .

forvalues h=0/10 {
	winsor2 milex`h', cuts(5 95)
	rename milex`h'_w milex`h'_w5
	
	winsor2 milex`h', cuts(1 99)
	rename milex`h'_w milex`h'_w1
	
	winsor2 milex`h', cuts(0.5 99.5)
	rename milex`h'_w milex`h'_w05
	
	winsor2 milex`h', cuts(2.5 97.5)
	rename milex`h'_w milex`h'_w25
}
gen dTMA = d.TMA
gen dTRA = d.TRA
gen diff = dTMA - dTRA

xtset cid year


// TMA First stage
label var ALLY_windfall "Ally Windfall"
label var TRA_windfall "Rival Windfall"

label var dTMA "\(\widehat{\Delta TMA}\)"
label var dTRA "\(\widehat{\Delta TRA}\)"

local se_1 iso
local se_2 iso year

foreach se in se_1 se_2 {
	foreach depvar in dTMA dTRA {
		eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(``se'') noabsorb
		eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(``se'') absorb(iso)
		estadd local hascfe "\checkmark"
		eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(``se'') absorb(iso year)
		estadd local hascfe "\checkmark"
		estadd local hasyfe "\checkmark"

		esttab using "${DIR_DATA_EXPORTS}/iv/firststage_depvar[`depvar']_se[``se''].tex", tex fragment nonumber nomtitle keep(ALLY_windfall TRA_windfall) posthead("") label stats(hascfe hasyfe F r2 N, fmt(1 1 1 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01)
		eststo clear
	}
	
	eststo: ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(``se'') first
	eststo: ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(``se'') absorb(iso) first
	estadd local hascfe "\checkmark"
	eststo: ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(``se'') absorb(iso year) first
	estadd local hascfe "\checkmark"
	estadd local hasyfe "\checkmark"

	esttab using "${DIR_DATA_EXPORTS}/iv/secondstage_se[``se''].tex", tex fragment nonumber nomtitle keep(dTMA dTRA) posthead("") label stats(hascfe hasyfe F N, fmt(1 1 1 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01) se
	eststo clear
}
	
	
foreach se in se_1 se_2 {
	eststo: reghdfe diff ALLY_windfall TRA_windfall, cluster(``se'') noabsorb
	eststo: reghdfe diff ALLY_windfall TRA_windfall, cluster(``se'') absorb(iso)
	estadd local hascfe "\checkmark"
	eststo: reghdfe diff ALLY_windfall TRA_windfall, cluster(``se'') absorb(iso year)
	estadd local hascfe "\checkmark"
	estadd local hasyfe "\checkmark"

	esttab using "${DIR_DATA_EXPORTS}/iv/firststage_diff_se[``se''].tex", tex fragment nonumber nomtitle keep(ALLY_windfall TRA_windfall) posthead("") label stats(hascfe hasyfe F r2 N, fmt(1 1 1 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01)
	eststo clear
	
	eststo: ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(``se'') first
	eststo: ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(``se'') absorb(iso) first
	estadd local hascfe "\checkmark"
	eststo: ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(``se'') absorb(iso year) first
	estadd local hascfe "\checkmark"
	estadd local hasyfe "\checkmark"

	
	esttab using "${DIR_DATA_EXPORTS}/iv/secondstage_diff_se[``se''].tex", tex fragment nonumber nomtitle keep(diff) posthead("") label stats(hascfe hasyfe F N, fmt(1 1 1 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$N\$")) replace star(* 0.1 ** 0.05  *** 0.01)
	eststo clear
}


gen milex_predicted = _b["dTMA"] * TMA + _b["dTRA"] * TRA

reghdfe milex milex_predicted if TRA > 0 | TMA > 0, absorb(iso year)
reghdfe milex milex_predicted if TRA > 0 | TMA > 0, absorb(iso year) cluster(iso)






/// Block Bootstrap at product year level
capture program drop bootprog
program define bootprog, rclass   
    version 17.0
	preserve
	
	// Collapse windfalls
	collapse (sum) windfall windfall_* (count) n=windfall, by(iso year)
	replace windfall = . if n == 0
	replace windfall_10 = . if n == 0
	replace windfall_05 = . if n == 0
	replace windfall_01 = . if n == 0
	tempfile windfalls 
	save `windfalls', replace
	
	// Merge panel
	use "${DIR_DATA_PROCESSED}/panel.dta", clear
	drop windfall windfall_*
	merge 1:1 iso year using `windfalls', nogen keep(master matched)
	gen windfall_gdp = windfall / l1gdp
	
    
	build_panel_firststage
	build_panel_secondstage
	xtset cid year

	*replace RIVAL_pred_change = . if RIVAL_pred_change == 0
	*replace ALLY_pred_change = . if ALLY_pred_change == 0
	replace RIVAL_pred_change = 0 if RIVAL_pred_change == .
	replace ALLY_pred_change = 0 if ALLY_pred_change == .
	replace TRA = 0 if TRA == .
	replace TMA = 0 if TMA == .
	replace ALLY_windfall = 0 if ALLY_windfall == .
	replace TRA_windfall = 0 if TRA_windfall == .

	forvalues h=0/10 {
		winsor2 milex`h', cuts(5 95)
		rename milex`h'_w milex`h'_w5
		
		winsor2 milex`h', cuts(1 99)
		rename milex`h'_w milex`h'_w1
		
		winsor2 milex`h', cuts(0.5 99.5)
		rename milex`h'_w milex`h'_w05
		
		winsor2 milex`h', cuts(2.5 97.5)
		rename milex`h'_w milex`h'_w25
	}
	gen dTMA = d.TMA
	gen dTRA = d.TRA
	gen diff = dTMA - dTRA

	xtset cid year
	*ivreghdfe milex0_w (diff = ALLY_windfall TRA_windfall), absorb(iso year) first
	ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso year) first
	return scalar b_ALLY = _b[dTMA]
	return scalar b_RIVAL = _b[dTRA]
	xtset, clear
	restore
end

use "${DIR_DATA_PROCESSED}/windfalls_disaggregated.dta", clear
egen prodyear = group(cmdcode year)

xtset, clear
bootstrap b_ALLY=r(b_ALLY) b_RIVAL=r(b_RIVAL), level(90) reps(1000) seed(0) cluster(prodyear) idcluster(bootclust): bootprog


