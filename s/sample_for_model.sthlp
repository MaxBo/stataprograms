{smcl}
{* *! version 1.0 28 Dec 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "C:\Users\Max\ado\personal\s\sample_for_model##syntax"}{...}
{viewerjumpto "Description" "C:\Users\Max\ado\personal\s\sample_for_model##description"}{...}
{viewerjumpto "Options" "C:\Users\Max\ado\personal\s\sample_for_model##options"}{...}
{viewerjumpto "Remarks" "C:\Users\Max\ado\personal\s\sample_for_model##remarks"}{...}
{viewerjumpto "Examples" "C:\Users\Max\ado\personal\s\sample_for_model##examples"}{...}
{title:Title}
{phang}
{bf:C:\Users\Max\ado\personal\s\sample_for_model} {hline 2} Prepare the sample for a clogit-model

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:C:\Users\Max\ado\personal\s\sample_for_model}
varlist(min=4
fv)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:sample_for_model} prepares the dataset to estimate clogit-models.

{pstd}
 It expects the dataset to be in "Long-Format" with one row per observation and alternative

{pstd}
 It takes the following variables as input:

{pstd}
  {cmd:casevar}: the variable that identifies the case (e.g. a Person_ID)	 

{pstd}
  {cmd:choicevar}: a boolen-variable that marks the chosen alternative

{pstd}
  {cmd:depvar}: a factor variable that describes the alternatives
	
  {cmd:indeps}: one or more factor variables as covariates

{pstd}
 It creates dummy-variables in the form:
 depvar__depvalue__indepvar__indepvalue, e.g.
 ncars__2__inc__4

{pstd}
 As stata variables must not exceed 32 letters, take care to use not too long variable names

{pstd}
 It creates a boolean-variable {cmd:sample}

{pstd}
 It adds observations with negative casevars for all combinations 
 of the dependent and independet variables, marked with the new variable {cmd:prediction_sample}.

{pstd}
 and it returns two varlists as results:

{pstd}
 r(dummyvars): the varlist of the dummy-variables created, excluding variables for baselevels. 
 This varlist can be used in the clogit-command.

{pstd}
 r(constraintvars): the varlist of dummy-variables not created, because they 
 refer to the baselevel of the dependent or indipendent variables, but that have observations.
 for prediction, this varlist can be included with coefficients 0.

{pstd}
  the varlists can be written to an excel-file using:

{pstd}
  putexcel set "resultcoeff_fn", modify sheet(car_availability, replace)

{pstd}
quietly {
	
	putexcel B1 = "dummyvar"
	
	putexcel C1 = "Coef."
	
	local r = 2
	
	foreach v of local constraintvars {
		
		putexcel B = ""
		
		putexcel C = 0
		
		local ++r
		
	}
	
	matrix b = e(b)'
	
	putexcel A = matrix(b), rownames nformat(number_d2)
	
}

{pstd}

{pstd}
 The prediction can be made using:

{pstd}
predict pr if prediction_sample & sample

{pstd}
predict xb if prediction_sample & sample, xb

{pstd}
* setze bei Alternativen mit einer Auswahlwahrscheinlichkeit von 0 
pr auf 0 bzw. den Coeffizienten xb auf -99999

{pstd}
replace pr = 0 if pr == . & prediction_sample 

{pstd}
replace xb = -99999 if xb == . & prediction_sample 

{pstd}

{pstd}

{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}


{marker examples}{...}
{title:Examples}
{pstd}

{pstd}

{pstd}
sample_for_model HP_ID choice taet_id ibn.alkl_han i.han_reg i.an_schiene

{pstd}
* generiere dummy-Variablen choice_x für die Taetigkeit der Person
tab taetigkeit, generate(choice)

{pstd}
* Konvertiere ins Long-Format, so dass jede Kombination aus HP_ID und taet_id 
* erstellt wird. taet_id kommt aus dem _x in choice_x.

{pstd}
* Die Zeile mit der gewählten Tätigkeit der Person wird mit choice=1 gekennzeichnet.
reshape long choice, i(HP_ID) j(taet_id)

{pstd}
sample_for_model HP_ID choice taet_id ibn.alkl_han i.han_reg i.an_schiene

{pstd}
local dummyvars "r(dummyvars)"

{pstd}
local constraintvars "r(constraintvars)"

{pstd}

{pstd}
* Schätze das clogit-Modell für die Haupttätigkeit

{pstd}
clogit choice dummyvars if sample, group(HP_ID)

{pstd}


{title:References}
{pstd}

{pstd}

{pstd}

{pstd}


{title:Author}
{p}

Max Bohnet, Gertz Gutsche Rümenapp GbR.

Email {browse "mailto:bohnet@ggr-planung.de":bohnet@ggr-planung.de}



{title:See Also}
Related commands:

