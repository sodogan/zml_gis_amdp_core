"! <p class="shorttext synchronized" lang="en">GetWorkingSiteMapSymbol</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteMapSymbol</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/zpi1_id1183_requestsend/source/main#start=91,0;end=107,15</p>
CLASS zcl_gis_amdp_id813 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS GetWorkingSiteMapSymbol
      IMPORTING
                VALUE(contractid)  TYPE zmhobject
                VALUE(blocknumber) TYPE zmhblockno
                VALUE(decade)      TYPE zzostosopvk
* MFORT-18318: enable searching map symbols from other contracts, enable change of power line search buffer
                VALUE(powerLineSearchBufferInMeters)   TYPE int4 DEFAULT 150
                VALUE(searchMapSymFromOtherContracts)  TYPE char10 DEFAULT 'true'
      EXPORTING
                VALUE(response)           TYPE ziidt_id813_ms_gis_get_re_tab
                VALUE(spare_trees)        TYPE ziidt_id813_ms_gis_get_r_tab1
      RAISING   cx_amdp_error
      .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id813 IMPLEMENTATION.





  METHOD getworkingsitemapsymbol BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoshape_to_xml
                           .
-- TODO geometry string size set to 10000, what is real max length?
    --Local data declarations
    declare lv_index integer;
    declare contract_with_decade string;
    declare is_contract int;
    declare THINNING_HARVESTING_METHOD nvarchar( 10 ) := '1,2';
    declare SILVICULTURAL_WORK_TYPE_GROUP nvarchar( 10 ) := '5,7';
    declare harvesting INT := 1;
    declare worktype INT := 1;
    declare harvesting_method nvarchar( 10 );
    declare worktype_group nvarchar( 10 );
    declare sparetrees_t TABLE (
    mapsymbolid nvarchar( 100 ),
    category nvarchar ( 30 ),
    amount bigint
    );
    declare output_t TABLE (
        contractid bigint,
        blocknumber nvarchar( 100 ),
        mapsymbolid nvarchar( 100 ),
        wfinsertedmapsymbolid nvarchar( 100 ),
        featurecode nvarchar( 100 ),
        featureadditionalcode nvarchar( 100 ),
        featureinfo nvarchar( 100 ),
        geometry nvarchar( 10000 ),
        canmodify nvarchar( 100 ),
        variantname nvarchar( 100 ),
        resourceid nvarchar( 100 ),
        mapsymbolname nvarchar( 100 ),
        ditchtype nvarchar( 100 ),
        length nvarchar( 100 ),
        depth nvarchar( 100 ),
        width nvarchar( 100 ),
        volume nvarchar( 100 ),
        materialcode nvarchar( 100 ),
        materialinfotext nvarchar( 100 ),
        dorplanname nvarchar( 100 ),
        updatedtime nvarchar( 100 ),
        amountoflivingtrees nvarchar( 100 ),
        amountofrottensnags nvarchar( 100 ),
        amountofrottentrees nvarchar( 100 ),
        amountofmapsymbols nvarchar( 100 )
       ,geometry_orig st_geometry
    );


    declare uniquemapsymbolids TABLE ( mapsymbolid nvarchar ( 100 ) );

    --Steps to follow
    --Check whether the decade is supplied
    --CONTRACTID=request.CONTRACTID+request.DECADE
     contract_with_decade = CONCAT(:contractid,:decade);
     if LENGTH (:decade) > 0/*check the length of the decade*/
      then
         is_contract = 1;
     else
         is_contract = 0;
     end if ;


* get Geometries

    line_geometries  = SELECT
                    t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC,
                    to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid, wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    GISDATA.V_GIS_LINE_STANDARD a
                    WHERE
                    ((contractid = :contract_with_decade or silviculturalorderid = :contractid) or (
                    ((contractid is null and silviculturalorderid is null) or WF_MAPSYMBOLID is not null or (to_number(featurecode)<10000 or featurecode='11001')) and
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                     union all
                     SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )), 1000) = 1))
                    ) t order by KOODI;

* add line geometries to output
     output_t = select :contractid contractid,
               :blocknumber blocknumber,
               :line_geometries.ID mapsymbolid,
               :line_geometries.wf_mapsymbolid wfinsertedmapsymbolid,
               :line_geometries.KOODI featurecode,
               :line_geometries.LISAMAARE featureadditionalcode,
               coalesce( :line_geometries.SELITETEKSTI, '') featureinfo,
               null geometry,
               'K' canmodify,
               null variantname,
               :line_geometries.resourceid,
               :line_geometries.mapsymbolname,
               :line_geometries.ditchtype,
               TO_VARCHAR( :line_geometries.length ) length,
               TO_VARCHAR( :line_geometries.depth ) depth,
               TO_VARCHAR( :line_geometries.width ) width,
               TO_VARCHAR( :line_geometries.volume ) volume,
               :line_geometries.materialcode ,
               :line_geometries.materialinfotext,
               :line_geometries.ditchorroadplanname dorplanname,
               :line_geometries.updated_on updatedtime,
               TO_VARCHAR( :line_geometries.amountoflivingtrees ) amountoflivingtrees,
               TO_VARCHAR( :line_geometries.amountofrottensnags ) amountofrottensnags,
               TO_VARCHAR( :line_geometries.amountofrottentrees ) amountofrottentrees,
               '0' amountofmapsymbols,
               geoloc geometry_orig
               from :line_geometries;

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;


    if :searchMapSymFromOtherContracts = 'true'
    then
