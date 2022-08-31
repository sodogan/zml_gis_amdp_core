***********************************************************************
* Class         : ZCL_GIS_AMDP_ID746                                  *
* Package       : ZML_GIS_AMDP                                        *
*                                                                     *
* Author        : Viktors Krebss, Tietoevry                           *
*                                                                     *
* Description   : SaveWorkingSiteMapSymbol:                           *
*                 Saves map symbols (karttamerkit) in the GIS database*
*                 Returns a message indicating either a successful    *
*                 or a failed save.                                   *
*                                                                     *
*                                                                     *
*                                                                     *
* Change history:                                                     *
* Date       // Author                    // Description              *
* ------------------------------------------------------------------- *
* 25 april 2022 Viktors Krebss, Tietoevry                             *
*                                                                     *
***********************************************************************
CLASS zcl_gis_amdp_id746 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS SaveWorkingSiteMapSymbol
      IMPORTING
        VALUE(contractid)          TYPE zmhobject
        VALUE(decade)              TYPE zzostosopvk
        VALUE(blocknumber)         TYPE zmhblockno
        VALUE(harvestingblockid)   TYPE int4
        VALUE(action)              TYPE int4
        VALUE(workingsite_request) TYPE zmgkotka_746_worksitemapsym_tt
        RAISING cx_amdp_error
       .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id746 IMPLEMENTATION.





  METHOD SaveWorkingSiteMapSymbol BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                             USING   zcl_gis_amdp_util=>geoxml_to_geoshape.
* Saves map symbols (karttamerkit) in the GIS database.
* Returns a message indicating either a successfull or a failed save.

* Geometry types
*
*lSP lineStringProperty
*lineStringProperty/LineString/posList
*PGE PolygonGeometryExt
*PolygonGeometry/polygonProperty/Polygon/exterior/LinearRing/posList
*PGI PolygonGeometryInt
*PolygonGeometry/polygonProperty/Polygon/interior/LinearRing/posList
*pP  pointProperty
*pointProperty/Point/pos
*MPE MultiPolygonGeometry Ext
*MultiPolygon/polygonMember/Polygon/exterior/LinearRing/posList
*MPI MultiPolygonGeometry Int
*MultiPolygon/polygonMember/Polygon/interior/LinearRing/posList


    --Local data declarations
    DECLARE lv_index INTEGER;
    DECLARE contract_with_decade string;
    DECLARE workingsite_t TABLE (
       mapsymbolid  int
      ,insertmapsymbolid int
      ,featurecode int
      ,featurecodeadditional int
      ,featureinfo nvarchar ( 20 )
      ,geometry  nvarchar( 10000 )
      ,geom  st_geometry
      ,geom_type nvarchar ( 20 )
      ,canmodify int
      ,resourceid int
      ,mapsymbolname nvarchar ( 100 )
      ,ditchtype nvarchar
      ,length double
      ,depth double
      ,width double
      ,volume double
      ,materialcode nvarchar ( 100 )
      ,materialinfotext nvarchar ( 100 )
      ,ditchorroadplanname nvarchar ( 100 )
      ,amountofrottentreesinspareg int
      ,amountofrottensnagsinspareg int
      ,amountoflivingtreesinspareg int
      ,variantname nvarchar ( 100 )
    );
    DECLARE lv_st_text String;
    declare invalid_action CONDITION FOR SQL_ERROR_CODE 10001;

**Validate the Action- can only be 1 or 2
     if NOT :action IN (  1 , 2 )
     then
      SIGNAL invalid_action SET MESSAGE_TEXT = 'Invalid Action-only 1 and 2 are possible';
    end if;


    contract_with_decade = CONCAT(:contractid,:decade);
