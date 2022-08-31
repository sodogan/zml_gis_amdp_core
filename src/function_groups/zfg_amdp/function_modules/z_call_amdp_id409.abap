FUNCTION z_call_amdp_id409
  IMPORTING
    VALUE(contract_number) TYPE zzprcontract_number_type
    VALUE(decade) TYPE zzprdecade_type
    VALUE(storage_number) TYPE zzprstorage_number_type
    VALUE(coordinate_system) TYPE zzprcoordinate_system_type
    VALUE(coordinates) TYPE string
    VALUE(in_action) TYPE string
  EXPORTING
    VALUE(code) TYPE string
    VALUE(out_action) TYPE string
    VALUE(info) TYPE string
    VALUE(status) TYPE string
    VALUE(ev_success) TYPE flag
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID409' ).
      ENDIF.

      DATA(lref_gis_amdp) =  CAST zcl_gis_amdp_id409( zcl_gis_amdp_base=>get_instance( iv_id = '409'  ) ).

      ASSERT ID zml_gis_amdp CONDITION  lref_gis_amdp  IS BOUND.

**Call the AMDP method passing the input parameters
      lref_gis_amdp->manage_storage_location(
        EXPORTING
          contract_number   = contract_number
          decade            = decade
          storage_number    = storage_number
          coordinate_system = coordinate_system
          coordinates       = coordinates
          in_action         = in_action
        IMPORTING
          code              = code
          out_action        = out_action
          info              = info
          status            = status
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