* Line Geometries From Other Contracts

    line_geometries_other  = SELECT
                    t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC,
                    to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid, wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    GISDATA.V_GIS_LINE_STANDARD a
                    WHERE
                    (((contractid != :contract_with_decade and contractid is not null) or (silviculturalorderid != :contractid and silviculturalorderid is not null)) and (
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                     union all
                     SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )), 1) = 1))
                    ) t order by KOODI;

* add line geometries to output
     output_t = select * from :output_t union select :contractid contractid, :blocknumber blocknumber, :line_geometries_other.ID mapsymbolid, :line_geometries_other.wf_mapsymbolid wfinsertedmapsymbolid,
               :line_geometries_other.KOODI featurecode, :line_geometries_other.LISAMAARE featureadditionalcode, coalesce( :line_geometries_other.SELITETEKSTI, '') featureinfo, null geometry, 'K' canmodify, null variantname,
               :line_geometries_other.resourceid, :line_geometries_other.mapsymbolname, :line_geometries_other.ditchtype, TO_VARCHAR( :line_geometries_other.length ) length, TO_VARCHAR( :line_geometries_other.depth ) depth,
               TO_VARCHAR( :line_geometries_other.width ) width, TO_VARCHAR( :line_geometries_other.volume ) volume, :line_geometries_other.materialcode , :line_geometries_other.materialinfotext,
               :line_geometries_other.ditchorroadplanname dorplanname, :line_geometries_other.updated_on updatedtime, TO_VARCHAR( :line_geometries_other.amountoflivingtrees ) amountoflivingtrees,
               TO_VARCHAR( :line_geometries_other.amountofrottensnags ) amountofrottensnags, TO_VARCHAR( :line_geometries_other.amountofrottentrees ) amountofrottentrees, '0' amountofmapsymbols,
               geoloc geometry_orig from :line_geometries_other where :line_geometries_other.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
     uniquemapsymbolids = select distinct * from :uniquemapsymbolids union select distinct :output_t.mapsymbolid from :output_t;

    end if;

    point_geom_0 = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC,
                   to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid, wf_mapsymbolid,
                   MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                   (select geoloc.st_centroid( ) as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                   gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                   MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                   GISDATA.V_GIS_POINT_STANDARD a
                   WHERE
                   (contractid = :contract_with_decade or silviculturalorderid = :contractid)
                   AND featurecode in ('10015')) t order by KOODI;

* add point geometries distance 0 to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :point_geom_0.ID, :point_geom_0.wf_mapsymbolid, :point_geom_0.KOODI, :point_geom_0.LISAMAARE, coalesce( :point_geom_0.SELITETEKSTI, ''),
       null, 'K', null, :point_geom_0.resourceid, :point_geom_0.mapsymbolname, :point_geom_0.ditchtype, TO_VARCHAR( :point_geom_0.length ),
       TO_VARCHAR( :point_geom_0.depth ), TO_VARCHAR( :point_geom_0.width ), TO_VARCHAR( :point_geom_0.volume ), :point_geom_0.materialcode , :point_geom_0.materialinfotext,
       :point_geom_0.ditchorroadplanname, :point_geom_0.updated_on, TO_VARCHAR( :point_geom_0.amountoflivingtrees ), TO_VARCHAR( :point_geom_0.amountofrottensnags ),
       TO_VARCHAR( :point_geom_0.amountofrottentrees ), '0', geoloc geometry_orig from :point_geom_0 where :point_geom_0.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct * from :uniquemapsymbolids union select distinct :output_t.mapsymbolid from :output_t;

    point_geom_1000 = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    (select geoloc.st_centroid( ) as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT,
                    DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    GISDATA.V_GIS_POINT_STANDARD a
                    WHERE
                    ((contractid = :contract_with_decade or silviculturalorderid = :contractid) or (
                    ((contractid is null and silviculturalorderid is null) or WF_MAPSYMBOLID is not null or (to_number(featurecode)<10000 or featurecode='11001')) and
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )), 1000) = 1))
                    AND (featurecode is not null and featurecode not in ('10030','10036'))) t order by KOODI;