*   update featurecode 10120 -> 10123;
    workingsite_t = select
       mapsymbolid
      ,insertmapsymbolid
      ,CASE WHEN featurecode = 10120 THEN 10123 ELSE featurecode END as featurecode
      ,featurecodeadditional
      ,featureinfo
      ,geometry
      ,geom
      ,null as geom_type
      ,canmodify
      ,resourceid
      ,mapsymbolname
      ,ditchtype
      ,length
      ,depth
      ,width
      ,volume
      ,materialcode
      ,materialinfotext
      ,ditchorroadplanname
      ,amountofrottentreesinspareg
      ,amountofrottensnagsinspareg
      ,amountoflivingtreesinspareg
      ,variantname
    from :workingsite_request;

   --Loop the table to set the geometry
    for lv_index in 1..record_count(:workingsite_t)
      do
        declare lv_poslist string = :workingsite_t.geometry[:lv_index];
        declare lv_variant_name varchar( 5 ) = :workingsite_t.variantname[:lv_index];
        DECLARE lv_geom st_geometry =  :workingsite_t.geom[:lv_index];
        DECLARE lv_geom_type string =  :workingsite_t.geom_type[:lv_index];
        --Convert the geom string to geometric object
         call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
              poslist => :lv_poslist,
              gtype   => :lv_variant_name,
              st_text => :lv_st_text,
              geom_type => :lv_geom_type,
              geom    => :lv_geom /*set the geom object*/
            );

       --Assign fields
       workingsite_t.geom[:lv_index] = :lv_geom;
       workingsite_t.geom_type[:lv_index] = :lv_geom_type;
    end for ;
* not filtering by geometry tipe, IDs source is same for all GISDATA.MAPSYMBOL_SEQ.nextval
* i.e. it "must" be globally unique
    if :action = 2 -- action delete
    then
* sqlCommand = "delete GISDATA.GIS_POINT where ID=:Mapsymbol.MAPSYMBOLID
        delete from GISDATA.GIS_POINT WHERE GISDATA.GIS_POINT.ID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0 );
* sqlCommand = "delete GISDATA.GIS_LINE where ID=:Mapsymbol.MAPSYMBOLID
        delete from GISDATA.GIS_LINE where GISDATA.GIS_LINE.ID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0 );
* sqlCommand = "delete GISDATA.GIS_POLYGON where ID=:Mapsymbol.MAPSYMBOLID
        delete from GISDATA.GIS_POLYGON where GISDATA.GIS_POLYGON.ID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0 );
* sqlCommand = "delete GISDATA.RESOURCE_PATH where ID=:Mapsymbol.MAPSYMBOLID
        delete from GISDATA.RESOURCE_PATH where GISDATA.RESOURCE_PATH.ID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0 );
* sqlCommand = "delete GISDATA.SPARETREES where MAPSYMBOLID=:Mapsymbol.MAPSYMBOLID
        delete from GISDATA.SPARETREES where GISDATA.SPARETREES.MAPSYMBOLID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0 );
* sqlCommand = "delete GISDATA.GIS_POINT where WF_MAPSYMBOLID=:Mapsymbol.WF_MAPSYMBOLID
        delete from GISDATA.GIS_POINT where GISDATA.GIS_POINT.WF_MAPSYMBOLID IN  ( select insertmapsymbolid from :workingsite_t where length( :workingsite_t.insertmapsymbolid ) > 0 );
* sqlCommand = "delete GISDATA.GIS_LINE where WF_MAPSYMBOLID=:Mapsymbol.WF_MAPSYMBOLID
        delete from GISDATA.GIS_LINE where GISDATA.GIS_LINE.WF_MAPSYMBOLID IN  ( select insertmapsymbolid from :workingsite_t where length( :workingsite_t.insertmapsymbolid ) > 0 );
* sqlCommand = "delete GISDATA.GIS_POLYGON where WF_MAPSYMBOLID=:Mapsymbol.WF_MAPSYMBOLID
        delete from GISDATA.GIS_POLYGON where GISDATA.GIS_POLYGON.WF_MAPSYMBOLID IN  ( select insertmapsymbolid from :workingsite_t where length( :workingsite_t.insertmapsymbolid ) > 0 );
* sqlCommand = "delete GISDATA.RESOURCE_PATH where WF_MAPSYMBOLID=:Mapsymbol.WF_MAPSYMBOLID
        delete from GISDATA.RESOURCE_PATH where GISDATA.RESOURCE_PATH.WF_MAPSYMBOLID IN ( select insertmapsymbolid from :workingsite_t where length( :workingsite_t.insertmapsymbolid ) > 0 );
