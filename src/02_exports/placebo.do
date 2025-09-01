/*
* Shuffle alliances
*/
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]

tempfile alliances
local nSims = 100
nois _dots 0, title(Loop running) reps(`nSims')
cap mat drop sims
forvalues i=1/`nSims' {
	qui {
		// Shuffle alliances	
		use "${DIR_DATA_PROCESSED}/alliances.dta", clear
		
		shufflevar iso
		shufflevar iso_ally
		drop iso iso_ally
		rename iso_shuffled iso
		rename iso_ally_shuffled iso_ally
		
		/* 1. Get all unique ISO values into a local macro
		levelsof iso, local(isos)

		* 2. Count how many unique ISO values exist
		local n_isos : word count `isos'

		* 3. Generate a random integer between 1 and n
		gen rnd = runiformint(1, `n_isos')
		gen rnd_ally = runiformint(1, `n_isos')

		* 4. Map that random index back to an iso value
		gen iso_random = ""
		gen iso_random_ally = ""
		forvalues n_iso = 1/`n_isos' {
			replace iso_random = "`: word `n_iso' of `isos''" if rnd == `n_iso'
			replace iso_random_ally = "`: word `n_iso' of `isos''" if rnd_ally == `n_iso'
		}
		drop iso iso_ally
		rename iso_random iso
		rename iso_random_ally iso_ally*/
		
		keep if iso != iso_ally
		save `alliances', replace
		
		// Build second stage with custom alliances
		use "${DIR_DATA_PROCESSED}/panel.dta", clear
		build_panel_firststage
		build_panel_secondstage, custom_alliances(`alliances')
		
		xtset cid year
		reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
		
		matrix sims = nullmat(sims) \ _b["ALLY_pred_change"]
	}
	nois _dots `i' 0
}
svmat sims
keep sims 
drop if sims == .
gen byte reached = sims > `coeff_baseline'
sum reached

preserve
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]
restore

twoway (hist sims, bins(100)), xline(`coeff_baseline', lcolor(red)) xtitle("Estimated coefficient") title("Randomize alliances") xsize(12) ysize(9) scale(1.3) name(alliances, replace)
graph export "${DIR_DATA_EXPORTS}/placebo_alliances.pdf", as(pdf) replace



/*
* Shuffle alliances
*/
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]

tempfile alliances
local nSims = 1000
nois _dots 0, title(Loop running) reps(`nSims')
cap mat drop sims
forvalues i=1/`nSims' {
	qui {
		use "${DIR_DATA_PROCESSED}/panel.dta", clear		
		build_panel_firststage
		build_panel_secondstage
		
		shufflevar ALLY_pred_change
		drop ALLY_pred_change
		rename ALLY_pred_change_shuffled ALLY_pred_change
		
		xtset cid year
		reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
		
		matrix sims = nullmat(sims) \ _b["ALLY_pred_change"]
	}
	nois _dots `i' 0
}
svmat sims
keep sims 
drop if sims == .
gen byte reached = sims > `coeff_baseline'
sum reached

preserve
use "${DIR_DATA_PROCESSED}/panel.dta", clear
build_panel_firststage
build_panel_secondstage

xtset cid year
reghdfe milex8 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp, absorb(iso year)
local coeff_baseline = _b["ALLY_pred_change"]
restore

twoway (hist sims, bins(100)), xline(`coeff_baseline', lcolor(red)) xtitle("Estimated coefficient") title("Randomize allied windfalls") xsize(12) ysize(9) scale(1.3) name(windfalls, replace)
graph export "${DIR_DATA_EXPORTS}/placebo_windfalls.pdf", as(pdf) replace


grc1leg2 alliances windfalls, loff ysize(9) xsize(20) scale(1.4)
graph export "${DIR_DATA_EXPORTS}/placebo.pdf", as(pdf) replace