* add point geometries distance 1000 to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :point_geom_1000.ID, :point_geom_1000.wf_mapsymbolid, :point_geom_1000.KOODI, :point_geom_1000.LISAMAARE, coalesce( :point_geom_1000.SELITETEKSTI, ''),
       null, 'K', null, :point_geom_1000.resourceid, :point_geom_1000.mapsymbolname, :point_geom_1000.ditchtype, TO_VARCHAR( :point_geom_1000.length ),
       TO_VARCHAR( :point_geom_1000.depth ), TO_VARCHAR( :point_geom_1000.width ), TO_VARCHAR( :point_geom_1000.volume ), :point_geom_1000.materialcode , :point_geom_1000.materialinfotext,
       :point_geom_1000.ditchorroadplanname, :point_geom_1000.updated_on, TO_VARCHAR( :point_geom_1000.amountoflivingtrees ), TO_VARCHAR( :point_geom_1000.amountofrottensnags ),
       TO_VARCHAR( :point_geom_1000.amountofrottentrees ), '0', geoloc geometry_orig from :point_geom_1000 where :point_geom_1000.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    point_geom_5000 = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    (select geoloc.st_centroid( ) as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT,
                    DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    GISDATA.V_GIS_POINT_STANDARD a
                    WHERE
                    ((contractid = :contract_with_decade or silviculturalorderid = :contractid) or (
                    ((contractid is null and silviculturalorderid is null) or WF_MAPSYMBOLID is not null) and
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )
                    ), 5000) = 1))
                    AND featurecode in ('10030','10036')) t order by KOODI;

* add point geometries distance 5000 to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :point_geom_5000.ID, :point_geom_5000.wf_mapsymbolid, :point_geom_5000.KOODI, :point_geom_5000.LISAMAARE, coalesce( :point_geom_5000.SELITETEKSTI, ''),
       null, 'K', null, :point_geom_5000.resourceid, :point_geom_5000.mapsymbolname, :point_geom_5000.ditchtype, TO_VARCHAR( :point_geom_5000.length ),
       TO_VARCHAR( :point_geom_5000.depth ), TO_VARCHAR( :point_geom_5000.width ), TO_VARCHAR( :point_geom_5000.volume ), :point_geom_5000.materialcode , :point_geom_5000.materialinfotext,
       :point_geom_5000.ditchorroadplanname, :point_geom_5000.updated_on, TO_VARCHAR( :point_geom_5000.amountoflivingtrees ), TO_VARCHAR( :point_geom_5000.amountofrottensnags ),
       TO_VARCHAR( :point_geom_5000.amountofrottentrees ), '0', geoloc geometry_orig from :point_geom_5000 where :point_geom_5000.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

* Point Geometries From Other Contracts
    if :searchMapSymFromOtherContracts = 'true'
    then

        point_geom_other = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                        resourceid, wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                        FROM
                        (select geoloc.st_centroid( ) as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                        gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT,
                        DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                        FROM
                        GISDATA.V_GIS_POINT_STANDARD a
                        WHERE
                        (((contractid != :contract_with_decade and contractid is not null) or (silviculturalorderid != :contractid and silviculturalorderid is not null)) and (
                        geoloc.ST_WithinDistance(
                        (SELECT ST_UNIONAGGR(geoloc) from
                        (
                        SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                        union all
                        SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                        )
                        ), 1) = 1))
                        ) t order by KOODI;

* add point geometries distance 5000 to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :point_geom_other.ID, :point_geom_other.wf_mapsymbolid, :point_geom_other.KOODI, :point_geom_other.LISAMAARE, coalesce( :point_geom_other.SELITETEKSTI, ''),
       null, 'K', null, :point_geom_other.resourceid, :point_geom_other.mapsymbolname, :point_geom_other.ditchtype, TO_VARCHAR( :point_geom_other.length ),
       TO_VARCHAR( :point_geom_other.depth ), TO_VARCHAR( :point_geom_other.width ), TO_VARCHAR( :point_geom_other.volume ), :point_geom_other.materialcode , :point_geom_other.materialinfotext,
       :point_geom_other.ditchorroadplanname, :point_geom_other.updated_on, TO_VARCHAR( :point_geom_other.amountoflivingtrees ), TO_VARCHAR( :point_geom_other.amountofrottensnags ),
       TO_VARCHAR( :point_geom_other.amountofrottentrees ), '0', geoloc geometry_orig from :point_geom_other where :point_geom_other.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    end if;

    polygon_geom = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                    FROM
                    GISDATA.V_GIS_POLYGON_STANDARD a
                    WHERE
                    ((contractid = :contract_with_decade or silviculturalorderid = :contractid) or (
                    ((contractid is null and silviculturalorderid is null) or WF_MAPSYMBOLID is not null or (to_number(featurecode)<10000 or featurecode='11001')) and
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )
                    ), 1000) = 1))
                    ) t order by KOODI;

* add polygon geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :polygon_geom.ID, :polygon_geom.wf_mapsymbolid, :polygon_geom.KOODI, :polygon_geom.LISAMAARE, coalesce( :polygon_geom.SELITETEKSTI, ''),
       null, 'K', null, :polygon_geom.resourceid, :polygon_geom.mapsymbolname, :polygon_geom.ditchtype, TO_VARCHAR( :polygon_geom.length ),
       TO_VARCHAR( :polygon_geom.depth ), TO_VARCHAR( :polygon_geom.width ), TO_VARCHAR( :polygon_geom.volume ), :polygon_geom.materialcode , :polygon_geom.materialinfotext,
       :polygon_geom.ditchorroadplanname, :polygon_geom.updated_on, TO_VARCHAR( :polygon_geom.amountoflivingtrees ), TO_VARCHAR( :polygon_geom.amountofrottensnags ),
       TO_VARCHAR( :polygon_geom.amountofrottentrees ), '0', geoloc geometry_orig from :polygon_geom where :polygon_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