* sqlCommand = "delete GISDATA.SPARETREES where MAPSYMBOLID=:Mapsymbol.WF_MAPSYMBOLID
        delete from GISDATA.SPARETREES where GISDATA.SPARETREES.MAPSYMBOLID IN ( select insertmapsymbolid from :workingsite_t where length( :workingsite_t.insertmapsymbolid ) > 0 );
    elseif  :action = 1 -- insert / update
    then

* update GIS_POINT
        merge into GISDATA.GIS_POINT using :workingsite_t on GISDATA.GIS_POINT.ID = :workingsite_t.mapsymbolid and :workingsite_t.mapsymbolid > 0 when matched then update set
        GISDATA.GIS_POINT.GEOLOC = :workingsite_t.geom,
        GISDATA.GIS_POINT.FEATURECODE = :workingsite_t.featurecode,
        GISDATA.GIS_POINT.MAPSYMBOLNAME = :workingsite_t.mapsymbolname,
        GISDATA.GIS_POINT.FEATUREINFO = :workingsite_t.featureinfo,
        GISDATA.GIS_POINT.FEATUREADDITIONALCODE = :workingsite_t.featurecodeadditional,
        GISDATA.GIS_POINT.RESOURCEID = :workingsite_t.resourceid,
        GISDATA.GIS_POINT.WF_MAPSYMBOLID = :workingsite_t.insertmapsymbolid,
        GISDATA.GIS_POINT.AMOUNTOFLIVINGTREES = :workingsite_t.amountoflivingtreesinspareg,
        GISDATA.GIS_POINT.AMOUNTOFROTTENSNAGS = :workingsite_t.amountofrottensnagsinspareg,
        GISDATA.GIS_POINT.AMOUNTOFROTTENTREES = :workingsite_t.amountofrottentreesinspareg,
        GISDATA.GIS_POINT.DEPTH = :workingsite_t.depth,
        GISDATA.GIS_POINT.DITCHORROADPLANNAME = :workingsite_t.ditchorroadplanname,
        GISDATA.GIS_POINT.DITCHTYPE = :workingsite_t.ditchtype,
        GISDATA.GIS_POINT.LENGTH = :workingsite_t.length,
        GISDATA.GIS_POINT.MATERIALCODE = :workingsite_t.materialcode,
        GISDATA.GIS_POINT.MATERIALINFOTEXT = :workingsite_t.materialinfotext,
        GISDATA.GIS_POINT.VOLUME = :workingsite_t.volume,
        GISDATA.GIS_POINT.Width = :workingsite_t.width,
        GISDATA.GIS_POINT.REPLICATED_TO_PATIKKA =  0
;

* update GIS_LINE
        merge into GISDATA.GIS_LINE using :workingsite_t on GISDATA.GIS_LINE.ID = :workingsite_t.mapsymbolid and :workingsite_t.mapsymbolid > 0 when matched then update set
        GISDATA.GIS_LINE.GEOLOC = :workingsite_t.geom,
        GISDATA.GIS_LINE.FEATURECODE = :workingsite_t.featurecode,
        GISDATA.GIS_LINE.MAPSYMBOLNAME = :workingsite_t.mapsymbolname,
        GISDATA.GIS_LINE.FEATUREINFO = :workingsite_t.featureinfo,
        GISDATA.GIS_LINE.FEATUREADDITIONALCODE = :workingsite_t.featurecodeadditional,
        GISDATA.GIS_LINE.RESOURCEID = :workingsite_t.resourceid,
        GISDATA.GIS_LINE.WF_MAPSYMBOLID = :workingsite_t.insertmapsymbolid,
        GISDATA.GIS_LINE.AMOUNTOFLIVINGTREES = :workingsite_t.amountoflivingtreesinspareg,
        GISDATA.GIS_LINE.AMOUNTOFROTTENSNAGS = :workingsite_t.amountofrottensnagsinspareg,
        GISDATA.GIS_LINE.AMOUNTOFROTTENTREES = :workingsite_t.amountofrottentreesinspareg,
        GISDATA.GIS_LINE.DEPTH = :workingsite_t.depth,
        GISDATA.GIS_LINE.DITCHORROADPLANNAME = :workingsite_t.ditchorroadplanname,
        GISDATA.GIS_LINE.DITCHTYPE = :workingsite_t.ditchtype,
        GISDATA.GIS_LINE.LENGTH = :workingsite_t.length,
        GISDATA.GIS_LINE.MATERIALCODE = :workingsite_t.materialcode,
        GISDATA.GIS_LINE.MATERIALINFOTEXT = :workingsite_t.materialinfotext,
        GISDATA.GIS_LINE.VOLUME = :workingsite_t.volume,
        GISDATA.GIS_LINE.Width = :workingsite_t.width,
        GISDATA.GIS_LINE.REPLICATED_TO_PATIKKA =  0
