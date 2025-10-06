do "${DIR_SRC_PROCESS}/shortrun/firststage.do"
do "${DIR_SRC_PROCESS}/shortrun/secondstage.do"
use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear
build_panel_firststage
build_panel_secondstage


* Generate average GDP
bysort year: egen gdp_avg = mean(gdp)
xtset cid year
encode iso, gen(iso_enc)
gen l1dgdp = l.d.gdp
gen l1dgdp_avg = l.d.gdp_avg

* Generate forward variables
xtset cid year
forvalues h=0/8 {
	gen ALLY_milex`h' = f`h'.ALLY_milex - l.ALLY_milex
	gen RIVAL_milex`h' = f`h'.RIVAL_milex - l.RIVAL_milex
}

label var ALLY_windfall "Ally windfalls"
label var RIVAL_windfall "Rival windfalls"

* Restrict to PLE countries
merge 1:1 iso year using "${DIR_DATA_PROCESSED}/longrun/macro.dta", nogen keep(matched) keepusing(iso)

* Restrict to complete sample
xtset cid year
gen ldgdp = l.d.gdp
gen ldgdp_avg = l.d.gdp_avg
drop if milex0 == .
drop if windfall == .
drop if ldgdp == .
drop if ldgdp_avg == .
encode iso, gen(isoenc)


* First stage estimation
reghdfe ALLY_milex0 ALLY_windfall RIVAL_windfall, noabsorb cluster(iso) nocons
predict ALLY_milex0_pred, xb

reghdfe RIVAL_milex0 ALLY_windfall RIVAL_windfall, noabsorb cluster(iso) nocons
predict RIVAL_milex0_pred, xb

reghdfe milex0 ALLY_milex0_pred RIVAL_milex0_pred windfall l.d.gdp l.d.gdp_avg, noabsorb cluster(iso)


gen ldgdp_avg_neg = -ldgdp_avg
reg milex ALLY_milex RIVAL_milex ldgdp_avg_neg

sum isoenc
local isoenc_max = r(max) 
local expression_gdp
local expression_gdp_avg

forvalues isoenc_id=1/`isoenc_max' {
	local lbl: label (isoenc) `isoenc_id'
	
	local expression_gdp `expression_gdp' exp({`lbl'_GDP=1}) * `isoenc_id'.isoenc * ldgdp +
	
	local expression_gdp_avg `expression_gdp_avg' exp({`lbl'_GDP_avg=1}) * `isoenc_id'.isoenc * ldgdp_avg +
}

disp "`expression_gdp'"

nl ( ///
	milex = ///
	{ALLY_milex=_b[ALLY_milex]} * ALLY_milex + ///
	{RIVAL_milex=_b[RIVAL_milex]} * RIVAL_milex + ///
	`expression_gdp' ///
	`expression_gdp_avg' ///
	{_cons=1} ///
)



nl ( ///
	milex = ///
	{ALLY_milex=1} * ALLY_milex + ///
	{RIVAL_milex=1} * RIVAL_milex + ///
	{_cons=1} ///
)





