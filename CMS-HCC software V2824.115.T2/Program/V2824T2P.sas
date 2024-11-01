/*
    The following is JCL if you are using an IBM-type mainframe:

   //JOBCARD
   //V2824T2P EXEC SAS94,REGION=8M,
   // OPTIONS='ERRORS=0,NOCENTER,NEWS'
   //WORK  DD SPACE=(CYL,(1000,2))
   //WORK1   DD SPACE=(CYL,(2000,2))
   //* user-defined the location of formats
   //LIBRARY DD DISP=SHR,DSN=XXXX.XXXXXXX
   //*user-defined the location of macros
   //IN0 DD DISP=SHR,DSN=XXXX.XXXXXX
   //*the location of person-level file
   //IN1 DD DISP=SHR,DSN=XXXX.PERSON
   //*the location of the diagnosis file
   //IN2 DD DISP=SHR,DSN=XXXX.DIAG
   //*the location of the file containing all coefficients
   //INCOEF DD DISP=SHR,DSN=XXXX.HCCCOEFN
   //*the output file containing person-level scores
   //OUT DD DISP=(NEW,CATLG,KEEP),
   //    DSN=XXX.V2824T2P.PERSON,
   //    SPACE=(TRK,(20,10),RLSE)
   //SYSIN  DD *

   ******************************************************************
  If you are using PC-SAS, you must specify the location of the files
  on your PC in a libname/filename statement.

  LIBNAME LIBRARY "location of formats";
  FILENAME IN0 "location of macros";
  LIBNAME  IN1 "location of person-level file";
  LIBNAME  IN2 "location of diagnosis file";
  LIBNAME  INCOEF "location of the coefficients file";
  LIBNAME  OUT "location for the output file";
  */
 ***********************************************************************
 *
 *   DESCRIPTION:
 *
 * V2824T2P program creates 115 HCC variables Version 28 
 * (&HCCV28_list115) and nine score variables for each person who is 
 * present in a person file (supplied by user).
 * If a person has at least one diagnosis in DIAG file (supplied by 
 * user) then HCC variables are created, otherwise HCCs are set to 0.
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
 *
 *   - person level file has the following variables:
 *     :&IDVAR    - person ID variable (it is a macro parameter, MBI  
 *                  for Medicare data)
 *     :DOB       - date of birth
 *     :SEX       - sex
 *     :OREC      - original reason for entitlement
 *     :LTIMCAID  - Medicaid dummy variable for LTI (payment year)
 *     :NEMCAID   - Medicaid dummy variable for new enrollees (payment
 *                  year)
 *
 *   - diagnosis level file has the following vars:
 *     :&IDVAR  - person ID variable (it is a macro parameter, MBI for 
 *                Medicare data)
 *     :DIAG    - diagnosis
 *
 * The program supplies parameters to a main macro %V2824T2M that calls
 * other external macros specific to V28 model HCCs:
 *
 *      %AGESEXV2   - create age/sex, originally disabled, disabled vars
 *      %V28I0ED2   - perform edits to ICD10 diagnosis
 *      %V28115L3   - assign labels to HCCs
 *      %V28115H1   - set HCC=0 according to hierarchies
 *      %SCOREVAR   - calculate a score variable
 *
 * Program steps:
 *         step1: include external macros
 *         step2: define internal macro variables
 *         step3: merge person and diagnosis files outputting one
 *                record per person for each input person level record
 *         step3.1: declaration section
 *         step3.2: bring regression coefficients
 *         step3.3: merge person and diagnosis file
 *         step3.4: for the first record for a person set CC to 0
 *                  and calculate age
 *         step3.5: if there are any diagnoses for a person
 *                  then do the following:
 *                   - perform ICD10 edits using V28I0ED2 macro
 *                   - create CC using provided format 
 *                   - create additional CC using additional formats
 *         step3.6: for the last record for a person do the
 *                  following:
 *                   - create demographic variables needed
 *                     for regressions (macro AGESEXV2)
 *                   - create HCC using hierarchies (macro V28115H1)
 *                   - create HCC interaction variables
 *                   - create HCC and DISABL interaction variables
 *                   - set HCCs and interaction vars to zero if there
 *                     are no diagnoses for a person
 *                   - create scores for community models
 *                   - create score for institutional model
 *                   - create score for new enrollee model
 *                   - create score for SNP new enrollee model
 *         step4: data checks and proc contents
 *
 *   USER CUSTOMIZATION:
 *
 * A user must supply 2 files with the variables described above and
 * set the following parameters:
 *      INP      - SAS input person dataset
 *      IND      - SAS input diagnosis dataset
 *      OUTDATA  - SAS output dataset
 *      IDVAR    - name of person ID variable (MBI for medicare data)
 *      KEEPVAR  - variables to keep in the output dataset
 *      SEDITS   - a switch that controls whether to perform MCE edits
 *                 on ICD10: 1-YES, 0-NO
 *      DATE_ASOF- reference date to calculate age. Set to February 1  
 *                 of the payment year for consistency with CMS 
 ***********************************************************************;

 %LET INPUTVARS=%STR(SEX DOB LTIMCAID NEMCAID OREC);

 %*demographic variables;
 %LET DEMVARS  =%STR(AGEF ORIGDS DISABL
                     F0_34  F35_44 F45_54 F55_59 F60_64 F65_69
                     F70_74 F75_79 F80_84 F85_89 F90_94 F95_GT
                     M0_34  M35_44 M45_54 M55_59 M60_64 M65_69
                     M70_74 M75_79 M80_84 M85_89 M90_94 M95_GT
                     NEF0_34  NEF35_44 NEF45_54 NEF55_59 NEF60_64
                     NEF65    NEF66    NEF67    NEF68    NEF69
                     NEF70_74 NEF75_79 NEF80_84 NEF85_89 NEF90_94
                     NEF95_GT
                     NEM0_34  NEM35_44 NEM45_54 NEM55_59 NEM60_64
                     NEM65    NEM66    NEM67    NEM68    NEM69
                     NEM70_74 NEM75_79 NEM80_84 NEM85_89 NEM90_94
                     NEM95_GT);

 %*list of HCCs included in models;
 %LET HCCV28_list115 = %STR(      
HCC1 HCC2 HCC6 HCC17 HCC18 HCC19 HCC20 HCC21 HCC22 HCC23 HCC35 HCC36
HCC37 HCC38 HCC48 HCC49 HCC50 HCC51 HCC62 HCC63 HCC64 HCC65 HCC68 HCC77
HCC78 HCC79 HCC80 HCC81 HCC92 HCC93 HCC94 HCC107 HCC108 HCC109 HCC111
HCC112 HCC114 HCC115 HCC125 HCC126 HCC127 HCC135 HCC136 HCC137 HCC138
HCC139 HCC151 HCC152 HCC153 HCC154 HCC155 HCC180 HCC181 HCC182 HCC190
HCC191 HCC192 HCC193 HCC195 HCC196 HCC197 HCC198 HCC199 HCC200 HCC201
HCC202 HCC211 HCC212 HCC213 HCC221 HCC222 HCC223 HCC224 HCC225 HCC226
HCC227 HCC228 HCC229 HCC238 HCC248 HCC249 HCC253 HCC254 HCC263 HCC264
HCC267 HCC276 HCC277 HCC278 HCC279 HCC280 HCC282 HCC283 HCC298 HCC300
HCC326 HCC327 HCC328 HCC329 HCC379 HCC380 HCC381 HCC382 HCC383 HCC385
HCC387 HCC397 HCC398 HCC399 HCC401 HCC402 HCC405 HCC409 HCC454 HCC463
     );

 %*list of CCs that correspond to model HCCs;
 %LET CCV28_list115 = %STR(      
CC1 CC2 CC6 CC17 CC18 CC19 CC20 CC21 CC22 CC23 CC35 CC36 CC37 CC38 CC48
CC49 CC50 CC51 CC62 CC63 CC64 CC65 CC68 CC77 CC78 CC79 CC80 CC81 CC92
CC93 CC94 CC107 CC108 CC109 CC111 CC112 CC114 CC115 CC125 CC126 CC127
CC135 CC136 CC137 CC138 CC139 CC151 CC152 CC153 CC154 CC155 CC180 CC181
CC182 CC190 CC191 CC192 CC193 CC195 CC196 CC197 CC198 CC199 CC200 CC201
CC202 CC211 CC212 CC213 CC221 CC222 CC223 CC224 CC225 CC226 CC227 CC228
CC229 CC238 CC248 CC249 CC253 CC254 CC263 CC264 CC267 CC276 CC277 CC278
CC279 CC280 CC282 CC283 CC298 CC300 CC326 CC327 CC328 CC329 CC379 CC380
CC381 CC382 CC383 CC385 CC387 CC397 CC398 CC399 CC401 CC402 CC405 CC409
CC454 CC463
     );

 %LET SCOREVARS=%STR(SCORE_COMMUNITY_NA
                     SCORE_COMMUNITY_ND
                     SCORE_COMMUNITY_FBA
                     SCORE_COMMUNITY_FBD
                     SCORE_COMMUNITY_PBA
                     SCORE_COMMUNITY_PBD 
                     SCORE_INSTITUTIONAL
                     SCORE_NEW_ENROLLEE
                     SCORE_SNP_NEW_ENROLLEE
                     );

 %* include main macro;
 %INCLUDE IN0(V2824T2M)/SOURCE2;

 %V2824T2M(INP      =IN1.PERSON,
           IND      =IN2.DIAG,
           OUTDATA  =OUT.PERSON,
           IDVAR    =MBI,
           KEEPVAR  =MBI &INPUTVARS &SCOREVARS &DEMVARS 
                     &HCCV28_list115 &CCV28_list115, 
           SEDITS   =1,
           DATE_ASOF="1FEB2025"D);