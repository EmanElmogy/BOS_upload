*&---------------------------------------------------------------------*
*& Report  Z_SD_UPLOAD_BOS
*&
*&---------------------------------------------------------------------*

************************************************************************
* OBJECT ID               :
* PROGRAM TITLE           :  BOS UPLOAD
* MODULE                  :  SD
* PROGRAM TYPE            :  UPLOAD PROGRAM
* INPUT                   :  FILE WITH BOS QUOT. DATA
* OUTPUT                  :  LOG
* CREATED BY              :  EMAN EL-SAID /CIC
* CREATION DATE           :  6/7/2014
*-----------------------------------------------------------------------
* DESCRIPTION             :   UPLOAD BOS QUOTATION WITH SERVICES
************************************************************************
* Modification history:
*-----------------------------------------------------------------------
* DATE      |Owner  |Request  | Description
*-----------------------------------------------------------------------
************************************************************************


REPORT  Z_SD_UPLOAD_BOS.

" TOP INCLUDE
INCLUDE Z_SD_UPLOAD_BOS_TOP.

"SELECTION SCREEN
INCLUDE Z_SD_UPLOAD_BOS_SEL.

"SUBROUTINES
INCLUDE Z_SD_UPLOAD_BOS_F01.

*&---------------------------------------------------------------------*
*&  MAIN PROCESSING
*&---------------------------------------------------------------------*
at selection-screen on value-request for dataset.
**********************************************************************
  " popup for geting the text file

  perform filename_get.

**********************************************************************

end-of-selection.

*-----------------------------Read Folders----------------------------
PERFORM UPLOAD_FILE .
PERFORM DEL_EMPTY_ROWS .
PERFORM PROCESS_DATA .
PERFORM CALL_UPLOAD_FUNCTION.
PERFORM DISPLAY_LOG .