* Polygon Geometries From Other Contracts
    if :searchMapSymFromOtherContracts = 'true'
    then

        polygon_geom_other = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                        resourceid, wf_mapsymbolid, MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                        FROM
                        (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                        gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                        MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES
                        FROM
                        GISDATA.V_GIS_POLYGON_STANDARD a
                        WHERE
                        (((contractid != :contract_with_decade and contractid is not null) or (silviculturalorderid != :contractid and silviculturalorderid is not null)) and (
                        geoloc.ST_WithinDistance(
                        (SELECT ST_UNIONAGGR(geoloc) from
                        (
                        SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                        union all
                        SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                        )
                        ), 1) = 1))
                        ) t order by KOODI;

*     add polygon geometries to output
           output_t = select * from :output_t union select :contractid, :blocknumber, :polygon_geom_other.ID, :polygon_geom_other.wf_mapsymbolid, :polygon_geom_other.KOODI, :polygon_geom_other.LISAMAARE,
           coalesce( :polygon_geom_other.SELITETEKSTI, ''), null, 'K', null, :polygon_geom_other.resourceid, :polygon_geom_other.mapsymbolname, :polygon_geom_other.ditchtype, TO_VARCHAR( :polygon_geom_other.length ),
           TO_VARCHAR( :polygon_geom_other.depth ), TO_VARCHAR( :polygon_geom_other.width ), TO_VARCHAR( :polygon_geom_other.volume ), :polygon_geom_other.materialcode , :polygon_geom_other.materialinfotext,
           :polygon_geom_other.ditchorroadplanname, :polygon_geom_other.updated_on, TO_VARCHAR( :polygon_geom_other.amountoflivingtrees ), TO_VARCHAR( :polygon_geom_other.amountofrottensnags ),
           TO_VARCHAR( :polygon_geom_other.amountofrottentrees ), '0', geoloc geometry_orig from :polygon_geom_other where :polygon_geom_other.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

*     update unique map symbols
        uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    end if;

    forest_geom = SELECT 'Kuvio: ' || t.stand_number || ', Kehitysluokka: ' ||
                    map(t.development_class,'Y1','Ylispuutaimikko','ER','Eri-ikaisrakenteinen metsikko','04','Uudistuskypsa metsikko','05','Suojuspuumetsikko','S0','Siemenpuumetsikko','T1','Taimikko alle 1.3 m','02',
                    'Nuori kasvatusmetsikko','03','Varttunut kasv.metsikko','T2','Taimikko yli 1.3 m','A0','Aukko',t.development_class) ||
                    (select ', Ika: ' || mean_age from MVK.TREE_STAND_DATA where stand_id = t.stand_id and alternative_id=1 and data_type=(select max(data_type) from MVK.TREE_STAND_DATA
                    where stand_id = t.stand_id and alternative_id=1 and data_type < 3)) as seliteteksti,
                    lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid
                    FROM
                    (select a.geoloc, b.stand_number, b.development_class, 9000000000 + a.stand_geometry_id as id, '10072' as featurecode, coalesce(a.updated_on,a.created_on) as updated_on, null as resourceid, b.stand_id
                    FROM
                    MVK.FOREST_PLAN c, MVK.STAND b, MVK.STAND_GEOMETRY a
                    WHERE c.status=1 and c.forest_plan_id = b.forest_plan_id and b.stand_id = a.stand_id and
                    ((
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT MG_KOTKA.getHBlockSearchPolygon(harvestingblockid) as geoloc from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber
                    union all
                    SELECT MG_KOTKA.getSWBlockSearchPolygon(sw_planningblockid) as geoloc from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber
                    )
                    ), 10) = 1))
                    ) t order by KOODI;

* add forest plan geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :forest_geom.ID, null, :forest_geom.KOODI, '', coalesce( :forest_geom.SELITETEKSTI, ''),
       null, 'E', null, :forest_geom.resourceid, null, null, null,
       null, null, null, null, null, null, :forest_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :forest_geom where :forest_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    power_geom = SELECT
                    seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid FROM
                    (select geoloc, description as seliteteksti, 8000000000 + id as id, '10005' as featurecode, coalesce(updated_on,created_on) as updated_on, null as resourceid FROM
                    GISDATA.GIS_POWERLINE_WF
                    WHERE ((
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT MG_KOTKA.getHBlockSearchPolygon(harvestingblockid) as geoloc from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber
                    union all
                    SELECT MG_KOTKA.getSWBlockSearchPolygon(sw_planningblockid) as geoloc from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber
                    )
                    ), :powerLineSearchBufferInMeters) = 1))
                    ) t order by KOODI;

