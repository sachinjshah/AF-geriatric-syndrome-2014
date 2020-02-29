/*
DATA DEVELOPMENT 

Program by Sachin J Shah / sachin.j.shah@gmail.com
please cite if used;
*/


/*-----------------------------------------------------------------------

Code to identify participant with geriatric syndromes. 

Geriatric Syndrome		Source
-----------------------------------------
ADL						RAND
IADL					HRS core
Cognitive impairment	LANGA WEIR dataset
Falls					HRS Core
Incontinence			HRS Core
-----------------------------------------------------------------------*/

OPTIONS nofmterr;
%LET path = C:\Users\sachi\Box Sync\data\HRS\;
libname in "&path\temp\trk2014\data";
libname in14 "&path\temp\h14core\h14sas\data";
LIBNAME in12 "&path\temp\h12core\h12sas\data";
LIBNAME in10 "&path\temp\h10core\h10sas\data";
LIBNAME in08 "&path\temp\h08core\h08sas\data";
LIBNAME in06 "&path\temp\h06core\h06sas\data";
LIBNAME in04 "&path\temp\h04core\h04sas\data";
LIBNAME in02 "&path\temp\h02core\h02sas\data";
LIBNAME in00 "&path\temp\h00core\h00sas\data";
LIBNAME inr "&path\temp\randhrs1992_2014v2";
LIBNAME inLW "&path\LangaWeir";

libname out "C:\Users\sachi\Box Sync\AF frailty\data\AF frailty 2014 crosssection";

/*
Set up tracker backbone
*/

data _temp; set in.trk2014tr_r;

keep hhid pn  
EXDEATHYR EXDEATHMO 
NMONTH NYEAR

GIWMONTH GIWYEAR
HIWMONTH HIWYEAR
JIWMONTH JIWYEAR
KIWMONTH KIWYEAR
LIWMONTH LIWYEAR
MIWMONTH MIWYEAR
NIWMONTH NIWYEAR
OIWMONTH OIWYEAR
OIWTYPE
;
run;

DATA  _t; set _temp;

wave_yr = "wave_yr_00";
interview_month = GIWMONTH;
interview_year = GIWYEAR;
OUTPUT;

wave_yr = "wave_yr_02";
interview_month = HIWMONTH;
interview_year = HIWYEAR;
OUTPUT;

wave_yr = "wave_yr_04";
interview_month = JIWMONTH;
interview_year = JIWYEAR;
OUTPUT;

wave_yr = "wave_yr_06";
interview_month = KIWMONTH;
interview_year = KIWYEAR;
OUTPUT;

wave_yr = "wave_yr_08";
interview_month = LIWMONTH;
interview_year = LIWYEAR;
OUTPUT;

wave_yr = "wave_yr_10";
interview_month = MIWMONTH;
interview_year = MIWYEAR;
OUTPUT;

wave_yr = "wave_yr_12";
interview_month = NIWMONTH;
interview_year = NIWYEAR;
OUTPUT;

wave_yr = "wave_yr_14";
interview_month = OIWMONTH;
interview_year = OIWYEAR;
OUTPUT;

DROP 
GIWMONTH GIWYEAR
HIWMONTH HIWYEAR
JIWMONTH JIWYEAR
KIWMONTH KIWYEAR
LIWMONTH LIWYEAR
MIWMONTH MIWYEAR
NIWMONTH NIWYEAR
OIWMONTH OIWYEAR;
RUN;

/*-------------------------------------------

Import raw HRS data files and selected variables

---------------------------------------------*/

/*Section C: PHYSICAL HEALTH  (Respondent)
2004-2014
*/

%macro importem(yr, l);

data c_&yr; set in&yr..h&yr.c_r;
length wave_yr $ 10;
keep 	HHID pn 
		wave_yr
		FALLS FALL_NUM FALL_INJ
		IMP_VISION IMP_HEARING
		INCONTINENT 
		HF_last2yr
		MI_last2yr
		angina_last2yr
		EVER_HF
		EVER_MI
		EVER_ANGINA
		EVER_RHYTHM
		DAYS_IN_BED
		;

FALLS = (&l.C079 = 1); 
FALL_NUM = &l.C080;
FALL_INJ = &l.C081;

IMP_VISION = (&l.C095 in (4, 5, 6));
IMP_HEARING = (&l.C103 in (4, 5)); 
INCONTINENT = (&l.C087 =1); 
/* in last 12 months, have you lost any amount of urine beyond your control? = Y */

