"! <p class="shorttext synchronized" lang="en">GetWorkingSiteForestPlanStandGeometries</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteForestPlanStandGeometries</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger:</p>
CLASS zcl_gis_amdp_id1142 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS GetWorkSiteForestPlanStandGeom
      IMPORTING
        VALUE(in_contractid)       TYPE zmhobject
        VALUE(in_blocknumber)      TYPE zmhblockno
        VALUE(in_decade)           TYPE zzostosopvk
       exporting
        VALUE(out_contractid)        TYPE int8
        VALUE(out_blocknumber)       TYPE zmhblockno
        VALUE(out_decade)            TYPE zzostosopvk
*        VALUE(out_amount_of_stands)  TYPE string
        VALUE(stands_tt)             TYPE  ziidt_id1142_gis_get_wsfo_tab
       RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1142 IMPLEMENTATION.





  METHOD GetWorkSiteForestPlanStandGeom BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.

    --Local data declarations
    declare lv_index integer;
    declare geom st_geometry;
    declare contract_with_decade string;
    declare response_t TABLE (
       contractid nvarchar( 100 )
     , decade int
     , blocknumber int
     , wsostandid int
     , forestplanstandid int
     , forestplanid int
     , realestateid int
     , standnumber int
     , standnumberextension nvarchar( 10 )
     , developmentclass nvarchar( 100 )
     , area float
     , updatedon date
     , hasoverlaparea nvarchar( 100 )
     , geometry st_geometry
     , geometry_text nvarchar( 5000 ) --TODO is 5000 enough?
    );

    --Steps to follow
    contract_with_decade := CONCAT(:in_contractid,:in_decade);

* Replicates four select steps in:   MG0729  https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteForestPlanStandGeometries
* first four additional selects is bug workaround described in MFORT-16418

    stand_of_harvestingstand = select * from mg_kotka.vi_stand_of_harvestingstand where contractid = :contract_with_decade and blocknumber = :in_blocknumber;
    stand_of_harvestingstand_all = select * from mg_kotka.vi_stand_of_harvestingstand_all where contractid = :contract_with_decade and blocknumber = :in_blocknumber;
    stand_of_swplanningstand = select * from mg_kotka.vi_stand_of_swplanningstand where silviculturalorderid = :in_contractid and blocknumber = :in_blocknumber;
    stand_of_swplanningstand_all = select * from mg_kotka.vi_stand_of_swplanningstand_all where silviculturalorderid = :in_contractid and blocknumber = :in_blocknumber;

    src0 = select :in_contractid as contractid,
                  :in_decade as decade,
                  :in_blocknumber as blocknumber,
                  soh.harvestingstandid as wsostandid,
                  soh.stand_id as forestplanstandid,
                  stand.forest_plan_id as forestplanid,
                  stand.real_estate_id as realestateid,
                  stand.stand_number as standnumber,
                  stand.stand_number_extension as standnumberextension,
                  stand.development_class as developmentclass,
                  stand.area as area,
                  stand.updated_on as updatedon,
                  'true' as hasoverlaparea,
                  harvestingstand.geoloc as geometry,
                  null as geometry_text
     from :stand_of_harvestingstand soh
     left join mvk.stand on mvk.stand.stand_id = soh.stand_id
     left join mg_kotka.harvestingstand on harvestingstand.harvestingstandid = soh.harvestingstandid
     where soh.IntersectionPros > 70 and harvestingstand.status != 3 and harvestingstand.geoloc is not null;

    src1 = select :in_contractid as contractid, :in_decade as decade, :in_blocknumber as blocknumber, :stand_of_harvestingstand_all.harvestingstandid as wsostandid
    , :stand_of_harvestingstand_all.stand_id as forestplanstandid, stand.forest_plan_id as forestplanid, stand.real_estate_id as realestateid, stand.stand_number as standnumber
    , stand.stand_number_extension as standnumberextension, stand.development_class as developmentclass, stand.area as area, stand.updated_on as updatedon, 'true' as hasoverlaparea, harvestingstand.geoloc as geometry
    , null as geometry_text
    from :stand_of_harvestingstand_all
    left join mvk.stand on mvk.stand.stand_id = :stand_of_harvestingstand_all.stand_id
    left join mg_kotka.harvestingstand on harvestingstand.harvestingstandid = :stand_of_harvestingstand_all.harvestingstandid
    where :stand_of_harvestingstand_all.IntersectionPros > 70 and harvestingstand.status != 3 and harvestingstand.geoloc is not null;

    src2 = select :in_contractid as contractid, :in_decade as decade, :in_blocknumber as blocknumber, :stand_of_swplanningstand.sw_planningstandid as wsostandid
    , :stand_of_swplanningstand.stand_id as forestplanstandid, stand.forest_plan_id as forestplanid, stand.real_estate_id as realestateid, stand.stand_number as standnumber
    , stand.stand_number_extension as standnumberextension, stand.development_class as developmentclass, stand.area as area, stand.updated_on as updatedon, 'true' as hasoverlaparea, sw_planningstand.geoloc as geometry
    , null as geometry_text
    from :stand_of_swplanningstand
    left join mvk.stand on mvk.stand.stand_id = :stand_of_swplanningstand.stand_id
    left join mg_kotka.sw_planningstand on sw_planningstand.sw_planningstandid = :stand_of_swplanningstand.sw_planningstandid
    where:stand_of_swplanningstand.IntersectionPros > 70 and sw_planningstand.status != 3 and sw_planningstand.geoloc is not null;

    src3 = select :in_contractid as contractid, :in_decade as decade, :in_blocknumber as blocknumber, :stand_of_swplanningstand_all.sw_planningstandid as wsostandid
    , :stand_of_swplanningstand_all.stand_id as forestplanstandid, stand.forest_plan_id as forestplanid, stand.real_estate_id as realestateid, stand.stand_number as standnumber
    , stand.stand_number_extension as standnumberextension, stand.development_class as developmentclass, stand.area as area, stand.updated_on as updatedon, 'true' as hasoverlaparea, sw_planningstand.geoloc as geometry
    , null as geometry_text
    from :stand_of_swplanningstand_all
    left join mvk.stand on mvk.stand.stand_id = :stand_of_swplanningstand_all.stand_id
    left join mg_kotka.sw_planningstand on sw_planningstand.sw_planningstandid = :stand_of_swplanningstand_all.sw_planningstandid
    where :stand_of_swplanningstand_all.IntersectionPros > 70 and sw_planningstand.status != 3 and sw_planningstand.geoloc is not null;

* merging results in one dataset
    tmp0 = select * from :src0 union select * from :src1 where :src1.forestplanstandid not in ( select forestplanstandid from :src0 );
    tmp1 = select * from :tmp0 union select * from :src2 where :src2.forestplanstandid not in ( select forestplanstandid from :tmp0 );
    response_t = select * from :tmp1 union select * from :src3 where :src3.forestplanstandid not in (  select forestplanstandid from :tmp1 );

* geometry as text for response message
    for lv_index in 1..record_count(:response_t)
      do
       geom =:response_t.geometry[:lv_index];
       response_t.geometry_text[:lv_index] = :geom.ST_AsText();
    end for ;

/* Creating the final output*/
   out_contractid = :in_contractid;
   out_blocknumber = :in_blocknumber;
   out_decade = :in_decade;

  stands_tt = select forestplanstandid  as forest_plan_stand_id,
                     standnumber as stand_number,
                     standnumberextension as stand_number_extension,
                     'TRUE' as has_overlap_area
                    from
                    :response_t;

  ENDMETHOD.

ENDCLASS.