* add power lines geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :power_geom.ID, null, :power_geom.KOODI, '', coalesce( :power_geom.SELITETEKSTI, ''),
       null, 'E', null, :power_geom.resourceid, null, null, null,
       null, null, null, null, null, null, :power_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :power_geom where :power_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    estate_geom = SELECT LPAD(e.ID, 10, '0') AS ID, '10078' AS KOODI,
                e.REG_UNIT_ID || ' ' || e.REG_UNIT_NAME AS SELITETEKSTI,
                TO_CHAR(e.UPDATED_ON,'DD.MM.YYYY HH24:MI:SS') AS UPDATED_ON,
                e.GEOLOC AS GEOLOC
                FROM MG_SPATIAL.V_MML_KRK_A e WHERE
                e.GEOLOC.ST_WithinDistance(
                (SELECT ST_UNIONAGGR(MG_SPATIAL.SIMPLIFYGEOM(GEOLOC)) FROM
                (SELECT MG_KOTKA.GETHBLOCKSEARCHPOLYGON_KRK(HARVESTINGBLOCKID) AS GEOLOC FROM MG_KOTKA.HARVESTINGBLOCK WHERE CONTRACTID= :contract_with_decade AND BLOCKNUMBER= :blocknumber
                UNION ALL
                SELECT MG_KOTKA.GETSWBLOCKSEARCHPOLYGON_KRK(SW_PLANNINGBLOCKID) AS GEOLOC FROM MG_KOTKA.SW_PLANNINGBLOCK WHERE SILVICULTURALORDERID= :contractid AND BLOCKNUMBER= :blocknumber
                )), 10) = 1;

* add estate geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :estate_geom.ID, null, :estate_geom.KOODI, '', coalesce( :estate_geom.SELITETEKSTI, ''),
       null, 'E', null, null, null, null, null,
       null, null, null, null, null, null, :estate_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :estate_geom where :estate_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;


* Search for resource paths if we have a thinning or silvicultural block only
        SELECT STRING_AGG(HARVESTINGMETHOD) into harvesting_method default null FROM MG_KOTKA.HARVESTINGBLOCK WHERE CONTRACTID = :contract_with_decade AND BLOCKNUMBER = :blocknumber;
        SELECT STRING_AGG(WORKTYPEGROUP) into worktype_group default null FROM MG_KOTKA.SW_PLANNINGBLOCK WHERE SILVICULTURALORDERID = :contractid AND BLOCKNUMBER = :blocknumber;
        SELECT LOCATE(:THINNING_HARVESTING_METHOD, :harvesting_method) INTO harvesting default null FROM dummy;
        SELECT LOCATE(:SILVICULTURAL_WORK_TYPE_GROUP, :worktype_group) INTO worktype default null FROM dummy;
* Skip query if it's not a thinning or silvicultural block
        if harvesting = 0 and worktype = 0
        then
            resource_geom = SELECT
                        t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, replace(t.featurecode, '10052', '10061') as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC,
                        to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid, wf_mapsymbolid
                        FROM
                        (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(a.updated_on,a.created_on) as updated_on, resourceid,
                        gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid
                        FROM
                        GISDATA.RESOURCE_PATH a
                        WHERE
                        -- Vain hakkuukoneen reitit
                        a.featurecode = '10052' and
                        -- Saman korjuusopimuksen tai MH-tilauksen reittej
                        (a.CONTRACTID = :contract_with_decade or a.SILVICULTURALORDERID = :contractid) and
                        -- ... mutta ei saman lohkon reittej
                        not (a.BLOCKNUMBER = :blocknumber) and
                        -- Spatiaalisesti korjuulohkolla tai MH-lohkolla
                        geoloc.ST_WithinDistance(
                        (SELECT ST_UNIONAGGR(geoloc) from
                        (
                        SELECT MG_KOTKA.getHBlockSearchPolygon(harvestingblockid) as geoloc from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber
                        union all
                        SELECT MG_KOTKA.getSWBlockSearchPolygon(sw_planningblockid) as geoloc from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber
                        )
                        ), 10) = 1
                        ) t order by KOODI;

*         add resource geometries to output
               output_t = select * from :output_t union select :contractid, :blocknumber, :resource_geom.ID, :resource_geom.wf_mapsymbolid, :resource_geom.KOODI, '', coalesce( :resource_geom.SELITETEKSTI, ''),
               null, 'E', null, :resource_geom.resourceid, null, null, null,
               null, null, null, null, null, null, :resource_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :resource_geom where :resource_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

*         update unique map symbols
            uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;
        end if;

    outer_geom = SELECT
                t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, replace(t.featurecode, '10052', '10061') as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC,
                to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on, resourceid, wf_mapsymbolid
                FROM
                (select geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(a.updated_on,a.created_on) as updated_on, resourceid,
                gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid FROM
                GISDATA.RESOURCE_PATH a
                WHERE
                -- Vain hakkuukoneen reitit
                a.featurecode = '10052' and

                ((a.CONTRACTID != :contract_with_decade and a.SILVICULTURALORDERID is null) or (a.CONTRACTID is null and a.SILVICULTURALORDERID != contractid)) and
                -- mutta spatiaalisesti ko. korjuulohkolla tai MH-lohkolla kuitenkin
                geoloc.ST_WithinDistance(
                (SELECT ST_UNIONAGGR(geoloc) from
                (
                SELECT MG_KOTKA.getHBlockSearchPolygon(harvestingblockid) as geoloc from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber
                union all
                SELECT MG_KOTKA.getSWBlockSearchPolygon(sw_planningblockid) as geoloc from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber
                )
                ), 100) = 1
                ) t order by KOODI;

