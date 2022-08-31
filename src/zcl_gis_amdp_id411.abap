"! <p class="shorttext synchronized" lang="en">DistanceMessageSend</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id411/source/main#start=86,2;end=91,0 </p>
CLASS zcl_gis_amdp_id411 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS call_id411
      IMPORTING
                VALUE(in_routes)  TYPE zprroadstorage_route_requ_tab
      EXPORTING
                VALUE(out_routes) TYPE zprroadstorage_route_resp_tab
      RAISING   cx_static_check.

    METHODS distance_message_send
      IMPORTING
                VALUE(in_routes)  TYPE zprroadstorage_route_requ_tab
      EXPORTING
                VALUE(out_routes) TYPE zprroadstorage_route_resp_tab
      RAISING   cx_amdp_error.

    METHODS distance_message_result
      IMPORTING
                VALUE(staging_routes) TYPE zprroadstorage_route_resp_tab
      EXPORTING
                VALUE(out_routes)     TYPE zprroadstorage_route_resp_tab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id411 IMPLEMENTATION.



  METHOD call_id411.

* Wrapper method to send the distance data and get the results
* The method will first call the methods and API call
* Call flow distance_message_send->API call->distance_message_result
* The exceptions are propagated to the higher level and for logging
    DATA: lr_rest_handler TYPE REF TO zcl_graphhopper_rest_handler,
          lx_rest_handler TYPE REF TO zcx_rest_handler.


    BREAK-POINT ID zml_gis_amdp.

    TRY.
        distance_message_send(
          EXPORTING
            in_routes  = in_routes
          IMPORTING
            out_routes = out_routes
        ).
        IF line_exists( out_routes[ 1 ] )."if any records exist

* TODO: API call goes here, the input for the API call should be in out_routes
** API should get the distance information and pass it to the distance_message_result method

          TRY.
              lr_rest_handler = NEW zcl_graphhopper_rest_handler( ).
            CATCH zcx_rest_handler INTO lx_rest_handler.
              DATA(error_text) = lx_rest_handler->get_text( ).
          ENDTRY.


          LOOP AT out_routes ASSIGNING FIELD-SYMBOL(<out_route>).

            TRY.
                lr_rest_handler->calculate_route_distance(
                  EXPORTING
                    iv_start_point = <out_route>-startpoint
                    iv_end_point   = <out_route>-endpoint
                  IMPORTING
                    ev_distance      = <out_route>-distance
                    ev_time          = <out_route>-time
                ).
              CATCH zcx_rest_handler INTO lx_rest_handler.

            ENDTRY.

          ENDLOOP.
*After the API call the method  distance_message_result
          distance_message_result(
            EXPORTING
              staging_routes = out_routes
            IMPORTING
              out_routes     = out_routes
          ).

        ENDIF.


      CATCH cx_root INTO DATA(lo_exception).
** Rethrow it to the higher level
        RAISE EXCEPTION lo_exception.
    ENDTRY.

  ENDMETHOD.

  METHOD distance_message_send BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare index_i int;
    declare out_t table (
        contract       nvarchar( 50 ),
        storage_number bigint,
        decade         int,
        storage_id     nvarchar( 50 ),
        storage_type   nvarchar( 50 ),
        distance       bigint,
        time           bigint,
        logyid         nvarchar( 50 ),
        metlaid        nvarchar( 50 ),
        piiriid        nvarchar( 50 ),
        startpoint     nvarchar( 50 ),
        endpoint       nvarchar( 50 )
      );

    for index_i in 1..record_count( :in_routes )
    do
        declare x_start, y_start, x_end, y_end bigint;
        declare startpoint string;
        declare endpoint string;
        declare contract bigint = TO_BIGINT( :in_routes.contract[:index_i] );
        declare decade int = TO_INT( :in_routes.decade[:index_i] );
        declare contractid bigint = TO_BIGINT( :in_routes.contract[:index_i] || :in_routes.decade[:index_i] );
        declare storagenumber bigint = :in_routes.storage_number[:index_i];
        declare storage_type string = :in_routes.storage_type[:index_i];
        declare storage_id string = :in_routes.storage_id[:index_i];

        select
