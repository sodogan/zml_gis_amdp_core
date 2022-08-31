"! <p class="shorttext synchronized" lang="en">LocationLookup</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MFORIS/MG0410</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id411/source/main#start=86,2;end=91,0 </p>
CLASS zcl_gis_amdp_id410 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS location_lookup
      IMPORTING
                VALUE(in_logys)  TYPE ZPRLOGY_TYPETAB1
                VALUE(in_storages)  TYPE  zprstorage_typetab
                VALUE(in_road_storages)  TYPE  zprroad_storage_typetab
      EXPORTING
                VALUE(out_logys)  TYPE ZPRLOGY_TYPETAB1
                VALUE(out_storages)  TYPE  zprstorage_typetab
                VALUE(out_road_storages)  TYPE  zprroad_storage_typetab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id410 IMPLEMENTATION.

  METHOD location_lookup BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* all KKJ transformations changed to EUREF as KKJ is not supported by DB.
* uncomment KKJ comments to reenable
* local variables

--KKJ    declare SRS_KKJ int = 2393;
    declare SRS_EUREF int = 3067;
--KKJ    declare NAME_KKJ nvarchar( 10 ) = 'KKJ';
    declare NAME_EUREF nvarchar( 10 ) = 'EUREF';
    declare LOGY_ID_BY_POSITION int = 1;
    declare METLA_ID_BY_POSITION int = 2;
    declare PIIRI_ID_BY_POSITION int = 3;
    declare i int;

    -- Search logistic units
    for i in 1..record_count( :in_logys)
    do
        declare in_logyid bigint = TO_BIGINT( :in_logys.logy_id[:i] );
        declare in_class bigint =  TO_BIGINT( :in_logys.class[:i] );
        declare in_cs nvarchar( 10 ) =  :in_logys.coordinate_system[:i];
        declare out_cs nvarchar( 10 );
        declare x bigint;
        declare y bigint;

--KKJ        if :in_cs = :NAME_EUREF
--KKJ        then
            out_cs = :SRS_EUREF;
--KKJ        else
--KKJ            out_cs = :SRS_KKJ;
--KKJ        end if;

        select round(a.geoloc.ST_Transform( :out_cs ).ST_X()) ,round(a.geoloc.ST_Transform( :out_cs ).ST_Y()) into x , y default null, null
        from GISDATA.route_class_of_logy a, GISDATA.route_logy b where a.logy_id=b.id and b.logy_code=:in_logyid and a.class_id=:in_class and a.geoloc is not null;

        :out_logys.INSERT(( :in_logyid, :in_class, :out_cs, :x || CHAR(32) || :y ));

    end for;

    -- Search storage locations: ROUTE_STORAGE
    for i in 1..record_count( :in_storages )
    do
        declare in_storeid nvarchar( 20 ) = :in_storages.storage_id[:i];
        declare in_type nvarchar( 20 ) =  :in_storages.storage_type[:i];
        declare in_cs nvarchar( 10 ) =  :in_storages.coordinate_system[:i];
        declare out_cs nvarchar( 10 );
        declare x bigint;
        declare y bigint;
        declare in_store_logyid nvarchar( 20 );
        declare in_store_metlaid nvarchar( 20 );
        declare in_store_piiriid nvarchar( 20 );

--KKJ        if :in_cs = :NAME_EUREF
--KKJ        then
            out_cs = :SRS_EUREF;
--KKJ        else
--KKJ            out_cs = :SRS_KKJ;
--KKJ        end if;

        select round(geoloc.ST_Transform( :out_cs ).ST_X()) ,round(geoloc.ST_Transform( :out_cs ).ST_Y()) into x, y default null, null
        from GISDATA.ROUTE_STORAGE where storage_type=:in_type and storage_code=:in_storeid and geoloc is not null;

        if :x is not null and :y is not null
        then
            select LOGY_CODE into in_store_logyid default null from GISDATA.ROUTE_LOGY where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
            select ALUE_ID into in_store_metlaid default null from GISDATA.KUORMAINVAAKA_ALUEET where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
            select DISTRICT_ID into in_store_piiriid default null from MG_SPATIAL.V_GIS_DISTRICT where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
         end if;

        :out_storages.INSERT( ( :in_storeid, :in_type, :out_cs, :x || CHAR(32) || :y, :in_store_logyid, :in_store_metlaid, :in_store_piiriid ) );

    end for;

    for i in 1..record_count( :in_road_storages )
    do
        declare in_contract nvarchar( 20 ) = :in_road_storages.contract[:i];
        declare in_storage_number bigint = :in_road_storages.storage_number[:i];
        declare in_decade bigint = :in_road_storages.decade[:i];
        declare in_cs nvarchar( 20 ) = :in_road_storages.coordinate_system[:i];
        declare out_cs nvarchar( 10 );
        declare in_road_logyid nvarchar( 20 );
        declare in_road_metlaid nvarchar( 20 );
        declare in_road_piiriid nvarchar( 20 );
        declare x bigint;
        declare y bigint;
        declare alkux bigint;
        declare alkuy bigint;
        declare loppux bigint;
        declare loppuy bigint;
        declare coords nvarchar( 60 );
        declare coordsalkupiste nvarchar( 20 );
        declare coordsloppupiste nvarchar( 20 );

