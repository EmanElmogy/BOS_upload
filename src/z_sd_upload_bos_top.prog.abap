*&---------------------------------------------------------------------*
*&  Include           Z_SD_UPLOAD_BOS_TOP
*&---------------------------------------------------------------------*
TYPES : BEGIN OF RECORD ,
  "INQUIRY ITEM DATA
  ITM_NUMBER     TYPE  POSNR_VA ,
  MATERIAL       TYPE  MATNR ,
  MAT_SHORT_TEXT TYPE ARKTX ,
  PLANT          TYPE  WERKS_D ,
  "OUTLINE LEVEL DATA
  LINE_NO_OL     TYPE  SRV_LINE_NO ,
  OUTL_NO        TYPE  EXTGROUP ,
  SHORT_TEXT     TYPE  SH_TEXT1 ,
  OUTL_LEVEL     Type  RANG ,
  HI_LINE_NO     TYPE  HI_LINE_NO ,
  "SERVICE DATA
  LINE_NO_S      TYPE  SRV_LINE_NO ,
  SERVICE        TYPE  ASNUM ,
  QUANTITY       TYPE  MENGEV ,
  BASE_UOM       TYPE  MEINS ,
  OBJ_TYPE       TYPE  /SAPBOQ/OBJTYPE ,
  SI_LINE        TYPE  /SAPBOQ/SPOSNR ,
  MI_LINE_NO     TYPE  /SAPBOQ/MI_LINE_NO ,
  SHORT_TEXT_S   TYPE  SH_TEXT1 ,
  LONG_TEXT      TYPE  STRING ,
  FORM_VAL1      TYPE  FRMVAL ,
  FORM_VAL2      TYPE  FRMVAL2 ,

  END OF RECORD .

  DATA : IT_RECORD  TYPE TABLE OF RECORD ,
         WA_RECORD  LIKE LINE  OF IT_RECORD ,
         SUBPCKG_NO	TYPE SUB_PACKNO ,
         MATERIAL   TYPE N LENGTH 18 ,
         IT_T006b   TYPE TABLE OF T006B ,
         WA_T006b   LIKE LINE OF IT_T006b ,
         LINE_OFFSET TYPE SRV_LINE_NO ,
         IT_RECORD_COPY TYPE TABLE OF RECORD ,
         WA_RECORD_COPY LIKE LINE OF IT_RECORD_COPY .

  DATA : TFILE TYPE STRING.

  DATA : INQUIRYHEADERIN        TYPE           BAPISDHD1 ,
         it_INQUIRYPARTNERS     TYPE TABLE OF  BAPIPARNR ,
         WA_INQUIRYPARTNERS     LIKE LINE OF   it_INQUIRYPARTNERS ,
         IT_INQUIRYITEMSIN      TYPE TABLE OF  BAPISDITMBOS ,
         WA_INQUIRYITEMSIN      LIKE LINE OF   IT_INQUIRYITEMSIN ,
         IT_INQUIRYSCHEDULESIN  TYPE TABLE OF  BAPISCHDL ,
         WA_INQUIRYSCHEDULESIN  LIKE LINE OF   IT_INQUIRYSCHEDULESIN ,
         IT_INQUIRYSERVICES     TYPE TABLE OF  BAPISDESLLCBOS ,
         WA_INQUIRYSERVICES     LIKE LINE OF   IT_INQUIRYSERVICES ,
         IT_INQUIRYSERVICESTEXT TYPE TABLE OF  BAPIESLLTX ,
         WA_INQUIRYSERVICESTEXT LIKE LINE OF   IT_INQUIRYSERVICESTEXT ,
         IT_RETURN              TYPE TABLE OF  BAPIRET2 ,
         WA_RETURN              LIKE LINE OF   IT_RETURN .
