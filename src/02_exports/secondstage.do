do "${DIR_SRC_PROCESS}/firststage.do"
do "${DIR_SRC_PROCESS}/secondstage.do"
use "${DIR_DATA_PROCESSED}/panel.dta", clear

build_panel_firststage
build_panel_secondstage
xtset cid year

replace RIVAL_pred_change = 0 if RIVAL_pred_change == .

// Table
label var ALLY_pred_change "\(-\widehat{\Delta TMA}\)"

eststo: xtscc milex1 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp i.year, fe level(90)
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

eststo: xtscc milex5 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp i.year, fe level(90)
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

eststo: xtscc milex10 l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp i.year, fe level(90)
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"
estadd local hasctrl "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/secondstage.tex", star(* 0.1 ** 0.05  *** 0.01) keep(ALLY_pred_change) r2 label fragment se tex nomtitles nonumbers replace  stats(hasctrl hascfe hasyfe N, fmt(1 3 "%9.0fc") label("Controls" "Country fixed effects" "Year fixed effects" "\$N\$")) prefoot(\hline\noalign{\vskip 1.3mm}) posthead("") prehead("")
eststo clear

// Local projections
local h_max 15
cap drop b* ll* ul* h
gen b_instr = .
gen ll_instr = .
gen ul_instr = .
gen h = _n-1 if _n <= `h_max' + 1

forvalues h=0/`h_max' {
	xtscc milex`h' l(0/2).ALLY_pred_change l(0/2).windfall l(1/2).milex0 l(0/2).conflict_high l(0/2).conflict_low l(1/2).d.gdp i.year, fe level(90)
	lincom 100 * ALLY_pred_change, level(90)
	
	replace b_instr = r(estimate) if h == `h'
	replace ll_instr = r(lb) if h == `h'
	replace ul_instr = r(ub) if h == `h'
}


twoway ///
	(line b_instr h, color(stred)) ///
	(rarea ll_instr ul_instr h, color(stred%50) lwidth(0)) ///
	, yline(0) xtitle("Year after ally spending shock") ytitle("Military expenditures (in USD)") title("Response to 100 USD increase of allied military spending") legend(off) scale(1.4) ysize(9) xsize(20) xla(0(5)15)
	
graph export "${DIR_DATA_EXPORTS}/secondstage_lp.pdf", as(pdf) replace
