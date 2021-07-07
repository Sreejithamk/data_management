*SAS Codes_sample 1;
*Statistical analysis on blood cholesterol broken down by education status and gender; 

%let dir = /folders/myfolders/SAS /Data Files; 
proc import table="dem" dbms=accesscs out=temp replace;  
  database="/folders/myfolders/SAS /Data Files/NIV.mdb";  
run; 
proc print; run; 

proc import datafile="/folders/myfolders/SAS /Data Files/Demographics.csv"  out=demog replace;  
run; 
proc print; run; 

proc import datafile="/folders/myfolders/SAS /Data Files /BloodLipids.csv"  out=blood replace;  
run; 
proc print; run; 

proc import datafile="/folders/myfolders/SAS /Data Files /VitaminC.csv"  out=vitc replace;  
run; 
proc print; run;

*Match-merge the three data sets by the common ID variable; 
proc sort data=Demog; by ID; run; 
proc sort data=Blood; by ID; run; 
proc sort data=VitC; by ID; run; 
 
data mix; 
 merge Demog Blood VitC; 
 by ID; 
 if Choltot =. then delete; 
run; 
proc print; run;

*Define formats for EDUC, gender, marital and smoking status, and bmi; 
proc format; 
 value     EDUC 1-4 = "Some or less" 
			    5-7 = "College graduate"; 
 value        Sex 1 = "Male" 
 		          2 = "Female"; 
 value    Marital 0 = "Never married" 
 		  		  1 = "Married" 
 				  2 = "Widowed" 
 				  3 = "Divorced/separated"; 
 value 	    Smoke 0 = "Never" 
	        	  1 = "Past" 
		     	  2 = "Current"; 
 value  bmi     low-<25 = "Normal" 
 		    25-<30  = "Overweight" 
 		    30-high = "Obese"; 
run;

*Means, SDs and counts of total cholesterol,  
broken down by gender and education; 
proc tabulate data=mix; 
 format EDUC EDUC. Sex Sex.; 
 class EDUC Sex; 
 var CHOLTOT; 
 table EDUC = '', Sex * CHOLTOT = '' * (N mean StdDev) / box= 'Education'; run;

*Categorize BMI; 
Data Probmi; set mix; 
  BMI = (Weight * 0.4536) / ((feet*12+inch)*0.0254)**2; run; 
proc print; run;

*Frequency table on BMI; 
proc freq; 
 format bmi bmi.; 
 table bmi; run;

*Means and SDs of blood cholesterols by BMI categories; 
proc tabulate data=probmi; 
 format bmi bmi.; 
 class bmi ; 
 var CHOLTOT HDL LDL TRIG LDLHDL CHOL_HDL; 
 table (CHOLTOT HDL LDL TRIG LDLHDL CHOL_HDL) * (mean StdDev) ,  bmi / box= 'Cholesterol'; run;

*Correlations between blood vitamin E and cholesterol variables; 
ods trace on; 
proc corr data=probmi; 
 var VitE; 
 with CHOLTOT HDL LDL TRIG LDLHDL CHOL_HDL; 
ods output PearsonCorr=PCorr; run; 
ods trace off; 
proc print data=PCorr; run;


*SAS Codes_sample 2;
* Data is from the National Cooperative Gallstone study to evaluate the effect of the drug chenodiol for the treatment of cholesterol gallstones. Forty-one patients received the placebo, while 62 patients received the drug. Serum cholesterol was measured in all patients at baseline and month 6, 12, 20 and 24. 
data New; 
 infile "/folders/myfolders/SAS/Data Files/NCGS cholesterol.dat"; 
 input Group PatientID Month0 Month6 Month12 Month20 Month24; 
 ID= (Group * 100) + PatientID; run; 
proc print; run;

*Frequency table of patients by group; 
proc freq data=new; 
 tables group; run;

*Compute mean serum cholesterol over months by group; 
proc tabulate data=New; 
 class Group; 
 var Month:;  
 table Group * (Month0 Month6 Month12 Month20 Month24 )* mean; run;

*Convert the wide-format data into a long-format data;
proc sort data=new; 
 by ID Group; run; 
proc transpose data=New out=TransNewLong; 
 by ID Group; 
 var month0 month6 month12 month20 month24; run; 
proc print;run;

*Compute mean serum cholesterol over months by group;
data TransNewLong; 
 set TransNewLong (rename = (col1=chol)); 
 month=substr (_name_, 6) + 0; 
 drop _name_; run; 
 proc print; run; 
 
 proc tabulate data=TransNewLong; 
 class group month; 
 var chol; 
 table group, month * chol * mean; run;

*Create a profile plot of cholesterol over time to see the trend;
proc sort data=TransNewLong; by ID group; run; 
proc sgplot data=New_long; series x = month y = chol / group = ID; run;

*Create a smooth line plot by group;
proc sort data=TransNewLong; by ID month; run; 
proc sgpanel data=TransNewLong; panelby group / columns=2 rown=1;  
 series x = month y = chol / group = ID lineattrs=(color=lightgray patern=1); 
 pbspline x = month y = chol / group=group nomarkers lineattrs=(thickness=5);
run;
