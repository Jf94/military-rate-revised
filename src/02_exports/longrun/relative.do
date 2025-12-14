use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear


bysort year: egen gdp_avg = mean(gdp)

gen gdp_avg_gdp = gdp_avg / gdp
gen ALLY_milex_gdp = ALLY_milex / gdp
gen RIVAL_milex_gdp = RIVAL_milex / gdp

gen byte ww1 = (year >= 1914) & (year <= 1918)
gen byte ww2 = (year >= 1939) & (year <= 1945)

egen cid = group(iso)
xtset cid year
encode iso, gen(isoenc)

label var ALLY_milex_gdp "\(TMA / GDP\)"
label var RIVAL_milex_gdp "\(TMR / GDP\)"
label var gdp_avg_gdp "\(GDP^{avg} / GDP\)"
label var war "War"
label var ww1 "World War I"
label var ww2 "World War II"

replace milex_gdp = milex_gdp * 100

eststo clear
eststo: xtscc f.milex_gdp ALLY_milex_gdp RIVAL_milex_gdp
eststo: xtscc f.milex_gdp ALLY_milex_gdp RIVAL_milex_gdp gdp_avg_gdp
eststo: xtscc f.milex_gdp i.year ALLY_milex_gdp RIVAL_milex_gdp gdp_avg_gdp
estadd local yfe "\checkmark"

eststo: xtscc f.milex_gdp i.year ALLY_milex_gdp RIVAL_milex_gdp war, nocons
estadd local yfe "\checkmark"

eststo: xtscc f.milex_gdp i.year i.isoenc ALLY_milex_gdp RIVAL_milex_gdp war i.isoenc#c.gdp_avg_gdp, nocons
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

eststo: xtscc f.milex_gdp i.year i.isoenc ALLY_milex_gdp RIVAL_milex_gdp war i.isoenc#c.gdp_avg_gdp ww1 ww2, nocons
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/longrun/relative.tex", keep(_cons ALLY_milex_gdp RIVAL_milex_gdp gdp_avg_gdp war ww*) star(* 0.1 ** 0.05 *** 0.01) tex fragment nonumbers nomtitle posthead("") r2 label ///
	stats(yfe csexposure csexposure r2 N, fmt(1 1 1 2 "%9.0fc") label("Year FE" "Country-specific \(\lambda\)" "Country-specific \(\theta\)" "\(R^2\)"  "\$N\$")) replace se
