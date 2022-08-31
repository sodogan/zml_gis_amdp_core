FUNCTION z_call_amdp_id408
  IMPORTING
    VALUE(contract_code) TYPE string
    VALUE(storage_code) TYPE string
    VALUE(decade) TYPE int4
    VALUE(in_coordinate_system) TYPE string
  EXPORTING
    VALUE(map_symbols) TYPE zprmapsymbol_type_tab
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.





  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID408' ).
      ENDIF.

      DATA(lref_gis_amdp) =  CAST zcl_gis_amdp_id408( zcl_gis_amdp_base=>get_instance( iv_id = '408'  ) ).

      ASSERT ID zml_gis_amdp CONDITION  lref_gis_amdp  IS BOUND.

**Call the AMDP method passing the input parameters
      lref_gis_amdp->map_symbols_send(
        EXPORTING
          contract_code        = contract_code
          storage_code         = storage_code
          decade               = decade
          in_coordinate_system = in_coordinate_system
        IMPORTING
          map_symbols          = map_symbols
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