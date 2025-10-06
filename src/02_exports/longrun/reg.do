use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear


bysort year: egen gdp_avg = mean(gdp)
label var ALLY_milex "\(TMA\)"
label var RIVAL_milex "\(TMR\)"
label var gdp "\(GDP\)"
label var gdp_avg "\(GDP^{avg}\)"

gen byte ww1 = (year >= 1914) & (year <= 1918)
gen byte ww2 = (year >= 1939) & (year <= 1945)

gen ww1_bn = ww1 * 1e9
gen ww2_bn = ww2 * 1e9

egen cid = group(iso)
xtset cid year

encode iso, gen(isoenc)


merge m:1 year using "${DIR_DATA_PROCESSED}/common/gprc_global.dta", nogen keep(master matched)

gen war_x_gdp = war * gdp
gen war_bn = war * 1e9
label var war_bn "War (USD bn)"
label var war_x_gdp "War \(\times\) GDP"
label var ww1_bn "World War I (USD bn)"
label var ww2_bn "World War II (USD bn)"

xtset cid year

**** Baseline
eststo clear
eststo: xtscc f.milex ALLY_milex RIVAL_milex gdp
eststo: xtscc f.milex ALLY_milex RIVAL_milex gdp gdp_avg
eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp war_bn
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp war_bn war_x_gdp
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex war_bn war_x_gdp i.isoenc#c.gdp i.isoenc#c.gdp_avg
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex war_bn war_x_gdp i.isoenc#c.gdp i.isoenc#c.gdp_avg ww1_bn ww2_bn
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"
// From call: Here also one with regional wars

esttab using "${DIR_DATA_EXPORTS}/longrun/reg.tex",  star(* 0.1 ** 0.05 *** 0.01) tex fragment nonumbers nomtitle posthead("") keep(ALLY_* RIVAL_* gdp gdp_avg war_bn war_x_gdp ww*) label ///
	stats(yfe csexposure r2 N, fmt(1 1 2 "%9.0fc") label("Year FE" "Country-specific slopes" "\(R^2\)"  "\$N\$")) replace se
eststo clear



**** Baseline + country fe
eststo: xtscc f.milex ALLY_milex RIVAL_milex gdp, fe
eststo: xtscc f.milex ALLY_milex RIVAL_milex gdp gdp_avg, fe
eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp, fe
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp war_bn, fe
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex gdp war_bn war_x_gdp, fe
estadd local yfe "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex war_bn war_x_gdp i.isoenc#c.gdp i.isoenc#c.gdp_avg, fe
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

eststo: xtscc f.milex i.year ALLY_milex RIVAL_milex war_bn war_x_gdp i.isoenc#c.gdp i.isoenc#c.gdp_avg ww1_bn ww2_bn, fe
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"
// From call: Here also one with regional wars

esttab using "${DIR_DATA_EXPORTS}/longrun/reg_cfe.tex",  star(* 0.1 ** 0.05 *** 0.01) tex fragment nonumbers nomtitle posthead("") keep(ALLY_* RIVAL_* gdp gdp_avg war_bn war_x_gdp ww*) label ///
	stats(yfe csexposure r2 N, fmt(1 1 2 "%9.0fc") label("Year FE" "Country-specific slopes" "\(R^2\)"  "\$N\$")) replace se
eststo clear








**** Descriptive graph
xtscc milex ALLY_milex RIVAL_milex i.isoenc#c.gdp i.isoenc#c.gdp_avg c.war#c.gdp c.war ww1 ww2

predict milex_pred, xb

replace milex_pred = . if milex == . | gdp == .
replace milex = . if milex_pred == . | gdp == .
replace gdp = . if milex_pred == . | milex == .

collapse (sum) milex milex_pred gdp, by(year)

gen milex_gdp = milex / gdp * 100
gen milex_pred_gdp = milex_pred / gdp * 100
	
twoway ///
	(line milex_gdp year, lwidth(0.6) color(stblue)) ///
	(line milex_pred_gdp year, lpattern(dash) lwidth(0.6) color(stred)), xsize(20) ysize(9) legend(order(1 "Realized" 2 "Prediction") position(6) rows(1)) ytitle("Global military spending (% of GDP)") xtitle("Year") xla(1870(10)2022) scale(1.3)

graph export "${DIR_DATA_EXPORTS}/longrun/reg_longrun.pdf", as(pdf) replace
	
/*
bysort year: egen gdp_world = total(gdp)

gen size = gdp / gdp_world
*/
