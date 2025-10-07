use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear


cap program drop define_eras 
program define define_eras
	/*gen era = 0 // Not included
	replace era = 1 if year >= 1871
	replace era = 2 if year >= 1950 // Post WW era
	replace era = 3 if year >= 1990 // Post SU era
	replace era = 4 if year >= 2022 // Post invasion era
	*/
	// Decade specific eras:
	tostring year, gen(year_str)
	gen decade_str = substr(year_str, 1, 3)
	destring decade_str, gen(decade)
	gen era = decade
	drop *_str decade
end


cap program drop build_era_network
program define build_era_network
	use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

	// Generate lagged a+ / a-
	egen gid = group(iso1 iso2)
	xtset gid year
	gen a_plus = l.F_ally
	gen a_minus = l.F_rival
	
	// Only keep first year of era
	// 	- a+ and a- then are fixed to pre-era year
	define_eras
	bysort iso1 iso2 era (year): gen n = _n
	keep if n == 1
	drop n year
	drop if a_plus == . | a_minus == .
	drop if era == 0
end


// Build peer spending data
cap program drop build_peer_spending
program define build_peer_spending
	build_era_network	
	tempfile network
	save `network'
	
	// Compute total spending of allies / rivals in network
	use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear
	drop *_milex
	
	define_eras
	rename iso iso2
	joinby iso2 era using `network'
	
	gen ALLY_milex = a_plus * milex
	gen RIVAL_milex = a_minus * milex
	
	collapse (sum) *_milex, by(iso1 year)
	rename iso1 iso
end

// Build final macro panel
cap program drop build_macro_panel
program define build_macro_panel
	build_peer_spending
		
	merge 1:1 iso year using "${DIR_DATA_PROCESSED}/longrun/macro.dta", nogen keep(matched using) keepusing(gdp war milex)
	
	// Country has no allies/rivals at a given point in time
	replace ALLY_milex = 0 if ALLY_milex == .
	replace RIVAL_milex = 0 if RIVAL_milex == .
	
	
	// Compute average gdp
	bysort year: egen gdp_avg = mean(gdp)
	
	// Define WW dummies
	gen byte ww1 = (year >= 1914) & (year <= 1918)
	gen byte ww2 = (year >= 1939) & (year <= 1945)
	
	define_eras
	
	
	encode iso, gen(isoenc)
	order iso era
	
	xtset isoenc year
		
	drop if era == 0
end


/*********
* Decade panel
*/
build_macro_panel
collapse (mean) milex *_milex gdp gdp_avg war, by(iso isoenc era)
xtset isoenc era
gen war_x_gdp = war * gdp


gen war_bn = war * 1e9
label var ALLY_milex "\(TMA\)"
label var RIVAL_milex "\(TMR\)"
label var gdp "\(GDP\)"
label var gdp_avg "\(GDP^{avg}\)"
label var war_bn "War (USD bn)"
label var war_x_gdp "War \(\times\) GDP"

eststo clear

eststo: xtscc milex ///
	ALLY_milex RIVAL_milex ///
	gdp
	
eststo: xtscc milex ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	gdp_avg
	
eststo: xtscc milex ///
	i.era ///
	ALLY_milex RIVAL_milex ///
	gdp
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.era ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	war_bn
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.era ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	war_bn ///
	war_x_gdp
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.era ///
	ALLY_milex RIVAL_milex ///
	c.gdp#i.isoenc ///
	c.gdp_avg#i.isoenc ///
	war_bn ///
	war_x_gdp
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/longrun/reg_decade.tex",  star(* 0.1 ** 0.05 *** 0.01) tex fragment nonumbers nomtitle posthead("") keep(ALLY_* RIVAL_* gdp gdp_avg war_bn war_x_gdp) label ///
	stats(yfe csexposure r2 N, fmt(1 1 2 "%9.0fc") label("Decade FE" "Country-specific loading" "\(R^2\)"  "\$N\$")) replace se
	
	
// Yearly, decade network	
build_macro_panel

gen war_x_gdp = war * gdp


