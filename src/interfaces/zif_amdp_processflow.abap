INTERFACE zif_amdp_processflow
  PUBLIC.
  TYPES: BEGIN OF ENUM process_flow_key,
           id221,
           id231,
           id374,
         END OF ENUM process_flow_key.

  METHODS: process IMPORTING input_parameters        TYPE data
                   EXPORTING VALUE(ev_success)       TYPE flag
                             VALUE(ev_error_message) TYPE string.


ENDINTERFACE.