* add outer resource geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :outer_geom.ID, :outer_geom.wf_mapsymbolid, :outer_geom.KOODI, '', coalesce( :outer_geom.SELITETEKSTI, ''),
       null, 'E', null, :outer_geom.resourceid, null, null, null,
       null, null, null, null, null, null, :outer_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :outer_geom where :outer_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    ditch_point_geom = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    (select geoloc.st_centroid( ) as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    GISDATA.V_GIS_POINT_STANDARD a
                    WHERE
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber )
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber )
                    )
                    ), 1000) = 1
                    AND (featurecode in (
            '10003',
            '10018',
            '10020',
            '10026',
            '10027',
            '10028',
            '10041',
            '10042',
            '10044',
            '10045',
            '10048',
            '10049',
            '10057',
            '10060',
            '10062',
            '10079',
            '10094',
            '10111',
            '10114',
            '40001',
            '40101',
            '40102',
            '40103',
            '40104',
            '40201',
            '40202',
            '40203',
            '40204',
            '40301',
            '40302',
            '40303',
            '40304'
                    ))) t order by KOODI;

* add ditch point geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :ditch_point_geom.ID, :ditch_point_geom.wf_mapsymbolid, :ditch_point_geom.KOODI, :ditch_point_geom.LISAMAARE, coalesce( :ditch_point_geom.SELITETEKSTI, ''),
       null, 'K', null, :ditch_point_geom.resourceid, :ditch_point_geom.mapsymbolname, :ditch_point_geom.ditchtype, TO_VARCHAR( :ditch_point_geom.length ),
       TO_VARCHAR( :ditch_point_geom.depth ), TO_VARCHAR( :ditch_point_geom.width ), TO_VARCHAR( :ditch_point_geom.volume ), :ditch_point_geom.materialcode , :ditch_point_geom.materialinfotext,
       :ditch_point_geom.ditchorroadplanname, :ditch_point_geom.updated_on, TO_VARCHAR( :ditch_point_geom.amountoflivingtrees ), TO_VARCHAR( :ditch_point_geom.amountofrottensnags ),
       TO_VARCHAR( :ditch_point_geom.amountofrottentrees ), '0', geoloc geometry_orig from :ditch_point_geom where :ditch_point_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    ditch_line_geom = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    (select geoloc as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    GISDATA.V_GIS_LINE_STANDARD a
                    WHERE
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID = :contractid and BLOCKNUMBER = :blocknumber)
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )
                    ), 1000) = 1
                    AND (featurecode in (
            '10003',
            '10018',
            '10020',
            '10026',
            '10027',
            '10028',
            '10041',
            '10042',
            '10044',
            '10045',
            '10048',
            '10049',
            '10057',
            '10060',
            '10062',
            '10079',
            '10094',
            '10111',
            '10114',
            '40001',
            '40101',
            '40102',
            '40103',
            '40104',
            '40201',
            '40202',
            '40203',
            '40204',
            '40301',
            '40302',
            '40303',
            '40304'
                    ))) t order by KOODI;

* add ditch line geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :ditch_line_geom.ID, :ditch_line_geom.wf_mapsymbolid, :ditch_line_geom.KOODI, :ditch_line_geom.LISAMAARE, coalesce( :ditch_line_geom.SELITETEKSTI, ''),
       null, 'K', null, :ditch_line_geom.resourceid, :ditch_line_geom.mapsymbolname, :ditch_line_geom.ditchtype, TO_VARCHAR( :ditch_line_geom.length ),
       TO_VARCHAR( :ditch_line_geom.depth ), TO_VARCHAR( :ditch_line_geom.width ), TO_VARCHAR( :ditch_line_geom.volume ), :ditch_line_geom.materialcode , :ditch_line_geom.materialinfotext,
       :ditch_line_geom.ditchorroadplanname, :ditch_line_geom.updated_on, TO_VARCHAR( :ditch_line_geom.amountoflivingtrees ), TO_VARCHAR( :ditch_line_geom.amountofrottensnags ),
       TO_VARCHAR( :ditch_line_geom.amountofrottentrees ), '0', geoloc geometry_orig from :ditch_line_geom where :ditch_line_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    ditch_poly_geom = SELECT t.featureinfo as seliteteksti, lpad(t.id,10,'0') as ID, t.featurecode as KOODI, t.FEATUREADDITIONALCODE as LISAMAARE, t.geoloc as GEOLOC, to_char(updated_on,'DD.MM.YYYY HH24:MI:SS') as updated_on,
                    resourceid, wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    (select geoloc as geoloc, featureinfo, id, featurecode, FEATUREADDITIONALCODE, coalesce(updated_on,created_on) as updated_on, resourceid,
                    gisdata.getwfmapsymbolfromblock(wf_mapsymbolid,:contract_with_decade,:blocknumber,:is_contract) as wf_mapsymbolid,
                    MAPSYMBOLNAME, DITCHTYPE, LENGTH, DEPTH, WIDTH, VOLUME, MATERIALCODE, MATERIALINFOTEXT, DITCHORROADPLANNAME, AMOUNTOFROTTENTREES, AMOUNTOFROTTENSNAGS, AMOUNTOFLIVINGTREES FROM
                    GISDATA.V_GIS_POLYGON_STANDARD a
                    WHERE
                    geoloc.ST_WithinDistance(
                    (SELECT ST_UNIONAGGR(geoloc) from
                    (
                    SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID =:contractid and BLOCKNUMBER = :blocknumber)
                    union all
                    SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID in (select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID = :contract_with_decade and BLOCKNUMBER = :blocknumber)
                    )
                    ), 1000)= 1
                    AND (featurecode in (
            '10003',
            '10018',
            '10020',
            '10026',
            '10027',
            '10028',
            '10041',
            '10042',
            '10044',
            '10045',
            '10048',
            '10049',
            '10057',
            '10060',
            '10062',
            '10079',
            '10094',
            '10111',
            '10114',
            '40001',
            '40101',
            '40102',
            '40103',
            '40104',
            '40201',
            '40202',
            '40203',
            '40204',
            '40301',
            '40302',
            '40303',
            '40304'
                    ))) t order by KOODI;

