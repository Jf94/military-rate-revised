/******************************************************************************
* Prepare military expenditure data
* Combines COW NMC dataset with exchange rates and deflators
******************************************************************************/

* 1. Prepare exchange rate data (USD/GBP)
tempfile fx
import excel "${DIR_DATA_RAW}/measuringworth/fx.xlsx", clear cellrange(A3) firstrow
rename USDGBP USD_over_GBP
duplicates drop
save `fx'

/******************************************************************************
* 2. Load military expenditure data from CoW NMC-60
******************************************************************************/
use "${DIR_DATA_RAW}/cow/NMC_Documentation-6.0/NMC-60-abridged/NMC-60-abridged.dta", clear
keep ccode year milex milper cinc tpop


/******************************************************************************
* 3. Clean values and scale units
******************************************************************************/

replace milex = . if milex < 0
replace milper = . if milper < 0

replace milper = milper * 1000      // thousands → units
replace milex  = milex  * 1000

collapse (sum) milex milper tpop (mean) cinc, by(ccode year)

* Treat zeros as missing
replace milex  = . if milex  == 0
replace milper = . if milper == 0

/******************************************************************************
* 4. Convert currencies (if year ≤ 1913, convert GBP → USD)
******************************************************************************/

merge m:1 year using `fx', keep(matched) nogen
replace milex = milex * USD_over_GBP if year <= 1913
drop USD_over_GBP

/******************************************************************************
* 5. Adjust to constant 2015 USD using CPI deflator
******************************************************************************/

merge m:1 year using "${DIR_DATA_RAW}/federle/deflator_longrun.dta", keep(matched) nogen
replace milex = milex * conv_USD_cur_to_2015
drop conv_USD_cur_to_2015

* 6. Save final dataset
save "${DIR_DATA_PROCESSED}/milex_longrun.dta", replace
