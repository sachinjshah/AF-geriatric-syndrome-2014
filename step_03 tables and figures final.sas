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
run;

proc contents; run;

/*------------------------------------------------------

Table 1: Cohort characterisitcs

--------------------------------------------------------*/

*median age and IQR;
PROC SURVEYMEANS  data = af median Q1 Q3; 
	weight &wt;
	cluster secu;
	strata stratum;
	domain cohort;
	var age;
	run;

** to calculate median CHADSVASC score by cohort;
PROC SURVEYMEANS  data = af median Q1 Q3; 
	weight &wt;
	cluster secu;
	strata stratum;
	domain cohort;
	var CHADSVASC;
	run;

** need to recode since there are no 0s in the AF cohort
	the missing values create an error in the PROC SURVEYFREQ analysis.
	This recode only affects the unmatched HRS cohort;
data af; set af;
if CHADSVASC = 0 then CHADSVASC = 1;
run;

** TABLE 1;
PROC SURVEYFREQ data = af missing;
ods output CrossTabs = table1_cross ChiSq = table1_p; ** output to excel file for figures;
	weight &wt;
	strata stratum;
	cluster secu;
tables  cohort * (
RAGENDER MARRIED LIVES_ALONE EDU RARACEM RAHISPAN
op FAIR_POOR_HEALTH DEPRESSED EVER_HF HTN
STROKE DM EVER_MI EVER_ANGINA LUNG_EVER CANCER_EVER CHADSVASC 
guideline19 guideline14  BLOOD_THINNER ONURSHM)
 /  row chisq nocellpercent nowt nototal cl(type=cp);
run;
ods output close;

** clean up data to export;
data table1_cross; set table1_cross;
level = sum(of RAGENDER MARRIED LIVES_ALONE EDU RARACEM RAHISPAN
op FAIR_POOR_HEALTH DEPRESSED EVER_HF HTN
STROKE DM EVER_MI EVER_ANGINA LUNG_EVER CANCER_EVER CHADSVASC guideline19 guideline14 BLOOD_THINNER);

drop RAGENDER MARRIED LIVES_ALONE EDU RARACEM RAHISPAN
op FAIR_POOR_HEALTH DEPRESSED EVER_HF HTN
STROKE DM EVER_MI EVER_ANGINA LUNG_EVER CANCER_EVER CHADSVASC guideline19 guideline14 BLOOD_THINNER _: F_:; ** clean up extraneous variables;
* if matched = 0 then delete; ** drop the sections that are not relevant;
run;

* save only the test characteristics I need for Table 1;
data table1_p; set table1_p;
if label1 = "Pr > ChiSq"; 
run;

*export to excel to build table;
proc export 
  data=work.table1_cross
  dbms=xlsx 
  outfile="&path\tables and figures\table1cross.xlsx" 
  replace;
run;

/*------------------------------------------------------

TABLE 2: PREVALENCE OF GERIATRIC SYNDROMES

--------------------------------------------------------*/

** to calculate median COUNT of geri syndromes;
PROC SURVEYMEANS data = af median Q1 Q3; 
	weight &wt;
	cluster secu;
	strata stratum;
	domain af;
	var GERI_SYN_COUNT;
	run;

** to calculate the prevalence of individual geriatric syndromes;
%macro prev(name);
data _t; set af;
if &name = . then cohort = 2;
run;

PROC SURVEYFREQ data = _t missing;
	ods output CrossTabs = table2_cross_&name;
	weight &wt;
	strata stratum;
	cluster secu;
	tables  cohort * &name
 /  row nocellpercent nowt nototal cl(type=cp) ;
run; 
%mend;

%prev(falls_2);
%prev(adl);
%prev(iadl);
%prev(INCONTINENT);
%prev(cogfunction);
%prev(GERI_SYN_COUNT);


data table2_cross;
set table2_cross:;
run;
** clean up ouput;
data table2_cross; set table2_cross;
level = sum(of falls_2 adl iadl INCONTINENT cogfunction GERI_SYN_COUNT);
drop falls_2 adl iadl INCONTINENT cogfunction _: F_: matched GERI_SYN_COUNT;
if cohort = 1;
run;

** save pertinent results to excel file for use in table 2;
proc export 
  data=work.table2_cross
  dbms=xlsx 
  outfile="&path\tables and figures\table2cross.xlsx" 
  replace;
run;


/*------------------------------------------------------
	
FIGURE 1: COUNT OF GS X AC USE version 2

--------------------------------------------------------*/

