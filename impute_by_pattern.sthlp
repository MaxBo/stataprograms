{smcl}
{* *! version 1.0  7 Dec 2019}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "impute_by_pattern##syntax"}{...}
{viewerjumpto "Description" "impute_by_pattern##description"}{...}
{viewerjumpto "Options" "impute_by_pattern##options"}{...}
{viewerjumpto "Remarks" "impute_by_pattern##remarks"}{...}
{viewerjumpto "Examples" "impute_by_pattern##examples"}{...}
{title:Title}
{phang}
{bf:impute_by_pattern} {hline 2} <Insert title>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:impute_by_pattern}
{depvar} {indepvars}
[weight]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt mod:eltype(string)}} modeltype (Default: logit) {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
The variable `depvar' will be imputed using the
independent variables in `indepvars' to estimate and predict variable to impute.
It uses mi impute.
So all values of `depvar' which are missing (.) will be imputed. 
Qualified missings (.a, .b, ...) are not imputed.
First the whole expression given in `indepvars' is used to impute. 
If there are pattern of missing values, some cases will not be imputed in the first step.
Therefore, impute_by_pattern analyses the pattern of missing values. 
It first uses the most frequent pattern of existing values, imputes the depending variable 
and then continues with the less frequent pattern, until all variables are used.


{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt mod:eltype(string)}    {p_end}


{marker examples}{...}
{title:Examples}
impute_by_pattern zwd_f i.taetigkeit dauer_akt i.w_sts_gr ln_km i.arbwo i.hvm [pweight=W_GEW], ///
  modeltype(mlogit)
 

{pstd}


{title:Author}
{p}


