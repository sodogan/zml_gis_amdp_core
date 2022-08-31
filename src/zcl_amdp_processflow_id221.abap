"! <p class="shorttext synchronized" lang="en">Process flow for ID221</p>
CLASS zcl_amdp_processflow_id221 DEFINITION
  PUBLIC
  INHERITING FROM zcl_amdp_processflow_base
  FINAL
  CREATE PRIVATE  GLOBAL FRIENDS zif_amdp_processflow_factory.

  PUBLIC SECTION.
      METHODS: constructor.
    METHODS: process REDEFINITION.
  PROTECTED SECTION.
    METHODS: init REDEFINITION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_amdp_processflow_id221 IMPLEMENTATION.
  METHOD process.




  ENDMETHOD.

  METHOD constructor.

    super->constructor( ).
**Call the init
    init(  ).

  ENDMETHOD.


  METHOD init.
    go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID221' ).
  ENDMETHOD.

ENDCLASS.