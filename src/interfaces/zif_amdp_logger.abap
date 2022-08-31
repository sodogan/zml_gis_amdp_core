INTERFACE zif_amdp_logger
  PUBLIC .
  CONSTANTS :  GC_OBJECT    TYPE balhdr-object VALUE 'ZAMDP'.
  CONSTANTS :  GC_SUBOBJECT    TYPE balhdr-object VALUE 'ZGENERAL'.
  METHODS add_balmi
    IMPORTING
      !balmi TYPE balmi .
  METHODS add_bapiret2
    IMPORTING
      !bapiret2 TYPE bapiret2_tab
      !row      TYPE bapiret2-row DEFAULT -1 .
  METHODS add_collector
    IMPORTING
      !messages TYPE REF TO zmessage_collector .
  METHODS add_exception
    IMPORTING
      !msgty     TYPE symsgty DEFAULT 'E'
      !exception TYPE REF TO cx_root .
   METHODS add_exception_text
    IMPORTING
      !type      TYPE symsgty DEFAULT 'E'
      !exception TYPE REF TO cx_root .
   METHODS add_free_text
    IMPORTING
      !type   TYPE symsgty DEFAULT 'E'
      !STRING type STRING .
  METHODS add_if_t100_message
    IMPORTING
      !iif_t100_message TYPE REF TO if_t100_message
      !i_type           TYPE bal_s_msg-msgty DEFAULT 'E' .
  METHODS add_msg
    IMPORTING
      VALUE(msg) TYPE bal_s_msg .
  METHODS add_selections
    IMPORTING
      VALUE(repid) TYPE sy-repid .
  METHODS add_string
    IMPORTING
      !type   TYPE balmi-msgty DEFAULT 'I'
      !id     TYPE balmi-msgid OPTIONAL
      !number TYPE balmi-msgno DEFAULT '000'
      !string TYPE string .

  METHODS add_timestamp
    IMPORTING
      !msgno TYPE balmi-msgno .
  METHODS add_timestamp_and_text
    IMPORTING
      !i_text TYPE c OPTIONAL .
    methods has_LOG_contents
    returning
      value(R_VALUE) type ABAP_BOOL .
   methods WRITE_LOG .
   INTERFACES if_badi_interface .

ENDINTERFACE.