;

* update GIS_POLYGON
        merge into GISDATA.GIS_POLYGON using :workingsite_t on GISDATA.GIS_POLYGON.ID = :workingsite_t.mapsymbolid and :workingsite_t.mapsymbolid > 0 when matched then update set
        GISDATA.GIS_POLYGON.GEOLOC = :workingsite_t.geom,
        GISDATA.GIS_POLYGON.FEATURECODE = :workingsite_t.featurecode,
        GISDATA.GIS_POLYGON.MAPSYMBOLNAME = :workingsite_t.mapsymbolname,
        GISDATA.GIS_POLYGON.FEATUREINFO = :workingsite_t.featureinfo,
        GISDATA.GIS_POLYGON.FEATUREADDITIONALCODE = :workingsite_t.featurecodeadditional,
        GISDATA.GIS_POLYGON.RESOURCEID = :workingsite_t.resourceid,
        GISDATA.GIS_POLYGON.WF_MAPSYMBOLID = :workingsite_t.insertmapsymbolid,
        GISDATA.GIS_POLYGON.AMOUNTOFLIVINGTREES = :workingsite_t.amountoflivingtreesinspareg,
        GISDATA.GIS_POLYGON.AMOUNTOFROTTENSNAGS = :workingsite_t.amountofrottensnagsinspareg,
        GISDATA.GIS_POLYGON.AMOUNTOFROTTENTREES = :workingsite_t.amountofrottentreesinspareg,
        GISDATA.GIS_POLYGON.DEPTH = :workingsite_t.depth,
        GISDATA.GIS_POLYGON.DITCHORROADPLANNAME = :workingsite_t.ditchorroadplanname,
        GISDATA.GIS_POLYGON.DITCHTYPE = :workingsite_t.ditchtype,
        GISDATA.GIS_POLYGON.LENGTH = :workingsite_t.length,
        GISDATA.GIS_POLYGON.MATERIALCODE = :workingsite_t.materialcode,
        GISDATA.GIS_POLYGON.MATERIALINFOTEXT = :workingsite_t.materialinfotext,
        GISDATA.GIS_POLYGON.VOLUME = :workingsite_t.volume,
        GISDATA.GIS_POLYGON.Width = :workingsite_t.width,
        GISDATA.GIS_POLYGON.REPLICATED_TO_PATIKKA =  0
;

* delete sparetrees
        delete from GISDATA.SPARETREES where GISDATA.SPARETREES.MAPSYMBOLID IN ( select mapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid > 0  );

* insert sparetrees
* TODO find group ID
        insert into GISDATA.SPARETREES SELECT GISDATA.SPARETREES_SEQ.nextval, :workingsite_t.mapsymbolid, 1, :workingsite_t.amountoflivingtreesinspareg from :workingsite_t where :workingsite_t.mapsymbolid > 0;
        insert into GISDATA.SPARETREES SELECT GISDATA.SPARETREES_SEQ.nextval, :workingsite_t.mapsymbolid, 2, :workingsite_t.amountofrottentreesinspareg from :workingsite_t where :workingsite_t.mapsymbolid > 0;
        insert into GISDATA.SPARETREES SELECT GISDATA.SPARETREES_SEQ.nextval, :workingsite_t.mapsymbolid, 3, :workingsite_t.amountofrottensnagsinspareg from :workingsite_t where :workingsite_t.mapsymbolid > 0;

