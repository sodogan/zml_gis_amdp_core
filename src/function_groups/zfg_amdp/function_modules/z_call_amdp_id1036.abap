FUNCTION z_call_amdp_id1036
  IMPORTING
    VALUE(in_workingsiteid) TYPE zzworkingsiteid
    VALUE(in_logy) TYPE zzlogy
    VALUE(in_treespeciesitems) TYPE ziidtid1036_model_compart_tab
  EXPORTING
    VALUE(out_workingsiteid) TYPE zzworkingsiteid
    VALUE(out_logy) TYPE zzlogy
    VALUE(out_treespeciesitems) TYPE ziidtid1036_model_compar_tab1
    VALUE(ev_success) TYPE abap_bool
    VALUE(ev_error_message) TYPE string.



  BREAK-POINT ID zml_gis_amdp.

  TRY.

      IF NOT go_amdp_logger IS BOUND.
        go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID1036' ).
      ENDIF.

      DATA:lref_gis_amdp TYPE REF  TO zcl_gis_amdp_id1036.

      lref_gis_amdp =  CAST zcl_gis_amdp_id1036( zcl_gis_amdp_base=>get_instance( iv_id = '1036'  ) ).

**Call the AMDP method passing the input parameters
      lref_gis_amdp->ModelCompartmentUp(
        EXPORTING
          in_workingsiteid     = in_workingsiteid
          in_logy              = in_logy
          in_treespeciesitems  = in_treespeciesitems
        IMPORTING
          out_workingsiteid    = out_workingsiteid
          out_logy             = out_logy
          out_treespeciesitems = out_treespeciesitems
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