libname mixed 'C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/';

/*1. DATA DESCRIPTION*/
/*Data input*/
data patients;
	set mixed.adl;
	TIMESCALE=log(time);
	age=age-78.5;
run;
proc print data=patients;
run;


/*Exploratory analysis*/
proc means data=patients;
	var age adl; *important continuous variables;
run;
proc means data=patients;
	class neuro time;
	var adl;
run;
proc means data=patients;
	class time; var adl; *adl decreases over time;
run;
proc freq data=patients;
	table neuro time housing; *important categorical variables;
	table neuro*housing neuro*time / nocol norow;
run;
proc corr data=patients cov;
	var neuro adl time age;
run;
	*positive correlation between adl-age and adl-neuro;
	*negative correlation between adl-time;
	
/*Linear plots*/
proc sgplot data=patients;
	series x=timescale y=adl;
	reg x=timescale y=adl / lineattrs=(color=red);
run;
proc sgpanel data=patients;
	panelby neuro / columns=2 onepanel sparse;
	series x=timescale y=adl;
	reg x=timescale y=adl / lineattrs=(color=red);
run;
proc sgpanel data=patients;
	panelby housing / columns=3 onepanel sparse;
	series x=timescale y=adl;
	reg x=timescale y=adl / lineattrs=(color=red);
run;


/*2. LINEAR MIXED MODEL*/
/*Explaining log-transformation*/
proc sgplot data=patients;
	scatter x=time y=adl;
	loess x=time y=adl / degree=2 lineattrs=(color=red);
run;

/*Residual plot*/
proc glm data=patients;
	model adl=timescale neuro housing age timescale*neuro timescale*housing timescale*age / solution;
run;
proc import datafile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/Patients.xlsx" replace out=work.res dbms=xlsx ;
run;
proc print data=res;run;
proc sgplot data=res;
	series x=timescale y=residual;
	reg x=timescale y=residual / lineattrs=(color=red);
run;

/*General model, with no random effects*/
proc glm data=patients;
	class neuro;
	model adl=timescale neuro / solution;
run; *timescale and neuro are significant;
/*Mixed model - 1: Basic*/
proc mixed data=patients;
	class neuro id;
	model adl=timescale neuro / solution;
	random id;
run; *really high covariance for id;
/*Mixed model - 2: Interaction*/
proc mixed data=patients;
	class neuro id;
	model adl=timescale neuro timescale*neuro / solution;
	random id;
run; *neuro=0 provides faster recovery (interaction is significant);
/*Mixed model - 3: Random intercept*/
proc mixed data=patients;
	class neuro id;
	model adl=timescale neuro timescale*neuro / noint solution;
	random intercept / subject=id;
run;
/*Mixed model - 4: Random intercept and random slope*/
proc mixed data=patients;
	class neuro(ref="0") id;
	model adl=neuro timescale timescale*neuro / solution;
	random intercept timescale / type=un subject=id g gcorr v vcorr;
run; *Type 3 tests of fixed effects are different;


/*Observed and fitted variance functions*/
data variance_structure;
	input time observed estimated;
	timescale=log(time);
	datalines;
1 12.6195 11.5259
5 20.3330 16.5887
12 27.6672 22.1659
	;
run;
proc print data=variance_structure;
run;
proc sgplot data=variance_structure;
	series x=timescale y=observed;
	series x=timescale y=estimated;
	yaxis label="variance";
run;


/*3. RANDOM EFFECT ESTIMATES AND SCATTERPLOTS*/
/*Model with random intercept + random slope*/
proc mixed data=patients;
	class neuro id;
	model adl=timescale neuro timescale*neuro / solution outpm=predmean outp=pred;
	random intercept timescale / type=un subject=id solution;
	ods listing exclude solutionr;
	ods output solutionr=out;
	/*store out=out; *required for plm plotting;*/
run;

/*Scatterplot for only random effect estimates*/
data random_int;
	set out;
	rename estimate=intercept;
	where effect="Intercept";
run;
data random_slope;
	set out;
	rename estimate=slope;
	where effect="TIMESCALE";
