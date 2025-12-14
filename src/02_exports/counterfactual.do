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

gen war_x_gdp = war * gdp
gen ww1_gdp = ww1 * gdp
gen ww2_gdp = ww2 * gdp
gen war_bn = war * 1e9

xtset cid year
encode iso, gen(iso_enc)

sum isoenc
local isoenc_max = r(max) 
local expression_gdp
local expression_gdp_avg

drop if gdp == .

gen gdp_avg_neg = -gdp_avg
gen fmilex = f.milex

tostring year, gen(decade)
replace decade = substr(decade, 1, 3)
destring decade, replace

collapse (mean) fmilex ALLY_milex RIVAL_milex war_bn war_x_gdp gdp gdp_avg_neg ww1_bn ww2_bn, by(iso cid isoenc decade)

xtset cid decade

xtscc fmilex ALLY_milex RIVAL_milex war_bn war_x_gdp c.gdp c.gdp_avg_neg ww1_bn ww2_bn
local b_TMA = r(table)["b", "ALLY_milex"]
local b_TMR = r(table)["b", "RIVAL_milex"]
local b_gdp = r(table)["b", "gdp"]
local b_gdp_avg_neg = r(table)["b", "gdp_avg_neg"]



// Set up non-linear regressio
forvalues isoenc_id=1/`isoenc_max' {
	local lbl: label (isoenc) `isoenc_id'
	local expression_gdp `expression_gdp' exp({`lbl'_gdp=`b_gdp'}) * `isoenc_id'.isoenc * gdp +	
	local expression_gdp_avg `expression_gdp_avg' exp({`lbl'_gdp_avg_neg=`b_gdp_avg_neg'}) * `isoenc_id'.isoenc * gdp_avg_neg
	
	if `isoenc_id' < `isoenc_max' {
		local expression_gdp_avg `expression_gdp_avg' +
	}
}

nl ( ///
	fmilex = ///
	{ALLY_milex=`b_TMA'} * ALLY_milex + ///
	{RIVAL_milex=`b_TMR'} * RIVAL_milex + ///
	`expression_gdp' ///
	`expression_gdp_avg' ///
)

// Store regression coefficients
gen coeff_iso = ""
gen lambda = .
gen theta = .

gen alpha_A = _b[/ALLY_milex]
gen alpha_R = _b[/RIVAL_milex]


sum isoenc
local isoenc_max = r(max) 
forvalues isoenc_id=1/`isoenc_max' {
	local vl: value label isoenc
	local iso: label (`vl') `isoenc_id'
	
	replace coeff_iso = "`iso'" if _n == `isoenc_id'
	replace theta = -exp(_b[/`iso'_gdp_avg_neg]) if _n == `isoenc_id'
	replace lambda = exp(_b[/`iso'_gdp]) if _n == `isoenc_id'
}

keep coeff_iso theta lambda alpha_A alpha_R
rename coeff_iso iso
drop if lambda == .

save "${DIR_DATA_TMP}/scratch_coeffs.dta", replace


use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear


cap program drop build_network
program define build_network
	use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

	// Generate lagged a+ / a-
	egen gid = group(iso1 iso2)
	xtset gid year
	gen a_plus = l.F_ally
	gen a_minus = l.F_rival
	rename iso1 iso
end


/*
* Compute actual hostility level in 2023
*/
build_network
keep if year == 2023
collapse (sum) d_plus=a_plus d_minus=a_minus, by(iso year)

merge n:1 iso using "${DIR_DATA_TMP}/scratch_coeffs.dta", nogen keep(matched)
gen H = 1 / (1 - alpha_A * d_plus - alpha_R * d_minus)
keep iso H
tempfile H
save `H', replace



/*
* Compute hostility level absent USA (h_prime) in 2023
*/
build_network
keep if year == 2023
replace a_plus = 0 if iso2 == "USA"
replace a_plus = 0 if iso == "USA"
*replace a_minus = 0 if iso == "USA"
*replace a_minus = 0 if iso2 == "USA"
collapse (sum) d_plus=a_plus d_minus=a_minus, by(iso year)

merge n:1 iso using "${DIR_DATA_TMP}/scratch_coeffs.dta", nogen keep(matched)
gen H_prime = 1 / (1 - alpha_A * d_plus - alpha_R * d_minus) 
keep iso H_prime
tempfile H_prime
save `H_prime', replace


/*
* Compute TMA / TMR in 2023
*/
build_network
keep if year == 2023
merge m:1 iso year using "${DIR_DATA_PROCESSED}/longrun/macro.dta", nogen keep(matched)
drop iso
rename iso2 iso


gen TMA = F_ally * milex
gen TMR = F_rival * milex
collapse (sum) TMA TMR, by(iso)

tempfile milex
save `milex'


/*
* Compute TMA / TMR absent USA (h_prime) in 2023
*/
build_network
keep if year == 2023
merge m:1 iso year using "${DIR_DATA_PROCESSED}/longrun/macro.dta", nogen keep(matched)
replace F_ally = 0 if iso == "USA"
replace F_ally = 0 if iso2 == "USA"
*replace F_rival = 0 if iso == "USA"
*replace F_rival = 0 if iso2 == "USA"
drop iso
rename iso2 iso


gen TMA_prime = F_ally * milex
gen TMR_prime = F_rival * milex

collapse (sum) TMA_prime TMR_prime, by(iso)
tempfile milex_exus
save `milex_exus', replace


/*
* Merge everything, compute coefficients and predictions
*/
use "${DIR_DATA_PROCESSED}/longrun/macro.dta", clear
bysort year: egen gdp_avg = mean(gdp)


keep if year == 2023

merge 1:1 iso using "${DIR_DATA_TMP}/scratch_coeffs.dta", nogen keep(master matched)
merge 1:1 iso using `H', nogen keep(master matched)
merge 1:1 iso using `H_prime', nogen keep(master matched)
merge 1:1 iso using `milex_exus', nogen keep(master matched)
merge 1:1 iso using `milex', nogen keep(master matched)


bysort year: egen H_sum = total(H)
bysort year: egen H_prime_sum = total(H_prime)


// Model-implied coefficients for counterfactual
gen theta_prime = H_prime / H * theta
gen lambda_prime = H_prime / H * ((1-1/H_prime_sum) / (1-1/H_sum))^2 * lambda


gen milpred_orig = TMA * alpha_A + TMR * alpha_R + theta * gdp_avg + lambda * gdp
gen milpred_exus = TMA_prime * alpha_A + TMR_prime * alpha_R + theta_prime * gdp_avg + lambda_prime * gdp

gen diff_gdp = (milpred_exus - milpred_orig) / gdp

gen eu27 = 0
foreach c in AUT BEL BGR HRV CYP CZE DNK EST FIN FRA DEU GRC HUN IRL ITA LVA LTU LUX MLT NLD POL PRT ROU SVK SVN ESP SWE {
    replace eu27 = 1 if iso == "`c'"
}

save "${DIR_DATA_TMP}/scratch_predictions.dta", replace





/*
* Compute TMA / TMR absent USA (h_prime) in 2023
*/
use "${DIR_DATA_TMP}/scratch_predictions.dta", clear
gen diff_pct = diff_gdp * 100

keep if eu27 == 1

graph bar diff_pct, ///
    over(iso, label(labsize(small) angle(45)) sort(1) descending) ///
    bargap(15) bar(1, color(purple)) ///
    ytitle("Difference in military spending / GDP") ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white)) xsize(20) ysize(9)

graph export "${DIR_DATA_EXPORTS}/counterfactual.pdf", as(pdf) replace
graph close	


use "${DIR_DATA_TMP}/scratch_predictions.dta", clear

gen H_relative = H_prime / H
gen mil_relative = milpred_exus / milpred_orig

twoway (scatter H_relative mil_relative)




use "${DIR_DATA_TMP}/scratch_predictions.dta", clear
gen milratio = milpred_exus / milpred_orig

gen H_relative = H_prime / H
drop if H < 0 | H_prime < 0

twoway (scatter milratio H_relative, mlabel(iso))

graph export "${DIR_DATA_EXPORTS}/counterfactual_rel.pdf", as(pdf) replace
graph close	



/*
* Compute TMA / TMR absent USA (h_prime) in 2023
*/
use "${DIR_DATA_TMP}/scratch_predictions.dta", clear

gen diff_TMA = ((TMA_prime - TMA) * alpha_A) / gdp * 100
gen diff_TMR = ((TMR_prime - TMR) * alpha_R) / gdp * 100

gen diff_theta = ((theta_prime - theta) * gdp_avg) / gdp * 100
gen diff_lambda = ((lambda_prime - lambda) * gdp) / gdp * 100

gen diff_gdp_ppt = diff_gdp * 100



graph bar diff_TMA if eu27 == 1, ///
    over(iso, label(labsize(small) angle(45)) sort(1) descending) ///
    bargap(15) bar(1, color(purple)) ///
    ytitle("Difference in military spending / GDP %") ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white)) xsize(20) ysize(9) name("TMA", replace)



graph bar diff_gdp_ppt if eu27 == 1, ///
    over(iso, label(labsize(small) angle(45)) sort(1) descending) ///
    bargap(15) bar(1, color(purple)) ///
    ytitle("Difference in military spending / GDP %") ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white)) xsize(20) ysize(9) name("Total", replace)
	
	
sum TMA
local TMA_mean = r(mean)

sum TMR
local TMR_mean = r(mean)

local relation = `TMA_mean' / `TMR_mean'
disp `relation'