** limit the dataset to those with AF and with AC use data;
data af2; set af; 
where af = 1 and BLOOD_THINNER ne .N and GERI_SYN_COUNT ne .;
log_GERI_SYN_COUNT = log(GERI_SYN_COUNT+0.1);
sq_GERI_SYN_COUNT = GERI_SYN_COUNT ** 2;
run;

** base model;
proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT / 
		dist = bin link = log;
run;

** assess functional form;

* linear 
BIC (smaller is better)   982.5082   ;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT / 
		dist = bin link = log;
run;

* categorical
BIC (smaller is better)   1006.4442 
 ;
proc genmod data = af2 descending; 
class GERI_SYN_COUNT;
model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT / 
		dist = bin link = log;
run;

*quadratic
BIC (smaller is better)   987.0662  ;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc GERI_SYN_COUNT sq_GERI_SYN_COUNT / 
		dist = bin link = log;
run;

*log
BIC (smaller is better)   989.0107  ;

proc genmod data = af2 descending; 
	model BLOOD_THINNER = chadsvasc log_GERI_SYN_COUNT / 
		dist = bin link = log;
run;



** set up data for marginal effects;
data _me; 
do GERI_SYN_COUNT = 0 to 5 by 0.1;
output;
end;
run;

** marginal effects estimation;
%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
            model     	= chadsvasc GERI_SYN_COUNT,
            dist      	= binomial,
			link 	  	= log,
			effect    	= GERI_SYN_COUNT,
            options   	= cl desc nomodel)

%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
            model     	= chadsvasc GERI_SYN_COUNT,
            dist      	= binomial,
			link 	  	= log,
			margins    	= GERI_SYN_COUNT,
			margindata 	= _me,
            options   	= cl desc nomodel)

data out.gs_count_x_AC;
set _margins;
keep estimate geri_syn_count lower upper;
run;


/*------------------------------------------------------

FIGURE 2: GERIATRIC SYNDROMES AS PREDICTOR OF AC USE 

* notes in v6 on approach
--------------------------------------------------------*/


data af2; set af; 
* from full dataset remove those without af; 
where af = 1;

** recode levels so that all refernces levels are 1;
falls_2 = falls_2 + 1; 
INCONTINENT = INCONTINENT + 1;

* had to recode for the margins macro, for 
some reason it created errors with adl and iadl var name; 
zoom_a = adl; 
zoom_i = iadl;

* remove those with missing AC use data;
if BLOOD_THINNER in (0,1);
run;


/*---------------------------------
BASE MODEL, EFFECT ESTIMATE IN RR 
----------------------------------*/

%macro run_ar(syn, /*syndrome variable name*/
				name, /*display name*/
				_1, /* reference level*/
				_2, /* level 2*/
				_3 /* level 3*/);

ods output LSMeans = syn_AR_&syn Diffs = RR_&syn;
proc genmod data = af2 descending; 
	class &syn (ref="1");
	model BLOOD_THINNER = chadsvasc &syn / dist = bin link = log;
	lsmeans &syn / exp cl diff;
run;

data syn_AR_&syn
(rename =(ExpEstimate = Use LowerExp = LL UpperExp = UL));
set syn_AR_&syn;
length level $33.;
Syndrome = "&name";
if &syn = 1 then Level = "&_1";
if &syn = 2 then Level = "&_2";
if &syn = 3 then Level = "&_3";
drop StmtNo Effect zValue Probz Alpha Lower Upper &syn ;
run;

data rr_&syn
(rename =(ExpEstimate = RR LowerExp = LL UpperExp = UL));
set rr_&syn;
length comparison_level $33.;
length ref_level $33.;
if &syn = 1 then comparison_level= "&_1";
if &syn = 2 then comparison_level = "&_2";
if &syn = 3 then comparison_level = "&_3";

if _&syn = 1 then ref_level = "&_1";
if _&syn = 2 then ref_level = "&_2";
if _&syn = 3 then ref_level = "&_3";

drop StmtNo Effect alpha lower upper &syn _&syn;
Syndrome = "&name";
run;
%mend;

%run_ar(falls_2, Falls, No falls, Noninjurious falls, Injurious falls)
%run_ar(adl, ADL, ADL intact, ADL difficulty, ADL dependent)
%run_ar(IADL, IADL, IADL intact, IADL difficulty, IADL dependent)
%run_ar(INCONTINENT, Incontinence, Not incontinent, Incontinent)
%run_ar(cogfunction, Cognitive function, Cognitively intact, Cognitive impairment not dementia, Dementia)