gen war_bn = war * 1e9
gen ww1_bn = ww1 * 1e9
gen ww2_bn = ww2 * 1e9
label var ALLY_milex "\(TMA\)"
label var RIVAL_milex "\(TMR\)"
label var gdp "\(GDP\)"
label var gdp_avg "\(GDP^{avg}\)"
label var war_bn "War (USD bn)"
label var war_x_gdp "War \(\times\) GDP"
label var ww1_bn "World War I (USD bn)"
label var ww2_bn "World War II (USD bn)"

eststo clear

eststo: xtscc milex ///
	ALLY_milex RIVAL_milex ///
	gdp
	
eststo: xtscc milex ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	gdp_avg
	
eststo: xtscc milex ///
	i.year ///
	ALLY_milex RIVAL_milex ///
	gdp
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.year ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	war_bn
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.year ///
	ALLY_milex RIVAL_milex ///
	gdp ///
	war_bn ///
	war_x_gdp
estadd local yfe "\checkmark"
	
eststo: xtscc milex ///
	i.year ///
	ALLY_milex RIVAL_milex ///
	c.gdp#i.isoenc ///
	c.gdp_avg#i.isoenc ///
	war_bn ///
	war_x_gdp
	
eststo: xtscc milex ///
	i.year ///
	ALLY_milex RIVAL_milex ///
	c.gdp#i.isoenc ///
	c.gdp_avg#i.isoenc ///
	war_bn ///
	war_x_gdp ///
	ww1_bn ///
	ww2_bn
	
estadd local yfe "\checkmark"
estadd local csexposure "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/longrun/reg_yearly_decadenetwork.tex",  star(* 0.1 ** 0.05 *** 0.01) tex fragment nonumbers nomtitle posthead("") keep(ALLY_* RIVAL_* gdp gdp_avg war_bn war_x_gdp ww*) label ///
	stats(yfe csexposure r2 N, fmt(1 1 2 "%9.0fc") label("Year FE" "Country-specific loading" "\(R^2\)"  "\$N\$")) replace se

	
	
	
	
	
	
// Yearly panel, back out country
build_macro_panel

xtscc milex ///
	ALLY_milex RIVAL_milex ///
	c.gdp#i.isoenc#i.era ///
	c.gdp_avg#i.isoenc#i.era ///
	, nocons
	
disp _b[ALLY_milex]
disp _b[RIVAL_milex]

disp r(table)["pvalue", "ALLY_milex"]
disp r(table)["pvalue", "RIVAL_milex"]

// Store theta and lambda
gen theta = .
gen lambda = .
	
levelsof isoenc, local(isoencs)
levelsof era, local(eras)

foreach isoenc in `isoencs' {
	local vl: value label isoenc
	local iso: label (`vl') `isoenc'
	display "`iso'"
	
	foreach era in `eras' {
		replace theta = _b[`era'.era#`isoenc'.isoenc#c.gdp_avg] if era == `era' & iso == "`iso'"
		replace lambda = _b[`era'.era#`isoenc'.isoenc#c.gdp] if era == `era' & iso == "`iso'"
	}
}
keep iso era theta lambda
duplicates drop
tempfile coeffs
save `coeffs'


// Back out valence term
build_era_network

rename iso1 iso
collapse (sum) d_plus=a_plus d_minus=a_minus, by(iso era)

merge 1:1 iso era using `coeffs', nogen keep(matched)

gen H = 1 / (1 - _b[ALLY_milex] * d_plus - _b[RIVAL_milex] * d_minus)

bysort era: egen H_sum = total(H)
gen valence = lambda * H^-1 * (1 - 1/H_sum)^-2
replace valence = . if lambda == 0
tempfile valence
save `valence'


use "${DIR_DATA_PROCESSED}/common/gprc.dta", clear
define_eras

collapse (mean) gprc, by(era iso)
merge 1:1 iso era using `valence', keep(master matched)

bysort iso: egen valence_sd = sd(valence)
bysort iso: egen valence_mean = mean(valence)
gen valence_z = (valence - valence_mean) / valence_sd

bysort iso: egen gprc_sd = sd(gprc)
bysort iso: egen gprc_mean = mean(gprc)
gen gprc_z = (gprc - gprc_mean) / gprc_sd

