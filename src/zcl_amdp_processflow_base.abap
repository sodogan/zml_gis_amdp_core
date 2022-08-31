"! <p class="shorttext synchronized" lang="en">Base class for all process flows</p>
CLASS zcl_amdp_processflow_base DEFINITION
  PUBLIC
  CREATE PUBLIC ABSTRACT
  GLOBAL FRIENDS zif_amdp_processflow_factory.

  PUBLIC SECTION.
    INTERFACES zif_amdp_processflow ALL METHODS ABSTRACT.
    ALIASES process_flow_key FOR zif_amdp_processflow~process_flow_key.
    ALIASES process FOR zif_amdp_processflow~process.
    METHODS: constructor.
    class-METHODS: class_constructor.
  PROTECTED SECTION.
    METHODS: init ABSTRACT.
    DATA: go_amdp_logger TYPE REF TO zif_amdp_logger.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_amdp_processflow_base IMPLEMENTATION.

  METHOD class_constructor.
  ENDMETHOD.

  METHOD constructor.
  ENDMETHOD.

ENDCLASS.