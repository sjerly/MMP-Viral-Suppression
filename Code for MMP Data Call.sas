/*Program to create variable indicating durable viral suppression at MMP interview.
	Output dataset is named "mmp3" and contains variable "suppressed_long"
	More information can be found here: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10285601/*/

/*Setting Up Libraries*/
libname person "C:\SAS_Datasets\person_dataset";
libname document "C:\SAS_Datasets\document_dataset"; 
libname mmp "C:\MMP\Analytic datasets\2015-2021 Stacked Dataset\WA\Datasets";
options nofmterr;

/*File to connect Parid to stateno.  Should contain 1 column named parid and 1 column named stateno*/
proc import file="C:\MMP\Stateno Files for Import\2015.xlsx" replace dbms=xlsx
out=link;
run;

/*Name of MMP dataset*/
%let mmp=mmp1521_union_wa;


/**********************************THE BELOW SHOULD NOT NEED MODIFICIATION**********************************/
/*Reading in MMP and Adding Stateno to Link to EHARS*/
data mmp;
set mmp.&mmp.;
run;

proc sql;
create table mmp2 as
select mmp.parid, link.stateno, mmp.idate
from mmp inner join link
on mmp.parid=strip(link.parid);
quit;

/*Defining a function to convert ehars dates into SAS Dates*/
options cmplib=work.function;
proc fcmp outlib=work.function.eharsdate;
   function eharsdate(var_in $);
		if substr(var_in,1,1)="." or var_in="" then var_out=.;
		else if substr(var_in,5,1)="." and substr(var_in,7,1)="." then var_out=input("06/15/"||strip(substr(var_in,1,4)),mmddyy10.);
		else if substr(var_in,5,1)="." then var_out=input("06/"||strip(substr(var_in,7,2))||"/"||strip(substr(var_in,1,4)),mmddyy10.);
		else if substr(var_in,7,1)="." then var_out=input(strip(substr(var_in,5,2)||"/15/"||strip(substr(var_in,1,4))),mmddyy10.);
		else var_out=input(strip(substr(var_in,5,2)||"/"||strip(substr(var_in,7,2))||"/"||strip(substr(var_in,1,4))),mmddyy10.);
   return(var_out);
   endsub;
run;

/*Calculating durable viral suppression*/
proc sql;
create table doc as
select person.stateno, mmp2.parid, document.document_uid, eharsdate(hiv_aids_dx_dt) as dx_dt, idate
from person.person inner join mmp2
on person.stateno=mmp2.stateno
left join document.document
on document.ehars_uid=person.ehars_uid;

create table labs as
select doc.*, result, result_interpretation, eharsdate(sample_dt) as sample_dt
from doc left join document.lab
on doc.document_uid=lab.document_uid
where lab_test_cd in ("EC-014" "EC-060"); /*Just viral load tests*/
quit;

proc sort data=labs;
by stateno sample_dt result;
run;
proc sort data=labs nodupkey;	/*Deduplicating labs taken on the same date*/
by stateno sample_dt;
where input(result,8.0) ne .;
run;

/*Taking Labs representing the 2 year period centering on the interview date*/
data labs2;
set labs;
resultn=input(result,8.0);
if idate+365.25>=sample_dt>=idate-365.25;
format sample_dt dx_dt mmddyy10.;
run;

/*Appying Suppression Rules*/
data Long;
set labs2;
by stateno;
retain eversupp losssup firstsupp;
if first.stateno then do; 
	eversupp=0; 
	losssup=0; 
	if .<resultn<200 then firstsupp=1; else firstsupp=0; 
end;

if resultn lt 200 then eversupp=1;
if eversupp=1 and resultn>=200 then losssup=1;


if last.stateno then do;
	if eversupp=0 then class=3;				/*People who were never suppressed*/
	else if losssup=1 then class=2;			/*People who lost suppression during the time period (unstably suppressed)*/
	else if firstsupp=0 then class=1;		/*People who became suppressed during the time period*/
	else class=0;							/*People who were suppressed the whole time*/
end;

if class in (0 1) then suppressed_long=1;
else suppressed_long=0;

if last.stateno then output;
run;

/*Merging back onto original mmp dataset so that we include people who never got labs*/
proc sort data=mmp2;
by stateno;
run;

data mmp3;
merge mmp2 (in=a) long (keep=stateno class suppressed_long);
by stateno;
if a;
if suppressed_long=. then do; class=3; suppressed_long=0; end;
run;

proc freq data=mmp3;
table suppressed_long;
run;
