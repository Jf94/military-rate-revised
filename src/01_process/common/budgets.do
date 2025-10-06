/*
* General government spending
*/
import excel "${DIR_DATA_RAW}/marzian/Military_Booms_Data.xlsx", clear firstrow


rename Country country
replace country = "ARG" if country == "Argentina"
replace country = "AUS" if country == "Australia"
replace country = "AUT" if country == "Austria"
replace country = "CAN" if country == "Canada"
replace country = "CHN" if country == "China"
replace country = "DNK" if country == "Denmark"
replace country = "FIN" if country == "Finland"
replace country = "FRA" if country == "France"
replace country = "DEU" if country == "Germany"
replace country = "IND" if country == "India"
replace country = "ITA" if country == "Italy"
replace country = "JPN" if country == "Japan"
replace country = "NLD" if country == "Netherlands"
replace country = "RUS" if country == "Russia"
replace country = "ESP" if country == "Spain"
replace country = "SWE" if country == "Sweden"
replace country = "CHE" if country == "Switzerland"
replace country = "TUR" if country == "Turkey"
replace country = "GBR" if country == "UK"
replace country = "USA" if country == "USA"
replace country = "NOR" if country == "Norway"
replace country = "PRT" if country == "Portugal"
rename country iso

/* 
* 2. Introduce naming conventions 
*/
rename Year year

// Total number of name locals
local nnames 22


local name1 Interior_and_Economic_Affairs_Broad	bgt_brd_econinfra
local name2 Education_and_Research_Broad bgt_brd_edures
local name3 Health_Welfare_Work_and_Social_Affairs_Broad bgt_brd_soc
local name4 Military_Affairs_Broad bgt_brd_mil
local name5 Total_Spending_Broad bgt_brd_total
local name6 Foreign_Affairs_Broad bgt_brd_fa
local name7 Central_Government_Finance_Broad bgt_brd_cgfin
local name8 GG_Social_Spending gg_social

// Other vars
local name9 Nominal_GDP gdp_nom
local name10 Tax_GDP tax_gdp
local name11 Debt_GDP debt_gdp
local name12 Inflation inflation
local name13 Population pop
local name14 Primary_Balance pb_gdp
local name15 Real_2015_Dollar_GDP gdp_real
local name16 Percent_Military_Personnel milper_pop 
local name17 Real_2015_Dollar_Private_Consumption privcons_real
local name18 Real_2015_Dollar_Private_Investment privinv_real

// Taxes
local name19 Top_Income_Tax_Rate tax_rate_topinc
local name20 Top_Inheritance_Tax_Rate tax_rate_inherit

// Booms
local name21 Military_Boom_Initial_Year boom_start
local name22 Military_Boom_Narratively_Identified boom


local keepvars
foreach var of varlist * {
	local lbl: variable label `var'
	
	// Convert to our naming convention
	forvalues i = 1/`nnames' {
		tokenize `name`i''
				
		if "`lbl'" == "`1'" {
			rename `var' `2'
			local keepvars `keepvars' `2'
		}
	}
}
keep iso year `keepvars'
order *, alphabetic
order iso year


local name1 Interior_and_Economic_Affairs_Broad	bgt_brd_econinfra
local name2 Education_and_Research_Broad bgt_brd_edures
local name3 Health_Welfare_Work_and_Social_Affairs_Broad bgt_brd_soc
local name4 Military_Affairs_Broad bgt_brd_mil
local name5 Total_Spending_Broad bgt_brd_total
local name6 Foreign_Affairs_Broad bgt_brd_fa
local name7 Central_Government_Finance_Broad bgt_brd_cgfin

* Gen other budgets
local vars bgt_brd_econinfra bgt_brd_edures bgt_brd_soc bgt_brd_fa bgt_brd_cgfin

gen bgt_other = 0
foreach var in `vars' {
	gen _tmp = `var'
	replace _tmp = 0 if _tmp == .
	replace bgt_other = bgt_other + _tmp
	drop _tmp
}
replace bgt_other = . if bgt_other == 0
gen milratio_hannes = bgt_brd_mil / gdp_nom

keep iso year milratio_hannes

gen country_hannes = 1

save "${DIR_DATA_PROCESSED}/common/budgets.dta", replace
