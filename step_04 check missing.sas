OPTIONS nofmterr;
libname in14 "C:\USERS\sachi\Box Sync\data\HRS\temp\h14core\h14sas\data";

data c_14; set in14.h14c_r;
keep hhid pn OC079 OC080 OC081 OC087; 
run;

%LET path = C:\Users\sachi\Box Sync\AF frailty;
libname in "&path\data\AF frailty 2014 crosssection";
libname out "&path\tables and figures";

data af; set in.analytic_file_v2;
run;

proc sql;
create table missing as 
select * from af
left join c_14 
on af.hhid = c_14.hhid and af.pn = c_14.pn;
quit;

proc freq data = af;
tables cohort * OC079 / missing;
where af = 1; ** 2 missing falls data;
run;

proc freq data = af;
tables OC081 * OC079 / missing;
where af = 1; * 1 missing injurious fall who fell;
run;

PROC FREQ data = af;
	tables  cohort * ADL_: /  missing ;
 where af = 1; ** 3 missing 1 ADL -> assumed unimpaired;
run;

PROC FREQ data = missing;
	tables AF * BLOOD_THINNER / missing;
	RUN;

PROC FREQ data = missing;
	tables ADL_WALK * ADL_BATH / missing;
	where af = 1 and BLOOD_THINNER ne .N;
	run;

PROC FREQ data = missing;
	tables cohort * G_IADL_: / missing;
	where af = 1 ;
	run; ** 2 don't take medications IADLs p -> assumed unimpaired;

PROC FREQ data = missing;
	tables cohort * cogfunction: / missing;
	where af = 1 ;
	run; ** none missing;

proc freq data = af;
tables OC087 / missing;
where af = 1; * 3 DK/R ;
run;

data missing2; set missing;
where af = 1 and blood_thinner ne .N;
run;


%macro run_ar(syn, /*syndrome variable name*/
				where);

proc genmod data = missing2 descending; 
	class &syn (ref="1");
	model BLOOD_THINNER = chadsvasc &syn / dist = bin link = log;
	lsmeans &syn / exp cl diff;
	where &where;
run;
%mend;

%run_ar(falls_2, OC079 ne 8 and (OC079 ne 8 or OC081 ne .))
%run_ar(adl, ADL_BATH ne . and ADL_WALK ne . )
%run_ar(IADL, G_IADL_MEDS ne .Z )
%run_ar(INCONTINENT, OC087 in (1,5))
%run_ar(cogfunction, Cognitive function, Cognitively intact, Cognitive impariment not dementia, Dementia)