data random(drop=timescale);
	set random_int(keep=intercept);
	set random_slope(keep=slope);
	set patients(keep=neuro timescale);
		where (timescale=0);
run;
proc print data=random; run;
proc sgplot data=random;
	scatter x=intercept y=slope / group=neuro;
	reg x=intercept y=slope / group=neuro;
run;
proc print data=predmean; *calculation of predicted means (basic regression);
proc print data=pred; *calculation of predictions at cluster level (random effects included);
run;
proc univariate data=random;
	histogram intercept slope;
run;
/*Exporting random effects data. Some data analysis made in R.*/
proc export data=out dbms=xlsx outfile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/Solution for Random Effects" replace;
run;

/*Scatterplot*/
proc import datafile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/scatterplot.csv" replace out=work.scatterplot dbms=csv ;
run;
proc print data=scatterplot;
run;
proc sgplot data=scatterplot;
	scatter y=slope x=intercept / group=neuro;
	reg y=slope x=intercept / group=neuro;
run;

/*Scatterplot part 4*/
proc import datafile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/scatterplot4.csv" replace out=work.scatterplot4 dbms=csv ;
run;
proc print data=scatterplot4;
run;

proc import datafile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/rand4.csv" replace out=work.rand4 dbms=csv ;
run;
proc print data=rand4;
run;

proc sgplot data=scatterplot4;
	scatter y=slope x=intercept / group=neuro;
	reg y=slope x=intercept / group=neuro;
run;
proc sgplot data=rand4;
	scatter y=slope x=intercept / group=neuro;
	reg y=slope x=intercept / group=neuro;
run;

/*Plots - Audrie's code*/
proc print data=out;
run;
proc plm restore=out;
effectplot fit(x=timescale plotby=neuro);
effectplot slicefit(x=timescale sliceby=neuro);
run;

/*4. ADDING COVARIATES TO THE MODEL*/
/*Mixed Model 1: Model with all interactions*/
proc mixed data=patients;
	class  neuro id housing;
	model adl=neuro housing age timescale
			  neuro*timescale housing*timescale age*timescale neuro*housing neuro*age housing*age
			  neuro*housing*age neuro*housing*timescale neuro*age*timescale housing*age*timescale
			  neuro*housing*age*timescale/ solution;
	random intercept timescale /subject=id g solution;
	ods listing exclude solutionr;
	ods output solutionr=out2;
run; *Really messy, no significance in all parameter estimates.;
/*Mixed Model 2: Model with 2 level interactions*/
proc mixed data=patients;
	class  neuro id housing;
	model adl=neuro housing age timescale
			  neuro*timescale housing*timescale age*timescale neuro*housing neuro*age housing*age / solution;
	random intercept timescale /subject=id g solution;
	ods listing exclude solutionr;
	ods output solutionr=out2;
run;  *timescale, timescale*neuro, timescale*age significant.;
/*Mixed Model 3: Model with only significant interactions*/
proc mixed data=patients;
	class  neuro(ref="0") id housing(ref="2");
	model adl=neuro timescale housing age
			  timescale*neuro timescale*age/ solution;
	random intercept timescale /subject=id g solution;
	ods listing exclude solutionr;
	ods output solutionr=out2;
	store out=out2;
run; *All are significant. When you add housing, neuro is not significant.;
/*Compare the random effects with the model selected in part 2.*/


/*5. DICHOTOMIZATION OF ADL*/
proc plm restore=out2;
	effectplot fit (x=timescale plotby=neuro);
	effectplot slicefit (x=timescale sliceby=neuro);
run; *17?;
/*Weighted average of adl by neuro: 15?*/

data patients2;
	set mixed.adl;
	if adl<17 then adl=0;
	if adl>=17 then adl=1;
	timescale=log(time);
run;

proc means data=patients2;
	var adl;
run;

proc print data=patients2;
run;

/*6. LOGISTIC MIXED MODEL*/
/*Model 1.1: Random intercept + random slope (no type)*/
proc glimmix data=patients2;
	class  neuro(ref="0") id;
	model adl(event='1')=neuro timescale timescale*neuro/ dist=binary solution;
	random intercept timescale /  subject=id solution;
	ods listing exclude solutionr;
	ods output solutionr=out2;
	store out=out2;
