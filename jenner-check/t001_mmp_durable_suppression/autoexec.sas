/* cap input rows for the captured run */
options obs=100;

/* sample data standing in for the EHARS extracts and the MMP dataset */
libname person ".";
libname document ".";
libname mmp ".";

data link;
  length parid $6 stateno $8;
  input parid $ stateno $;
  datalines;
P001 S001
P002 S002
P003 S003
P004 S004
P005 S005
P006 S006
;
run;

data mmp.mmp1521_union_wa;
  length parid $6;
  input parid $ idate :mmddyy10.;
  format idate mmddyy10.;
  datalines;
P001 06/01/2016
P002 06/01/2016
P003 06/01/2016
P004 06/01/2016
P005 06/01/2016
P007 06/01/2016
;
run;

data person.person;
  length stateno $8 ehars_uid $6 hiv_aids_dx_dt $8;
  input stateno $ ehars_uid $ hiv_aids_dx_dt $;
  datalines;
S001 E001 20100312
S002 E002 201205..
S003 E003 2008....
S004 E004 20110720
S005 E005 .
S006 E006 20130105
;
run;

data document.document;
  length ehars_uid $6 document_uid $6;
  input ehars_uid $ document_uid $;
  datalines;
E001 D001
E002 D002
E003 D003
E004 D004
E005 D005
E006 D006
;
run;

data document.lab;
  length document_uid $6 lab_test_cd $6 result $8 result_interpretation $8 sample_dt $8;
  input document_uid $ lab_test_cd $ result $ sample_dt $;
  result_interpretation=' ';
  datalines;
D001 EC-014 150 20150910
D001 EC-014 100 20160315
D001 EC-060 50 20160801
D002 EC-014 5000 20150810
D002 EC-014 80 20160115
D002 EC-060 900 20160701
D003 EC-014 20000 20151010
D003 EC-014 15000 20160215
D004 EC-014 100 20151210
D004 EC-014 250 20160415
D004 EC-099 7 20160415
D005 EC-014 . 2016..10
;
run;
