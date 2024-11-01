 %MACRO V2824T2M(INP=, IND=, OUTDATA=, IDVAR=, KEEPVAR=, SEDITS=,
                 DATE_ASOF=, DATE_ASOF_EDIT=, 
                 FMNAME0  =012428Y23Y24NC, 
                 AGEFMT0  =IAGEHYBCY23MCE, 
                 SEXFMT0  =ISEXHYBCY23MCE, DF=1, 
                 AGESEXMAC=AGESEXV2, LABELMAC=V28115L3, 
                 EDITMAC0=V28I0ED2,  
                 HIERMAC=V28115H1, SCOREMAC=SCOREVAR);

%**********************************************************************
 * Score variables are created using coefficients from 9 final models:
 *  1) Community NonDual Aged
 *  2) Community NonDual Disabled
 *  3) Community Full Benefit Dual Aged
 *  4) Community Full Benefit Dual Disabled
 *  5) Community Partial Benefit Dual Aged
 *  6) Community Partial Benefit Dual Disabled
 *  7) Long Term Institutional
 *  8) New Enrollees
 *  9) SNP New Enrollees
 *
 * Assumptions about input files:
 *   - both files are sorted by person ID
 *   - person level file has the following variables:
 *     :&IDVAR   - person ID variable (it is a macro parameter)
 *     :DOB      - date of birth
 *     :SEX      - sex
 *     :OREC     - original reason for entitlement
 *     :LTIMCAID - Medicaid dummy variable for LTI
 *     :NEMCAID  - Medicaid dummy variable for new enrollees
 *
 *   - diagnosis level file has the following variables:
 *     :&IDVAR  - person ID variable (it is a macro parameter)
 *     :DIAG    - diagnosis
 *
 * Parameters:
 * INP            - input person dataset
 * IND            - input diagnosis dataset
 * OUTDATA        - output dataset
 * IDVAR          - name of person id variable (MBI for Medicare data)
 * KEEPVAR        - variables to keep in the output file
 * SEDITS         - a switch that controls whether to perform MCE edits 
 *                  on ICD10. 1-YES, 0-NO
 * DATE_ASOF      - reference date to calculate age. Set to February 1
 *                  of the payment year for consistency with CMS.
 * DATE_ASOF_EDIT - reference date to calculate age used for 
 *                  validation of diagnoses (MCE edits)
 * FMNAME0        - format name (crosswalk ICD10 to V28 CCs)
 * AGEFMT0        - format name (crosswalk ICD10 to acceptable age range
 *                  in case MCE edits on diags are to be performed)
 * SEXFMT0        - format name (crosswalk ICD10 to acceptable sex in 
 *                  case MCE edits on diags are to be performed)
 * DF             - normalization factor.
 *                  Default=1
 * AGESEXMAC      - external macro name: create age/sex,
 *                  originally disabled, disabled vars
 * EDITMAC0       - external macro name: perform edits to ICD10
 * LABELMAC       - external macro name: assign labels to HCCs
 * HIERMAC        - external macro name: set HCC=0 according to
 *                  hierarchies
 * SCOREMAC       - external macro name: calculate a score variable
 *
 **********************************************************************;

 %**********************************************************************
 * step1: include external macros
 **********************************************************************;
 %IF "&AGESEXMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&AGESEXMAC) /SOURCE2; %* create demographic variables;
 %END;
 %IF "&EDITMAC0" ne "" %THEN %DO;
     %INCLUDE IN0(&EDITMAC0)   /SOURCE2; %* perform edits on ICD10;
 %END;
 %IF "&LABELMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&LABELMAC)  /SOURCE2; %* hcc labels;
 %END;
 %IF "&HIERMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&HIERMAC)   /SOURCE2; %* hierarchies;
 %END;
 %IF "&SCOREMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&SCOREMAC)  /SOURCE2; %* calculate score variable;
 %END;

 %**********************************************************************
 * step2: define internal macro variables
 **********************************************************************;

 %LET HCClist=&HCCV28_list115;
 %LET CClist=&CCV28_list115;
 %LET N_CC=%sysfunc(countw(&HCClist)); %*# of HCCs in payment model;
 %PUT "number of HCCs in payment model: " &N_CC;                                                                           
 %PUT "HCC list: "  &HCClist;                         

 %* age/sex variables for Community Aged regression;
 %LET AGESEXVA=                                    F65_69
                F70_74 F75_79 F80_84 F85_89 F90_94 F95_GT
                                                   M65_69
                M70_74 M75_79 M80_84 M85_89 M90_94 M95_GT;

 %* age/sex variables for Community Disabled regression;
 %LET AGESEXVD= F0_34  F35_44 F45_54 F55_59 F60_64
                M0_34  M35_44 M45_54 M55_59 M60_64;


 %* diagnostic categories necessary to create interaction variables;
 %LET DIAG_CAT= %STR(CANCER_V28                                                   
                     DIABETES_V28                                                 
                     CARD_RESP_FAIL                                               
                     HF_V28                                                       
                     CHR_LUNG_V28
                     KIDNEY_V28                                                   
                     SEPSIS                                                       
                     gSubUseDisorder_V28                                          
                     gPsychiatric_V28   
                     NEURO_V28
                     ULCER_V28 
                );                                                                            
                                                                                                
                                                                                               
 %LET ADDZ=%STR(                                                                                
  D1 D2 D3 D4 D5 D6 D7 D8 D9 D10P                                                                 
  );                                                                                                    
                                                                                                        
 %*orig disabled interactions for Community Aged regressions;                                           
 %LET ORIG_INT =%STR(OriginallyDisabled_Female OriginallyDisabled_Male);                                
                                                                                                     
 %*interaction variables for Community Aged regressions;                                             
 %LET INTERRACC_VARSA=%STR(DIABETES_HF_V28                                                                      
                           HF_CHR_LUNG_V28                                                                      
                           HF_KIDNEY_V28                                                                        
                           CHR_LUNG_CARD_RESP_FAIL_V28                                                          
                           HF_HCC238_V28                                                                         
           );                                                                                        
                                                                                                     
 %*interaction variables for Community Disabled regressions;                                         
 %LET INTERRACC_VARSD=%STR(DIABETES_HF_V28
                           HF_CHR_LUNG_V28
                           HF_KIDNEY_V28
                           CHR_LUNG_CARD_RESP_FAIL_V28
                           HF_HCC238_V28
                           gSubUseDisorder_gPsych_V28
           );


 %*variables for Community Aged regressions ;
 %LET COMM_REGA= %STR(&AGESEXVA
                      &orig_int
                      &HCClist
                      &INTERRACC_VARSA 
                      &ADDZ);


 %*variables for Community Disabled regressions ;
 %LET COMM_REGD= %STR(&AGESEXVD
                      &HCClist
                      &INTERRACC_VARSD
                      &ADDZ);


 %* age/sex variables for Insititutional regression;
 %LET AGESEXV=  F0_34  F35_44 F45_54 F55_59 F60_64 F65_69
                F70_74 F75_79 F80_84 F85_89 F90_94 F95_GT
                M0_34  M35_44 M45_54 M55_59 M60_64 M65_69
                M70_74 M75_79 M80_84 M85_89 M90_94 M95_GT;


 %*interaction variables for Institutional regression;
 %LET INTERRACI_VARS = %STR(DIABETES_HF_V28             
                            HF_CHR_LUNG_V28             
                            HF_KIDNEY_V28               
                            CHR_LUNG_CARD_RESP_FAIL_V28 
                            DISABLED_CANCER_V28         
                            DISABLED_NEURO_V28          
                            DISABLED_HF_V28         
                            DISABLED_CHR_LUNG_V28       
                            DISABLED_ULCER_V28 
                            );


 %*variables for Institutional regression;
 %LET INST_REG = %STR(&AGESEXV
                      LTIMCAID  ORIGDS
                      &HCClist
                      &INTERRACI_VARS
                      &ADDZ);

 %*age/sex variables for non-ORIGDS New Enrollee and SNP New Enrollee 
 interactions; 
 %LET NE_AGESEXV=
      NEF0_34    NEF35_44   NEF45_54   NEF55_59   NEF60_64
      NEF65      NEF66      NEF67      NEF68      NEF69
      NEF70_74   NEF75_79   NEF80_84
      NEF85_89   NEF90_94   NEF95_GT
      NEM0_34    NEM35_44   NEM45_54   NEM55_59   NEM60_64
      NEM65      NEM66      NEM67      NEM68      NEM69
      NEM70_74   NEM75_79   NEM80_84
      NEM85_89   NEM90_94   NEM95_GT;

 %*age/sex variables for ORIGDS New Enrollee and SNP New Enrollee 
 interactions;
 %LET ONE_AGESEXV=
      NEF65      NEF66      NEF67      NEF68      NEF69
      NEF70_74   NEF75_79   NEF80_84
      NEF85_89   NEF90_94   NEF95_GT
      NEM65      NEM66      NEM67      NEM68      NEM69
      NEM70_74   NEM75_79   NEM80_84
      NEM85_89   NEM90_94   NEM95_GT;

 
 %*variables for New Enrollee and SNP New Enrollee regression;
 %LET NE_REG=%STR(
   NMCAID_NORIGDIS_NEF0_34        NMCAID_NORIGDIS_NEF35_44
   NMCAID_NORIGDIS_NEF45_54       NMCAID_NORIGDIS_NEF55_59
   NMCAID_NORIGDIS_NEF60_64       NMCAID_NORIGDIS_NEF65
   NMCAID_NORIGDIS_NEF66          NMCAID_NORIGDIS_NEF67
   NMCAID_NORIGDIS_NEF68          NMCAID_NORIGDIS_NEF69
   NMCAID_NORIGDIS_NEF70_74       NMCAID_NORIGDIS_NEF75_79
   NMCAID_NORIGDIS_NEF80_84       NMCAID_NORIGDIS_NEF85_89
   NMCAID_NORIGDIS_NEF90_94       NMCAID_NORIGDIS_NEF95_GT
   
   NMCAID_NORIGDIS_NEM0_34        NMCAID_NORIGDIS_NEM35_44
   NMCAID_NORIGDIS_NEM45_54       NMCAID_NORIGDIS_NEM55_59
   NMCAID_NORIGDIS_NEM60_64       NMCAID_NORIGDIS_NEM65
   NMCAID_NORIGDIS_NEM66          NMCAID_NORIGDIS_NEM67
   NMCAID_NORIGDIS_NEM68          NMCAID_NORIGDIS_NEM69
   NMCAID_NORIGDIS_NEM70_74       NMCAID_NORIGDIS_NEM75_79
   NMCAID_NORIGDIS_NEM80_84       NMCAID_NORIGDIS_NEM85_89
   NMCAID_NORIGDIS_NEM90_94       NMCAID_NORIGDIS_NEM95_GT
   
   MCAID_NORIGDIS_NEF0_34         MCAID_NORIGDIS_NEF35_44
   MCAID_NORIGDIS_NEF45_54        MCAID_NORIGDIS_NEF55_59
   MCAID_NORIGDIS_NEF60_64        MCAID_NORIGDIS_NEF65
   MCAID_NORIGDIS_NEF66           MCAID_NORIGDIS_NEF67
   MCAID_NORIGDIS_NEF68           MCAID_NORIGDIS_NEF69
   MCAID_NORIGDIS_NEF70_74        MCAID_NORIGDIS_NEF75_79
   MCAID_NORIGDIS_NEF80_84        MCAID_NORIGDIS_NEF85_89
   MCAID_NORIGDIS_NEF90_94        MCAID_NORIGDIS_NEF95_GT
           
   MCAID_NORIGDIS_NEM0_34         MCAID_NORIGDIS_NEM35_44
   MCAID_NORIGDIS_NEM45_54        MCAID_NORIGDIS_NEM55_59
   MCAID_NORIGDIS_NEM60_64        MCAID_NORIGDIS_NEM65
   MCAID_NORIGDIS_NEM66           MCAID_NORIGDIS_NEM67
   MCAID_NORIGDIS_NEM68           MCAID_NORIGDIS_NEM69
   MCAID_NORIGDIS_NEM70_74        MCAID_NORIGDIS_NEM75_79
   MCAID_NORIGDIS_NEM80_84        MCAID_NORIGDIS_NEM85_89
   MCAID_NORIGDIS_NEM90_94        MCAID_NORIGDIS_NEM95_GT
   
   NMCAID_ORIGDIS_NEF65           NMCAID_ORIGDIS_NEF66
   NMCAID_ORIGDIS_NEF67           NMCAID_ORIGDIS_NEF68
   NMCAID_ORIGDIS_NEF69           NMCAID_ORIGDIS_NEF70_74
   NMCAID_ORIGDIS_NEF75_79        NMCAID_ORIGDIS_NEF80_84
   NMCAID_ORIGDIS_NEF85_89        NMCAID_ORIGDIS_NEF90_94
   NMCAID_ORIGDIS_NEF95_GT    
   
   NMCAID_ORIGDIS_NEM65           NMCAID_ORIGDIS_NEM66
   NMCAID_ORIGDIS_NEM67           NMCAID_ORIGDIS_NEM68
   NMCAID_ORIGDIS_NEM69           NMCAID_ORIGDIS_NEM70_74
   NMCAID_ORIGDIS_NEM75_79        NMCAID_ORIGDIS_NEM80_84
   NMCAID_ORIGDIS_NEM85_89        NMCAID_ORIGDIS_NEM90_94
   NMCAID_ORIGDIS_NEM95_GT
        
   MCAID_ORIGDIS_NEF65            MCAID_ORIGDIS_NEF66
   MCAID_ORIGDIS_NEF67            MCAID_ORIGDIS_NEF68
   MCAID_ORIGDIS_NEF69            MCAID_ORIGDIS_NEF70_74
   MCAID_ORIGDIS_NEF75_79         MCAID_ORIGDIS_NEF80_84
   MCAID_ORIGDIS_NEF85_89         MCAID_ORIGDIS_NEF90_94
   MCAID_ORIGDIS_NEF95_GT    
   
   MCAID_ORIGDIS_NEM65            MCAID_ORIGDIS_NEM66
   MCAID_ORIGDIS_NEM67            MCAID_ORIGDIS_NEM68
   MCAID_ORIGDIS_NEM69            MCAID_ORIGDIS_NEM70_74
   MCAID_ORIGDIS_NEM75_79         MCAID_ORIGDIS_NEM80_84
   MCAID_ORIGDIS_NEM85_89         MCAID_ORIGDIS_NEM90_94
   MCAID_ORIGDIS_NEM95_GT);

 %*macro to create New Enrollee and SNP New Enrollee regression 
 variables;
 %MACRO INTER(PVAR=, RLIST=);
    %LOCAL I;
    %LET I=1;
    %DO %UNTIL(%SCAN(&RLIST,&I)=);
       &PVAR._%SCAN(&RLIST,&I) = &PVAR * %SCAN(&RLIST,&I);
       %LET I=%EVAL(&I+1);
    %END;
 %MEND INTER;              

 %* macro to find CC number in array of CCs; 
 %MACRO FIND_IND;
   %LET J=1;
   %DO %UNTIL( &J > &N_CC) ;
       IF CC="%SCAN(&CClist,&J)"  THEN IND=&J;                                                                                    
       %LET J=%EVAL(&J+1);                                                                                                            
   %END;   
 %MEND FIND_IND;


 %**********************************************************************
 * step3: merge person and diagnosis files outputting one record
 *        per person with score and HCC variables for each input person
 *        level record
 ***********************************************************************;

 DATA &OUTDATA(KEEP=&KEEPVAR );
   %****************************************************
    * step3.1: declaration section
    ****************************************************;

    %IF "&LABELMAC" ne "" %THEN %&LABELMAC;  *HCC labels;

   %* length of new variables (length for other age/sex vars is set in
      &AGESEXMAC macro);
    LENGTH CC $5  
           AGEF 
           OriginallyDisabled_Female  
           OriginallyDisabled_Male
           &NE_REG
           &CClist &HCClist   
           &DIAG_CAT
           &INTERRACC_VARSA
           &INTERRACC_VARSD
           &INTERRACI_VARS 
           AGEF_EDIT 
           HCC_pymt &ADDZ
           3.;

    %*retain cc vars;
    RETAIN &CClist 0  AGEF AGEF_EDIT;
    %*arrays;
    ARRAY C(&N_CC) &CClist ;
    ARRAY HCC(&N_CC) &HCClist ;
    %*interaction vars;
    ARRAY RV &INTERRACC_VARSA &INTERRACC_VARSD 
          &INTERRACI_VARS &DIAG_CAT HCC_pymt &ADDZ;

    %***************************************************
    * step3.2: to bring in regression coefficients
    ****************************************************;
    IF _N_ = 1 THEN SET INCOEF.HCCCOEFN;
    %***************************************************
    * step3.3: merge
    ****************************************************;
    MERGE &INP(IN=IN1)
          &IND(IN=IN2);
    BY &IDVAR;

    IF IN1 THEN DO;

    %*******************************************************
    * step3.4: for the first record for a person set CC to 0
    ********************************************************;

       IF FIRST.&IDVAR THEN DO;
          %*set ccs to 0;
           DO I=1 TO &N_CC;
            C(I)=0;
           END;
           %* age;
           AGEF =FLOOR((INTCK(
                'MONTH',DOB,&DATE_ASOF)-(DAY(&DATE_ASOF)<DAY(DOB)))/12);
           IF AGEF<0 THEN AGEF=0;

           %IF "&DATE_ASOF_EDIT" ne "" %THEN  
           AGEF_EDIT =FLOOR((INTCK('MONTH',DOB,&DATE_ASOF_EDIT)
                -(DAY(&DATE_ASOF_EDIT)<DAY(DOB)))/12);
           %ELSE AGEF_EDIT=AGEF;
           ;
       END;         

    %***************************************************
    * step3.5 if there are any diagnoses for a person
    *         then do the following:
    *         - perform diag edits using macro &EDITMAC0
    *         - create CC using corresponding formats for ICD10
    *         - assign additional CC using provided additional formats
    ****************************************************;

     IF IN1 & IN2 THEN DO;
          %*initialize;
          CC="9999";
          
     %IF "&FMNAME0" NE "" %THEN %DO;     
      %IF "&EDITMAC0" NE "" %THEN 
                 %&EDITMAC0(AGE=AGEF_EDIT,SEX=SEX,ICD10=DIAG); 
            IF CC NE "-1.0" AND CC NE "9999" THEN DO;
               CC="CC" !! LEFT(PUT(CC, 4.));
               %FIND_IND;
               IF 1 <= IND <= &N_CC THEN C(IND)=1;
            END;
            ELSE IF CC="9999" THEN DO;
               ** assignment 1 **;
               CC = "CC" !! LEFT(PUT(LEFT(PUT(DIAG,$IAS1&FMNAME0..)),4.)); 
               %FIND_IND;
               IF 1 <= IND <= &N_CC THEN C(IND)=1;
               ** assignment 2 **;
               CC = "CC" !! LEFT(PUT(LEFT(PUT(DIAG,$IAS2&FMNAME0..)),4.)); 
               %FIND_IND;
               IF 1 <= IND <= &N_CC THEN C(IND)=1;
           END;
          %END;
          
       END; %*CC creation;  


    %*************************************************************
    * step3.6 for the last record for a person do the
    *         following:
    *         - create demographic variables needed (macro &AGESEXMAC)
    *         - create HCC using hierarchies (macro &HIERMAC)
    *         - create HCC interaction variables
    *         - create HCC and DISABL interaction variables
    *         - set HCCs and interaction vars to zero if there
    *           are no diagnoses for a person
    *         - create scores for community models
    *         - create score for institutional model
    *         - create score for new enrollee model
    *         - create score for SNP new enrollee model
    **************************************************************;
       IF LAST.&IDVAR THEN DO;

           %****************************
           * demographic vars
           *****************************;
           %*create age/sex cells, originally disabled, disabled vars;
           %IF "&AGESEXMAC" ne "" %THEN
           %&AGESEXMAC(AGEF=AGEF, SEX=SEX, OREC=OREC);

           %*interaction;
           OriginallyDisabled_Female= ORIGDS*(SEX='2');
           OriginallyDisabled_Male  = ORIGDS*(SEX='1');

           %* NE interactions;
           NE_ORIGDS       = (AGEF>=65)*(OREC='1');
           NMCAID_NORIGDIS = (NEMCAID <=0 and NE_ORIGDS <=0);
           MCAID_NORIGDIS  = (NEMCAID > 0 and NE_ORIGDS <=0);
           NMCAID_ORIGDIS  = (NEMCAID <=0 and NE_ORIGDS > 0);
           MCAID_ORIGDIS   = (NEMCAID > 0 and NE_ORIGDS > 0);

           %INTER(PVAR =  NMCAID_NORIGDIS,  RLIST = &NE_AGESEXV );
           %INTER(PVAR =  MCAID_NORIGDIS,   RLIST = &NE_AGESEXV );
           %INTER(PVAR =  NMCAID_ORIGDIS,   RLIST = &ONE_AGESEXV);
           %INTER(PVAR =  MCAID_ORIGDIS,    RLIST = &ONE_AGESEXV);

           IF IN1 & IN2 THEN DO;
            %**********************
            * hierarchies
            **********************;

            %*heart interaction patch;
            IF CC223 = 1 AND MAX(CC221, CC222, CC224, CC225, CC226) = 0                                                                                                                                          
            THEN CC223 = 0;                                                                                                                                                                     

            %IF "&HIERMAC" ne "" %THEN %&HIERMAC;
            %************************
            * interaction variables
            *************************; 

            %*diagnostic categories;
            CANCER_V28          = MAX(HCC17, HCC18, HCC19, HCC20, HCC21, HCC22, HCC23);
            DIABETES_V28        = MAX(HCC35, HCC36, HCC37, HCC38);
            CARD_RESP_FAIL      = MAX(HCC211, HCC212, HCC213);
            HF_V28              = MAX(HCC221, HCC222, HCC223, HCC224, HCC225, HCC226);
            CHR_LUNG_V28        = MAX(HCC276, HCC277, HCC278, HCC279, HCC280);
            KIDNEY_V28          = MAX(HCC326, HCC327, HCC328, HCC329);
            SEPSIS              = HCC2;
            gSubUseDisorder_V28 = MAX(HCC135, HCC136, HCC137, HCC138, HCC139);
            gPsychiatric_V28    = MAX(HCC151, HCC152, HCC153, HCC154, HCC155);   
            NEURO_V28           = MAX(HCC180, HCC181, HCC182, HCC190, HCC191, HCC192, HCC195, HCC196, HCC198, HCC199);
            ULCER_V28           = MAX(HCC379, HCC380, HCC381, HCC382);   
            
            %*community models interactions ;
            DIABETES_HF_V28               = DIABETES_V28*HF_V28;
            HF_CHR_LUNG_V28               = HF_V28*CHR_LUNG_V28;
            HF_KIDNEY_V28                 = HF_V28*KIDNEY_V28;
            CHR_LUNG_CARD_RESP_FAIL_V28   = CHR_LUNG_V28*CARD_RESP_FAIL;
            HF_HCC238_V28                 = HF_V28*HCC238;
            gSubUseDisorder_gPsych_V28    = gSubUseDisorder_V28*gPsychiatric_V28;
            
            %*institutional model;
            DISABLED_CANCER_V28          = DISABL*CANCER_V28;
            DISABLED_NEURO_V28           = DISABL*NEURO_V28;
            DISABLED_HF_V28              = DISABL*HF_V28;
            DISABLED_CHR_LUNG_V28        = DISABL*CHR_LUNG_V28;
            DISABLED_ULCER_V28           = DISABL*ULCER_V28;

           END; *there are some diagnoses for a person;
           ELSE DO;
              DO I=1 TO &N_CC ;
                 HCC(I)=0;
              END;
              DO OVER RV;
                 RV=0;
              END;
           END;
           *HCC Counts;
           ARRAY CHPYMT(&N_CC) &HCClist;
           ARRAY ZS(9) D1-D9;
           HCC_pymt = sum(of CHPYMT(*));
           do i = 1 to dim(ZS) ;
              ZS(i)=(HCC_pymt=i);
           end ;
           D10P=(HCC_pymt>=10);

           LABEL
              F0_34  ="Female 0-34 "
              F35_44 ="Female 35-44"
              F45_54 ="Female 45-54"
              F55_59 ="Female 55-59"
              F60_64 ="Female 60-64"
              F65_69 ="Female 65-69"
              F70_74 ="Female 70-74"
              F75_79 ="Female 75-79"
              F80_84 ="Female 80-84"
              F85_89 ="Female 85-89"
              F90_94 ="Female 90-94"
              F95_GT ="Female 95+  "
              M0_34  ="Male 0-34   "
              M35_44 ="Male 35-44  "
              M45_54 ="Male 45-54  "
              M55_59 ="Male 55-59  "
              M60_64 ="Male 60-64  "
              M65_69 ="Male 65-69  "
              M70_74 ="Male 70-74  "
              M75_79 ="Male 75-79  "
              M80_84 ="Male 80-84  "
              M85_89 ="Male 85-89  "
              M90_94 ="Male 90-94  "
              M95_GT ="Male 95+    "
              HCC_pymt  = "Count of &N_CC V28 model payment HCCs: Single continuous integer variable"
	      	     D1= "1 payment HCC"
              D2= "2 payment HCCs"
              D3= "3 payment HCCs"
              D4= "4 payment HCCs"
              D5= "5 payment HCCs"
              D6= "6 payment HCCs"
              D7= "7 payment HCCs"
              D8= "8 payment HCCs"
              D9= "9 payment HCCs"
              D10P="10 or more payment HCCs"
              DIABETES_HF_V28             = "Diabetes*Heart Failure"
              HF_CHR_LUNG_V28             = "Heart Failure*Chronic Lung Disorder"
              HF_KIDNEY_V28               = "Heart Failure*Kidney"
              CHR_LUNG_CARD_RESP_FAIL_V28 = "Chronic Lung Disorder*Cardiorespiratory Failure"
              HF_HCC238_V28               = "Heart Failure*Specified Heart Arrhythmias"
              gSubUseDisorder_gPsych_V28  = "Substance Use Disorder*Psychiatric"
              DISABLED_CANCER_V28         = "Disabled, Cancer"
              DISABLED_NEURO_V28          = "Disabled, Neurological"
              DISABLED_HF_V28             = "Disabled, Heart Failure"
              DISABLED_CHR_LUNG_V28       = "Disabled, Chronic Lung Disorder"
              DISABLED_ULCER_V28          = "Disabled, Skin Ulcer" ;

              ;

           %*score calculation;

           /***************************/
           /*    community models     */
           /***************************/;
        %IF "&SCOREMAC" ne "" %THEN %DO;
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_NA,  RLIST=&COMM_REGA, CPREF=CNA_);
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_ND,  RLIST=&COMM_REGD, CPREF=CND_);
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_FBA, RLIST=&COMM_REGA, CPREF=CFA_);
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_FBD, RLIST=&COMM_REGD, CPREF=CFD_);
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_PBA, RLIST=&COMM_REGA, CPREF=CPA_);
     %&SCOREMAC(PVAR=SCORE_COMMUNITY_PBD, RLIST=&COMM_REGD, CPREF=CPD_);

           /***************************/
           /*   institutional model   */
           /***************************/;

     %&SCOREMAC(PVAR=SCORE_INSTITUTIONAL, RLIST=&INST_REG, CPREF=INS_);

           /***************************/
           /*   new enrollees model   */
           /***************************/;

     %&SCOREMAC(PVAR=SCORE_NEW_ENROLLEE, RLIST=&NE_REG, CPREF=NE_);

           /***************************/
           /* SNP new enrollees model */
           /***************************/;

     %&SCOREMAC(PVAR=SCORE_SNP_NEW_ENROLLEE, RLIST=&NE_REG, CPREF=SNPNE_);
        %END;
           /****************************/
           /*   normalize the scores   */
           /***************************/;
          SCORE_COMMUNITY_NA     = SCORE_COMMUNITY_NA    *&DF;
          SCORE_COMMUNITY_ND     = SCORE_COMMUNITY_ND    *&DF;
          SCORE_COMMUNITY_FBA    = SCORE_COMMUNITY_FBA   *&DF;
          SCORE_COMMUNITY_FBD    = SCORE_COMMUNITY_FBD   *&DF;
          SCORE_COMMUNITY_PBA    = SCORE_COMMUNITY_PBA   *&DF;
          SCORE_COMMUNITY_PBD    = SCORE_COMMUNITY_PBD   *&DF;
          SCORE_INSTITUTIONAL    = SCORE_INSTITUTIONAL   *&DF;
          SCORE_NEW_ENROLLEE     = SCORE_NEW_ENROLLEE    *&DF;
          SCORE_SNP_NEW_ENROLLEE = SCORE_SNP_NEW_ENROLLEE*&DF;
          OUTPUT &OUTDATA;
       END; %*last record for a person;
     END; %*there is a person record;
 RUN;

 %**********************************************************************
 * step4: data checks and proc contents
 ***********************************************************************;
 PROC PRINT U DATA=&OUTDATA(OBS=46);
     TITLE '*** V2824T2M output file ***';
 RUN ;
 PROC CONTENTS DATA=&OUTDATA;
 RUN;

 %MEND V2824T2M;
