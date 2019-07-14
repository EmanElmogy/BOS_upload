*----------------------------------------------------------------------*
***INCLUDE Z_SD_UPLOAD_BOS_F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  FILENAME_GET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILENAME_GET .
  DATA: FILERC          TYPE I,
       FILENAME_TAB    TYPE FILETABLE,
       FILENAME        TYPE FILE_TABLE,
       FILEACTION      TYPE I,
       WINDOW_TITLE    TYPE STRING,
       MY_FILE_FILTER  TYPE STRING.

  WINDOW_TITLE = TEXT-005.

  CLASS CL_GUI_FRONTEND_SERVICES DEFINITION LOAD.
*  concatenate cl_gui_frontend_services=>filetype_all
*              into my_file_filter.
  MY_FILE_FILTER = 'All files(*.*)|*.*'(084).
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      WINDOW_TITLE            = WINDOW_TITLE
      FILE_FILTER             = MY_FILE_FILTER
    CHANGING
      FILE_TABLE              = FILENAME_TAB
      RC                      = FILERC
      USER_ACTION             = FILEACTION
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      NOT_SUPPORTED_BY_GUI    = 4.


  IF FILEACTION EQ CL_GUI_FRONTEND_SERVICES=>ACTION_OK.
    CHECK NOT FILENAME_TAB IS INITIAL.
    READ TABLE FILENAME_TAB INTO FILENAME INDEX 1.
    MOVE FILENAME-FILENAME TO DATASET.
  ENDIF.

ENDFORM.                    " FILENAME_GET
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPLOAD_FILE .
  TFILE = DATASET.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME                = TFILE
      FILETYPE                = 'ASC'
      NO_AUTH_CHECK           = 'X'
      HAS_FIELD_SEPARATOR     = 'X'
    TABLES
      DATA_TAB                = IT_RECORD
    EXCEPTIONS
      FILE_OPEN_ERROR         = 1
      FILE_READ_ERROR         = 2
      NO_BATCH                = 3
      GUI_REFUSE_FILETRANSFER = 4
      INVALID_TYPE            = 5
      NO_AUTHORITY            = 6
      UNKNOWN_ERROR           = 7
      BAD_DATA_FORMAT         = 8
      HEADER_NOT_ALLOWED      = 9
      SEPARATOR_NOT_ALLOWED   = 10
      HEADER_TOO_LONG         = 11
      UNKNOWN_DP_ERROR        = 12
      ACCESS_DENIED           = 13
      DP_OUT_OF_MEMORY        = 14
      DISK_FULL               = 15
      DP_TIMEOUT              = 16
      OTHERS                  = 17.
**********************************************************************
*--------------------------------------------------------------------*

ENDFORM.                    " UPLOAD_FILE
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PROCESS_DATA .
  PERFORM GET_COMM_UOM . " GET COMMERCIAL UOM.
  PERFORM FILL_HEADER_DATA .
  PERFORM FILL_ITEM_DATA .
*  PERFORM UPDATE_SUBITEM_DATA . " FOR SUBITEM SERVICES
  PERFORM FILL_SERVICE_DATA .

ENDFORM.                    " PROCESS_DATA
*&---------------------------------------------------------------------*
*&      Form  FILL_HEADER_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_HEADER_DATA .

  INQUIRYHEADERIN-SALES_ORG  = P_VKORG .
  INQUIRYHEADERIN-DISTR_CHAN = P_VTWEG .
  INQUIRYHEADERIN-DIVISION   = P_SPART .
  TRANSLATE P_AUART TO UPPER CASE.
  INQUIRYHEADERIN-DOC_TYPE   = P_AUART.

  " FILL SOLD TO PARTY FIELD
  WA_INQUIRYPARTNERS-PARTN_ROLE = 'AG'.
  WA_INQUIRYPARTNERS-PARTN_NUMB = P_KUNNR .

  APPEND WA_INQUIRYPARTNERS TO IT_INQUIRYPARTNERS.
  CLEAR WA_INQUIRYPARTNERS.

ENDFORM.                    " FILL_HEADER_DATA
*&---------------------------------------------------------------------*
*&      Form  FILL_ITEM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_ITEM_DATA .
  REFRESH IT_INQUIRYITEMSIN.
  REFRESH IT_INQUIRYSCHEDULESIN.
  LOOP AT IT_RECORD INTO WA_RECORD .
    ON CHANGE OF WA_RECORD-ITM_NUMBER  .
      WA_INQUIRYITEMSIN-ITM_NUMBER = WA_RECORD-ITM_NUMBER .
      MATERIAL = WA_RECORD-MATERIAL .