run; *type=un and type=un(1) are different;

/*Model 1.2: Random intercept + random slope (type=un)*/
proc glimmix data=patients2;
	class neuro(ref="0") id;
	model adl(event='1')=neuro timescale neuro*timescale / dist=binary solution;
	random intercept timescale /type=un subject=id solution;
	ods listing exclude solutionr;
	ods output solutionr=out2;
	store out=out2;
run;

/*Model 1.3: Random intercept + random slope (type=un(1))*/
proc glimmix data=patients2;
	class  neuro(ref="0") id;
	model adl(event='1')=neuro timescale timescale*neuro/ dist=binary solution;
	random intercept timescale / type=un(1) subject=id g v solution;
	estimate 'slope differences' neuro*timescale 1 -1;
	ods listing exclude solutionr;
	ods output solutionr=out2;
	store out=out2;
run;
proc export data=out2 dbms=xlsx outfile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/glimmix" replace;
run;
proc sgplot data=patients2;
	series x=time y=adl / group=neuro;
	reg x=time y=adl / lineattrs=(color=red);
run;

proc sgpanel data=patients2;
	panelby neuro / columns=2 onepanel sparse;
	series x=timescale y=adl;
	reg x=timescale y=adl / lineattrs=(color=red);
run;

/*Model 2.1: Random intercept, comparison of slopes (no type)*/
proc glimmix data=patients2;
	class neuro(ref="0") id;
	model adl(event='1')=neuro timescale neuro*timescale /dist=binary solution;
	random intercept / subject=id g v solution;
	estimate 'slope differences' neuro*timescale 1 -1;
	ods listing exclude solutionr;
	ods output solutionr=out_log;
run; *some random estimates are the same for some patients;

/*Model 2.2: Random intercept, comparison of slopes  (type=un)*/
proc glimmix data=patients2;
	class neuro(ref="0") id;
	model adl(event='1')=neuro timescale neuro*timescale /dist=binary solution;
	random intercept / type=un subject=id g v solution;
	estimate 'slope differences' neuro*timescale 1 -1;
	ods listing exclude solutionr;
	ods output solutionr=out_log;
run; *some random estimates are the same for some patients;

/*Model 2.3: Random intercept, comparison of slopes  (type=un(1))*/
proc glimmix data=patients2;
	class neuro(ref="0") id;
	model adl(event='1')=neuro timescale neuro*timescale /dist=binary solution;
	random intercept / type=un(1) subject=id g v solution;
	estimate 'slope differences' neuro*timescale 1 -1;
	ods listing exclude solutionr;
	ods output solutionr=out_log;
run; *some random estimates are the same for some patients;

/*ULTIMATE GLIMMIX MODEL: RANDOM INTERCEPT ONLY*/
proc glimmix data=patients2;
	class neuro(ref="1") id;
	model adl(event='1')=neuro timescale neuro*timescale / noint dist=binary solution;
	random intercept / subject=id g v solution;
	ods listing exclude solutionr;
	estimate 'slope differences' neuro*timescale 1 -1;
	ods output solutionr=out_log;
run;
proc export data=out_log dbms=xlsx outfile="C:/Users/tejksedopc/Desktop/Classes/Concepts of Multilevel, Longitudinal and Mixed Models/glimmix random estimates" replace;
run;


/*EVOLUTION PLOTS*/
/*Average evolution*/
data h;
	do neuro=0 to 1 by 1;
		do id=1 to 1000 by 1;
			b=sqrt(3.2852)*rannor(-1);
			do timescale=0 to 3 by 0.05;
				time=exp(timescale);
				if neuro=0 then y=exp(0.4385 + b -0.8696*timescale)/(1+ exp(0.4385 + b -0.8696*timescale));
					else y=exp(0.4385 + 1.2806 + b + (-0.8696+0.6360)*timescale)/(1+ exp(0.4385 + 1.2806 + b + (-0.8696+0.6360)*timescale));
				output;
			end;
		end;
	end;
