"! <p class="shorttext synchronized" lang="en">AMDP Logger wrapping ZCL_APPLICATION_LOG_WRAPPER</p>
CLASS zcl_amdp_application_logger DEFINITION
  PUBLIC
  CREATE PUBLIC INHERITING FROM zcl_amdp_logger_base.

*"* public components of class ZCL_APPLICATION_LOG_WRAPPER
*"* do not include other source files here!!!
  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING
        !object          TYPE balhdr-object DEFAULT zif_amdp_logger~gc_object
        !subobject       TYPE balhdr-subobject DEFAULT zif_amdp_logger~gc_subobject
        external_id TYPE clike
        altcode TYPE clike
        msgid TYPE sy-msgid
        is_extended_log TYPE abap_bool
      RETURNING
        value(r_result) TYPE REF TO zcl_amdp_application_logger.
    METHODS constructor
      IMPORTING
        !object          TYPE balhdr-object DEFAULT zif_amdp_logger~gc_object
        !subobject       TYPE balhdr-subobject DEFAULT zif_amdp_logger~gc_subobject
        external_id     TYPE clike OPTIONAL
        altcode         TYPE clike OPTIONAL
        msgid           TYPE sy-msgid OPTIONAL
        is_extended_log TYPE abap_bool DEFAULT abap_false .
    METHODS: zif_amdp_logger~has_log_contents REDEFINITION.
    METHODS: zif_amdp_logger~write_log REDEFINITION.
    METHODS: zif_amdp_logger~add_balmi REDEFINITION,
      zif_amdp_logger~add_bapiret2 REDEFINITION,
      zif_amdp_logger~add_collector REDEFINITION,
      zif_amdp_logger~add_exception REDEFINITION,
      zif_amdp_logger~add_exception_text REDEFINITION,
      zif_amdp_logger~add_free_text REDEFINITION,
      zif_amdp_logger~add_if_t100_message REDEFINITION,
      zif_amdp_logger~add_msg REDEFINITION,
      zif_amdp_logger~add_selections REDEFINITION,
      zif_amdp_logger~add_string REDEFINITION,
      zif_amdp_logger~add_timestamp REDEFINITION,
      zif_amdp_logger~add_timestamp_and_text REDEFINITION.

  PROTECTED SECTION.



  PRIVATE SECTION.


ENDCLASS.

CLASS zcl_amdp_application_logger IMPLEMENTATION.

  METHOD create.

    r_result = NEW #(
      object = object
      subobject = subobject
      external_id = external_id
      altcode = altcode
      msgid = msgid
      is_extended_log = is_extended_log
    ).

  ENDMETHOD.


  METHOD constructor.

    super->constructor(
*                        object          = object
      subobject       = subobject
      external_id     = external_id
      altcode         = altcode
      msgid           = msgid
      is_extended_log = is_extended_log ).

  ENDMETHOD.

  METHOD zif_amdp_logger~add_balmi.
    mo_application_logger->add_balmi( balmi = balmi ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_bapiret2.
    mo_application_logger->add_bapiret2(
      EXPORTING
        bapiret2 = bapiret2
*       row      = -1
    ).
  ENDMETHOD.


  METHOD zif_amdp_logger~add_collector.
    mo_application_logger->add_collector( messages = messages ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_exception.
    mo_application_logger->add_exception(
      EXPORTING
        msgty     = msgty
        exception = exception
    ).
  ENDMETHOD.


  METHOD zif_amdp_logger~add_exception_text.
    mo_application_logger->add_exception_text(
      EXPORTING
*       type      = 'E'
        exception = exception
    ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_free_text.
    mo_application_logger->add_free_text(
      type   = type
      string = string
    ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_if_t100_message.
    mo_application_logger->add_if_t100_message(
      EXPORTING
        iif_t100_message = iif_t100_message
*       i_type           = 'E'
    ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_msg.
    mo_application_logger->add_msg( msg = msg ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_selections.

    mo_application_logger->add_selections( repid = repid ).

  ENDMETHOD.

  METHOD zif_amdp_logger~add_string.
    mo_application_logger->add_string(
      EXPORTING
*       type   = 'I'
*       id     =
*       number = '000'
        string = string
    ).
  ENDMETHOD.



  METHOD zif_amdp_logger~add_timestamp.
    mo_application_logger->add_timestamp( msgno = msgno ).
  ENDMETHOD.

  METHOD zif_amdp_logger~add_timestamp_and_text.
    mo_application_logger->add_timestamp_and_text(
      i_text = i_text
    ).
  ENDMETHOD.



  METHOD zif_amdp_logger~write_log.
*Write only if there is any contents
    IF zif_amdp_logger~has_log_contents(  ) EQ abap_true.
      mo_application_logger->write( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_amdp_logger~has_log_contents.
    r_value = mo_application_logger->something_is_put_to_log( ).
  ENDMETHOD.

ENDCLASS.