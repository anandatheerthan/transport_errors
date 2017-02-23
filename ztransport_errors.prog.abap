REPORT ztransport.

PARAMETERS: p_sys TYPE tmssysnam MATCHCODE OBJECT s_realsys OBLIGATORY.

START-OF-SELECTION.
  PERFORM run.

FORM run.

  DATA: lt_log        TYPE tmstpalogs,
        lv_domain     TYPE tmsmconf-domnam,
        lv_start_date TYPE dats,
        lv_start_time TYPE tims,
        lv_end_date   TYPE dats,
        lv_end_time   TYPE tims.


  lv_start_date = sy-datum - 100.
  lv_start_time = sy-uzeit.
  lv_end_date = sy-datum.
  lv_end_time = sy-uzeit.

  CALL FUNCTION 'TMS_CFG_GET_LOCAL_DOMAIN_NAME'
    IMPORTING
      ev_domain_name        = lv_domain
    EXCEPTIONS
      tms_is_not_configured = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    BREAK-POINT.
  ENDIF.

  CALL FUNCTION 'TMS_TM_GET_HISTORY'
    EXPORTING
      iv_system     = p_sys
      iv_domain     = lv_domain
    IMPORTING
      et_tmstpalog  = lt_log
    CHANGING
      cv_start_date = lv_start_date
      cv_start_time = lv_start_time
      cv_end_date   = lv_end_date
      cv_end_time   = lv_end_time
    EXCEPTIONS
      alert         = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    BREAK-POINT.
  ENDIF.

  SORT lt_log BY trtime ASCENDING.
  LOOP AT lt_log ASSIGNING FIELD-SYMBOL(<ls_log>) WHERE retcode = '0008'.
    cl_progress_indicator=>progress_indicate(
      i_text               = <ls_log>-trkorr
      i_processed          = sy-tabix
      i_total              = lines( lt_log )
      i_output_immediately = abap_true ).

    WRITE: / <ls_log>-trtime, <ls_log>-trkorr.
    PERFORM read_log USING <ls_log>-trkorr.
  ENDLOOP.

ENDFORM.

FORM read_log USING pv_trkorr TYPE trkorr.

  DATA: lt_log TYPE trlogs.

  CALL FUNCTION 'TMS_WBO_READ_LOG'
    EXPORTING
      iv_sysname        = p_sys
      iv_acttype        = 'G'
      iv_trkorr         = pv_trkorr
    IMPORTING
      et_logtab         = lt_log
    EXCEPTIONS
      invalid_input     = 1
      file_access_error = 2
      db_access_error   = 3
      OTHERS            = 4.
  IF sy-subrc <> 0.
    WRITE: / space, space, 'Error'.
    RETURN.
  ENDIF.

  DELETE lt_log WHERE severity <> 'E'.

  LOOP AT lt_log ASSIGNING FIELD-SYMBOL(<ls_log>).
    WRITE: / space, space, <ls_log>-line.
  ENDLOOP.

ENDFORM.