--KKJ        if :in_cs = :NAME_EUREF
--KKJ        then
            out_cs = :SRS_EUREF;
--KKJ        else
--KKJ            out_cs = :SRS_KKJ;
--KKJ        end if;

        select
--KKJ               round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_X()) as x,
--KKJ               round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_Y()) as y,
--KKJ               (select round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_X())
              round(geoloc.ST_Centroid().ST_X()) as x,
              round(geoloc.ST_Centroid().ST_Y()) as y,
              (select round(geoloc.ST_Centroid().ST_X())
              from GISDATA.gis_point where
              featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid and id = (select min(id)
              from GISDATA.gis_point where featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid )) as alkux,
--KKJ              (select round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_Y())
              (select round(geoloc.ST_Centroid().ST_Y())
              from GISDATA.gis_point where
              featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid and id = (select min(id)
              from GISDATA.gis_point where featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid )) as alkuy,
--KKJ              (select round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_X())
              (select round(geoloc.ST_Centroid().ST_X())
              from GISDATA.gis_point where
              featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid and id = (select max(id)
              from GISDATA.gis_point where featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid )) as loppux,
--KKJ              (select round(geoloc.ST_Centroid().ST_Transform( 2393 ).ST_Y())
              (select round(geoloc.ST_Centroid().ST_Y())
              from GISDATA.gis_point where
              featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid and id = (select max(id)
              from GISDATA.gis_point where featurecode='10033' and featureinfo = 'VP ' || :in_storage_number and contractid=a.contractid )) as loppuy
              into x, y, alkux, alkuy, loppux, loppuy  default null, null, null, null, null, null from
              MG_KOTKA.STORAGE a where CONTRACTID = TO_BIGINT( :in_contract || :in_decade ) and storage_number=:in_storage_number;

        if :x is not null and :y is not null
        then
            select LOGY_CODE into in_road_logyid default null from GISDATA.ROUTE_LOGY where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
            select ALUE_ID into in_road_metlaid default null from GISDATA.KUORMAINVAAKA_ALUEET where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
            select DISTRICT_ID into in_road_piiriid default null from MG_SPATIAL.V_GIS_DISTRICT where geoloc.ST_Contains( new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :out_cs ) ) = 1;
         end if;

        if :x is not null and :y is not null
        then
            select
*-KKJ            TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_X()))
*-KKJ            || CHAR(32) ||
*-KKJ            TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_Y()))
*-KKJ            into coords from dummy;
            TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :SRS_EUREF ).ST_X()))
            || CHAR(32) ||
            TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:x) || CHAR(32) || TO_NVARCHAR(:y) || ')', :SRS_EUREF ).ST_Y()))
            into coords default null from dummy;

            if :alkux > 0
            then
                select
*-KKJ                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:alkux) || CHAR(32) || TO_NVARCHAR(:alkuy) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_X()))
*-KKJ                || CHAR(32) ||
*-KKJ                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:alkux) || CHAR(32) || TO_NVARCHAR(:alkuy) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_Y()))
                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:alkux) || CHAR(32) || TO_NVARCHAR(:alkuy) || ')', :SRS_EUREF ).ST_Transform( :out_cs ).ST_X()))
                || CHAR(32) ||
                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:alkux) || CHAR(32) || TO_NVARCHAR(:alkuy) || ')', :SRS_EUREF ).ST_Transform( :out_cs ).ST_Y()))
                into coordsalkupiste default null from dummy;
                select
*-KKJ                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:loppux) || CHAR(32) || TO_NVARCHAR(:loppuy) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_X()))
*-KKJ                || CHAR(32) ||
*-KKJ                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:loppux) || CHAR(32) || TO_NVARCHAR(:loppuy) || ')', :SRS_KKJ ).ST_Transform( :out_cs ).ST_Y()))
                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:loppux) || CHAR(32) || TO_NVARCHAR(:loppuy) || ')', :SRS_EUREF ).ST_X()))
                || CHAR(32) ||
                TO_NVARCHAR(round(new ST_Point( 'Point (' || TO_NVARCHAR(:loppux) || CHAR(32) || TO_NVARCHAR(:loppuy) || ')', :SRS_EUREF ).ST_Y()))
                into coordsloppupiste default null from dummy;

                if :coordsloppupiste != :coordsalkupiste
                then
                    coords=:coords || ',' || :coordsalkupiste || ',' || :coordsloppupiste;
                else
                    coords=:coords || ',' || :coordsalkupiste || ',' || :coords;
                end if;
            end if;
        end if;

        :out_road_storages.INSERT( ( :in_contract, :in_storage_number, :in_decade, :in_cs, :coords, :in_road_logyid, :in_road_metlaid, :in_road_piiriid ) );

    end for;



  ENDMETHOD.

ENDCLASS.