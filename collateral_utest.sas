

 ************************************************************************************************
                                                                                                *
 Assertion 1:ReportingPartyLEi is not equal to NonreportingPartyLEI.                            *
 Assertion 2:There are no missing NonreportingPartyLEI's.                                       *
 Assertion 3:For delegated clients NonreportingPartyLEI field has FFS LEI only.                 *
 Assertion 4:There are no duplicate CollateralPortfolioCode's.                                  *
 Assertion 5:For institutional clients "LEI" is populated for NonReportingPartyIDType field.    *
 Assertion 6:For individual clients "CLC" is populated for NonReportingPartyIDType field.       *
 Assertion 7:Posted fields are reported if Collateralization field populated as "PC".           *
                                                                                                *
 ************************************************************************************************
 ;

 options mprint;

 %macro collateral_unit_test(filename=collateral1, report=True);

   %global test1 test2 test3 test3 test5 test6 test7;

   %if %sysfunc(exist(work.&filename)) %then %do;

      proc sort data=&filename dupout=portfolio_codes_dup nodupkey; by tmp5; run;

      data _null_;
       if 0 then set portfolio_codes_dup nobs=n;
         call symputx('test4',n);
         stop;
      run;

      %let assertion1=tmp1=tmp3;
      %let assertion2=tmp3=" ";
      %let assertion3=index(tmp5,'delegated') and tmp3^=cfh_lei;
      %let assertion5=length(id_number) ge 20 and tmp2^='LEI';
      %let assertion6=id_number in (" " "NULL") and tmp2^='CLC';
      %let assertion7=tmp22='PC' and (tmp8=" " or tmp9=" " or tmp14=" " or tmp15=" ");

      data _null_;
        set &filename end=eof;
         array test_cases[7] test1-test7;
          call symput('n_test',dim(test_cases));
          cfh_lei='549300FSY1BKNGVUOR59';
          if &assertion1 then test1 +1;
          if &assertion2 then test2 +1;
          if &assertion3 then test3 +1;
          if &assertion5 then test5 +1;
          if &assertion6 then test6 +1;
          if &assertion7 then test7 +1;

         if eof then do;
            call symputx('test1',test1);
            call symputx('test2',test2);
            call symputx('test3',test3);
            call symputx('test5',test5);
            call symputx('test6',test6);
            call symputx('test7',test7);
         end;

      run;

      %do i=1 %to &n_test;
         %if &&test&i=0 %then %do;
              %put NOTE: Assertion &i: Passed!;
         %end;
         %else %do;
             %put WARNING: Assertion &i: Failed!;
         %end;
      %end;


      %if &report=True %then %do;

         data summary;
            do j=1 to &n_test;
              Assertions=cats("Assertion",j);
              failed=symget(cats("test",j));
              output;
            end;
            drop j;
         run;

         proc print data=summary; run;

         data report0;
           set %report_builder
               portfolio_codes_dup(in=_f4);
               %conditional;
               if _f4 then part="file4";
         run;

         data collateral_unit_test_report1;
          length failed $50;
           set report0;
            by part;
             n=compress(part,,'kd');
             if FIRST.part then failed=cat("Assertion ", strip(n), " failed trades:");
             drop part n;
         run;

      %end;


   %end;


 %mend;

 %macro report_builder(start=1,end=7);

        %do i=1 %to &end;
           %if &i^=4 %then %do;
             &filename(in=f&i where=(&&assertion&i))
           %end;
        %end;

 %mend;


 %macro conditional(start=1,end=7);

        %do i=1 %to &end;
           %if &i^=4 %then %do;
              if f&i then part="file&i";
           %end;
        %end;

 %mend;

 %collateral_unit_test;