run;
proc sort data=h;
	by timescale neuro;
run;
proc means data=h;
	var y;
	by timescale neuro;
	output out=out;
run;
proc gplot data=out;
	plot y*timescale=neuro / haxis=axis1 vaxis=axis2 legend=legend1;
	axis1 label=(h=2 'Timescale') value=(h=1.5) order=(0 to 3.2 by 0.2) minor=none;
	axis2 label=(h=2 A=90 'P{adl=1}') value=(h=1.5) order=(0 to 1 by 0.1) minor=none;
	legend1 label=(h=1.5 'Neuro: ') value=(h=1.5 '0' '1');
 	title h=2.5 'Marginal average evolutions (GLMM)';
	symbol1 c=red i=join w=2 l=1 mode=include;
	symbol2 c=blue i=join w=2 l=1 mode=include;
	where _stat_='MEAN';
run; quit; run;
proc sort data=h;
	by time neuro;
run;
proc means data=h;
	var y;
	by time neuro;
	output out=out;
run;
proc gplot data=out;
	plot y*time=neuro / haxis=axis1 vaxis=axis2 legend=legend1;
	axis1 label=(h=2 'Time (day)') value=(h=1.5) order=(0 to 22 by 2) minor=none;
	axis2 label=(h=2 A=90 'P{adl=1}') value=(h=1.5) order=(0.1 to 1 by 0.1) minor=none;
	legend1 label=(h=1.5 'Neuro: ') value=(h=1.5 '0' '1');
 	title h=2.5 'Marginal average evolutions (GLMM)';
	symbol1 c=red i=join w=2 l=1 mode=include;
	symbol2 c=blue i=join w=2 l=1 mode=include;
	where _stat_='MEAN';
run; quit; run;
/*Evolution of average subject*/
data h2;
	do neuro=0 to 1 by 1;
		do id=1 to 1000 by 1;
			do timescale=0 to 3 by 0.05;
				time=exp(timescale);
				if neuro=0 then y=exp(0.4385 -0.8696*timescale)/(1+ exp(0.4385 -0.8696*timescale));
					else y=exp(0.4385 + 1.2806 + (-0.8696+0.6360)*timescale)/(1+ exp(0.4385 + 1.2806 + (-0.8696+0.6360)*timescale));
				output;
			end;
		end;
	end;
run;
proc sort data=h2;
	by timescale neuro;
run;
proc means data=h2;
	var y;
	by timescale neuro;
	output out=out2;
run;
proc gplot data=out2;
	plot y*timescale=neuro / haxis=axis1 vaxis=axis2 legend=legend1;
	axis1 label=(h=2 'Timescale') value=(h=1.5) order=(0 to 3.2 by 0.2) minor=none;
	axis2 label=(h=2 A=90 'P{adl=1}') value=(h=1.5) order=(0 to 1 by 0.1) minor=none;
	legend1 label=(h=1.5 'Neuro: ') value=(h=1.5 '0' '1');
 	title h=2.5 'Evolutions for average subjects (GLMM)';
	symbol1 c=red i=join w=2 l=1 mode=include;
	symbol2 c=blue i=join w=2 l=1 mode=include;
	where _stat_='MEAN';
run; quit; run;
proc sort data=h2;
	by time neuro;
run;
proc means data=h2;
	var y;
	by time neuro;
	output out=out2;
run;
proc gplot data=out2;
	plot y*time=neuro / haxis=axis1 vaxis=axis2 legend=legend1;
	axis1 label=(h=2 'Time (day)') value=(h=1.5) order=(0 to 22 by 2) minor=none;
	axis2 label=(h=2 A=90 'P{adl=1}') value=(h=1.5) order=(0 to 0.9 by 0.1) minor=none;
	legend1 label=(h=1.5 'Neuro: ') value=(h=1.5 '0' '1');
 	title h=2.5 'Evolutions for average subjects (GLMM)';
	symbol1 c=red i=join w=2 l=1 mode=include;
	symbol2 c=blue i=join w=2 l=1 mode=include;
	where _stat_='MEAN';
run; quit; run;