if &l.C048 in (1,5) then HF_last2yr = (&l.C048 = 1); * creates yes, no, and missing values;
if &l.C040 in (1,5) then MI_last2yr = (&l.C040 = 1); * creates yes, no, and missing values;
if &l.C045 in (1,5) then angina_last2yr = (&l.C045 = 1); * creates yes, no, and missing values;

if &l.C263 in (1,5) then EVER_HF = (&l.C263 = 1); * C263 asked 2010 onwards;
if &l.C263 in (8) then EVER_HF = .N; 
if &l.C263 in (9) then EVER_HF = .R;

if (&l.C257 in (1,5) OR &l.C036 = 5) then EVER_MI = (&l.C257 = 1); *C257 asked 2010 onwards;
if &l.C257 in (8) then EVER_MI = .N;
if &l.C257 in (9) then EVER_MI = .R;

if (&l.C260 in (1,5) OR &l.C036 = 5) then EVER_ANGINA = (&l.C260 = 1); * C260 asked 2010 onwards;
if &l.C260 in (8) then EVER_ANGINA = .N;
if &l.C260 in (9) then EVER_ANGINA = .R;

if (&l.C266 in (1,5) OR &l.C036 = 5) then EVER_RHYTHM = (&l.C266 = 1); * C266 asked 2010 onwards;
if &l.C266 in (8) then EVER_RHYTHM = .N;
if &l.C266 in (9) then EVER_RHYTHM = .R;

DAYS_IN_BED = &l.C229;

wave_yr = "wave_yr_&yr.";
run;


%mend;

%importem(02, H);
%importem(04, J);
%importem(06, K);
%importem(08, L);
%importem(10, M);
%importem(12, N);
%importem(14, O);


/*
Section C: PHYSICAL HEALTH  (Respondent) 
2000
*/

data c_00; set in00.h00b_r;
length wave_yr $ 10;
keep 	HHID 
		pn 
		wave_yr
		FALLS 
		FALL_NUM 
		FALL_INJ
		IMP_VISION 
		IMP_HEARING
		INCONTINENT 
		HF_last2yr
		MI_last2yr
		angina_last2yr
		;

FALLS = (G1339 = 1); 
FALL_NUM = G1340;
FALL_INJ = G1345;

IMP_VISION = (G1361 in (4, 5, 6)); /*self rated vision is fair, poor, or they volunteer they are legally blind*/
IMP_HEARING = (G1369 in (4, 5)); /*self rate hearing fair or poor*/

INCONTINENT = (G1353 =1); /* in last 12 months, have you lost any amount of urine beyond your control? = Y */

if G1304 in (1,5) then HF_last2yr = (G1304 = 1);
if G1295 in (1,5) then MI_last2yr = (G1295 = 1);
if G1301 in (1,5) then angina_last2yr = (G1301 = 1);

wave_yr = "wave_yr_00";
run;



/*
Section N: HEALTH SERVICES AND INSURANCE  (Respondent)
2012 and 2014
*/


data n_12; set in12.h12n_r;
length wave_yr $ 10;
keep 	HHID pn 
		wave_yr
		BLOOD_THINNER
		;

	if NN283 = 1 then BLOOD_THINNER = 1;
	else if NN283 = 8 then BLOOD_THINNER = .N;
	else if NN283 = 9 then BLOOD_THINNER = .R;
	else BLOOD_THINNER = 0;

wave_yr = "wave_yr_12";
run;

data n_14; set in14.h14n_r;
length wave_yr $ 10;
keep 	HHID pn 
		wave_yr
		BLOOD_THINNER
		;

	if ON283 = 1 then BLOOD_THINNER = 1;
	else if ON283 = 8 then BLOOD_THINNER = .N;
	else if ON283 = 9 then BLOOD_THINNER = .R;
	else BLOOD_THINNER = 0;

wave_yr = "wave_yr_14";
run;



/*-------------------------------------------

Import RAND data files and selected variables

---------------------------------------------*/


options nonotes; 

%macro vars(n, yr);
data rand&n ;
set inr.randhrs1992_2014v2;

keep 
HHID PN HHIDPN RAGENDER RARACEM RAEDEGRM RAHISPAN 
IMMED_RECALL DELAY_RECALL SERIAL7s BWC20
COG_: PROXY BMI MULTIMORBID ADL_HELP AGE wave_yr 
FAIR_POOR_HEALTH DEPRESSED MARRIED PARTNERED LIVES_ALONE
INCOME NET_WORTH IN_WAVE IADL_MONEY IADL_MEDS IADL_HOTMEALS IADL_PHONE
IADL_GROCERIES HTN DM STROKE
SMOKE_:
ADL_:
CANCER_EVER
LUNG_EVER
CESD
;

