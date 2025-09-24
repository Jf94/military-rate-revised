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

foreach depvar in dTMA dTRA {
	eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(iso) noabsorb
	eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(iso) absorb(iso)
	estadd local hascfe "\checkmark"
	eststo: reghdfe `depvar' ALLY_windfall TRA_windfall, cluster(iso) absorb(iso year)
	estadd local hascfe "\checkmark"
	estadd local hasyfe "\checkmark"



	esttab using "${DIR_DATA_EXPORTS}/firststage_`depvar'.tex", tex fragment nonumber nomtitle keep(ALLY_windfall TRA_windfall) posthead("") label stats(hascfe hasyfe F r2 N, fmt(1 1 1 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$"))
	eststo clear
}

quit



ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso) first
ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso) first
ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso year) first

ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso year) first
ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso year) absorb(iso) first
ivreghdfe milex0_w5 (dTMA dTRA = ALLY_windfall TRA_windfall), cluster(iso year) absorb(iso year) first

ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso year) first
ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso) first
ivreghdfe milex0_w5 (diff = ALLY_windfall TRA_windfall), cluster(iso) absorb(iso year) first

