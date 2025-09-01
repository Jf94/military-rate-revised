use "${DIR_DATA_PROCESSED}/panel.dta", clear


// Larger countries have lower spending/gdp ratio than smaller countries
gen milgdp = milex / gdp
gen lgdp = log(gdp)
reghdfe milgdp lgdp, absorb(iso year) cluster(iso year)

binscatter milgdp lgdp, xtitle("Log of GDP") ytitle("Military spending in p.p. of GDP") name(noabsorb, replace) title("Without country fixed effects")
binscatter milgdp lgdp, absorb(iso) xtitle("Log of GDP") xtitle("Log of GDP") ytitle("Military spending in p.p. of GDP") name(absorb, replace) title("With country fixed effects")
grc1leg2 noabsorb absorb, loff ysize(9) xsize(20) scale(1.4)
graph export "${DIR_DATA_EXPORTS}/size.pdf", as(pdf) replace
graph close

