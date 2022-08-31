FUNCTION z_call_amdp_id1182
  IMPORTING
    VALUE(in_starttime) TYPE string
    VALUE(in_endtime) TYPE string
  EXPORTING
    VALUE(out_starttime) TYPE string
    VALUE(out_endtime) TYPE string
    VALUE(contracts) TYPE zprdtid1182_gisget_map_sy_tab
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID1182' ).
      ENDIF.

      DATA(lref_gis_amdp) =  CAST zcl_gis_amdp_id1182( zcl_gis_amdp_base=>get_instance( iv_id = '1182'  ) ).

      ASSERT ID zml_gis_amdp CONDITION  lref_gis_amdp  IS BOUND.

**Call the AMDP method passing the input parameters
      lref_gis_amdp->get_map_symbol_modif(
        EXPORTING
          in_starttime  = in_starttime
          in_endtime    = in_endtime
        IMPORTING
          out_starttime = out_starttime
          out_endtime   = out_endtime
          contracts     = contracts
      ).

      ev_success = abap_true.
    CATCH cx_root INTO DATA(lo_exception).
      ROLLBACK WORK.
      ev_error_message = lo_exception->get_text(  ).
*Log the error message
      go_amdp_logger->add_exception(
        EXPORTING
          msgty     = 'E'
          exception = lo_exception
      ).
      go_amdp_logger->write_log(  ).
      ev_success = abap_false.
  ENDTRY.



ENDFUNCTION.