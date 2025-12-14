use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear

reghdfe milex1 windfall l1dmilex l2dmilex, noabsorb cluster(iso)




// Get degree 1 allies of iso
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear


/*
* Get degree 2 allies of iso
*/
use "${DIR_DATA_PROCESSED}/common/scores.dta", clear

rename F_ally F_ally_degree01
rename F_rival F_rival_degree01
rename iso1 iso0
rename iso2 iso1

// Now merge allies/rivals of iso2
joinby iso1 year using "${DIR_DATA_PROCESSED}/common/scores.dta"
rename F_ally F_ally_degree12
rename F_rival F_rival_degree12


// 
rename iso1 iso1_former
rename iso0 iso1

merge m:1 iso1 iso2 year using "${DIR_DATA_PROCESSED}/common/scores.dta", nogen keep(master matched using)

rename iso1 iso0
rename iso1_former iso1

rename F_ally F_ally_degree02
rename F_rival F_rival_degree02

drop if iso0 == iso1 | iso0 == iso1 | iso0 == iso2


save "${DIR_DATA_TMP}/network_degree.dta", replace


use "${DIR_DATA_PROCESSED}/shortrun/macro.dta", clear
reghdfe milex1 windfall, noabsorb cluster(iso)
gen milex_pred_chg = windfall * _b[windfall]

keep iso year milex_pred_chg

tempfile windfalls
save `windfalls'


use "${DIR_DATA_TMP}/network_degree.dta", clear
keep if F_ally_degree01 == 1 | F_rival_degree01 == 1
keep if F_ally_degree02 == 0 & F_rival_degree02 == 0

keep if F_ally_degree12 == 1
* | F_rival_degree12 == 1

rename iso2 iso
merge m:1 iso year using `windfalls', nogen keep(matched)
rename iso iso2
rename milex_pred_chg iso2_milex1_hat

rename iso1 iso
merge m:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/macro.dta", nogen keep(master matched) keepusing(milex1)
rename iso iso1
rename milex1 iso1_milex1

gen iso2_milex1_hat_ally = iso2_milex1_hat * F_ally_degree12
gen iso2_milex1_hat_rival = iso2_milex1_hat * F_rival_degree12

reg iso1_milex1 iso2_milex1_hat_ally

gen iso1_milex1_hat = iso2_milex1_hat_ally * _b[iso2_milex1_hat_ally]

collapse (sum) iso1_milex1_hat, by(iso0 iso1 year)

rename iso1 iso2
rename iso0 iso1
rename iso1_milex1_hat iso2_milex1_hat

merge 1:1 iso1 iso2 year using "${DIR_DATA_PROCESSED}/common/scores.dta", nogen keep(master matched)

gen TMA_hat = iso2_milex1_hat * F_ally
gen TMR_hat = iso2_milex1_hat * F_rival

collapse (sum) *_hat, by(iso1 year)
keep if year >= 1977
rename iso1 iso

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/macro.dta", nogen keep(master matched)
reg milex1 TMA_hat TMR_hat 



rename iso2 iso
merge m:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/macro.dta", nogen keep(master matched) keepusing(milex1)
rename iso iso2





collapse (max) F_ally_degree2 F_rival_degree2, by(iso_focal iso2 year)

rename iso_focal iso1
drop if iso1 == iso2

merge 1:1 iso1 iso2 year using "${DIR_DATA_PROCESSED}/common/scores.dta", nogen keep(master matched using)

rename F_ally F_ally_degree1
rename F_rival F_rival_degree1

// Allies of allies (without ally of 1)
gen byte F_ally_of_ally = (F_ally_degree1 == 1) & (F)

*replace F_ally_degree2 = 0 if F_ally_degree1 == 1
*replace F_rival_degree2 = 0 if F_rival_degree1 == 1

*replace F_ally_degree1 = 0 if F_ally_degree1 == .
*replace F_rival_degree1 = 0 if F_rival_degree1 == .




/*
* Compute windfalls
*/

keep iso year milex_pred_chg milex1
rename iso iso2

merge 1:m iso2 year using "${DIR_DATA_TMP}/network_degree.dta", nogen keep(matched using)

gen TMA = milex1 if F_ally_degree2 == 1
gen TMR = milex1 if F_rival_degree2 == 1

gen TMA_hat = milex_pred_chg if F_ally_degree2 == 1
gen TMR_hat = milex_pred_chg if F_rival_degree2 == 1

collapse (sum) TM* (count) c_TMA_hat=TMA_hat c_TMR_hat=TMR_hat, by(iso1 year)
rename iso1 iso

drop if c_TMA_hat == 0 | c_TMR_hat == 0

merge 1:1 iso year using "${DIR_DATA_PROCESSED}/shortrun/macro.dta", nogen keep(master matched) keepusing(milex1)

reg TMA TMA_hat
reg TMA TMA_hat


ivreghdfe milex1 (TMA TMR=TMA_hat TMR_hat)