* update RESOURCE_PATH
        merge into GISDATA.RESOURCE_PATH using :workingsite_t on GISDATA.RESOURCE_PATH.ID = :workingsite_t.mapsymbolid and :workingsite_t.mapsymbolid > 0 when matched then update set
        GISDATA.RESOURCE_PATH.GEOLOC = :workingsite_t.geom,
        GISDATA.RESOURCE_PATH.FEATURECODE = :workingsite_t.featurecode,
        GISDATA.RESOURCE_PATH.FEATUREINFO = :workingsite_t.featureinfo,
        GISDATA.RESOURCE_PATH.FEATUREADDITIONALCODE = :workingsite_t.featurecodeadditional,
        GISDATA.RESOURCE_PATH.RESOURCEID = :workingsite_t.resourceid,
        GISDATA.RESOURCE_PATH.WF_MAPSYMBOLID = :workingsite_t.insertmapsymbolid,
        GISDATA.RESOURCE_PATH.REPLICATED_TO_PATIKKA =  0
;

* insert new objects into WF_MAPSYMBOL_LOG
        insert into GISDATA.WF_MAPSYMBOL_LOG SELECT :workingsite_t.insertmapsymbolid, case when :decade is not null then contract_with_decade else null end, case when :decade is null then :contractid else null end, :blocknumber,
        CURRENT_TIMESTAMP from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0 and :workingsite_t.insertmapsymbolid not in ( SELECT WF_MAPSYMBOLID FROM GISDATA.WF_MAPSYMBOL_LOG );

* insert new objects into RESOURCE_PATH Featurecode in ("10052","10053","10061","10118")
        insert into GISDATA.RESOURCE_PATH ( ID, GEOLOC, MAINTYPE, SUBTYPE, FEATURECODE, FEATUREINFO, FEATUREADDITIONALCODE, RESOURCEID, WF_MAPSYMBOLID, REPLICATED_TO_PATIKKA, BLOCKNUMBER, CONTRACTID, SILVICULTURALORDERID )
        SELECT GISDATA.MAPSYMBOL_SEQ.nextval, :workingsite_t.geom, 'OperativeFeature', 'OfficialFeature', :workingsite_t.featurecode, :workingsite_t.featureinfo, :workingsite_t.featurecodeadditional,
        :workingsite_t.resourceid, :workingsite_t.insertmapsymbolid, 0, :blocknumber, case when :decade is not null then contract_with_decade else null end, case when :decade is null then :contractid else null end
        from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0 and :workingsite_t.featurecode in ( '10052','10053','10061','10118' );

*insert new points
        insert into GISDATA.GIS_POINT ( ID, GEOLOC, MAINTYPE, SUBTYPE, FEATURECODE, FEATUREINFO, FEATUREADDITIONALCODE, RESOURCEID, WF_MAPSYMBOLID, REPLICATED_TO_PATIKKA, CONTRACTID, SILVICULTURALORDERID, AMOUNTOFLIVINGTREES,
        AMOUNTOFROTTENSNAGS, AMOUNTOFROTTENTREES, DEPTH, LENGTH, VOLUME, WIDTH, DITCHORROADPLANNAME, DITCHTYPE, MAPSYMBOLNAME, MATERIALCODE, MATERIALINFOTEXT )
        SELECT GISDATA.MAPSYMBOL_SEQ.nextval, :workingsite_t.geom, 'OperativeFeature', 'OfficialFeature', :workingsite_t.featurecode, :workingsite_t.featureinfo, :workingsite_t.featurecodeadditional,
        :workingsite_t.resourceid, :workingsite_t.insertmapsymbolid, 0, case when :decade is not null then contract_with_decade else null end, case when :decade is null then :contractid else null end,
        :workingsite_t.amountoflivingtreesinspareg, :workingsite_t.amountofrottensnagsinspareg, :workingsite_t.amountofrottentreesinspareg, :workingsite_t.depth, :workingsite_t.length, :workingsite_t.volume, :workingsite_t.width,
        :workingsite_t.ditchorroadplanname, :workingsite_t.ditchtype, :workingsite_t.mapsymbolname, :workingsite_t.materialcode, :workingsite_t.materialinfotext
        from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0  and :workingsite_t.geom_type IN ( 'ST_Point' )
        ;

