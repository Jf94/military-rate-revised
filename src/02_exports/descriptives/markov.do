cap program drop save_markov
program define save_markov
	syntax, ///
		[type(string)] ///
		[filepath(string)]
		
			
	local ally_neg_l "\(a^+_{i,j,t}=0\)"
	local allyt1_neg_l "\(a^+_{i,j,t+1}=0\)"
	
	local ally_pos_l "\(a^+_{i,j,t}=1\)"
	local allyt1_pos_l "\(a^+_{i,j,t+1}=1\)"
	
	
	local rival_neg_l "\(a^-_{i,j,t}=0\)"
	local rivalt1_neg_l "\(a^-_{i,j,t+1}=0\)"
	
	local rival_pos_l "\(a^-_{i,j,t}=1\)"
	local rivalt1_pos_l "\(a^-_{i,j,t+1}=1\)"
		
	* Assumes: xtset dyadid year, F_`type' is 0/1
	gen byte `type'_t   = F_`type'
	gen byte `type'_tp1 = F.F_`type'
	drop if missing(`type'_t, `type'_tp1)

	* Counts matrix M (rows = t, cols = t+1) in natural 0/1 order
	tabulate `type'_t `type'_tp1, matcell(M)

	* Convert to row-stochastic P (probabilities of t+1 given t)
	matrix P = J(2,2,.)
	forvalues r = 1/2 {
		scalar rs = M[`r',1] + M[`r',2]
		matrix P[`r',1] = M[`r',1] / rs
		matrix P[`r',2] = M[`r',2] / rs
	}

	matrix P = P * 100
	matrix rownames P = "``type'_neg_l'" "``type'_pos_l'"
	matrix colnames P = "``type't1_neg_l'" "``type't1_pos_l'"

	* Show and export
	* --- prepare safe LaTeX labels (escape underscores) ---
	local cns : colnames P
	local rns : rownames P
	local c1 : word 1 of `cns'
	local c2 : word 2 of `cns'
	local r1 : word 1 of `rns'
	local r2 : word 2 of `rns'

	* --- pull values and format ---
	scalar p11 = P[1,1]
	scalar p12 = P[1,2]
	scalar p21 = P[2,1]
	scalar p22 = P[2,2]

	local f11 : display %9.2f p11
	local f12 : display %9.2f p12
	local f21 : display %9.2f p21
	local f22 : display %9.2f p22

	* --- write LaTeX file ---
	local outfile "`filepath'"
	file close _all
	file open F using "`outfile'", write replace
	file write F " & `c1' & `c2' \\" _n
	file write F "\hline" _n
	file write F "`r1' & `f11'\% & `f12'\% \\" _n
	file write F "`r2' & `f21'\% & `f22'\% \\" _n
	file close F

	display as result "Wrote LaTeX table to `outfile'. Use: \input{`outfile'}"
end


foreach frequency in annual decade {
	foreach sample in full recent {
		foreach type in ally rival {
			use "${DIR_DATA_PROCESSED}/common/scores.dta", clear
						
			if "`sample'" == "recent" {
				keep if year >= 1977
			}

			egen dyadid = group(iso1 iso2)
			
			
			if "`frequency'" == "decade" {
				tostring year, gen(decade)
				replace decade = substr(decade, 1, 3)
				destring decade, replace
				
				sort dyadid year
				collapse (lastnm) F_*, by(dyadid decade)
				
				xtset dyadid decade
			}
			else if "`frequency'" == "annual" {
				xtset dyadid year
			}			

			
			save_markov, ///
				type(`type') ///
				filepath("${DIR_DATA_EXPORTS}/descriptives/markov/sample[`sample']_type[`type']_frequency[`frequency'].tex")
		}
	}
}
