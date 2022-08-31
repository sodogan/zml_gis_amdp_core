"! <p class="shorttext synchronized" lang="en">MapSymbolsSend</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zprco_si_id408_map_symbols_sen/source/main#start=15,0;end=19,48  </p>
CLASS zcl_gis_amdp_id408 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS MAP_SYMBOLS_SEND
      IMPORTING
                VALUE(contract_code) TYPE  string
                VALUE(storage_code)  TYPE  string
                VALUE(decade)        TYPE  int4
                VALUE(in_coordinate_system)  TYPE  string
      EXPORTING
                VALUE(map_symbols)  TYPE ZPRMAPSYMBOL_TYPE_TAB
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id408 IMPLEMENTATION.

  METHOD MAP_SYMBOLS_SEND BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare contract_id_decade bigint = TO_BIGINT( :contract_code || :decade );
    declare varasto nvarchar( 50 );
    declare varastonumero bigint;
    declare SRS_EUREF int = 3067;
    declare SRS_KKJ int = 2393;
    declare srid int = SRS_KKJ;
    declare STATUS_OK nvarchar( 10 ) = '2';
    declare mapsymbolresp_t table(
        symbolid nvarchar( 50 ),
        symbol nvarchar( 50 ),
        info nvarchar( 100 ),
        status nvarchar( 50 ),
        coordinates nvarchar( 10000 ),
        coordinatesystem  nvarchar( 10 )
    );

    mapsymbolresp = select * from :mapsymbolresp_t limit 0;

    if length( :storage_code ) > 0
    then
        varasto = :contract_code || :storage_code;
        varastonumero = TO_BIGINT( :storage_code );
    else
        varastonumero = 0;
    end if;

    if :in_coordinate_system = 'EUREF'
    then
        srid = :SRS_EUREF;
    end if;

   --getPointGeometries 0
    if length ( :contract_code ) > 0
    then
        tmp = select TO_NVARCHAR(round(t.geoloc.ST_X( ) )) || CHAR(32) || TO_NVARCHAR(round(t.geoloc.ST_Y(  ) )) as koordstring, t.seliteteksti, lpad(t.id,10,CHAR(48)) as ID, '18' as KOODI FROM
            (select geoloc.ST_Centroid( ).ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id FROM
            gisdata.gis_point a WHERE contractid = :contract_id_decade AND (featurecode in('10015','10058') OR (featurecode='10033' and featureinfo not like 'VP%')) ) t;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    end if;

    if length( :varasto ) > 0 and length ( :contract_code ) > 0
    then
    --getLineGeometries
        tmp = select
            gisdata.getlineasstring(t.geoloc, CHAR(32)) koordstring, t.seliteteksti, lpad(t.id,10,CHAR(48)) as ID, map(t.featurecode,'10031','03','10005','05','10007','03','10017','07','10008','16','10006','17','00') as KOODI FROM
            (select geoloc.ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode from
            gisdata.gis_line a WHERE ((a.contractid = :contract_id_decade ) or ((
            (a.contractid is null) and a.geoloc.ST_WithinDistance((SELECT ST_UnionAggr( geoloc ) FROM mg_kotka.storage WHERE contractid = :contract_id_decade and storage_number = :varastonumero), 500) = 1)))
            AND featurecode in ('10005', '10007', '10017', '10008', '10006', '10031')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getSahkojohtoGeometries
        tmp = select
            gisdata.getlineasstring(geoloc, CHAR(32)) koordstring, seliteteksti, lpad(id,10,CHAR(48)) as ID, '05' as KOODI FROM
            (select geoloc.ST_Transform( :srid ) as geoloc, 'Johto (' || DESCRIPTION || ')' as seliteteksti, id from
            GISDATA.GIS_POWERLINE_GENERALIZED a where
            TYPE_OF_LINE_PART = 'ilma' and a.geoloc.ST_WithinDistance((SELECT ST_UnionAggr( b.geoloc ) FROM mg_kotka.storage b WHERE contractid = :contract_id_decade and storage_number = :varastonumero), 200) = 1)
            order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getPointGeometries 1000
        tmp = select
            TO_NVARCHAR(round(t.geoloc.ST_X( ) )) || CHAR(32) || TO_NVARCHAR(round(t.geoloc.ST_Y(  ) )) as koordstring, t.seliteteksti, lpad(t.id,10,CHAR(48)) as ID, map(t.featurecode,'10035','06','10034','11','10029','04','00') as KOODI
            FROM (select geoloc.ST_Centroid( ).ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode FROM
            gisdata.gis_point a WHERE ((contractid = :contract_id_decade ) or ((
            (contractid is null) and geoloc.ST_WithinDistance((SELECT ST_UnionAggr( geoloc ) FROM mg_kotka.storage WHERE contractid = :contract_id_decade and storage_number = :varastonumero), 1000) = 1)))
            AND featurecode in ('10035', '10034', '10029')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getPointGeometries 5000
        tmp = select
                TO_NVARCHAR(round(t.geoloc.ST_X( ) )) || CHAR(32) || TO_NVARCHAR(round(t.geoloc.ST_Y(  ) )) as koordstring, t.seliteteksti, lpad(t.id,10,'0') as ID, map(t.featurecode,'10030','15','10036','14','00') as KOODI FROM
                (select geoloc.ST_Centroid( ).ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode FROM
                gisdata.gis_point a
                WHERE ((contractid = :contract_id_decade) or ((
                (contractid is null) and geoloc.ST_WithinDistance((SELECT ST_UnionAggr( geoloc ) FROM mg_kotka.storage WHERE contractid=:contract_id_decade and storage_number=:varastonumero), 5000) = 1)))
                AND featurecode in ('10030', '10036')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    elseif length ( :contract_code ) > 0
    then
    --getLineGeometries
        tmp = select
            gisdata.getlineasstring(t.geoloc, CHAR(32)) koordstring, t.seliteteksti, lpad(t.id,10,CHAR(48)) as ID, map(t.featurecode,'10031','03','10005','05','10007','03','10017','07','10008','16','10006','17','00') as KOODI FROM
            (select geoloc.ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode from
            gisdata.gis_line a WHERE ((a.contractid = :contract_id_decade ) or ((
            (a.contractid is null) and a.geoloc.ST_WithinDistance((SELECT ST_UnionAggr( geoloc ) FROM mg_kotka.storage WHERE contractid=:contract_id_decade), 500) = 1)))
            AND featurecode in ('10005', '10007', '10017', '10008', '10006', '10031')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getSahkojohtoGeometries
        tmp = select
            gisdata.getlineasstring(geoloc, CHAR(32)) koordstring, seliteteksti, lpad(id,10,CHAR(48)) as ID, '05' as KOODI FROM
            (select geoloc.ST_Transform( :srid ) as geoloc, 'Johto (' || DESCRIPTION || ')' as seliteteksti, id from
            GISDATA.GIS_POWERLINE_GENERALIZED a where
            TYPE_OF_LINE_PART = 'ilma' and a.geoloc.ST_WithinDistance((SELECT ST_UnionAggr( b.geoloc ) FROM mg_kotka.storage b WHERE contractid=:contract_id_decade), 200) = 1)
            order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getPointGeometries 1000
        tmp = select
             TO_NVARCHAR(round(t.geoloc.ST_X( ) )) || CHAR(32) || TO_NVARCHAR(round(t.geoloc.ST_Y(  ) )) as koordstring, t.seliteteksti, lpad(t.id,10,'0') as ID, map(t.featurecode,'10035','06','10034','11','10029','04','00') as KOODI
             FROM (select geoloc.ST_Centroid( ).ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode FROM
             gisdata.gis_point a WHERE ((contractid = :contract_id_decade ) or ((
             (contractid is null) and geoloc.ST_WithinDistance((SELECT ST_UnionAggr(geoloc) FROM mg_kotka.storage WHERE contractid=:contract_id_decade), 1000) = 1)))
             AND featurecode in ('10035', '10034', '10029')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    --getPointGeometries 5000
        tmp = select
            TO_NVARCHAR(round(t.geoloc.ST_X( ) )) || CHAR(32) || TO_NVARCHAR(round(t.geoloc.ST_Y(  ) )) as koordstring, t.seliteteksti, lpad(t.id,10,'0') as ID, map(t.featurecode,'10030','15','10036','14','00') as KOODI FROM
            (select geoloc.ST_Centroid( ).ST_Transform( :srid ) as geoloc, substr(featureinfo,1,254) as seliteteksti, id, featurecode FROM
            gisdata.gis_point a
            WHERE ((contractid = :contract_id_decade ) or ((
            (contractid is null) and geoloc.ST_WithinDistance((SELECT ST_UnionAggr(geoloc) FROM mg_kotka.storage WHERE contractid=:contract_id_decade), 5000)= 1 )))
            AND featurecode in ('10030', '10036')) t order by KOODI;

        mapsymbolresp = select * from :mapsymbolresp union
                        select ID symbolid, KOODI symbol, SELITETEKSTI info, :STATUS_OK status, replace(koordstring, CHAR(32) || CHAR(48), CHAR(32) ) coordinates,:in_coordinate_system coordinatesystem from :tmp;

    end if;

*Build the output
  map_symbols = select symbolid as symbol_id,
                       symbol,
                       info,
                       status,
                       coordinates,
                       coordinatesystem as coordinate_system
                        from  :mapsymbolresp;


  ENDMETHOD.

ENDCLASS.