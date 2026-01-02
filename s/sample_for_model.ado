program define sample_for_model, rclass

version 14

syntax varlist(min=4 fv) [if] [in]

gettoken casevar varlist : varlist
gettoken choicevar varlist : varlist
gettoken depvar indeps : varlist

fvrevar `indeps', list
local vlist `r(varlist)'
fvexpand `indeps'
local fullvlist `r(varlist)'
di "`fullvlist'"
capture drop if full_prediction_sample == 1
dropvars sample full_prediction_sample prediction_sample rowid_prediction_sample
dropvars `depvar'_*
gen byte sample = 1 `if' `in'

foreach indepvar of varlist `vlist' {
    replace sample = 0 if `indepvar' >= .
}

marksample touse
local dummyvars = ""
local constraintvars = ""

/// create prediction sample
qui tab `depvar' if `choicevar' == 1 & `touse', matrow(ALTERNATIVES)
local n_alternatives = rowsof(ALTERNATIVES)
local ncombinations = `n_alternatives'

foreach indepvar of varlist `vlist' {
    qui tab `depvar' `indepvar' if `choicevar' == 1 & `touse', matcol(COLS)
	local ncols = colsof(COLS)
	local ncombinations = `ncombinations' * `ncols'
}
local old_obs = _N
local new_obs = `old_obs' + `ncombinations'
set obs `new_obs'
gen byte full_prediction_sample = (sample == .)
gen byte prediction_sample = full_prediction_sample
gen rowid_prediction_sample = (_n - `old_obs') -1 if full_prediction_sample
// generate casevar with negative values
replace `casevar' = - floor(rowid_prediction_sample / `n_alternatives') - 1 if full_prediction_sample
replace `depvar' = mod(rowid_prediction_sample, `n_alternatives') + 1 if full_prediction_sample
mkmat `depvar' if full_prediction_sample == 1
mata: D = st_data(., "`depvar'", "full_prediction_sample")

forvalues i = 1/`ncols' {
	local depvalue = ALTERNATIVES[`i', 1]
	mata: _editvalue(D, `i', `depvalue')
}
// write values back
mata: st_view(V=., ., "`depvar'", "full_prediction_sample")
mata: V[., .] = D

local ncombinations = `n_alternatives'

// identify alternatives which have more than one non-determinating variable

matrix TOTALLY_DETERMINATED = J(`n_alternatives', 1, 0)
foreach indepvar of varlist `vlist' {
    tab `depvar' `indepvar' if `choicevar' == 1 & `touse', matcell(CELLS) matrow(ROWS) matcol(COLS)
	local nrows = rowsof(CELLS)
	local ncols = colsof(CELLS)

	matrix DETERMINATED = J(`nrows', `ncols', 0)
	///Loop over the categories and look for alternatives, that are categories, that totally determines an alternative
	forvalues j = 1/`ncols' {
		local several_alternatives = 0
		local indepvalue = COLS[1, `j']
		forvalues i = 1/`nrows' {
			if CELLS[`i', `j'] > 0 {
				local several_alternatives = `several_alternatives' + 1
				local altnum = `i'
			}
		}
		
		if `several_alternatives' == 1 {
			local vl : label (`depvar') `altnum'
			matrix DETERMINATED[`altnum', `j'] = 1
		}			
	}

	mata: DETERMINATED = st_matrix("DETERMINATED"); /*
	    */CELLS = st_matrix("CELLS"); /*
	    */TOTALLY_DETERMINATED = st_matrix("TOTALLY_DETERMINATED"); /*
	    */POS_CELLS = (CELLS :> 0);/*
	    */ALT_DET = rowsum(DETERMINATED);/*
	    */ALT_DET2 = (rowsum(POS_CELLS) :<= 1);/*
	    */TOTALLY = (( ALT_DET :* ALT_DET2)) :> 0;/*
	    */TOTALLY_DETERMINATED = TOTALLY_DETERMINATED :| TOTALLY ;/*
	    */st_matrix("ALT_DET", ALT_DET);/*
	    */st_matrix("ALT_DET2", ALT_DET2);/*
	    */st_matrix("TOTALLY_DETERMINATED", TOTALLY_DETERMINATED)
}
// exclude these alternatives, because they are totally determinated by one or several variables
matrix list TOTALLY_DETERMINATED


