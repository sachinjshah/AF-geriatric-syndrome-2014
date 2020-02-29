
/** VA LIBRARY NAMES **/
libname af 'V:\Health and Retirement Study\Sun\Sachin\AF\SAS interim';
libname Mdcr 'V:\Health and Retirement Study\DATAinSAS2018\HRS_Provider_Distribution HRS018 - NCIRE 51424';
libname dod 'V:\Health and Retirement Study\DATAinSAS\dod_gdr';
libname trk 'V:\Health and Retirement Study\Grisell\HRS_data\trk2016earlyv3';
libname rand 'V:\Health and Retirement Study\Grisell\HRS_data\rand\randhrs1992_2016v1';
libname exit 'V:\Health and Retirement Study\Sun\data\exit';
libname doi 	'V:\Health and Retirement Study\DATAinSAS\doi_gdr';
libname practice 'V:\Health and Retirement Study\Grisell\AlexSmith\SpousalPairsDeath\sasdata';



**** 1. Tracker (06/15/2019: Update to the 2016 tracker);

data trk2016_0;
set trk.trk2016tr_r 
(keep=hhid pn OIWTYPE OAGE OWGTR); 

HHIDPN=HHID*1000 + PN;
if OIWTYPE = 1; 
 
run; /*18747*/


**** 1-(1) AGE >=65;
data trk2016; set trk2016_0; 
IF OAGE>=65; run;  /*10364*/

	proc freq data=trk2016_0; tables OAGE/missing; run;

 
**** 2. Medicare Linkage & HRS interview dates;

DATA cmsxref (keep=BID_HRS_22 HHIDPN);
set mdcr.XREF2015Medicare (keep=BID_HRS_22  HHIDPN rename=(HHIDPN=HHIDPN_C));
HHIDPN=input(HHIDPN_C,9.0);
proc sort; by BID_HRS_22; run;
 
proc sort; by BID_HRS_22; run;
proc sort data=cmsxref; by hhidpn; run;

data hrs_cms;
merge trk2016 (in=A) cmsxref (in=B);
 
by hhidpn; if A;
if B=1 then hrslink=1;
else if B=0 then hrslink=0;

if hrslink=1; 
label hrslink='R in YOURDATA accepted to have Med files linked to HRS. 0.no, 1.yes';
 
proc sort; by BID_HRS_22; run; /*9249*/
proc sort data=hrs_cms; by HHIDPN; run; 


*====See the interview date, and create the date 1 year/2years before 2014 interview;
DATA doi (keep=HHIDPN OIWDATE ); set doi.doi2017_gdr; run;
PROC SORT; by HHIDPN; run;

DATA cohort_1; merge doi hrs_cms(in=A drop=HHID PN hrslink OIWTYPE); 
by HHIDPN; 
if A;
date_flag1 = intnx('year',OIWDATE,-1, "sameday");
date_flag2 = intnx('year',OIWDATE,-2, "sameday");
label date_flag1="date 1 years before the 2014 interview date";
label date_flag2="date 2 years before the 2014 interview date";

format date_flag1 mmddyy10.;
format date_flag2 mmddyy10.;
run; /*9249*/


