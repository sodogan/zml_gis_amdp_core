FUNCTION z_call_amdp_id231
  IMPORTING
    VALUE(id231_parameters) TYPE zid231_parameters
  EXPORTING
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID231' ).
      ENDIF.

      DATA(lref_231_process_flow) = zcl_amdp_processflow_factory=>new_process_flow( process_flow_key = zif_amdp_processflow=>id231 ).


      ASSERT ID zml_gis_amdp CONDITION  lref_231_process_flow  IS BOUND.

**Call the AMDP method passing the input parameters

      lref_231_process_flow->process(
        EXPORTING
          input_parameters = id231_parameters
        IMPORTING
          ev_success       = ev_success
          ev_error_message = ev_error_message
      ).

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