* add ditch polygon geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :ditch_poly_geom.ID, :ditch_poly_geom.wf_mapsymbolid, :ditch_poly_geom.KOODI, :ditch_poly_geom.LISAMAARE, coalesce( :ditch_poly_geom.SELITETEKSTI, ''),
       null, 'K', null, :ditch_poly_geom.resourceid, :ditch_poly_geom.mapsymbolname, :ditch_poly_geom.ditchtype, TO_VARCHAR( :ditch_poly_geom.length ),
       TO_VARCHAR( :ditch_poly_geom.depth ), TO_VARCHAR( :ditch_poly_geom.width ), TO_VARCHAR( :ditch_poly_geom.volume ), :ditch_poly_geom.materialcode , :ditch_poly_geom.materialinfotext,
       :ditch_poly_geom.ditchorroadplanname, :ditch_poly_geom.updated_on, TO_VARCHAR( :ditch_poly_geom.amountoflivingtrees ), TO_VARCHAR( :ditch_poly_geom.amountofrottensnags ),
       TO_VARCHAR( :ditch_poly_geom.amountofrottentrees ), '0', geoloc geometry_orig from :ditch_poly_geom where :ditch_poly_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

    bird_geom = SELECT p.*, TO_CHAR(UPDATED_ON, 'DD.MM.YYYY HH24:MI:SS') AS WOODFORCE_UPDATED_ON
                FROM MG_SPATIAL.SYKE_ELIOLAJIT_P p
                WHERE
                p.LAHDE IN ('Luomus, petolintujen pesäaineisto', 'Luontojärjestön oma havainto')
                AND
                geoloc.ST_WithinDistance(
                (SELECT ST_UNIONAGGR(GEOLOC) FROM
                (
                SELECT GEOLOC FROM MG_KOTKA.SW_PLANNINGSTAND WHERE SW_PLANNINGBLOCKID IN (SELECT SW_PLANNINGBLOCKID FROM MG_KOTKA.SW_PLANNINGBLOCK WHERE SILVICULTURALORDERID = :contractid AND BLOCKNUMBER = :blocknumber)
                UNION ALL
                SELECT GEOLOC FROM MG_KOTKA.HARVESTINGSTAND WHERE HARVESTINGBLOCKID IN (SELECT HARVESTINGBLOCKID FROM MG_KOTKA.HARVESTINGBLOCK WHERE CONTRACTID = :contract_with_decade AND BLOCKNUMBER = :blocknumber)
                )
                ), 1000) = 1;