**** 2-(1) Part A & B and FFS ;
	*===0. Medicare denominator files;
	%MACRO HMOIND(INDATA,YR);
	DATA A (KEEP=BID_HRS_22 HMOIND12 BUYIN12 rename=(BUYIN12=BUYIN12_&YR HMOIND12=HMOIND12_&YR)); SET &INDATA ;
	PROC SORT; BY BID_HRS_22 HMOIND12_&YR; RUN;
	PROC SORT DATA=A OUT=DN&YR nodupkey; BY BID_HRS_22; RUN;
	%MEND HMOIND;
	%HMOIND(MDCR.DN_2012,12)
	
	/*### UPDATED MBSF 2013-2015 */	
	%MACRO HMOIND1(INDATA,YR);
		DATA A (keep=BID_HRS_22 HMOIND12_&YR BUYIN12_&YR); 
		SET &INDATA;
		HMOIND12_&YR = catt(HMO_IND_01,HMO_IND_02,HMO_IND_03,HMO_IND_04,HMO_IND_05,HMO_IND_06,HMO_IND_07,HMO_IND_08,HMO_IND_09,HMO_IND_10,HMO_IND_11,HMO_IND_12);
		BUYIN12_&YR =catt(MDCR_ENTLMT_BUYIN_IND_01,MDCR_ENTLMT_BUYIN_IND_02,MDCR_ENTLMT_BUYIN_IND_03,MDCR_ENTLMT_BUYIN_IND_04,MDCR_ENTLMT_BUYIN_IND_05,
						MDCR_ENTLMT_BUYIN_IND_06,MDCR_ENTLMT_BUYIN_IND_07,MDCR_ENTLMT_BUYIN_IND_08,MDCR_ENTLMT_BUYIN_IND_09,MDCR_ENTLMT_BUYIN_IND_10,
						MDCR_ENTLMT_BUYIN_IND_11,MDCR_ENTLMT_BUYIN_IND_12);
		PROC SORT; BY BID_HRS_22 HMOIND12_&YR; RUN;
		PROC SORT DATA=A OUT=DN&YR nodupkey; BY BID_HRS_22; RUN;
		%MEND HMOIND1;
	%HMOIND1(mdcr.mbsf_2013,13)
	%HMOIND1(mdcr.mbsf_2014,14)
	%HMOIND1(mdcr.mbsf_2015,15)

	/*### CROSS WALK + MEDICARE */
	DATA DN1215; MERGE DN12-DN15; BY BID_HRS_22; PROC SORT; BY BID_HRS_22;  run;
	PROC SORT data=cmsxref; by BID_HRS_22; run;
	DATA DN1215_1; MERGE DN1215 (in=A) cmsxref (in=B); by BID_HRS_22; if A & B; run;
	PROC SORT DATA=DN1215_1; by HHIDPN; run;

	*===a. 24 months from the interview date scan;
	data cohort_1_a; 
	length BUYIN12_13 $12 BUYIN12_14 $12 BUYIN12_15 $12 HMOIND12_13 $12 HMOIND12_14 $12 HMOIND12_15 $12 ;

	merge cohort_1 (in=A) DN1215_1 (in=B); by HHIDPN; 
	IF A & B;
	
	moi = month(OIWDATE);
	yoi = year(OIWDATE); 

		LENGTH HMOINDLAST24M $24;
		ARRAY HMOIND[4] HMOIND12_12-HMOIND12_15;

		length ABindlast24M $24;
		array ab[4] BUYIN12_12-BUYIN12_15;

	/*** LAST 24 MONTH ***/
	DO I=1 TO 4;
	   IF I=(yoi-2011) AND HMOIND[I]^=' ' 
		THEN HMOINDLAST24M = SUBSTR((HMOIND[I-2]||HMOIND[I-1]||HMOIND[I]), moi,24);
	   END;
	DROP I; 

	do i=1 TO 4;
	   if i=(yoi-2011) and ab[i]^=' ' 
		then ABindlast24m=substr((ab[i-2]|| ab[i-1]||ab[i]), moi, 24);
	   END; 
	drop i;
	

	IF HMOINDLAST24M^=' ' AND HMOINDLAST24M="000000000000000000000000" THEN FFSLAST24M=1;
	ELSE IF HMOINDLAST24M^=' ' AND HMOINDLAST24M^="000000000000000000000000" THEN FFSLAST24M=0;
	ELSE IF HMOINDLAST24M=' ' THEN FFSLAST24M=.;

	if (ABindlast24m^=' ' and verify(ABindlast24m,"3C") NE 0) then partABlast24m=0;
	else if (ABindlast24m^=' ' and verify (ABindlast24m,"3C")=0) then partABlast24m=1;
	else if ABindlast24m=' ' then partABlast24m=.;

	run; 

	data cohort_1_b; set cohort_1_a; 
	if partABlast24m=1 & FFSLAST24M=1; run; /*4882*/




 
