program define sample_for_model, rclass

version 14

syntax varlist(min=3 fv) [if] [in], [MINConstraintno(integer 1)]

gettoken casevar varlist : varlist
gettoken depvar indeps : varlist

fvrevar `indeps', list
local vlist `r(varlist)'
fvexpand `indeps'
local fullvlist `r(varlist)'
di "`fullvlist'"
capture drop if prediction_sample == 1
dropvars sample prediction_sample rowid_prediction_sample
dropvars `depvar'_*
gen byte sample = 1

marksample touse
local dummyvars = ""

/// create prediction sample
qui tab `depvar' if choice == 1 & `touse', matrow(ALTERNATIVES)
local n_alternatives = rowsof(ALTERNATIVES)
local ncombinations = `n_alternatives'

foreach indepvar of varlist `vlist' {
    qui tab `depvar' `indepvar' if choice == 1 & `touse', matcol(COLS)
	local ncols = colsof(COLS)
	local ncombinations = `ncombinations' * `ncols'
}
local old_obs = _N
local new_obs = `old_obs' + `ncombinations'
set obs `new_obs'
gen byte prediction_sample = (sample == .)
replace sample = 1 if sample == .
gen rowid_prediction_sample = (_n - `old_obs') -1 if prediction_sample
// generate casevar with negative values
replace `casevar' = - floor(rowid_prediction_sample / `n_alternatives') - 1 if prediction_sample
replace `depvar' = mod(rowid_prediction_sample, `n_alternatives') + 1 if prediction_sample
mkmat `depvar' if prediction_sample == 1
mata: D = st_data(., "`depvar'", "prediction_sample")

forvalues i = 1/`ncols' {
	local depvalue = ALTERNATIVES[`i', 1]
	mata: _editvalue(D, `i', `depvalue')
}
// write values back
mata: st_view(V=., ., "`depvar'", "prediction_sample")
mata: V[., .] = D

local ncombinations = `n_alternatives'

foreach indepvar of varlist `vlist' {
    tab `depvar' `indepvar' if choice == 1 & `touse', matcell(CELLS) matrow(ROWS) matcol(COLS)
	local nrows = rowsof(CELLS)
	local ncols = colsof(CELLS)
	matrix list ROWS
	matrix list COLS

	replace `indepvar' = mod(floor(rowid_prediction_sample / `ncombinations'), `ncols') + 1 if prediction_sample
	local ncombinations = `ncombinations' * `ncols'
	mkmat `indepvar' if prediction_sample == 1
	mata: D = st_data(., "`indepvar'", "prediction_sample")

	forvalues j = 1/`ncols' {
		local indepvalue = COLS[1, `j']
		mata: _editvalue(D, `j', `indepvalue')
	}
	// write values back
	mata: st_view(V=., ., "`indepvar'", "prediction_sample")
	mata: V[., .] = D

	
	
	///Loop over the categories and look for categories, that totally determines an alternative
	matrix DETERMINATED = J(`nrows', `ncols', 0)
	forvalues j = 1/`ncols' {
		local max_values = 0
		local baselevel = -1
		local several_alternatives = 0
		local indepvalue = COLS[1, `j']
		forvalues i = 1/`nrows' {
			if CELLS[`i', `j'] > 0 {
				local several_alternatives = `several_alternatives' + 1
				local altnum = `i'
				/// take the most frequent alternative as baselevel
				if CELLS[`i', `j'] > `max_values' {
					local max_values = CELLS[`i', `j']
					local baselevel = `i'
				}
			}
		}
			
		if `several_alternatives' == 1 {
			local vl : label (`depvar') `altnum'
			matrix DETERMINATED[`altnum', `j'] = 1
			qui replace sample = 0 if `indepvar' == `indepvalue' & `depvar' != `altnum'
		}
		forvalues i = 1/`nrows' {
			local depvalue = ROWS[`i', 1]
			// check if the variable has a baselevel defined
			local has_base = strrpos("`fullvlist'", "`indepvalue'b.`indepvar'")
			if `i' != `baselevel' & DETERMINATED[`i', `j'] == 0 & CELLS[`i', `j'] > 0 & `has_base' == 0 {
				local dummyvar `depvar'_`depvalue'_`indepvar'_`indepvalue'
				qui gen byte `dummyvar' = (`depvar' == `depvalue') * (`indepvar' == `indepvalue')
				local dummyvars `dummyvars' `dummyvar'
			}
			else if CELLS[`i', `j'] == 0 {
			    qui replace sample = 0 if `indepvar' == `indepvalue' & `depvar' == `depvalue'
			}
		}

	}

	matrix list DETERMINATED
	matrix list CELLS
}
return local dummyvars `"`dummyvars'"'
end