/*
use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear


cap program drop define_eras 
program define define_eras
	/*gen era = 0 // Not included
	replace era = 1 if year >= 1871
	replace era = 2 if year >= 1950 // Post WW era
	replace era = 3 if year >= 1990 // Post SU era
	replace era = 4 if year >= 2022 // Post invasion era
	*/
	// Decade specific eras:
	tostring year, gen(year_str)
	gen decade_str = substr(year_str, 1, 3)
	destring decade_str, gen(decade)
	gen era = decade
	drop *_str decade
end


cap program drop build_era_network
program define build_era_network
	use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

	// Generate lagged a+ / a-
	egen gid = group(iso1 iso2)
	xtset gid year
	gen a_plus = l.F_ally
	gen a_minus = l.F_rival
	
	// Only keep first year of era
	// 	- a+ and a- then are fixed to pre-era year
	define_eras
	bysort iso1 iso2 era (year): gen n = _n
	keep if n == 1
	drop n year
	drop if a_plus == . | a_minus == .
	drop if era == 0
end


// Build peer spending data
cap program drop build_peer_spending
program define build_peer_spending
	build_era_network	
	tempfile network
	save `network'
	
	// Compute total spending of allies / rivals in network
	use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear
	drop *_milex
	
	define_eras
	rename iso iso2
	joinby iso2 era using `network'
	
	gen ALLY_milex = a_plus * milex
	gen RIVAL_milex = a_minus * milex
	
	collapse (sum) *_milex, by(iso1 year)
	rename iso1 iso
end

// Build final macro panel
cap program drop build_macro_panel
program define build_macro_panel
	build_peer_spending
		
	merge 1:1 iso year using "${DIR_DATA_PROCESSED}/longrun/macro.dta", nogen keep(matched using) keepusing(gdp war milex)
	
	// Country has no allies/rivals at a given point in time
	replace ALLY_milex = 0 if ALLY_milex == .
	replace RIVAL_milex = 0 if RIVAL_milex == .
	
	
	// Compute average gdp
	bysort year: egen gdp_avg = mean(gdp)
	
	// Define WW dummies
	gen byte ww1 = (year >= 1914) & (year <= 1918)
	gen byte ww2 = (year >= 1939) & (year <= 1945)
	
	// Compute MAs of milex
	rangestat (mean) milex_10y=milex ALLY_milex_10y=ALLY_milex RIVAL_milex_10y=RIVAL_milex, interval(year -10 0) by(iso)
	
	define_eras
	
	encode iso, gen(isoenc)
	order iso year
	
	xtset isoenc year
	
	drop if era == 0
end

build_macro_panel
xtscc milex ///
	ALLY_milex RIVAL_milex ///
	c.gdp#i.isoenc#i.era ///
	c.gdp_avg#i.isoenc#i.era ///
	, nocons

// Store theta and lambda
gen theta = .
gen lambda = .
	
levelsof isoenc, local(isoencs)
levelsof era, local(eras)

foreach isoenc in `isoencs' {
	local vl: value label isoenc
	local iso: label (`vl') `isoenc'
	display "`iso'"
	
	foreach era in `eras' {
		replace theta = _b[`era'.era#`isoenc'.isoenc#c.gdp_avg] if era == `era' & iso == "`iso'"
		replace lambda = _b[`era'.era#`isoenc'.isoenc#c.gdp] if era == `era' & iso == "`iso'"
	}
}
keep iso era theta lambda
duplicates drop
tempfile coeffs
save `coeffs'


// Back out valence term
build_era_network

rename iso1 iso
collapse (sum) d_plus=a_plus d_minus=a_minus, by(iso era)

merge 1:1 iso era using `coeffs', nogen keep(matched)

gen H = 1 / (1 - _b[ALLY_milex] * d_plus - _b[RIVAL_milex] * d_minus)

bysort era: egen H_sum = total(H)
gen valence = lambda * H^-1 * (1 - 1/H_sum)^-2
tempfile valence
save `valence'


use "${DIR_DATA_PROCESSED}/common/gprc.dta", clear
define_eras

collapse (mean) gprc, by(era iso)
merge 1:1 iso era using `valence', keep(master matched)

bysort iso: egen valence_sd = sd(valence)
bysort iso: egen valence_mean = mean(valence)
gen valence_z = (valence - valence_mean) / valence_sd

bysort iso: egen gprc_sd = sd(gprc)
bysort iso: egen gprc_mean = mean(gprc)
gen gprc_z = (gprc - gprc_mean) / gprc_sd*/
