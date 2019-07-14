*&---------------------------------------------------------------------*
*&  Include           Z_SD_UPLOAD_BOS_SEL
*&---------------------------------------------------------------------*
selection-screen : begin of block blck with frame title text-001 .
  parameters : p_KUNNR TYPE KUNNR .
  PARAMETERS : P_VKORG TYPE VKORG ,
               P_VTWEG TYPE VTWEG ,
               P_sPART TYPE SPART ,
               p_AUART TYPE vbak-AUART .
  parameters : dataset(132) lower case.
selection-screen : end of block BLCK.