*      TRANSLATE WA_RECORD-MATERIAL TO UPPER CASE.
      WA_INQUIRYITEMSIN-MATERIAL   = MATERIAL.
      WA_INQUIRYITEMSIN-SHORT_TEXT = WA_RECORD-MAT_SHORT_TEXT.
      WA_INQUIRYITEMSIN-PLANT      = WA_RECORD-PLANT.
      WA_INQUIRYITEMSIN-PCKG_NO    = WA_RECORD-ITM_NUMBER.

      APPEND WA_INQUIRYITEMSIN TO IT_INQUIRYITEMSIN .
      CLEAR WA_INQUIRYITEMSIN.

      " FILL QUANTITY IT HAS TO BE 1
      WA_INQUIRYSCHEDULESIN-ITM_NUMBER = WA_RECORD-ITM_NUMBER.
      WA_INQUIRYSCHEDULESIN-REQ_QTY    = 1.

      APPEND WA_INQUIRYSCHEDULESIN TO IT_INQUIRYSCHEDULESIN.
      CLEAR WA_INQUIRYSCHEDULESIN.
    ENDON.

  ENDLOOP.

ENDFORM.                    " FILL_ITEM_DATA
*&---------------------------------------------------------------------*
*&      Form  FILL_SERVICE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_SERVICE_DATA .
  DATA : REM      TYPE I.
  DATA : SERV     TYPE N  LENGTH 18,
         MAIN_SRV TYPE N LENGTH 6.

  PERFORM FILL_RECORD_COPY .
  REFRESH IT_INQUIRYSERVICES.
  CLEAR SUBPCKG_NO.
  CLEAR LINE_OFFSET.
  LOOP AT IT_RECORD INTO WA_RECORD .
    ON CHANGE OF WA_RECORD-ITM_NUMBER .
      PERFORM CALC_LINE_OFFSET.
    ENDON.

    ON CHANGE OF WA_RECORD-ITM_NUMBER OR WA_RECORD-LINE_NO_OL .

      "subpackage
      IF WA_RECORD-LINE_NO_S IS  NOT INITIAL.
        ADD 1 TO SUBPCKG_NO.
        REM = SUBPCKG_NO MOD 10 .
        IF REM = 0.
          ADD 1 TO SUBPCKG_NO.
        ENDIF.
      ENDIF.
      WA_INQUIRYSERVICES-PCKG_NO    = WA_RECORD-ITM_NUMBER.
      WA_INQUIRYSERVICES-LINE_NO    = WA_RECORD-LINE_NO_OL + LINE_OFFSET
      .
      IF WA_RECORD-OUTL_LEVEL NE 0 .
        WA_INQUIRYSERVICES-EXT_LINE   = WA_RECORD-HI_LINE_NO +
        LINE_OFFSET.
        WA_INQUIRYSERVICES-HI_LINE_NO = WA_RECORD-HI_LINE_NO +
        LINE_OFFSET.
        WA_INQUIRYSERVICES-OUTL_NO    = WA_RECORD-OUTL_NO .
      ENDIF.


      WA_INQUIRYSERVICES-OUTL_LEVEL = WA_RECORD-OUTL_LEVEL.
      IF  WA_INQUIRYSERVICES-OUTL_LEVEL = 0 .
        WA_INQUIRYSERVICES-FROM_LINE = 1.
      ENDIF.
      WA_INQUIRYSERVICES-OUTL_IND = 'X'.

      WA_INQUIRYSERVICES-SHORT_TEXT = WA_RECORD-SHORT_TEXT.
      WA_INQUIRYSERVICES-SUBPCKG_NO = SUBPCKG_NO.

      APPEND WA_INQUIRYSERVICES TO IT_INQUIRYSERVICES.
      CLEAR WA_INQUIRYSERVICES .
    ENDON.

    " Services
    TRANSLATE WA_RECORD-OBJ_TYPE TO UPPER CASE. " object category
    IF WA_RECORD-LINE_NO_S IS NOT INITIAL OR WA_RECORD-SI_LINE IS NOT INITIAL.
      WA_INQUIRYSERVICES-PCKG_NO = SUBPCKG_NO.
      " set service line no for sub  services
      IF WA_RECORD-OBJ_TYPE = 'U'.
        MAIN_SRV = WA_RECORD-MI_LINE_NO.
        CONCATENATE MAIN_SRV WA_RECORD-SI_LINE INTO WA_INQUIRYSERVICES-LINE_NO .
      ELSE.
        WA_INQUIRYSERVICES-LINE_NO = WA_RECORD-LINE_NO_S.
      ENDIF.

      WA_INQUIRYSERVICES-EXT_LINE = WA_INQUIRYSERVICES-LINE_NO.
      WA_INQUIRYSERVICES-OBJ_TYPE = WA_RECORD-OBJ_TYPE .
      WA_INQUIRYSERVICES-MI_LINE_NO = WA_RECORD-MI_LINE_NO .
      WA_INQUIRYSERVICES-SI_LINE = WA_RECORD-SI_LINE .
      IF WA_RECORD-SERVICE IS NOT INITIAL.
        CLEAR SERV.
        SERV = WA_RECORD-SERVICE. " to set leading zeros
        WA_INQUIRYSERVICES-SERVICE  = SERV .
      ENDIF.
      WA_INQUIRYSERVICES-SHORT_TEXT = WA_RECORD-SHORT_TEXT_S.
      IF ( WA_RECORD-FORM_VAL1 IS NOT INITIAL
         OR WA_RECORD-FORM_VAL2 IS NOT INITIAL ).
        BREAK ABAPER1.
        WA_INQUIRYSERVICES-OPEN_QTY = 'X'.
        WA_INQUIRYSERVICES-FORM_VAL1 = WA_RECORD-FORM_VAL1.
        WA_INQUIRYSERVICES-FORM_VAL2 = WA_RECORD-FORM_VAL2.

      ENDIF.

      WA_INQUIRYSERVICES-QUANTITY = WA_RECORD-QUANTITY.
      READ TABLE IT_T006B INTO WA_T006B WITH KEY MSEH3 =
      WA_RECORD-BASE_UOM.
      IF SY-SUBRC = 0.
        WA_INQUIRYSERVICES-BASE_UOM = WA_T006B-MSEHI.
        WA_INQUIRYSERVICES-UOM_ISO  = WA_T006B-MSEHI.
      ENDIF.
      APPEND WA_INQUIRYSERVICES TO IT_INQUIRYSERVICES.
      CLEAR WA_INQUIRYSERVICES .
      PERFORM FILL_SERVICE_LONG_TEXT .


    ENDIF.
  ENDLOOP.