IN_WAVE						= R&n.IWSTAT;
IMMED_RECALL 				= R&n.IMRC;
DELAY_RECALL 				= R&n.DLRC;
SERIAL7s 					= R&n.SER7;
BWC20 						= R&n.BWC20;
PROXY 						= R&n.PROXY;
BMI 						= R&n.BMI;
MULTIMORBID 				= (R&n.CONDE ge 3);
ADL_HELP 					= SUM(of R&n.WALKRH R&n.DRESSH R&n.BATHH R&n.EATH R&n.TOILTH R&n.BEDH); 
AGE 						= R&n.AGEY_B;
wave_yr 					= "wave_yr_&yr";
FAIR_POOR_HEALTH 			= (R&n.SHLT in (4, 5)); /*FAIR OR POOR SELF REPORTED HEALTH*/
DEPRESSED 					= (R&n.CESD ge 3); /*CESD SCORE ge 3*/
MARRIED  					= (R&n.MSTAT in (1, 2, 3)); 
PARTNERED  					= (R&n.MPART = 1);
LIVES_ALONE 				= (H&n.HHRES =1); 
INCOME  					= H&n.ITOT;
NET_WORTH 	 				= H&n.ATOTN;
IADL_MONEY					= R&n.MONEYA;
IADL_MEDS 					= R&n.MEDSA;
IADL_HOTMEALS 				= R&n.MEALSA;
IADL_PHONE					= R&n.PHONEA;
IADL_GROCERIES				= R&n.SHOPA;
HTN 						= R&n.HIBPE;
DM 							= R&n.DIABE;
STROKE						= R&n.STROKE;
SMOKE_EVER					= R&n.SMOKEV;
SMOKE_NOW					= R&n.SMOKEN;
ADL_WALK_HELP				= R&n.WALKRH;
ADL_DRESS_HELP				= R&n.DRESSH;
ADL_BATH_HELP				= R&n.BATHH;
ADL_EAT_HELP				= R&n.EATH;
ADL_TOILET_HELP				= R&n.TOILTH;
ADL_BED_HELP				= R&n.BEDH;

ADL_WALK_DIFF				= R&n.WALKR;
ADL_DRESS_DIFF				= R&n.DRESS;
ADL_BATHING_DIFF			= R&n.BATH;
ADL_EAT_DIFF				= R&n.EAT;
ADL_TOILET_DIFF				= R&n.TOILT;
ADL_BED_DIFF				= R&n.BED;

ADL_WALK_EQUIP				= R&n.WALKRE;
ADL_BED_EQUIP				= R&n.BEDE;

CANCER_EVER					= R&n.CANCRE;
LUNG_EVER					= R&n.LUNGE;
CESD						= R&n.CESD;

RUN;
%mend;


%vars(5, 00);
%vars(6, 02);
%vars(7, 04);
%vars(8, 06);
%vars(9, 08);
%vars(10, 10);
%vars(11, 12);
%vars(12, 14);

options notes; 


/*-------------------------------------------

Import cognitive function data

---------------------------------------------*/

data lw_wide; set inLW.cognfinalimp_9514wide;
length hhidpn $9. ;
keep hhidpn hhid pn cogfunction2000 - cogfunction2014;
hhidpn = cats(hhid, pn);
run;

proc transpose data = lw_wide out = lw;
	by hhidpn;
run;

data lw; 
	set lw (rename = (col1=cogfunction));
length wave_yr $10.;
* length hhid $6.;
length pn $3.;
substr(_name_, 1, 13) = 'wave_yr_';
wave_yr = compress(_name_);
label cogfunction = "Cognition Category: 1=Normal, 2=CIND, 3=Demented";
hhid = compress(substr(hhidpn, 1, 6));
pn = compress(substr(right(hhidpn),7));
drop _name_ _label_ hhidpn;

run;


/*-----------------------------------------

combine files

-----------------------------------------*/


data c; 
set c_:; 
run;

data n; 
set n_:;
run;

data _rlong; 
set rand:; 
run;

proc sql;
create table _t2 as 
select * from _t left join c
on _t.hhid = c.hhid and _t.pn = c.pn and _t.wave_yr = c.wave_yr

left join n
on _t.hhid = n.hhid and _t.pn = n.pn and _t.wave_yr = n.wave_yr

left join lw
on _t.hhid = lw.hhid and _t.pn = lw.pn and _t.wave_yr = lw.wave_yr;

quit;