*insert point sparetrees
* TODO find group ID
        insert into GISDATA.SPARETREES SELECT GIS_POINT.ID, :workingsite_t.mapsymbolid, 1, :workingsite_t.amountoflivingtreesinspareg  FROM GISDATA.GIS_POINT
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POINT.WF_MAPSYMBOLID
        WHERE GIS_POINT.GEOLOC.ST_GeometryType() IN ( 'ST_Point' ) and GIS_POINT.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_POINT.ID, :workingsite_t.mapsymbolid, 2, :workingsite_t.amountofrottentreesinspareg  FROM GISDATA.GIS_POINT
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POINT.WF_MAPSYMBOLID
        WHERE GIS_POINT.GEOLOC.ST_GeometryType() IN ( 'ST_Point' ) and GIS_POINT.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_POINT.ID, :workingsite_t.mapsymbolid, 3, :workingsite_t.amountofrottensnagsinspareg  FROM GISDATA.GIS_POINT
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POINT.WF_MAPSYMBOLID
        WHERE GIS_POINT.GEOLOC.ST_GeometryType() IN ( 'ST_Point' ) and GIS_POINT.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

*insert new line
        insert into GISDATA.GIS_LINE ( ID, GEOLOC, MAINTYPE, SUBTYPE, FEATURECODE, FEATUREINFO, FEATUREADDITIONALCODE, RESOURCEID, WF_MAPSYMBOLID, REPLICATED_TO_PATIKKA, CONTRACTID, SILVICULTURALORDERID, AMOUNTOFLIVINGTREES,
        AMOUNTOFROTTENSNAGS, AMOUNTOFROTTENTREES, DEPTH, LENGTH, VOLUME, WIDTH, DITCHORROADPLANNAME, DITCHTYPE, MAPSYMBOLNAME, MATERIALCODE, MATERIALINFOTEXT )
        SELECT GISDATA.MAPSYMBOL_SEQ.nextval, :workingsite_t.geom,  'OperativeFeature', 'OfficialFeature', :workingsite_t.featurecode, :workingsite_t.featureinfo, :workingsite_t.featurecodeadditional,
        :workingsite_t.resourceid, :workingsite_t.insertmapsymbolid, 0, case when :decade is not null then contract_with_decade else null end, case when :decade is null then :contractid else null end,
        :workingsite_t.amountoflivingtreesinspareg, :workingsite_t.amountofrottensnagsinspareg, :workingsite_t.amountofrottentreesinspareg, :workingsite_t.depth, :workingsite_t.length, :workingsite_t.volume, :workingsite_t.width,
        :workingsite_t.ditchorroadplanname, :workingsite_t.ditchtype, :workingsite_t.mapsymbolname, :workingsite_t.materialcode, :workingsite_t.materialinfotext
        from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0 and :workingsite_t.geom_type IN ( 'ST_LineString', 'ST_MultiLineString' )
        ;

*insert line sparetrees
* TODO find group ID
        insert into GISDATA.SPARETREES SELECT GIS_LINE.ID, :workingsite_t.mapsymbolid, 1, :workingsite_t.amountoflivingtreesinspareg  FROM GISDATA.GIS_LINE
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_LINE.WF_MAPSYMBOLID
        WHERE GIS_LINE.GEOLOC.ST_GeometryType() IN ( 'ST_LineString', 'ST_MultiLineString' ) and GIS_LINE.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_LINE.ID, :workingsite_t.mapsymbolid, 2, :workingsite_t.amountofrottentreesinspareg  FROM GISDATA.GIS_LINE
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_LINE.WF_MAPSYMBOLID
        WHERE GIS_LINE.GEOLOC.ST_GeometryType() IN ( 'ST_LineString', 'ST_MultiLineString' ) and GIS_LINE.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_LINE.ID, :workingsite_t.mapsymbolid, 3, :workingsite_t.amountofrottensnagsinspareg  FROM GISDATA.GIS_LINE
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_LINE.WF_MAPSYMBOLID
        WHERE GIS_LINE.GEOLOC.ST_GeometryType() IN ( 'ST_LineString', 'ST_MultiLineString' ) and GIS_LINE.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

