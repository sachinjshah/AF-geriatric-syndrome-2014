%LET path = C:\Users\sachi\Box Sync\AF frailty;
libname in "&path\data\AF frailty 2014 crosssection";
libname out "&path\tables and figures";

%INCLUDE "C:\Users\sachi\Box Sync\data\!Macros\MARGINS.sas";

options nofmterr;

* set weight variable that using nuring home weights for HRS;
%LET wt = R12WTCRNH; 

data af; set in.analytic_file_v2;
** create domain variables;
* in the incoming file, cohort = 1 is assigned to participants with AF and 
cohort = . is assinged to participants without AF;
* recode below to create non missing levels;
if cohort = . then af = 0;
if cohort = . then cohort = 2; 

** US guideline recs;
guideline19 = 0;
if ragender = 1 and chadsvasc_collapsed ge 2 then guideline19 = 1;
if ragender = 2 and chadsvasc_collapsed ge 3 then guideline19 = 1;

guideline14 = 0;
if chadsvasc_collapsed ge 2 then guideline14 = 1;

GERI_SYN_COUNT2 = (FALLS_2 ne 0) + (ADL ne 1) + (IADL ne 1) + (cogfunction ne 1) + (INCONTINENT = 1) + (FRAIL = 1) + (WEIGHT_LOSS = 1);
if FALLS_2 = . OR ADL = . or IADL = . or cogfunction = . or INCONTINENT = . or frail = . or WEIGHT_LOSS = . then GERI_SYN_COUNT2 = .;
run;


/*------------------------------------------------------
	
FIGURE 1: COUNT OF GS X AC USE version 2

--------------------------------------------------------*/

** limit the dataset to those with AF and with AC use data;
data af2; set af; 
where af = 1 and BLOOD_THINNER ne .N ;
log_GERI_SYN_COUNT2 = log(GERI_SYN_COUNT2+0.1);
sq_GERI_SYN_COUNT2 = GERI_SYN_COUNT2 ** 2;
run;

** base model;
proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT2 / 
		dist = bin link = log;
run;

** assess functional form;

* linear 
BIC (smaller is better)   982.5082  / 928.4919 ;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT2 / 
		dist = bin link = log;
run;

* categorical
BIC (smaller is better)   1006.4442 / 957.6770
 ;
proc genmod data = af2 descending; 
class GERI_SYN_COUNT2 (ref = "0");
model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT2 / 
		dist = bin link = log;
run;

*quadratic
BIC (smaller is better)   987.0662  / 933.5854;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT sq_GERI_SYN_COUNT2 / 
		dist = bin link = log;
run;

*log
BIC (smaller is better)   989.0107 / 933.2778 ;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc log_GERI_SYN_COUNT2 / 
		dist = bin link = log;
run;

** set up data for marginal effects;
data _me; 
do GERI_SYN_COUNT2 = 0 to 7 by 0.1;
output;
end;
run;

** marginal effects estimation;
%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
            model     	= chadsvasc GERI_SYN_COUNT2,
            dist      	= binomial,
			link 	  	= log,
			effect    	= GERI_SYN_COUNT2,
            options   	= cl desc nomodel)

%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
			class		= GERI_SYN_COUNT2,
            model     	= chadsvasc GERI_SYN_COUNT2,
            dist      	= binomial,
			link 	  	= log,
			margins    	= GERI_SYN_COUNT2,
            options   	= cl desc nomodel)

%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
            model     	= chadsvasc GERI_SYN_COUNT2,
            dist      	= binomial,
			link 	  	= log,
			margins    	= GERI_SYN_COUNT2,
			margindata 	= _me,
            options   	= cl desc nomodel)

data out.gs_count_x_AC_20200804;
set _margins;
keep estimate geri_syn_count2 lower upper;
run;

