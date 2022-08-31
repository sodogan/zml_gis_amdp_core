FUNCTION z_call_amdp_id211
  IMPORTING
    VALUE(in_originid) TYPE string
    VALUE(in_origintype) TYPE string
    VALUE(in_originclass) TYPE string
    VALUE(in_origin_maxdistance) TYPE int4
    VALUE(in_destination_id) TYPE string
    VALUE(in_destination_type) TYPE string
    VALUE(in_destination_class) TYPE int4
    VALUE(in_destination_maxdistance) TYPE int4
  EXPORTING
    VALUE(routes) TYPE zprroutetype_tab
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID211' ).
      ENDIF.

      DATA(lref_gis_amdp) =  CAST zcl_gis_amdp_id211( zcl_gis_amdp_base=>get_instance( iv_id = '211'  ) ).

      ASSERT ID zml_gis_amdp CONDITION  lref_gis_amdp  IS BOUND.

**Call the AMDP method passing the input parameters
      lref_gis_amdp->route_message_send(
        EXPORTING
          in_originid                = in_originid
          in_origintype              = in_origintype
          in_originclass             = in_originclass
          in_origin_maxdistance      = in_origin_maxdistance
          in_destination_id          = in_destination_id
          in_destination_type        = in_destination_type
          in_destination_class       = in_destination_class
          in_destination_maxdistance = in_destination_maxdistance
        IMPORTING
          routes                     = routes
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