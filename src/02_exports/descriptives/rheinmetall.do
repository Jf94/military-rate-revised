import excel "${DIR_DATA_RAW}/refinitiv/rheinmetall.xlsx", firstrow cellrange(A32) clear


keep if ExchangeDate >= mdy(7,1,2021)


sort ExchangeDate

gen logret = log(1 + Chg)
gen cumlogret = sum(logret)
gen cumret = (exp(cumlogret) -1) * 100
*gen cumlogret = Close / Close[1] - 1

local start = mdy(2,24,2022)
local msc = mdy(2,14,2025)
local nato = mdy(6, 25, 2025)

preserve
keep if ExchangeDate <= mdy(7,1,2022)

quietly summarize ExchangeDate, meanonly
local qstart = qofd(r(min))        // first quarter in your data
local qend   = qofd(r(max))        // last quarter in your data

local qxlabs
forvalues q = `qstart'(1)`qend' {
    local d  = dofq(`q')           // daily date: first day of the quarter
    local yr = year(`d')
    local qq = quarter(`d')
    local qxlabs `qxlabs' `d' "Q`qq' `yr'"
}


twoway (line cumret ExchangeDate, lwidth(0.6) color(stred) xaxis(1 2)), xline(`start') ysize(9) xsize(20) ytitle("Cumulative return (in %)") xtitle("Date") scale(1.4) xlabel(`qxlabs', angle(45) axis(1)) xlabel(`start' "Russian invasion of Ukraine", axis(2)) xtitle("", axis(2))

graph export "${DIR_DATA_EXPORTS}/descriptives/rheinmetall/narrow.pdf", as(pdf) replace
graph close	
restore


* --- create quarterly tick positions + labels ---
quietly summarize ExchangeDate, meanonly
local qstart = qofd(r(min))        // first quarter in your data
local qend   = qofd(r(max))        // last quarter in your data

local qxlabs
forvalues q = `qstart'(1)`qend' {
    local d  = dofq(`q')           // daily date: first day of the quarter
    local yr = year(`d')
    local qq = quarter(`d')
    local qxlabs `qxlabs' `d' "Q`qq' `yr'"
}


twoway (line cumret ExchangeDate, lwidth(0.6) color(stred) xaxis(1 2)), xline(`start' `msc' `nato') ysize(9) xsize(20) ytitle("Cumulative return (in %)") xtitle("Date") scale(1.4) xlabel(`qxlabs', angle(45) axis(1)) xlabel(`start' "Russian invasion of Ukraine" `msc' "MSC" `nato' "NATO", axis(2)) xtitle("", axis(2))
graph export "${DIR_DATA_EXPORTS}/descriptives/rheinmetall/broad.pdf", as(pdf) replace
*graph close	
