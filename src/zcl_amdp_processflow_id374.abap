"! <p class="shorttext synchronized" lang="en">Process flow for ID374</p>
CLASS zcl_amdp_processflow_id374 DEFINITION
  PUBLIC
  INHERITING FROM zcl_amdp_processflow_base
  FINAL
  CREATE PRIVATE GLOBAL FRIENDS zif_amdp_processflow_factory.

  PUBLIC SECTION.
    METHODS: constructor.
    METHODS:process REDEFINITION.
  PROTECTED SECTION.
    METHODS: init REDEFINITION.
private section.
ENDCLASS.



CLASS ZCL_AMDP_PROCESSFLOW_ID374 IMPLEMENTATION.


  METHOD process.

    DATA: ls_id374_parameters TYPE zid374_parameters.

    DATA: lv_locno           TYPE string,
          lv_zwsyrittajatunn TYPE stcd3,
          lv_supplypointcode TYPE zzlyhenne2,
          lv_cepicode        TYPE zzcepikoodi,
          lv_lfcode          TYPE string,
          lv_name1           TYPE string,
          lv_name2           TYPE name2,
          lv_supplypointtype TYPE zztptlf.

    DATA: lv_ptl         TYPE zzptlryhma,
          lv_ptl_nimitys TYPE string,
          lv_scmjae      TYPE char1.

    TRY.
        DATA(type_descr) = cl_abap_typedescr=>describe_by_data( input_parameters ).

        ls_id374_parameters = input_parameters.


        CALL FUNCTION 'Z_GET_DELIVERYDESTINATIONINFO'
          EXPORTING
            locno           = lv_locno
            zwsyrittajatunn = lv_zwsyrittajatunn
          IMPORTING
            cepicode        = lv_cepicode
            lfcode          = lv_lfcode
            name1           = lv_name1
            name2           = lv_name2
            supplypointtype = lv_supplypointtype
            supplypointcode = lv_supplypointcode.

        CALL FUNCTION 'Z_GET_PTLINFO'
          EXPORTING
            ptl         = lv_ptl
          IMPORTING
            ptl_nimitys = lv_ptl_nimitys
            scmjae      = lv_scmjae.

      CATCH cx_root INTO DATA(lo_exception).
        ROLLBACK WORK.
        ev_error_message = lo_exception->get_text(  ).
*Log the error message (subobject ZID231)
        go_amdp_logger->add_exception(
          EXPORTING
            msgty     = 'E'
            exception = lo_exception
        ).
        go_amdp_logger->write_log(  ).
        ev_success = abap_false.
        RETURN.
    ENDTRY.

    ev_success = abap_true.

  ENDMETHOD.


  METHOD constructor.

    super->constructor( ).
**Call the init
    init(  ).

  ENDMETHOD.


  METHOD init.
    go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID374' ).
  ENDMETHOD.
ENDCLASS.