foreach indepvar of varlist `vlist' {
	di "`indepvar'"
    tab `depvar' `indepvar' if `choicevar' == 1 & `touse', matcell(CELLS) matrow(ROWS) matcol(COLS)
	local nrows = rowsof(CELLS)
	local ncols = colsof(CELLS)
	matrix list ROWS
	matrix list COLS

	// make prediction sample
	replace `indepvar' = mod(floor(rowid_prediction_sample / `ncombinations'), `ncols') + 1 if full_prediction_sample
	local ncombinations = `ncombinations' * `ncols'
	mkmat `indepvar' if full_prediction_sample == 1
	mata: D = st_data(., "`indepvar'", "full_prediction_sample")

	forvalues j = 1/`ncols' {
		local indepvalue = COLS[1, `j']
		mata: _editvalue(D, `j', `indepvalue')
	}
	// write values back
	mata: st_view(V=., ., "`indepvar'", "full_prediction_sample")
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

		if (`several_alternatives' == 1) {
			local vl : label (`depvar') `altnum'
			matrix DETERMINATED[`altnum', `j'] = 1
			// for estimation, exclude all alternatives from sample
			qui replace sample = 0 if `indepvar' == `indepvalue'
			// for prediction, exclude the non-chosen-alternatives from prediction_sample
			qui replace prediction_sample = 0 if `indepvar' == `indepvalue' & `depvar' != `altnum'
		}
		forvalues i = 1/`nrows' {
			if TOTALLY_DETERMINATED[`i', 1] == 1 {
				qui replace sample = 0 if `indepvar' == `indepvalue' & `depvar' == `i'
			}
			
			local depvalue = ROWS[`i', 1]
			// check if the variable has 'a baselevel defined
			local has_base = strrpos("`fullvlist'", "`indepvalue'b.`indepvar'")
			if CELLS[`i', `j'] > 0 {
				local dummyvar `depvar'__`depvalue'__`indepvar'__`indepvalue'
				if `i' != `baselevel' & DETERMINATED[`i', `j'] == 0 & TOTALLY_DETERMINATED[`i', 1] == 0 & `has_base' == 0 {
					qui gen byte `dummyvar' = (`depvar' == `depvalue') * (`indepvar' == `indepvalue')
					local dummyvars `dummyvars' `dummyvar'
				}
				else {
					local constraintvars `constraintvars' `dummyvar'
				}
			}
			else if CELLS[`i', `j'] == 0 {
				// no observations, so exclude from sample, don't add do constraintvars, so the coefficient will be -9999999
			    qui replace sample = 0 if `indepvar' == `indepvalue' & `depvar' == `depvalue'
				qui replace prediction_sample = 0 if `indepvar' == `indepvalue' & `depvar' == `depvalue'
			}
		}

	}

	matrix list DETERMINATED
	matrix list CELLS
}


qui corr `dummyvars' if sample & choice
matrix CORR = r(C)
local newvarlist
local nvars : word count `dummyvars'
forval i = 1/`nvars' {
    local keep = 1
    forval j = 1/`=`i'-1' {
        scalar corr_ij = CORR[`i',`j']
        if abs(corr_ij) == 1 {
            local keep = 0
            continue, break
        }
    }
	local var: word `i' of `dummyvars'
    if `keep' {
        local newvarlist `newvarlist' `var'
    }
	else {
		di "`var' is correlated, so it is excluded from dummyvars and added to constraintvars"
		local constraintvars `constraintvars' `var'
	}
}
local dummyvars `newvarlist'

return local dummyvars `"`dummyvars'"'
return local constraintvars `"`constraintvars'"'
end

/* START HELP FILE
title[Prepare the sample for a clogit-model]

desc[
 {cmd:sample_for_model} prepares the dataset to estimate clogit-models.
 
 It expects the dataset to be in "Long-Format" with one row per observation and alternative
 
 It takes the following variables as input:
   
  {cmd:casevar}: the variable that identifies the case (e.g. a Person_ID)	 
  
  {cmd:choicevar}: a boolen-variable that marks the chosen alternative

  {cmd:depvar}: a factor variable that describes the alternatives
	
  {cmd:indeps}: one or more factor variables as covariates
 
 It creates dummy-variables in the form:
 depvar__depvalue__indepvar__indepvalue, e.g.
 ncars__2__inc__4
 
 As stata variables must not exceed 32 letters, take care to use not too long variable names
 
 It creates a boolean-variable {cmd:sample}
 
 It adds observations with negative casevars for all combinations 
 of the dependent and independet variables, marked with the new variable {cmd:prediction_sample}.
 
 and it returns two varlists as results:
 
 r(dummyvars): the varlist of the dummy-variables created, excluding variables for baselevels. 
 This varlist can be used in the clogit-command.

 r(constraintvars): the varlist of dummy-variables not created, because they 
 refer to the baselevel of the dependent or indipendent variables, but that have observations.
 for prediction, this varlist can be included with coefficients 0.
  
  the varlists can be written to an excel-file using:
  
  putexcel set "resultcoeff_fn", modify sheet(car_availability, replace)
  
quietly {
	
	putexcel B1 = "dummyvar"
	
	putexcel C1 = "Coef."
	
	local r = 2
	
	foreach v of local constraintvars {
		
		putexcel B`r' = "`v'"
		
		putexcel C`r' = 0
		
		local ++r
		
	}
	
	matrix b = e(b)'
	
	putexcel A`r' = matrix(b), rownames nformat(number_d2)
	
}


 The prediction can be made using:

predict pr if prediction_sample

predict xb if prediction_sample, xb

* setze bei Alternativen mit einer Auswahlwahrscheinlichkeit von 0 
pr auf 0 bzw. den Coeffizienten xb auf -99999

replace pr = 0 if pr == . & full_prediction_sample 

replace xb = -99999 if xb == . & full_prediction_sample 

 
 
]



example[

sample_for_model HP_ID choice taet_id ibn.alkl_han i.han_reg i.an_schiene

* generiere dummy-Variablen choice_x für die Taetigkeit der Person
tab taetigkeit, generate(choice)

* Konvertiere ins Long-Format, so dass jede Kombination aus HP_ID und taet_id 
* erstellt wird. taet_id kommt aus dem _x in choice_x.

* Die Zeile mit der gewählten Tätigkeit der Person wird mit choice=1 gekennzeichnet.
reshape long choice, i(HP_ID) j(taet_id)

sample_for_model HP_ID choice taet_id ibn.alkl_han i.han_reg i.an_schiene

local dummyvars "r(dummyvars)"

local constraintvars "r(constraintvars)"


* Schätze das clogit-Modell für die Haupttätigkeit

clogit choice dummyvars if sample, group(HP_ID)

]

author[Max Bohnet]
institute[Gertz Gutsche Rümenapp GbR]
email[bohnet@ggr-planung.de]

return[dummyvars the varlist of dummy-variables created to use in clogit]
return[constraintvars the varlist of dummy-variables constraint to 0, which are not generated]

freetext[]

references[
]

seealso[
]

END HELP FILE */
