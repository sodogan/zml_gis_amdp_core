CLASS zcx_unexpected_exception DEFINITION
  PUBLIC
  CREATE PUBLIC inheriting from zcx_gis_abstract .

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    METHODS constructor IMPORTING iv_parameter_name TYPE string OPTIONAL
                                  iv_previous       LIKE previous OPTIONAL.

    DATA mv_parameter_name TYPE string ##NEEDED.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_unexpected_exception IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = iv_previous ).

    mv_parameter_name = iv_parameter_name.
  ENDMETHOD.



ENDCLASS.