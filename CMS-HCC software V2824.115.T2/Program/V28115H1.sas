 %MACRO V28115H1; 
 %**********************************************************************
 1  MACRO NAME: V28115H1
 2  PURPOSE:    HCC HIERARCHIES: version 28 of HCCs,
                only payment model HCCs are included
 3  COMMENT:    it is assumed that:
                -number of payment model HCCs are placed into global macro 
                 variable N_CC in the main program
                -the following arrays are set in the main program 
                 ARRAY C(&N_CC)   &CClist
                 ARRAY HCC(&N_CC) &HCClist
                -format ICD to CC creates only &N_CC CMS CCs
 **********************************************************************;
 %* set to 0 HCCs in HIER parameter;
 %MACRO SET0( CC=, HIER= );
 %LET K=1;                        
 IF HCC&CC=1 THEN DO;             
    %DO %UNTIL(%SCAN(&HIER,&K)=); 
         HCC%SCAN(&HIER,&K) = 0;     
         %LET K=%EVAL(&K+1);         
    %END;                         
 END;
 %MEND SET0;

 %*to copy CC into HCC;
  DO K=1 TO &N_CC;
     HCC(K)=C(K);
  END;

 %*imposing hierarchies;
 /*Neoplasm 1 */   %SET0(CC=17    , HIER=%STR(18, 19, 20, 21, 22, 23 ));
 /*Neoplasm 2 */   %SET0(CC=18    , HIER=%STR(19, 20, 21, 22, 23 ));
 /*Neoplasm 3 */   %SET0(CC=19    , HIER=%STR(20, 21, 22, 23 ));
 /*Neoplasm 4 */   %SET0(CC=20    , HIER=%STR(21, 22, 23 ));
 /*Neoplasm 5 */   %SET0(CC=21    , HIER=%STR(22, 23 ));
 /*Neoplasm 6 */   %SET0(CC=22    , HIER=%STR(23 ));
 /*Diabetes 1 */   %SET0(CC=35    , HIER=%STR(36, 37, 38 ));
 /*Diabetes 2 */   %SET0(CC=36    , HIER=%STR(37, 38 ));
 /*Diabetes 3 */   %SET0(CC=37    , HIER=%STR(38 ));
 /*Liver 1 */      %SET0(CC=62    , HIER=%STR(63, 64, 65, 68 ));
 /*Liver 2 */      %SET0(CC=63    , HIER=%STR(64, 65, 68, 202 ));
 /*Liver 3 */      %SET0(CC=64    , HIER=%STR(65, 68 ));
 /*GI 1 */         %SET0(CC=77    , HIER=%STR(78, 80, 81 ));
 /*GI 4 */         %SET0(CC=80    , HIER=%STR(81 ));
 /*MSK 2 */        %SET0(CC=93    , HIER=%STR(94 ));
 /*Blood 1 */      %SET0(CC=107   , HIER=%STR(108 ));
 /*Blood 5 */      %SET0(CC=111   , HIER=%STR(112 ));
 /*Blood 8 */      %SET0(CC=114   , HIER=%STR(115 ));
 /*Cognitive 2 */  %SET0(CC=125   , HIER=%STR(126, 127 ));
 /*Cognitive 3 */  %SET0(CC=126   , HIER=%STR(127 ));
 /*SUD 1 */        %SET0(CC=135   , HIER=%STR(136, 137, 138, 139 ));
 /*SUD 2 */        %SET0(CC=136   , HIER=%STR(137, 138, 139 ));
 /*SUD 3 */        %SET0(CC=137   , HIER=%STR(138, 139 ));
 /*SUD 4 */        %SET0(CC=138   , HIER=%STR(139 ));
 /*Psychiatric 1 */%SET0(CC=151   , HIER=%STR(152, 153, 154, 155 ));
 /*Psychiatric 2 */%SET0(CC=152   , HIER=%STR(153, 154, 155 ));
 /*Psychiatric 3 */%SET0(CC=153   , HIER=%STR(154, 155 ));
 /*Psychiatric 4 */%SET0(CC=154   , HIER=%STR(155 ));
 /*Spinal 1 */     %SET0(CC=180   , HIER=%STR(181, 182, 253, 254 ));
 /*Spinal 2 */     %SET0(CC=181   , HIER=%STR(182, 254 ));
 /*Neuro 2 */      %SET0(CC=191   , HIER=%STR(
180, 181, 182, 192, 253, 254 ));
 /*Neuro 3 */      %SET0(CC=192   , HIER=%STR(180, 181, 182, 253, 254
));
 /*Neuro 6 */      %SET0(CC=195   , HIER=%STR(196 ));
 /*Arrest 1 */     %SET0(CC=211   , HIER=%STR(212, 213 ));
 /*Arrest 2 */     %SET0(CC=212   , HIER=%STR(213 ));
 /*Heart 1 */      %SET0(CC=221   , HIER=%STR(
222, 223, 224, 225, 226, 227 ));
 /*Heart 2 */      %SET0(CC=222   , HIER=%STR(223, 224, 225, 226, 227
));
 /*Heart 3 */      %SET0(CC=223   , HIER=%STR(224, 225, 226, 227 ));
 /*Heart 4 */      %SET0(CC=224   , HIER=%STR(225, 226, 227 ));
 /*Heart 5 */      %SET0(CC=225   , HIER=%STR(226, 227 ));
 /*Heart 6 */      %SET0(CC=226   , HIER=%STR(227 ));
 /*Heart 8 */      %SET0(CC=228   , HIER=%STR(229 ));
 /*CVD 1 */        %SET0(CC=248   , HIER=%STR(249 ));
 /*CVD 6 */        %SET0(CC=253   , HIER=%STR(254 ));
 /*Vascular 1 */   %SET0(CC=263   , HIER=%STR(264, 383, 409 ));
 /*Lung 1 */       %SET0(CC=276   , HIER=%STR(277, 278, 279, 280 ));
 /*Lung 2 */       %SET0(CC=277   , HIER=%STR(278, 279, 280 ));
 /*Lung 3 */       %SET0(CC=278   , HIER=%STR(279, 280 ));
 /*Lung 4 */       %SET0(CC=279   , HIER=%STR(280 ));
 /*Lung 7 */       %SET0(CC=282   , HIER=%STR(283 ));
 /*Kidney 5 */     %SET0(CC=326   , HIER=%STR(327, 328, 329 ));
 /*Kidney 6 */     %SET0(CC=327   , HIER=%STR(328, 329 ));
 /*Kidney 7 */     %SET0(CC=328   , HIER=%STR(329 ));
 /*Skin 1 */       %SET0(CC=379   , HIER=%STR(380, 381, 382, 383 ));
 /*Skin 2 */       %SET0(CC=380   , HIER=%STR(381, 382, 383 ));
 /*Skin 3 */       %SET0(CC=381   , HIER=%STR(382, 383 ));
 /*Skin 4 */       %SET0(CC=382   , HIER=%STR(383 ));
 /*Injury 1 */     %SET0(CC=397   , HIER=%STR(202, 398, 399 ));
 /*Injury 2 */     %SET0(CC=398   , HIER=%STR(202, 399 ));
 /*Injury 9 */     %SET0(CC=405   , HIER=%STR(409 ));

 %MEND V28115H1;
