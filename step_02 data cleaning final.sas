%LET path = C:\Users\sachi\Box Sync\;
libname in "&path\AF frailty\data\AF frailty 2014 crosssection";
libname out "&path\AF frailty\data\AF frailty 2014 crosssection";
libname tr "&path\data\HRS\temp\trk2014\data";
libname g14 "&path\data\HRS\temp\h14core\h14sas\data";
libname in14 "&path\data\HRS\temp\h14core\h14sas\data";
libname r "&path\data\HRS\randhrs1992_2014v2";
options nofmterr;

*import dataset of patients with AF;
data _c1; set in.cohort_study_0726;
cohort = 1;
run;

data _c2; set in.cohort_matched_0910;
cohort = 2;
run;

data _af; set _c1 _c2;
keep hhid pn af cohort op;
run;

data _wts; set tr.trk2014tr_r;
keep hhid pn
stratum secu ;
run;

data _wts2; set r.randhrs1992_2014v2;
keep hhid pn R12WTCRNH R12CESD;
run;

data _g14; set g14.h14g_r;
keep hhid pn 
/*for data checks*/
/*OG041 OG043 OG044 OG046 OG047 OG049 OG050 OG051 OG053 OG059 OG061*/
G_:
;

G_IADL_MEAL = 0;
if OG041 in (1, 6, 7) then G_IADL_MEAL = 1;
if OG041 in (8, 9, .) then G_IADL_MEAL = .;
if OG043 = 1 then G_IADL_MEAL = 2;

G_IADL_GROC = 0;
if OG044 in (1, 6, 7) then G_IADL_GROC = 1;
if OG044 in (8, 9, .) then G_IADL_GROC = .;
if OG046 = 1 then G_IADL_GROC = 2;

G_IADL_PHONE = 0;
if OG047 in (1, 6, 7) then G_IADL_PHONE = 1;
if OG047 in (8, 9, .) then G_IADL_PHONE = .;
if OG049 = 1 then G_IADL_PHONE = 2;

G_IADL_MEDS = 0;
if OG050 in (1, 6) then G_IADL_MEDS = 1;
if OG050 = 7 then G_IADL_MEDS = .Z; *don't do;
if OG050 in (8, 9, .) then G_IADL_MEDS = .;
if OG051 = 5 then G_IADL_MEDS = 1; * if don't cold you?;
if OG053 = 1 then G_IADL_MEDS = 2;

G_IADL_MONEY = 0;
if OG059 in (1, 6, 7) then G_IADL_MONEY = 1;
if OG059 in (8, 9, .) then G_IADL_MONEY = .;
if OG061 = 1 then G_IADL_MONEY = 2;
run;

data _ccw; set in.af_ccw_080919;
keep hhid pn AF_dx_dt CCW_af;
run;

data _base; set in.af_frailty_v6_to_syj;
run;

proc sql;
create table working as 
select * from _base 
left join _wts2 
on _base.hhid = _wts2.hhid and _base.pn = _wts2.pn
left join _wts
on _base.hhid = _wts.hhid and _base.pn = _wts.pn
left join _af
on _base.hhid = _af.hhid and _base.pn = _af.pn
left join _g14
on _base.hhid = _g14.hhid and _base.pn = _g14.pn
left join _ccw 
on _base.hhid = _ccw.hhid and _base.pn = _ccw.pn;
quit;

** add back in the original data on falls and incontinence 
to code missing;
data c_14; set in14.h14c_r;
keep hhid pn OC079 OC080 OC081 OC087; 
run;

proc sql;
create table analytic_file as 
select * from working
left join c_14 
on working.hhid = c_14.hhid and working.pn = c_14.pn;
quit;

data analytic_file; set analytic_file;
**collapse CHADSVASC score;
CHADSVASC_collapsed = CHADSVASC;
if CHADSVASC > 7 then CHADSVASC_collapsed = 7;

** create 3 level function variable, per Ken's recommendation;
ADL_BATH = 0;
if ADL_BATHING_DIFF in (.D, .R) then ADL_BATH = .;
if ADL_BATHING_DIFF in (1, 2, 9) then ADL_BATH = 1;
if ADL_BATH_HELP = 1 then ADL_BATH = 2; 