* add bird nest geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :bird_geom.ID, null, '10013', '',
                        CASE WHEN :bird_geom.LAHDE = 'Luomus, petolintujen pesaaineisto' THEN
                                    coalesce(:bird_geom.SUOMENKIELINENNIMI, '-') || ', ' || coalesce(:bird_geom.TIETEELLINENNIMI, '-') ||
                                    ', havaintopaikka ' || coalesce(:bird_geom.KUNTA, '-') || ', havaintoaika ' ||
                                    CASE WHEN LOCATE(:bird_geom.ALKUPAIVAMAARA, '-') > 1 THEN SUBSTRING(:bird_geom.ALKUPAIVAMAARA, 1, LOCATE(:bird_geom.ALKUPAIVAMAARA, '-')) ELSE :bird_geom.ALKUPAIVAMAARA END ||
                                    ', havaintopaikan kuvaus ' ||
                                    CASE WHEN LENGTH(:bird_geom.HAVAINTOPAIKANKUVAUS) > 100 THEN SUBSTRING(:bird_geom.HAVAINTOPAIKANKUVAUS, 100) ELSE LENGTH(coalesce(:bird_geom.HAVAINTOPAIKANKUVAUS, '-')) END ||
                                    ', pesintojen lkm ' || coalesce(:bird_geom.MAARA, '-') || ', ' ||
                                    CASE WHEN LENGTH(:bird_geom.HAVAINNONKUVAUS) > 100 THEN SUBSTRING(:bird_geom.HAVAINNONKUVAUS, 100) ELSE LENGTH(coalesce(:bird_geom.HAVAINNONKUVAUS, '-')) END
                             WHEN :bird_geom.LAHDE = 'Luontojarjeston oma havainto' THEN
                                    coalesce(:bird_geom.SUOMENKIELINENNIMI, '-') || ', ' || coalesce(:bird_geom.TIETEELLINENNIMI, '-')
                                    || ', havaintopaikka ' || coalesce(:bird_geom.HAVAINTOPAIKANNIMI, '-')
                                    || ', havaintoaika ' || coalesce(:bird_geom.ALKUPAIVAMAARA, '-')
                                    || ', luokitus (IUCN) ' || coalesce(:bird_geom.IUCNLUOKKA, '-') || ', jarjestahavainto'
                         ELSE
                                    'Unsupported LAHDE: ' || coalesce(:bird_geom.LAHDE, '-')
                        END,
       null, 'E', null, null, null, null, null,
       null, null, null, null, null, null, :bird_geom.WOODFORCE_UPDATED_ON, null, null, null, '0', geoloc geometry_orig from :bird_geom where :bird_geom.ID not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;


    fertilizer_geom = SELECT
                      STORAGEID || STORAGE_NUMBER AS MAPSYMBOLID,
                      '10097' AS FEATURECODE,
                      'Lannoitevarasto_' || STORAGE_NUMBER AS MAPSYMBOLNAME,
                      INFOTEXT AS FEATUREINFO,
                      TO_CHAR(UPDATED_ON, 'DD.MM.YYYY HH24:MI:SS') AS UPDATED_ON,
                      GEOLOC
                      FROM MG_KOTKA.STORAGE
                      WHERE IS_FERTILIZER_STORAGE = 1
                      AND SILVICULTURALORDERID = :contractid;

* add outer resource geometries to output
       output_t = select * from :output_t union select :contractid, :blocknumber, :fertilizer_geom.mapsymbolid, null, :fertilizer_geom.featurecode, '', coalesce( :fertilizer_geom.featureinfo, ''),
       null, 'E', null, null, :fertilizer_geom.mapsymbolname, null, null,
       null, null, null, null, null, null, :fertilizer_geom.updated_on, null, null, null, '0', geoloc geometry_orig from :fertilizer_geom where :fertilizer_geom.mapsymbolid not in ( select :uniquemapsymbolids.mapsymbolid from :uniquemapsymbolids );

* update unique map symbols
    uniquemapsymbolids = select distinct :output_t.mapsymbolid from :output_t;

* normalize objects
    select count( 1 ) into lv_index from :uniquemapsymbolids;
    output_t = select
        contractid,
        blocknumber,
        mapsymbolid,
        wfinsertedmapsymbolid,
        case when featurecode = '10120' then '10123' else featurecode end as featurecode,
        featureadditionalcode,
        featureinfo, -- TODO for ABAP, XML characters must be escaped https://help.sap.com/doc/abapdocu_752_index_htm/7.52/en-us/abenescape_functions.htm
        geometry,
        canmodify,
        SUBSTR_BEFORE(SUBSTR_AFTER(variantname, '<VARIANT_NAME>'), '</VARIANT_NAME>') as variantname,
        resourceid,
        mapsymbolname, -- for ABAP, XML characters must be escaped
        ditchtype,
        length,
        depth,
        width,
        volume,
        materialcode,
        materialinfotext, -- TODO for ABAP, XML characters must be escaped
        dorplanname, -- TODO for ABAP, XML characters must be escaped
        updatedtime,
        amountoflivingtrees,
        amountofrottensnags,
        amountofrottentrees,
        lv_index as amountofmapsymbols,
        geometry_orig
            from :output_t;


   --Loop the table to set the geometry
    for lv_index in 1..record_count(:output_t)
      do
        declare geom nvarchar ( 10000 );
        declare shape_orig st_geometry = :output_t.geometry_orig[:lv_index];
        call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:shape_orig,
            st_text=>:geom
        );
        output_t.geometry[:lv_index] = geom;
    end for ;

* first output tabe
    response = select
         contractid
        ,blocknumber
        ,mapsymbolid
        ,wfinsertedmapsymbolid
        ,featurecode
        ,featureadditionalcode
        ,featureinfo
        ,geometry
        ,canmodify
        ,variantname
        ,resourceid
        ,mapsymbolname
        ,ditchtype
        ,length
        ,depth
        ,width
        ,volume
        ,materialcode
        ,materialinfotext
        ,dorplanname
        ,updatedtime
        ,amountofmapsymbols
            from :output_t;

* second output table
    spare_trees = SELECT SPARETREECATEGORY category, AMOUNTOFSPARETREES amount, lpad(MAPSYMBOLID,10,'0') mapsymbolid FROM GISDATA.SPARETREES
    WHERE MAPSYMBOLID IN ( select mapsymbolid from :uniquemapsymbolids );

  ENDMETHOD.

ENDCLASS.