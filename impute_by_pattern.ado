program define impute_by_pattern

version 10

syntax varlist(min=2 fv) [pweight], [MODeltype(string)]

gettoken depvar indepsvars : varlist
local nvars: word count `indeps'
/* Default modeltype */
if "`modeltype'" == "" local modeltype "logit"

/* get the variables used in the varlist indepsvars without factor variables */
fvrevar `indepsvars', list
local vlist `r(varlist)'

/* prepare the dataset for missing value analysis */
capture mi unset
mi set wide
mi register imputed `depvar'

capture {
	preserve
    /* get the different patterns of missing values and store it into 
	a matrix VARS, where the column name refer to the variables 
	that are at least missing for one case. The rows contain the pattern
	of missing values, starting with the most frequent pattern.*/
	mi misstable patterns `vlist' if `depvar' == . , exmiss frequency replace clear
	if r(N_incomplete) > 0 {
		local differnt_variables `r(vars)' 
		gsort -_freq
		local vars 
		foreach thing of local differnt_variables {
			capture unab Thing : `thing'  
			if _rc == 0 local vars `vars' `Thing'
		}
		mkmat `vars', matrix(VARS)	
	}
	restore
	
	/* if there are missing values */
	if "´vars'" != "" {
	    /* loop throut the different pattern in the rows */
		local nrows = rowsof(VARS)
		forvalues i = 1/`nrows' {
		   /* generate the list of independent variables for the pattern, 
		   including only (factor/interaction) variables 
		   that are not missing in the pattern*/
		   local fvarlist
		   di "Pattern `i'"
		   foreach fv in `indepsvars' {
			 fvrevar `fv', list
			 local fv_elems `r(varlist)'
			 /* use it by default ...*/
			 local use_fv 1
			 foreach elem in `fv_elems' {
			    /* except the variable (or one of the interaction variables)
				are marked as missing in the pattern */
				capture if VARS[`i', "`elem'"] == 0 local use_fv 0
			 }
			 if `use_fv' == 1 local fvarlist `fvarlist' `fv'
		   }

		   /* for the first pattern, add a new imputation*/
		   if `i'==1 local addreplace "add(1)"
		   /* for the next ones, replace the existing imputation */
		   else local addreplace "replace"
		   
		   local cmd mi impute `modeltype' `depvar' `fvarlist' [`weight' `exp'], ///
			  `addreplace' rseed(12343) augment dots force
		   di "`cmd'"
		   `cmd'
		   /* update the imputed values in the main dataset */
		   replace `depvar' = _1_`depvar' if `depvar' == . & _1_`depvar' < .
		}
	}
}
/* clean up */
mi unset, asis
drop _1_`depvar' _mi_miss

end