*  SORT it_inquiryservices BY OUTL_IND  PCKG_NO LINE_NO ASCENDING.
ENDFORM.                    " FILL_SERVICE_DATA
*&---------------------------------------------------------------------*
*&      Form  CALL_UPLOAD_FUNCTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CALL_UPLOAD_FUNCTION .
  CALL FUNCTION 'BAPI_INQUIRY_CREATEBOS'
    EXPORTING
*     SALESDOCUMENTIN     =
      INQUIRYHEADERIN     = INQUIRYHEADERIN
*     INQUIRYHEADERINX    =
*     SENDER              =
*     BINARYRELATIONSHIPTYPE       =
*     INTNUMBERASSIGNMENT =
*     BEHAVEWHENERROR     =
*     LOGICSWITCH         =
*     TESTRUN             =
* IMPORTING
*     SALESDOCUMENT       =
    TABLES
      RETURN              = IT_RETURN
      INQUIRYITEMSIN      = IT_INQUIRYITEMSIN
*     INQUIRYITEMSINX     =
      INQUIRYPARTNERS     = IT_INQUIRYPARTNERS
      INQUIRYSCHEDULESIN  = IT_INQUIRYSCHEDULESIN
*     INQUIRYSCHEDULESINX =
*     INQUIRYCONDITIONSIN =
*     INQUIRYCFGSREF      =
*     INQUIRYCFGSINST     =
*     INQUIRYCFGSPARTOF   =
*     INQUIRYCFGSVALUE    =
*     INQUIRYCFGSBLOB     =
*     INQUIRYCFGSVK       =
*     INQUIRYCFGSREFINST  =
*     INQUIRYTEXT         =
*     INQUIRYKEYS         =
*     EXTENSIONIN         =
      INQUIRYSERVICES     = IT_INQUIRYSERVICES
      INQUIRYSERVICESTEXT = IT_INQUIRYSERVICESTEXT
*     PARTNERADDRESSES    =
    .
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

ENDFORM.                    " CALL_UPLOAD_FUNCTION
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DISPLAY_LOG .
  LOOP AT IT_RETURN INTO WA_RETURN .
    WRITE : WA_RETURN-TYPE ,
            WA_RETURN-MESSAGE.
    NEW-LINE.

  ENDLOOP.