**** 3. AFib Diagnosis 
*===3-(1)  Inpatient ;
data allInpatient (keep=BID_HRS_22 Claim_ID_HRS_22 DGNSCD01-DGNSCD25 AD_DGNS ADMSN_DT);
set Mdcr.IP_2012-Mdcr.IP_2015; run;

proc sort data=allInpatient; by BID_HRS_22 Claim_ID_HRS_22; run;

data allInpatient0 (keep=BID_HRS_22 dx_af_ip ADMIT_DT); 
set allInpatient;
array af {26} AD_DGNS DGNSCD01-DGNSCD25;
		 
		/* (1) AF_MODIFIED, 12/05/2018*/
		dx_af_ip = 0;
			do i = 1 to 26; 
			if af{i} in ('42731') then dx_af_ip=1;
			end; drop i; 
		admit_dt = input(ADMSN_dt,yymmdd10.); 
		format admit_dt mmddyy10.;
		if dx_af_ip>0; 
run; 

		*-----------------merge it to the cmsxref----------------; 
		proc sort data=cmsxref; by BID_HRS_22; run;
		 
		data AF_ip (drop=BID_HRS_22); merge allInpatient0(in=A) cmsxref; by BID_HRS_22; if A; 
		proc sort; by hhidpn; run;

		data cohort_ip; merge AF_ip cohort_1_b (in=A); 
		by HHIDPN;
		if A; 

		if date_flag2<=admit_dt<=OIWDATE;
		run;  /*762*/

		proc sql; select count(HHIDPN), count(distinct HHIDPN) from cohort_ip; run; /*distinct 393*/

		proc sort data=cohort_ip; by HHIDPN admit_dt; run;
		data cohort_ip_1 (rename=(admit_dt = ADMIT_DT_IP) keep=HHIDPN dx_af_ip admit_Dt); set cohort_ip; 
		by HHIDPN;
		if first.HHIDPN; 
		run;


/**3-(2) Outpatient*/
data allOutpatient (keep= BID_HRS_22 ACRTN_NM DGNSCD01-DGNSCD25 FROM_DT);
set mdcr.OP_2012-Mdcr.OP_2015; 
run;
proc sort data=allOutpatient; by BID_HRS_22 ACRTN_NM; run;
 
DATA allOutpatient0  (keep=BID_HRS_22 dx_af_op ADMIT_DT);
set alloutpatient;  

array af{25} DGNSCD01-DGNSCD25; 
dx_af_op=0;
	do i = 1 to 25; 
	if af{i} in ('42731') then dx_af_op =1;
	end; drop i; 
	 
if dx_af_op>0; 
admit_dt = input(from_dt, yymmdd10.);
format admit_dt mmddyy10.;
run;

		*-----------------merge it to the cmsxref----------------; 
		proc sort data=cmsxref; by BID_HRS_22; run;
		 
		data AF_op (drop=BID_HRS_22); merge alloutpatient0(in=A) cmsxref; by BID_HRS_22; if A; 
		proc sort; by hhidpn; run;

		data cohort_op; merge AF_op cohort_1_b (in=A); 
		by HHIDPN;
		if A; 
		if date_flag2<=admit_dt<=OIWDATE;
		run;  
			proc sql; select count(HHIDPN), count(distinct HHIDPN) from cohort_op; run; /*3730 568*/


/**3-(3) Carrier **/
/*========AF DIAGNOSIS CARRIER FILE */
data allCarrier(keep= BID_HRS_22 ACRTN_NM DGNSCD01-DGNSCD12 FROM_DT);
set mdcr.PB_2012-Mdcr.PB_2015; 
proc sort data=allcarrier; by BID_HRS_22 ACRTN_NM; run;
 