ADL_BED = 0;
if ADL_BED_DIFF in (.D, .R) then ADL_BED = .;
if ADL_BED_DIFF in (1, 2, 9) then ADL_BED = 1;
if ADL_BED_HELP = 1 then ADL_BED = 2;

ADL_DRESS = 0;
if ADL_DRESS_DIFF in (.D, .R) then ADL_DRESS = .;
if ADL_DRESS_DIFF in (1, 2, 9) then ADL_DRESS = 1;
if ADL_DRESS_HELP = 1 then ADL_DRESS = 2;

ADL_EAT = 0;
if ADL_EAT_DIFF in (.D, .R) then ADL_EAT = .;
if ADL_EAT_DIFF in (1, 2, 9) then ADL_EAT = 1;
if ADL_EAT_HELP = 1 then ADL_EAT = 2;

ADL_TOILET = 0;
if ADL_TOILET_DIFF in (.D, .R) then ADL_TOILET = .;
if ADL_TOILET_DIFF in (1, 2, 9) then ADL_TOILET = 1;
if ADL_TOILET_HELP = 1 then ADL_TOILET = 2;

ADL_WALK = 0;
if ADL_WALK_DIFF in (.D, .R) then ADL_WALK = .;
if ADL_WALK_DIFF in (1, 2, 9) then ADL_WALK = 1;
if ADL_WALK_HELP = 1 then ADL_HELP = 2;

ADL = .;
if ADL_BATH = 0 and ADL_BED = 0 and ADL_DRESS = 0 
and ADL_EAT = 0 and ADL_TOILET = 0 and ADL_WALK = 0 
then ADL = 1;

if ADL_BATH = 1 or ADL_BED = 1 or ADL_DRESS = 1 or 
ADL_EAT = 1 or ADL_TOILET = 1 or ADL_WALK = 1 
then ADL = 2;

if ADL_BATH = 2 or ADL_BED = 2 or ADL_DRESS = 2 or 
ADL_EAT = 2 or ADL_TOILET = 2 or ADL_WALK = 2 
then ADL = 3;

if ADL_BATH = . then ADL = .;
if ADL_BED = . then ADL = .;
if ADL_DRESS = . then ADL = .;
if ADL_EAT = . then ADL = .;
if ADL_TOILET = . then ADL = .;
if ADL_WALK = . then ADL = .;

**recode FALLS to a three level variable so that levels are mutually exclusive;
FALLS_2 = FALLS;
if FALL_INJ = 1 then FALLS_2 = 2;
*original definition of FALLS did not include missing values;
*create missing values;
if OC079 = 8 then FALLS_2 = .; 
if FALLS_2 = 1 and OC081 in (., 8,9) then FALLS_2 = .;

/*
IADL coding
1 = no impairment
2 = any difficulty
3 = any dependency
*/
IADL = 1;
if G_IADL_MEAL = 1 or G_IADL_GROC=1 or G_IADL_PHONE = 1 or 
G_IADL_MEDS = 1 or G_IADL_MONEY = 1
then IADL = 2;
if G_IADL_MEAL = 2 or G_IADL_GROC=2 or G_IADL_PHONE = 2 or 
G_IADL_MEDS = 2 or G_IADL_MONEY = 2
then IADL = 3;
if G_IADL_MEAL = . or G_IADL_GROC=. or G_IADL_PHONE = . or 
G_IADL_MEDS in (., .Z) or G_IADL_MONEY = .
then IADL = 3;

* recode incontinence to include missing values;
if OC087 in (8,9) then INCONTINENT = .;

* frequency tables indicate no missing cognitive function values;

** count of syndromes;
GERI_SYN_COUNT = (FALLS_2 ne 0) + (ADL ne 1) + (IADL ne 1) + (cogfunction ne 1) + (INCONTINENT = 1);
if FALLS_2 = . OR ADL = . or IADL = . or cogfunction = . or INCONTINENT = . then GERI_SYN_COUNT = .;

EDU = 1;
if RAEDEGRM in (1, 2, 3) then EDU = 2;
if RAEDEGRM in (4, 5, 6, 7, 8) then EDU = 3;

DEPRESSED = 0;
if R12CESD ge 4 then DEPRESSED = 1;
RUN;


data out.analytic_file_v2; set work.analytic_file;
run;