*insert new polygon
        insert into GISDATA.GIS_POLYGON ( ID, GEOLOC, MAINTYPE, SUBTYPE, FEATURECODE, FEATUREINFO, FEATUREADDITIONALCODE, RESOURCEID, WF_MAPSYMBOLID, REPLICATED_TO_PATIKKA, CONTRACTID, SILVICULTURALORDERID, AMOUNTOFLIVINGTREES,
        AMOUNTOFROTTENSNAGS, AMOUNTOFROTTENTREES, DEPTH, LENGTH, VOLUME, WIDTH, DITCHORROADPLANNAME, DITCHTYPE, MAPSYMBOLNAME, MATERIALCODE, MATERIALINFOTEXT )
        SELECT GISDATA.MAPSYMBOL_SEQ.nextval, :workingsite_t.geom, 'OperativeFeature', 'OfficialFeature', :workingsite_t.featurecode, :workingsite_t.featureinfo, :workingsite_t.featurecodeadditional,
        :workingsite_t.resourceid, :workingsite_t.insertmapsymbolid, 0, case when :decade is not null then contract_with_decade else null end, case when :decade is null then :contractid else null end,
        :workingsite_t.amountoflivingtreesinspareg, :workingsite_t.amountofrottensnagsinspareg, :workingsite_t.amountofrottentreesinspareg, :workingsite_t.depth, :workingsite_t.length, :workingsite_t.volume, :workingsite_t.width,
        :workingsite_t.ditchorroadplanname, :workingsite_t.ditchtype, :workingsite_t.mapsymbolname, :workingsite_t.materialcode, :workingsite_t.materialinfotext
        from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0  and :workingsite_t.geom_type IN ( 'ST_Polygon', 'ST_MultiPolygon' )
        ;

*insert line polygon
* TODO find group ID
        insert into GISDATA.SPARETREES SELECT GIS_POLYGON.ID, :workingsite_t.mapsymbolid, 1, :workingsite_t.amountoflivingtreesinspareg  FROM GISDATA.GIS_POLYGON
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POLYGON.WF_MAPSYMBOLID
        WHERE GIS_POLYGON.GEOLOC.ST_GeometryType() IN ( 'ST_Polygon', 'ST_MultiPolygon' ) and GIS_POLYGON.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_POLYGON.ID, :workingsite_t.mapsymbolid, 2, :workingsite_t.amountofrottentreesinspareg  FROM GISDATA.GIS_POLYGON
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POLYGON.WF_MAPSYMBOLID
        WHERE GIS_POLYGON.GEOLOC.ST_GeometryType() IN ( 'ST_Polygon', 'ST_MultiPolygon' ) and GIS_POLYGON.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

        insert into GISDATA.SPARETREES SELECT GIS_POLYGON.ID, :workingsite_t.mapsymbolid, 3, :workingsite_t.amountofrottensnagsinspareg  FROM GISDATA.GIS_POLYGON
        inner join :workingsite_t on :workingsite_t.insertmapsymbolid = GIS_POLYGON.WF_MAPSYMBOLID
        WHERE GIS_POLYGON.GEOLOC.ST_GeometryType() IN ( 'ST_Polygon', 'ST_MultiPolygon' ) and GIS_POLYGON.ID IN ( SELECT insertmapsymbolid from :workingsite_t where :workingsite_t.mapsymbolid = 0 and length( :workingsite_t.insertmapsymbolid ) > 0);

    end if;


  ENDMETHOD.

ENDCLASS.