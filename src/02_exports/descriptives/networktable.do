local stats min max mean p25 median p75



foreach sample in full post1976 {
	foreach type in ally rival {		
		use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
		collapse (sum) F_*, by(iso1 year)
		
		if "`sample'" == "post1976" {
			keep if year > 1976
		}
		
		// Generate stats
		local collapse
		foreach stat in `stats' {
			local collapse `collapse' (`stat') `stat'=F_`type'
		}
		collapse `collapse'

		// Write file
		file open f using "${DIR_DATA_EXPORTS}/descriptives/networktable/`type'_`sample'.tex", write replace

		local row
		local add
		foreach stat in `stats' {
			local statval = round(`stat'[1], 0.01)
			
			local row `row' `add' `statval'
			local add " & "
		}
		
		file write f "`row'"
		
		file close f
	}	
}