DATA allcarrier0 (keep=BID_HRS_22 dx_af_cr ADMIT_DT );
set allcarrier; 
array af{12} DGNSCD01-DGNSCD12;
 
dx_af_cr=0;
	do i = 1 to 12; 
	if af{i} in ('42731') then dx_af_cr =1;
	end; drop i; 
if dx_af_cr>0; 

admit_dt = input(from_dt, yymmdd10.);
format admit_dt mmddyy10.;
 
run;

		*-----------------merge it to the cmsxref----------------; 
		proc sort data=cmsxref; by BID_HRS_22; run;
		 
		data AF_cr (drop=BID_HRS_22); merge allcarrier0(in=A) cmsxref; by BID_HRS_22; if A; 
		proc sort; by hhidpn; run;

		data cohort_cr; merge AF_cr cohort_1_b (in=A); 
		by HHIDPN;
		if A; 

		if date_flag2<=admit_dt<=OIWDATE;
		run;  /*12936*/
			proc sql; select count(HHIDPN), count(distinct HHIDPN) from cohort_cr; run; /*12620 836*/

/*--- append op + cr ***/
proc contents data=cohort_cr; 
proc contents data=cohort_op; run;

DATA OP_CR; set cohort_cr (keep=HHIDPN dx_af_cr admit_dt) cohort_op (keep=HHIDPN dx_af_op admit_dt); run; 
proc sort data=OP_cr nodupkey; by HHIDPN admit_dt; run; /*13266*/

data op_cr_1; set op_cr; by HHIDPN;
count+1; 
if first.HHIDPN then count=1; 
if count<=2;
run; 

proc sql; 
create table op_cr_2 as
select HHIDPN
	   , max(admit_dt) as ADMIT_DT_2op format mmddyy10.
	   , min(admit_dt) as ADMIT_DT_1op format mmddyy10.
	   , count as count, max(count) as count_total
from op_cr_1
group by HHIDPN
having count=1 & count_total=2; 
quit; 


/** merge it to the IP data */
proc sort data=op_cr_2; by HHIDPN;
proc sort data=cohort_ip_1; by HHIDPN; run;
proc contents data=cohort_ip_1; run;
proc contents data=op_cr_2; run;
data op_cr_ip; merge op_cr_2 (keep=HHIDPN ADMIT_DT_1op ADMIT_DT_2op) cohort_ip_1 (drop=dx_af_ip);  by HHIDPN; run;

	proc sql; select count(HHIDPN), count(distinct HHIDPN) from op_cr_ip; run; /*779 779*/
	data af.op_cr_ip_all; set op_cr_ip; run; 




******4. Merge it to Sachin's data;
option nofmterr;
data af_frailty; set af.af_frailty_v6_to_syj_061219;
HHIDPN=HHID*1000 + PN;
run; 

proc sort data=af_frailty; by HHIDPN;
proc sort data=op_cr_ip; by HHIDPN; run;

data af_medicare; merge op_cr_ip (in=A) af_frailty cohort_1 (keep=HHIDPN OIWDATE); 
by HHIDPN; 
if A; 

if ADMIT_DT_1op =. & ADMIT_DT_IP~=. then do; first_dx_dt = ADMIT_DT_IP; op=0; END;
else if ADMIT_DT_1op ~=. & ADMIT_DT_IP =. then do; first_dx_dt=ADMIT_DT_1OP; op=1; END;
else if ADMIT_DT_1op ~=. & ADMIT_DT_IP ~=. & ADMIT_DT_1op>=ADMIT_DT_IP then do; first_dx_dt=ADMIT_DT_IP; op=0; END;
else if ADMIT_DT_1op ~=. & ADMIT_DT_IP ~=. & ADMIT_DT_1op<ADMIT_DT_IP then do; first_dx_dt=ADMIT_DT_1op; op=1; END;
label op="diagnosed as an OP. 0=No (dx as IP) 1=YES (dx as OP)";

format first_dx_dt mmddyy10.;
label first_dx_dt="first date of AFib dx";