** used to create a figure that is not in the final paper
to display the rate of AC us by GS level and its 95% CI;
data out.thinner_ar;
length Syndrome $18.;
set syn_ar:;
run;

** used to create a figure that is not in the final paper
to display the relateive rate of AC us by GS level and its 95% CI;
data out.thinner_rr;
length Syndrome $18.;
set rr_:;
run;

** intercept only model for population rate use of AC;
proc genmod data = af2 descending; 
	model BLOOD_THINNER = / dist = bin link = log;
run; ** baseline ac rate is e^-0.41 = 0.664;

** clean up;
proc datasets library = work nolist;
  delete syn_: rr_: table2_: _: ;
run;
quit;

/*---------------------------------------------
EFFECT ESTIMATE USING AVERAGE MARGINAL EFFECTS 
---------------------------------------------*/

** SAS margins macro;
%INCLUDE "C:\Users\sachi\Box Sync\data\!Macros\MARGINS.sas";

%macro margin_arr(syn, /*syndrome variable name*/
					name, /*display name*/
					_1, /* reference level*/
					_2, /* level 2*/
					_3 /* level 3*/);

%Margins(	data      	= af2,
            response  	= BLOOD_THINNER,
			class		= &syn.,
            model     	= chadsvasc &syn.,
            dist      	= binomial,
			link 	  	= log,
			margins    	= &syn.,
            options   	= cl desc diff nomodel)

data arr_&syn.;
set _diffs;
format p Best12.;
length level $33.;
length syndrome $18.;
left = substr(Comp, 1, 1) * 1;
right = substr(Comp, 5, 1) * 1;
p = Pr;
if right = 2 then level = "&_2";
if right = 3 then level = "&_3";
if left = 2 then delete;
syndrome = "&name";
drop _atlevel ChiSq Pr Comp Alpha left right;
run;

data p_&syn;
set _margins;
length level $33.;
length syndrome $18.;
UL = upper;
LL = lower;
syndrome = "&name";
if &syn = 1 then level = "&_1";
if &syn = 2 then level = "&_2";
if &syn = 3 then level = "&_3";
drop atlevel _mlevel alpha &syn upper lower _mu _atlevel ChiSq Pr;
run;

proc datasets library = work nolist;
  delete _: ;
run;
quit;

%mend;

%margin_arr(falls_2, Falls, No falls, Noninjurious falls, Injurious falls);
%margin_arr(zoom_a, ADL, ADL intact, ADL difficulty, ADL dependent);
%margin_arr(zoom_i, IADL, IADL intact, IADL difficulty, IADL dependent);
%margin_arr(INCONTINENT, Incontinence, Not incontinent, Incontinent);
%margin_arr(cogfunction, Cognitive function, Cognitively intact, Cognitive impairment not dementia, Dementia);

** output the average marginal effects;
data out.thinner_ame;
set arr_:;
label Diff = Diff;
Diff = Diff * -1; ** reverse sign b/c we want 2-1 not 1-2;
UL = Lower * -1;
LL = Upper * -1;
drop Upper Lower;
run;

** output predicted rate of AC use;
data out.thinner_predicted;
set P_:;
run;

/*
Figure results as a table
*/

data thinner_ame;
set out.thinner_ame;
AME_UL = UL;
AME_LL = LL;
AME = Diff;
drop UL LL StdErrDiff p Diff;
run;

proc sql;
create table tabular_fig_2 as
select * from out.thinner_predicted
left join thinner_ame
on thinner_predicted.syndrome = thinner_ame.syndrome and thinner_predicted.level = thinner_ame.level;
quit;

data tabular_fig_2;
set tabular_fig_2;
predicted_AC_use = estimate;
predicted_AC_use_UL = UL;
predicted_AC_use_LL = LL;

array _nums {*} _numeric_;
do i = 1 to dim(_nums);
  _nums{i} = round(_nums{i},.001);
end;
drop i;

drop StdErr estimate UL LL;
run;

proc export 
  data=work.tabular_fig_2
  dbms=xlsx 
  outfile="&path\tables and figures\tabular_fig_2.xlsx" ; 
  *need to delete old file, will not replace;
run;

data out.tabular_fig_2; set work.tabular_fig_2;
run;

** clean up;
proc datasets library = work;
  delete arr_: P_:;
run;
quit;

