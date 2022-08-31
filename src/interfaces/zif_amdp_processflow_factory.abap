INTERFACE zif_amdp_processflow_factory
  PUBLIC .
  CLASS-METHODS: new_process_flow IMPORTING process_flow_key TYPE zif_amdp_processflow=>process_flow_key DEFAULT zif_amdp_processflow=>id374
                                  RETURNING VALUE(out_ref)   TYPE REF TO zif_amdp_processflow.

ENDINTERFACE.