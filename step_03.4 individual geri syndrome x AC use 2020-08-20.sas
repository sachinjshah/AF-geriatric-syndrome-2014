
/*------------------------------------------------------

FIGURE 2: GERIATRIC SYNDROMES AS PREDICTOR OF AC USE 

--------------------------------------------------------*/

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

GERI_SYN_COUNT2 = (FALLS_2 ne 0) + (ADL ne 1) + (IADL ne 1) + (cogfunction ne 1) + (INCONTINENT = 1) + (FRAILTY = 1) + (WEIGHT_LOSS = 1);
if FALLS_2 = . OR ADL = . or IADL = . or cogfunction = . or INCONTINENT = . or frail = . or WEIGHT_LOSS = . then GERI_SYN_COUNT2 = .;

run;

data af2; set af; 
* from full dataset remove those without af; 
where af = 1;
** recode levels so that all refernces levels are 1;
falls_2 = falls_2 + 1; 
INCONTINENT = INCONTINENT + 1;
Bath = ADL_BATH + 1;
Bed = ADL_BED + 1;
Dress = ADL_DRESS +1;
Eat = ADL_EAT + 1;
Toilet = ADL_TOILET + 1;
Walk = ADL_WALK + 1;
WEIGHT_LOSS = WEIGHT_LOSS + 1;
zfrail = frail +1;

* had to recode for the margins macro, for 
some reason it created errors with adl and iadl var name; 
zoom_a = adl; 
zoom_i = iadl;

* remove those with missing AC use data;
if BLOOD_THINNER in (0,1);
run;

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

%margin_arr(WEIGHT_LOSS, Weight loss, No weight loss, Weight loss);
%margin_arr(zfrail, Frail, Not frail, Frail);

%margin_arr(Bath, Bathing, ADL_BATH intact, ADL_BATH difficulty, ADL_BATH dependent)
%margin_arr(Bed, Getting out of bed, ADL_BED intact, ADL_BED difficulty, ADL_BED dependent)
%margin_arr(Dress, Dressing, ADL_DRESS intact, ADL_DRESS difficulty, ADL_DRESS dependent)
%margin_arr(Eat, Eating, ADL_EAT intact, ADL_EAT difficulty, ADL_EAT dependent)
%margin_arr(Toilet, Toileting, ADL_TOILET intact, ADL_TOILET difficulty, ADL_TOILET dependent)
%margin_arr(Walk, Walking, ADL_WALK intact, ADL_WALK difficulty, ADL_WALK dependent)

** output the average marginal effects;
data out.thinner_ame;
set arr_falls_2 arr_zoom_a arr_zoom_i arr_INCONTINENT arr_cogfunction arr_WEIGHT_LOSS arr_zfrail;
label Diff = Diff;
Diff = Diff * -1; ** reverse sign b/c we want 2-1 not 1-2;
UL = Lower * -1;
LL = Upper * -1;
drop Upper Lower;
run;

data out.thinner_individual_adl;
set arr_bath arr_bed arr_dress arr_eat arr_toilet arr_walk;
label Diff = Diff;
Diff = Diff * -1; ** reverse sign b/c we want 2-1 not 1-2;
UL = Lower * -1;
LL = Upper * -1;
drop Upper Lower;
run;

** output predicted rate of AC use;
data out.thinner_predicted;
set P_falls_2 P_zoom_a P_zoom_i P_INCONTINENT P_cogfunction P_WEIGHT_LOSS P_zfrail;
run;

data out.thinner_individual_adl_predicted;
set P_bath p_bed p_dress p_eat p_toilet p_walk;
run;

proc export 
  data=out.thinner_individual_adl
  dbms=xlsx 
  outfile="&path\tables and figures\tabular_fig_2_individual_ADLS 2020-08-04.xlsx" ; 
  *need to delete old file, will not replace;
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
  outfile="&path\tables and figures\tabular_fig_2 2020-08-04.xlsx" ; 
  *need to delete old file, will not replace;
run;

data out.tabular_fig_2; set work.tabular_fig_2;
run;


** clean up;
proc datasets library = work;
  delete arr_: P_:;
run;
quit;

