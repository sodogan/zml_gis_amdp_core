CLASS zcx_gis_invalid_param DEFINITION
  PUBLIC
  INHERITING FROM zcx_gis_abstract
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  constants:
  begin of CX_INVALID_PARAMETER,
      msgid type symsgid value 'ZML_GIS_AMDP',
      msgno type symsgno value '000',
      attr1 type scx_attrname value 'PARAMETER',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of CX_INVALID_PARAMETER.


    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !parameter type csequence optional.
  data: parameter  type c length 40 .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_gis_invalid_param IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    me->parameter = parameter.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = CX_INVALID_PARAMETER.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.