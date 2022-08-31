FUNCTION z_call_amdp_id411
  IMPORTING
    VALUE(in_routes) TYPE zprroadstorage_route_requ_tab
  EXPORTING
    VALUE(out_routes) TYPE zprroadstorage_route_resp_tab
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.
      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID411' ).
      ENDIF.

      DATA(lref_gis_amdp) =  CAST zcl_gis_amdp_id411( zcl_gis_amdp_base=>get_instance( iv_id = '411'  ) ).

      ASSERT ID zml_gis_amdp CONDITION  lref_gis_amdp  IS BOUND.

**First call the AMDP to send then
      lref_gis_amdp->call_id411(
        EXPORTING
          in_routes  = in_routes
        IMPORTING
          out_routes = DATA(lt_out_routes)
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