ENDFORM.                    " DISPLAY_LOG
*&---------------------------------------------------------------------*
*&      Form  GET_COMM_UOM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_COMM_UOM .
  " convert unit of measure to upper case
  LOOP AT IT_RECORD INTO WA_RECORD.
    TRANSLATE WA_RECORD-BASE_UOM TO UPPER CASE .
    MODIFY IT_RECORD FROM WA_RECORD INDEX SY-TABIX .
  ENDLOOP.
  IF IT_RECORD[] IS NOT INITIAL.
    SELECT *
      FROM T006B
      INTO TABLE IT_T006B
      FOR ALL ENTRIES IN IT_RECORD
      WHERE MSEH3 = IT_RECORD-BASE_UOM
        AND SPRAS = SY-LANGU.


  ENDIF.

ENDFORM.                    " GET_COMM_UOM
*&---------------------------------------------------------------------*
*&      Form  FILL_SERVICE_LONG_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_SERVICE_LONG_TEXT .
  DATA : LEN    TYPE I , "LONG TEXT LENGTH ,
         LINES  TYPE P LENGTH 10 DECIMALS 2 , " LONG TEXT LINES ,
         OFFSET TYPE I.

  LEN = STRLEN( WA_RECORD-LONG_TEXT ).
  LINES = LEN / 132.
  LINES = CEIL( LINES ).
  CLEAR OFFSET.
  DO LINES TIMES.
    WA_INQUIRYSERVICESTEXT-PCKG_NO = SUBPCKG_NO.
    WA_INQUIRYSERVICESTEXT-LINE_NO = WA_RECORD-LINE_NO_S.
    WA_INQUIRYSERVICESTEXT-TEXT_ID = 'LTXT'.
    IF SY-INDEX = LINES.
      WA_INQUIRYSERVICESTEXT-TEXT_LINE = WA_RECORD-LONG_TEXT+OFFSET .
    ELSE.
      WA_INQUIRYSERVICESTEXT-TEXT_LINE = WA_RECORD-LONG_TEXT+OFFSET(132)
      .

    ENDIF.

    ADD 132 TO OFFSET .
    APPEND WA_INQUIRYSERVICESTEXT TO IT_INQUIRYSERVICESTEXT.
    CLEAR WA_INQUIRYSERVICESTEXT.

  ENDDO.

ENDFORM.                    " FILL_SERVICE_LONG_TEXT
*&---------------------------------------------------------------------*
*&      Form  FILL_RECORD_COPY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_RECORD_COPY .
  LOOP AT IT_RECORD INTO WA_RECORD.
    ON CHANGE OF WA_RECORD-ITM_NUMBER OR WA_RECORD-LINE_NO_OL.
      WA_RECORD_COPY-ITM_NUMBER = WA_RECORD-ITM_NUMBER .
      WA_RECORD_COPY-LINE_NO_OL = WA_RECORD-LINE_NO_OL.
      APPEND WA_RECORD_COPY TO IT_RECORD_COPY .
      CLEAR WA_RECORD_COPY.
    ENDON.

  ENDLOOP.

  SORT IT_RECORD_COPY .
  DELETE ADJACENT DUPLICATES FROM IT_RECORD_COPY.
ENDFORM.                    " FILL_RECORD_COPY
*&---------------------------------------------------------------------*
*&      Form  CALC_LINE_OFFSET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CALC_LINE_OFFSET .
  CLEAR LINE_OFFSET.
  LOOP AT IT_RECORD_COPY INTO WA_RECORD_COPY WHERE ITM_NUMBER <
  WA_RECORD-ITM_NUMBER.
    ADD 1 TO LINE_OFFSET.
  ENDLOOP.


ENDFORM.                    " CALC_LINE_OFFSET
*&---------------------------------------------------------------------*
*&      Form  DEL_EMPTY_ROWS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DEL_EMPTY_ROWS .
  DELETE IT_RECORD WHERE ITM_NUMBER IS INITIAL .

ENDFORM.                    " DEL_EMPTY_ROWS
*&---------------------------------------------------------------------*
*&      Form  UPDATE_SUBITEM_DATA
*&---------------------------------------------------------------------*
*       update the service no. serial  of the subitem service to avoid
* conflict between main sevice and subservice
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_SUBITEM_DATA .
  DATA : SERIAL TYPE N LENGTH 10 .
  LOOP AT IT_RECORD INTO WA_RECORD .

  ENDLOOP.

ENDFORM.                    " UPDATE_SUBITEM_DATA
