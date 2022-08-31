"! <p class="shorttext synchronized" lang="en">Process flow  Factory class</p>
CLASS zcl_amdp_processflow_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_amdp_processflow_factory.
    ALIASES new_process_flow FOR zif_amdp_processflow_factory~new_process_flow.

  PROTECTED SECTION.
    TYPES: BEGIN OF ty_cache,
             id  TYPE zif_amdp_processflow=>process_flow_key,
             ref TYPE REF TO zif_amdp_processflow,
           END OF ty_cache,
           tt_instances TYPE HASHED TABLE OF ty_cache WITH UNIQUE KEY id.
    CLASS-DATA: mt_cache TYPE tt_instances.
  PRIVATE SECTION.
    CLASS-METHODS new
      IMPORTING
        i_process_flow_key TYPE zif_amdp_processflow=>process_flow_key
      RETURNING
        VALUE(r_out_ref)   TYPE REF TO zif_amdp_processflow.
ENDCLASS.



CLASS zcl_amdp_processflow_factory IMPLEMENTATION.

  METHOD zif_amdp_processflow_factory~new_process_flow.
    DATA: ls_instance TYPE ty_cache.
*Check if it exists in the buffer
    READ TABLE mt_cache
    WITH TABLE KEY id = process_flow_key
     ASSIGNING FIELD-SYMBOL(<lfs_instance>).

    out_ref = COND #( WHEN sy-subrc EQ 0 THEN <lfs_instance>-ref
                       ELSE new( process_flow_key ) ).



  ENDMETHOD.


  METHOD new.

    DATA ls_instance TYPE zcl_amdp_processflow_factory=>ty_cache.

    CASE i_process_flow_key.
      WHEN zif_amdp_processflow=>id221.
        r_out_ref = NEW zcl_amdp_processflow_id221(  ).
        ls_instance-ref = r_out_ref.
      WHEN zif_amdp_processflow=>id231.
        r_out_ref = NEW zcl_amdp_processflow_id231(  ).
        ls_instance-ref = r_out_ref.
      WHEN zif_amdp_processflow=>id374.
        r_out_ref = NEW zcl_amdp_processflow_id374(  ).
        ls_instance-ref = r_out_ref.
      WHEN OTHERS.
    ENDCASE.

    ls_instance-id = i_process_flow_key.
    INSERT ls_instance INTO TABLE mt_cache.

  ENDMETHOD.

ENDCLASS.