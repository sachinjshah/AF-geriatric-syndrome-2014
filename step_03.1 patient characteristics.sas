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
