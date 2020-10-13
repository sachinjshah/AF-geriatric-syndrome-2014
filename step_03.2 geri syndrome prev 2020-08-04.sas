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

ADL_WALK_EQUIP = (ADL_WALK_EQUIP = 1);

run;

/*------------------------------------------------------

TABLE 2: PREVALENCE OF GERIATRIC SYNDROMES

--------------------------------------------------------*/

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
%prev(frail);
%prev(WEIGHT_LOSS);
%prev(GERI_SYN_COUNT);
%prev(GERI_SYN_COUNT2);

%prev(ADL_BATH);%prev(ADL_BED);%prev(ADL_DRESS);%prev(ADL_EAT);%prev(ADL_TOILET); %prev(ADL_WALK); %prev(ADL_WALK_EQUIP);
%prev(G_IADL_MEAL); %prev(G_IADL_GROC); %prev(G_IADL_PHONE); %prev(G_IADL_MEDS); %prev(G_IADL_MONEY);

%prev(UNDERWEIGHT);

data table2_cross;
set table2_cross:;
run;
** clean up ouput;
data table2_cross; set table2_cross;
level = sum(of falls_2 adl iadl INCONTINENT cogfunction FRAIL WEIGHT_LOSS GERI_SYN_COUNT GERI_SYN_COUNT2
ADL_BATH ADL_BED ADL_DRESS ADL_EAT ADL_TOILET ADL_WALK ADL_WALK_EQUIP
G_IADL_MEAL G_IADL_GROC G_IADL_PHONE G_IADL_MEDS G_IADL_MONEY);
drop falls_2 adl iadl INCONTINENT cogfunction ADL_: _: F_: matched FRAIL WEIGHT_LOSS GERI: G_: ;
if cohort = 1;
run;

** save pertinent results to excel file for use in table 2;
proc export 
  data=work.table2_cross
  dbms=xlsx 
  outfile="&path\tables and figures\table2cross 2020-08-04.xlsx" 
  replace;
run;

