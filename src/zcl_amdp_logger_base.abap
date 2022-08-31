"! <p class="shorttext synchronized" lang="en">Abstract Base Logger for AMDP</p>
CLASS zcl_amdp_logger_base DEFINITION
  PUBLIC
  CREATE PUBLIC ABSTRACT .

  PUBLIC SECTION.
    TYPE-POOLS abap .

    INTERFACES zif_amdp_logger ALL METHODS ABSTRACT.
    DATA error_count TYPE i READ-ONLY .
    DATA other_count TYPE i READ-ONLY .
    DATA warning_count TYPE i READ-ONLY .
    METHODS constructor
      IMPORTING
        !object          TYPE balhdr-object DEFAULT zif_amdp_logger~gc_object
        !subobject       TYPE balhdr-subobject DEFAULT zif_amdp_logger~gc_subobject
        !external_id     TYPE clike OPTIONAL
        !altcode         TYPE clike OPTIONAL
        !msgid           TYPE sy-msgid OPTIONAL
        !is_extended_log TYPE abap_bool DEFAULT abap_false .

  PROTECTED SECTION.
    DATA: mo_application_logger TYPE REF TO zcl_application_log_wrapper.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_amdp_logger_base IMPLEMENTATION.
  METHOD constructor.
    mo_application_logger = NEW #(
      object       = object
      subobject    = subobject
      external_id  = external_id
      altcode      = altcode
      msgid        = msgid
      extended_log = is_extended_log
*     application_log_opened_message = abap_false
*     userexitp    = userexitp
*     userexitf    = userexitf
    ).

  ENDMETHOD.

ENDCLASS.