*-KKJ not supported            round(sdo_cs.transform(sdo_geom.sdo_centroid(geoloc,1),2393).SDO_POINT.x) as x,
*-KKJ not supported            round(sdo_cs.transform(sdo_geom.sdo_centroid(geoloc,1),2393).SDO_POINT.y) as y
            round( geoloc.ST_Centroid().ST_X(  ) ) as a,
            round( geoloc.ST_Centroid().ST_Y(  ) ) as b into x_start, y_start default null, null
            from
            MG_KOTKA.STORAGE a where CONTRACTID = :contractid and storage_number = :storagenumber;

        startpoint = TO_NVARCHAR(:x_start) || CHAR(32) || TO_NVARCHAR(:y_start);

        select
*-KKJ not supported            round(sdo_cs.transform(geoloc,?).SDO_POINT.x) as x,
*-KKJ not supported            round(sdo_cs.transform(geoloc,?).SDO_POINT.y) as y
            round( geoloc.ST_Centroid().ST_X(  ) ) as a,
            round( geoloc.ST_Centroid().ST_Y(  ) ) as b into x_end, y_end default null, null
            from GISDATA.ROUTE_STORAGE where storage_type = :storage_type and storage_code = :storage_id and geoloc is not null;

        endpoint =  TO_NVARCHAR(:x_end) || CHAR(32) || TO_NVARCHAR(:y_end);

* get route distance and time from map server
* mapserver.url.template=http://146.119.74.232/new_mapservertest/services/routing/route?point=START_POINT_Y%2CSTART_POINT_X&point=END_POINT_Y%2CEND_POINT_X&type=json&locale=en-GB&
* vehicle=car&weighting=fastest&elevation=false&key=&points_encoded=false&instructions=false
* where START_POINT_Y START_POINT_X END_POINT_Y END_POINT_X strings must be replaced by real values
* Resolved spliting the method in two parts
******************************************************

       :out_t.insert( ( TO_NVARCHAR( :contract ) , :storagenumber , :decade, :storage_id, :storage_type, null, null, null, null, null, :startpoint, :endpoint));

    end for;

    out_routes = select * from :out_t;


  ENDMETHOD.

  METHOD distance_message_result BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .
* local variables
    declare index_i int;
    declare logyid, metlaid, piiriid string;
    declare out_t table (
        contract       nvarchar( 50 ),
        storage_number bigint,
        decade         int,
        storage_id     nvarchar( 50 ),
        storage_type   nvarchar( 50 ),
        distance       bigint,
        time           bigint,
        logyid         nvarchar( 50 ),
        metlaid        nvarchar( 50 ),
        piiriid        nvarchar( 50 ),
        startpoint     nvarchar( 50 ),
        endpoint       nvarchar( 50 )
      );


    for index_i in 1..record_count( :staging_routes )
    do
        declare logyid, metlaid, piiriid string;

        declare startpoint string = :staging_routes.startpoint[:index_i];
        declare endpoint string = :staging_routes.endpoint[:index_i];
        declare x_end string;
        declare y_end string;

        select SUBSTR_BEFORE( :endpoint , CHAR(32)) into x_end from dummy;
        select SUBSTR_AFTER( :endpoint , CHAR(32)) into y_end from dummy;

        select LOGY_CODE into logyid default null from GISDATA.ROUTE_LOGY where geoloc.ST_Contains( new ST_Point( 'Point (' || :x_end || CHAR(32) || :y_end || ')', 3067 ) ) = 1;
        select ALUE_ID into metlaid default null from GISDATA.KUORMAINVAAKA_ALUEET where geoloc.ST_Contains( new ST_Point( 'Point (' || :x_end || CHAR(32) || :y_end || ')', 3067 ) ) = 1;
        select DISTRICT_ID into piiriid default null from MG_SPATIAL.V_GIS_DISTRICT where geoloc.ST_Contains( new ST_Point( 'Point (' || :x_end || CHAR(32) || :y_end || ')', 3067 ) ) = 1;

        :out_t.insert( ( :staging_routes.contract[:index_i], :staging_routes.storage_number[:index_i], :staging_routes.decade[:index_i], :staging_routes.storage_id[:index_i],
                         :staging_routes.storage_type[:index_i], :staging_routes.distance[:index_i], :staging_routes.time[:index_i], :logyid, :metlaid, :piiriid,
                         :staging_routes.startpoint[:index_i], :staging_routes.endpoint[:index_i] ));

    end for;

    out_routes = select * from :out_t;

  ENDMETHOD.


ENDCLASS.