proc sql;
create table _t3 as 
select * from _t2 left join _rlong
on _t2.hhid = _rlong.hhid and _t2.pn = _rlong.pn and _t2.wave_yr = _rlong.wave_yr;
quit;

title;

proc sort data = _t3;
by HHIDPN;
run;

data _t4; set _t3;
*where HHIDPN in (86113040, 86072010, 86066030 ,19280010, 19280020, 19286010, 19286020);
run;

data _t5 (drop = _:); set _t4;
* length cog $ 8 ;
length smoke $ 7;
by HHIDPN;
retain _HF _MI _angina _rhy;

if HF_last2yr =1 then EVER_HF = 1;
if MI_last2yr =1 then EVER_MI = 1;
if angina_last2yr = 1 then EVER_ANGINA = 1;

if first.hhidpn then do;
	if EVER_HF = . then EVER_HF = 0;
	_HF = EVER_HF ;

	if EVER_MI = . then EVER_MI = 0;
	_MI = EVER_MI;

	if EVER_ANGINA = . then EVER_ANGINA = 0;
	_angina = EVER_ANGINA;

	if EVER_RHYTHM = . then EVER_RHYTHM = 0;
	_rhy = EVER_RHYTHM;

end;

else do; /*if not first HHIDPN*/
	if EVER_HF = . then EVER_HF = _HF; /*if missing then bring use the prior value*/
	if EVER_HF = 0 and _HF = 1 then EVER_HF = 1; /*if the prior value is YES and the current value is NO then overwrite the curernt value to YES*/
	if EVER_HF = 1 then _HF = 1; /*set the retained value to YES when the current value is YES, once this values is 1 it is always 1*/

	if EVER_MI = . then EVER_MI = _MI;
	if EVER_MI = 0 and _MI = 1 then EVER_MI = 1;
	if EVER_MI = 1 then _MI = 1;

	if EVER_ANGINA = . then EVER_ANGINA = _ANGINA;
	if EVER_ANGINA = 0 and _angina = 1 then EVER_ANGINA = 1;
	if EVER_ANGINA = 1 then _angina = 1;
		
	if EVER_RHYTHM = . then EVER_RHYTHM = _rhy; /*if missing then bring use the prior value*/
	if EVER_RHYTHM = 0 and _rhy = 1 then EVER_RHYTHM = 1; /*if the prior value is YES and the current value is NO then overwrite the curernt value to YES*/
	if EVER_RHYTHM = 1 then _rhy = 1; /*set the retained value to YES when the current value is YES*/
	;
end;

VASCULAR_DZ = MAX(EVER_MI, EVER_ANGINA);

IF SMOKE_EVER = 0 then SMOKE = "NEVER";
if SMOKE_EVER = 1 and SMOKE_NOW = 1 then SMOKE = "CURRENT";
if SMOKE_EVER = 1 and SMOKE_NOW = 0 then SMOKE = "FORMER";

UNDERWEIGHT = (BMI < 18.5);

MARRIED_OR_PARTNERED = MAX(married, partnered);

EDU = 1;
if 0 < RAEDEGRM < 4 then EDU = 2;
else if RAEDEGRM ge 4 then EDU = 3;

geri_syndrome = 0 ;

/*cognitive impariment ref: https://doi.org/10.1093/geronb/gbr048*/
COG_DEMENTIA = (cogfunction = 3);
COG_CIND = (cogfunction=2);
COG_INTACT = (cogfunction=1);

if sum(of COG_DEMENTIA MULTIMORBID UNDERWEIGHT FALLS sensory_impairment INCONTINENT
disability) > 1 then geri_syndrome = 1;

CHADSVASC = 
(65 < AGE< 75) * 1 + 
(EVER_HF = 1) +
(AGE ge 75) * 2 +
(RAGENDER = 2) + 
(HTN = 1) + 
(STROKE = 1) * 2 +
(VASCULAR_DZ = 1) + 
(DM = 1);

CHADSVASC_collapsed = CHADSVASC;
if CHADSVASC < 2 then CHADSVASC_collapsed = 1;
run;

data _t6; set _t5;
if wave_yr = "wave_yr_14" and OIWTYPE = 1; 
drop adl_help sensory_impairment disability;
run;

proc freq;
tables ever_rhythm * blood_thinner  /  nopercent;
where in_wave =1 and wave_yr = "wave_yr_14";
run;

proc freq;
tables OIWTYPE * in_wave / missing;
where wave_yr = "wave_yr_14";
run;

data out.AF_Frailty_V6_to_SYJ; set _t6;
run;