duration = OIWDATE - first_dx_dt +1; 
label duration="duration of Afib";

BMI_18 =. ; 
if BMI~=. & BMI<18 then BMI_18=1; 
else if BMI~=. & BMI>=18 then BMI_18=0; 
label BMI_18="BMI <18";

DAYs_in_BED_30 = . ;
if DAYs_IN_BED ~=. & DAYs_IN_BED <98 & DAYs_IN_BED >=30 then DAYs_in_Bed_30=1; 
ELSE IF DAYs_IN_BED ~=. & DAYs_IN_BED <98 & DAYs_IN_BED <30 then DAYs_in_Bed_30=0;
ELSE IF DAYs_IN_BED =98 then DAYs_in_BED_30=.; 
label DAYs_in_Bed_30 = "0=less than 30d, 1=30d or more";

EDU = 1;
if 0 < RAEDEGRM < 4 then EDU = 2;
else if RAEDEGRM ge 4 then EDU = 3;
label EDU = "1=less than hs, 2=HS or equivalent, 3=greater than HS";


/*ADL DIFFICULTY*/
BATH_DIFF = ADL_BATHING_DIFF;
	IF ADL_BATHING_DIFF in (2, 9) then BATH_DIFF=1; 
BED_DIFF = ADL_BED_DIFF;
	IF ADL_BED_DIFF in (2, 9) then BED_DIFF=1; 
DRESS_DIFF = ADL_DRESS_DIFF;
	IF ADL_DRESS_DIFF in (2, 9) then DRESS_DIFF=1; 
EAT_DIFF = ADL_EAT_DIFF;
	IF ADL_EAT_DIFF in (2, 9) then EAT_DIFF=1; 
TOILET_DIFF = ADL_TOILET_DIFF;
	IF ADL_TOILET_DIFF in (2, 9) then TOILET_DIFF=1; 
WALK_DIFF = ADL_WALK_DIFF;
	IF ADL_WALK_DIFF in (2, 9) then WALK_DIFF=1; 

/* ADL DEPENDENCE*/
BATH_DEP = ADL_BATH_HELP;
	IF BATH_DIFF=0 & ADL_BATH_HELP=.S THEN BATH_DEP=0;
	IF BATH_DIFF in (.S, .D) THEN BATH_DEP=.;
BED_DEP = ADL_BED_HELP;
	IF BED_DIFF=0 & ADL_BED_HELP=.S THEN BED_DEP=0;
	IF BED_DIFF in (.S, .D) THEN BED_DEP=.;
DRESS_DEP = ADL_DRESS_HELP;
	IF DRESS_DIFF=0 & ADL_DRESS_HELP=.S THEN DRESS_DEP=0;
	IF DRESS_DIFF in (.S, .D) THEN DRESS_DEP=.;
EAT_DEP = ADL_EAT_HELP;
	IF EAT_DIFF=0 & ADL_EAT_HELP=.S THEN EAT_DEP=0;
	IF EAT_DIFF in (.S, .D) THEN EAT_DEP=.;
TOILET_DEP = ADL_TOILET_HELP;
	IF TOILET_DIFF=0 & ADL_TOILET_HELP=.S THEN TOILET_DEP=0;
	IF TOILET_DIFF in (.S, .D) THEN TOILET_DEP=.;
WALK_DEP = ADL_WALK_HELP;
	IF WALK_DIFF=0 & ADL_WALK_HELP=.S THEN WALK_DEP=0;
	IF WALK_DIFF in (.S, .D) THEN WALK_DEP=.;

run;


******5. Bringing survey weights from Rand and Trk;
proc sort data=trk2016_0; by HHIDPN; run;
data af.cohort_study_0726; 
merge af_medicare (in=A) trk2016_0 (keep=HHIDPN OWGTR) rand.randhrs1992_2016v1 (keep=HHIDPN R12WTCRNH); 
by HHIDPN; 

if A; 
AF=1; 

run; 
