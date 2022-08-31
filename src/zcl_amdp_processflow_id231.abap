"! <p class="shorttext synchronized" lang="en">Process flow for ID231 interface</p>
CLASS zcl_amdp_processflow_id231 DEFINITION
  PUBLIC
  INHERITING FROM zcl_amdp_processflow_base
  FINAL
  CREATE PRIVATE GLOBAL FRIENDS zif_amdp_processflow_factory.

  PUBLIC SECTION.
    METHODS: constructor.
    METHODS: process REDEFINITION.
  PROTECTED SECTION.
    METHODS: init REDEFINITION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_amdp_processflow_id231 IMPLEMENTATION.

  METHOD process.
    FREE: ev_error_message, ev_success.

********************************************************
** This is the entry point to the new ID231
** It will call the AMDPS in the order:
* ID408,
* ID410
* ID411
* ID211
* Also there is XMAPP part which needs to be enlightened!
* Important: What happens with the importing parameters
* For example: map_symbols: "ls_id408_parameters-exporting-map_symbols line 63"
********************************************************
    DATA: ls_id231_parameters TYPE zid231_parameters.
    DATA: ls_id408_parameters TYPE zid408_parameters.
    DATA: ls_id410_parameters TYPE zid410_parameters.
    DATA: ls_id411_parameters TYPE zid411_parameters.
    DATA: ls_id211_parameters TYPE zid211_parameters.

    TRY.

        BREAK-POINT ID zml_gis_amdp.

        DATA(type_descr) = cl_abap_typedescr=>describe_by_data( input_parameters ).


**Get all the parameters
        ls_id231_parameters =  input_parameters.

** Get the id408 parameters
        ls_id408_parameters = ls_id231_parameters-id408_parameters.

        DATA(lo_amdp_408) =  CAST zcl_gis_amdp_id408( zcl_gis_amdp_base=>get_instance( iv_id = '408'  ) ).

** Call the AMDP ID408
        lo_amdp_408->map_symbols_send(
          EXPORTING
            contract_code        = ls_id408_parameters-importing-contract_code
            storage_code         = ls_id408_parameters-importing-storage_code
            decade               = ls_id408_parameters-importing-decade
            in_coordinate_system = ls_id408_parameters-importing-in_coordinate_system
          IMPORTING
            map_symbols          = ls_id408_parameters-exporting-map_symbols
        ).

** Get the id410 parameters
        ls_id410_parameters = ls_id231_parameters-id410_parameters.

        DATA(lo_amdp_410) =  CAST zcl_gis_amdp_id410( zcl_gis_amdp_base=>get_instance( iv_id = '410'  ) ).

** Call the AMDP ID410
        lo_amdp_410->location_lookup(
          EXPORTING
            in_logys          = ls_id410_parameters-importing-in_logys
            in_storages       = ls_id410_parameters-importing-in_storages
            in_road_storages  = ls_id410_parameters-importing-in_road_storages
          IMPORTING
            out_logys         = ls_id410_parameters-exporting-out_logys
            out_storages      = ls_id410_parameters-exporting-out_storages
            out_road_storages = ls_id410_parameters-exporting-out_road_storages
        ).


** Get the id411 parameters
        ls_id411_parameters = ls_id231_parameters-id411_parameters.

        DATA(lo_amdp_411) =  CAST zcl_gis_amdp_id411( zcl_gis_amdp_base=>get_instance( iv_id = '411'  ) ).

**Call ID 411 is the main entry point
        lo_amdp_411->call_id411(
          EXPORTING
            in_routes  = ls_id411_parameters-importing-in_routes
          IMPORTING
            out_routes = ls_id411_parameters-exporting-out_routes
        ).


** Get the id211 parameters
        ls_id211_parameters = ls_id231_parameters-id211_parameters.

        DATA(lo_amdp_211) =  CAST zcl_gis_amdp_id211( zcl_gis_amdp_base=>get_instance( iv_id = '211'  ) ).


       lo_amdp_211->route_message_send(
         EXPORTING
           in_originid                = ls_id211_parameters-importing-in_originid
           in_origintype              = ls_id211_parameters-importing-in_origintype
           in_originclass             = ls_id211_parameters-importing-in_originclass
           in_origin_maxdistance      = ls_id211_parameters-importing-in_origin_maxdistance
           in_destination_id          = ls_id211_parameters-importing-in_destination_id
           in_destination_type        = ls_id211_parameters-importing-in_destination_type
           in_destination_class       = ls_id211_parameters-importing-in_destination_class
           in_destination_maxdistance = ls_id211_parameters-importing-in_destination_maxdistance
         IMPORTING
           routes                     = ls_id211_parameters-exporting-routes
       ).



      CATCH cx_root INTO DATA(lo_exception).
        ROLLBACK WORK.
        ev_error_message = lo_exception->get_text(  ).
*Log the error message
        go_amdp_logger->add_exception(
          EXPORTING
            msgty     = 'E'
            exception = lo_exception
        ).
        go_amdp_logger->write_log(  ).
        ev_success = abap_false.
        RETURN.

    ENDTRY.

**if reaches here without exception its successfull
    ev_success = abap_true.




  ENDMETHOD.

  METHOD init.
    go_amdp_logger = NEW zcl_amdp_application_logger( subobject = 'ZID231' ).
  ENDMETHOD.


  METHOD constructor.

    super->constructor( ).
**Call the init
    init(  ).

  ENDMETHOD.

ENDCLASS.