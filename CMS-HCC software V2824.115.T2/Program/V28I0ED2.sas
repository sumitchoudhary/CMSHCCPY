 %MACRO V28I0ED2(AGE=, SEX=, ICD10= );
 %**********************************************************************
 ***********************************************************************
 1  MACRO NAME:  V28I0ED2
                 UDXG update V0124 for V28 model (payment HCCs only). 
                 ICD10 codes valid in FY23/FY24.
 2  PURPOSE:     age/sex edits on ICD10: some edits are mandatory, 
                 others - are based on MCE list to check
                 if age or sex for a beneficiary is within the
                 range of acceptable age/sex, if not- CC is set to 
                 -1.0 - invalid
 3  PARAMETERS:  AGE   - beneficiary age variable calculated by DOB
                         from a person level file
                 SEX   - beneficiary SEX variable in a person level file
                 ICD10  - diagnosis variable in a diagnosis file

 4  COMMENTS:    1. Age format AGEFMT0 and sex format SEXFMT0 are 
                    parameters in the main macro. They have to 
                    correspond to the years of data

                 2. If ICD10 code does not have any restriction on age
                    or sex then the corresponding format puts it in "-1"

                 3. AGEL format sets lower limits for age
                    AGEU format sets upper limit for age
                    for specific edit categories:
                    "0"= "0 newborn (age 0)      "
                    "1"= "1 pediatric (age 0 -17)"
                    "2"= "2 maternity (age 9 -64)"
                    "3"= "3 adult (age 15+)      "

                 4. SEDITS - parameter for the main macro
 **********************************************************************;
   %* reset of CCs that is based on beneficiary age or sex;
   IF &SEX="2" AND &ICD10 IN ("D66", "D67")  THEN CC="112"; 
   ELSE
   IF &AGE < 18 AND &ICD10 IN ("J410", "J411", "J418", "J42",  "J430",
                               "J431", "J432", "J438", "J439", "J440",
                               "J441", "J449", "J982", "J983",
                               "J4481","J4489" ) 
                                             THEN CC="-1.0";
   ELSE 
   IF &AGE < 50 AND &ICD10 IN ( "C50011", "C50012", "C50019", "C50021",
                                "C50022", "C50029", "C50111", "C50112",
                                "C50119", "C50121", "C50122", "C50129",
                                "C50211", "C50212", "C50219", "C50221",
                                "C50222", "C50229", "C50311", "C50312",
                                "C50319", "C50321", "C50322", "C50329",
                                "C50411", "C50412", "C50419", "C50421",
                                "C50422", "C50429", "C50511", "C50512",
                                "C50519", "C50521", "C50522", "C50529",
                                "C50611", "C50612", "C50619", "C50621",
                                "C50622", "C50629", "C50811", "C50812",
                                "C50819", "C50821", "C50822", "C50829",
                                "C50911", "C50912", "C50919", "C50921",
                                "C50922", "C50929")
                                             THEN CC="22";
   ELSE
   IF &AGE >= 2 AND &ICD10 IN ("P040",  "P041",  "P0411", "P0412", 
                               "P0413", "P0414", "P0415", "P0416", 
                               "P0417", "P0418", "P0419", "P041A", 
                               "P042",  "P043",  "P0440", "P0441", 
                               "P0442", "P0449", "P045",  "P046",  
                               "P048",  "P0481", "P0489", "P049",  
                               "P270",  "P271",  "P278",  "P279",  
                               "P930",  "P938",  "P961",  "P962")  
                                             THEN CC="-1.0";

  %* MCE edits if needed (should be decided by a user by setting
     parameter SEDITS);
  %IF &SEDITS = 1 %THEN %DO;
     %* check if Age is within acceptable range;
     _TAGE=PUT(&ICD10, $&AGEFMT0..);
     IF _TAGE NE "-1" AND
        (&AGE < INPUT(PUT(_TAGE, $AGEL.),8.) OR
         &AGE > INPUT(PUT(_TAGE, $AGEU.),8.)) THEN CC='-1.0';

     %* check if Sex for a person is the one in the MCE file;
     _TSEX=PUT(&ICD10, $&SEXFMT0..);
     IF _TSEX NE "-1"  & _TSEX NE &SEX THEN CC='-1.0';

  %END;
 %MEND V28I0ED2;
