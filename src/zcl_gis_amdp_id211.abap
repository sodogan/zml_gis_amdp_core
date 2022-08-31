"! <p class="shorttext synchronized" lang="en">RouteMessageSend</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_distance01/source/main#start=471,0;end=475,23 </p>
CLASS zcl_gis_amdp_id211 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS route_message_send
      IMPORTING
                VALUE(in_originid)             TYPE string
                VALUE(in_origintype)           TYPE string
                VALUE(in_originclass)          TYPE string
                VALUE(in_origin_maxdistance)   TYPE int4
                VALUE(in_destination_id)       TYPE string
                VALUE(in_destination_type)     TYPE string
                VALUE(in_destination_class)    TYPE int4
                VALUE(in_destination_maxdistance)      TYPE int4
      EXPORTING
               VALUE(routes) TYPE ZPRROUTETYPE_TAB
            RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_GIS_AMDP_ID211 IMPLEMENTATION.


  METHOD route_message_send BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare id_origin string = '0';
    declare dist_origin int = 10000;
    declare tp_origin string = '';
    declare class_origin string = :in_originclass;
    declare id_destination string = '0';
    declare dist_destination int = 10000;
    declare tp_destination string = '';
    declare class_destination string = :in_destination_class;
    declare sqlstring string = '';
    declare output_t table(
            ORIGIN_ID                  nvarchar( 50 ),
            ORIGIN_CODE                nvarchar( 50 ),
            ORIGIN_CLASS_CODE          nvarchar( 50 ),
            ORIGIN_STORAGE_TYPE        nvarchar( 50 ),
            DESTINATION_ID             nvarchar( 50 ),
            DESTINATION_STORAGE_CODE   nvarchar( 50 ),
            DESTINATION_STORAGE_TYPE   nvarchar( 50 ),
            ROUTE_DISTANCE             bigint,
            ROUTE_TIME                 bigint,
            ROUTE_STRAIGHT             bigint
    );

    sqlstring = 'select ORIGIN_ID, coalesce(ORIGIN_LOGY_CODE,ORIGIN_STORAGE_CODE) ORIGIN_CODE,ORIGIN_CLASS_CODE, coalesce(ORIGIN_STORAGE_TYPE, ' ||
                CHAR( 39 ) || 'LOGY' || CHAR( 39 ) || ') ' ||
                'ORIGIN_STORAGE_TYPE, DESTINATION_ID,DESTINATION_STORAGE_CODE,DESTINATION_STORAGE_TYPE,ROUTE_DISTANCE,ROUTE_TIME,ROUTE_STRAIGHT ' ||
                'from GISDATA.ROUTE_OD_MATRIX_VI where 1 = 1';
    -- filter by origin
    if length( :in_originid ) > 0
    then
        id_origin = :in_originid;
        dist_origin = :in_origin_maxdistance;
        tp_origin = :in_origintype;
        if :dist_origin > 800000
        then
            dist_origin = 800000;
        end if;

        if upper( :tp_origin ) = 'LOGY'
        then
            sqlstring = :sqlstring || ' and ORIGIN_LOGY_CODE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :id_origin ) || CHAR( 39 ) ||
            ' and ROUTE_DISTANCE <= ' || ESCAPE_SINGLE_QUOTES( :dist_origin );
            if length( :class_origin ) > 0
            then
                sqlstring = :sqlstring || ' and ORIGIN_CLASS_CODE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :class_origin ) || CHAR( 39 );
            end if;
        else
            sqlstring = :sqlstring || ' and ORIGIN_STORAGE_CODE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :id_origin ) || CHAR( 39 ) ||
            ' and ROUTE_DISTANCE <= ' || ESCAPE_SINGLE_QUOTES( :dist_origin );
        end if;

    end if;
    -- filter by destination
    if length( :in_destination_id ) > 0
    then
        id_destination = :in_destination_id;
        dist_destination = :in_destination_maxdistance;
        tp_destination = :in_destination_type;
        if :dist_destination > 800000
        then
            dist_destination = 800000;
        end if;

        if length( :id_destination ) > 1  or length( :tp_destination ) > 0
        then
            if length( :id_destination ) > 1
            then
                sqlstring = :sqlstring || ' and DESTINATION_STORAGE_CODE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :id_destination ) || CHAR( 39 ) ||
                ' and ROUTE_DISTANCE <= ' || ESCAPE_SINGLE_QUOTES( :dist_destination );
                if length( :tp_destination ) > 0
                then
                    sqlstring = :sqlstring || ' and DESTINATION_STORAGE_TYPE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :tp_destination ) || CHAR( 39 );
                end if;
            elseif length( :tp_destination ) > 0
            then
                sqlstring = :sqlstring || ' and DESTINATION_STORAGE_TYPE = ' || CHAR( 39 ) || ESCAPE_SINGLE_QUOTES( :tp_destination ) || CHAR( 39 );
            end if;
        end if;

    end if;

    execute immediate :sqlstring into output_t;

    routes = select ORIGIN_ID originid, ORIGIN_STORAGE_TYPE origintype, DESTINATION_STORAGE_CODE destinationid, DESTINATION_STORAGE_TYPE destinationtype,
             ORIGIN_CLASS_CODE class, ROUTE_DISTANCE distanceroad, ROUTE_STRAIGHT distancestraight, ROUTE_TIME time
           from :output_t;

  ENDMETHOD.
ENDCLASS.