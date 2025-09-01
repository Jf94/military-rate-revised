use "${DIR_DATA_PROCESSED}/panel.dta", clear

build_panel_firststage

eststo clear
label var windfall "Windfall"
eststo: reghdfe milex0 windfall, noabsorb cluster(iso)

eststo: reghdfe milex0 windfall, absorb(iso) cluster(iso)
estadd local hascfe "\checkmark"

eststo: reghdfe milex0 windfall, absorb(iso year) cluster(iso)
estadd local hascfe "\checkmark"
estadd local hasyfe "\checkmark"

esttab using "${DIR_DATA_EXPORTS}/firststage.tex", star(* 0.1 ** 0.05  *** 0.01) keep(windfall) r2 label fragment se tex nomtitles nonumbers replace  stats(hascfe hasyfe F r2 N, fmt(1 1 3 3 "%9.0fc") label("Country fixed effects" "Year fixed effects" "F-Statistic" "\$R^2\$" "\$N\$"))
eststo clear
