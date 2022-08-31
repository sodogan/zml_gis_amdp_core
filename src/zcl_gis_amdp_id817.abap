"! <p class="shorttext synchronized" lang="en">SaveWorkingSiteSamplePlot</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveWorkingSiteSamplePlot</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id791_i_wsqc_plant_mng/source/main#start=871,6;end=875,36</p>
CLASS zcl_gis_amdp_id817 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS SaveWorkingSiteSamplePlot
      IMPORTING
                VALUE(contractid)       TYPE zmhobject
                VALUE(blocknumber)      TYPE zmhblockno
                VALUE(decade)           TYPE zzostosopvk
                VALUE(resourceid)       TYPE zzresource
                VALUE(sampleplots)      TYPE ZIIDT_ID817_QC_GIS_SAVE__TAB1
                VALUE(hoppers)          TYPE ZIIDT_ID817_QC_GIS_SAVE__TAB2
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id817 IMPLEMENTATION.

  METHOD SaveWorkingSiteSamplePlot BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

* local variables
    declare contractid_with_decade string;
    declare lv_index int;
    declare lv_st_text string;
    declare lv_geom_type string;
    declare geometrydummy st_geometry;
    declare sampleplots_t table (
      standnumber         nvarchar( 100 ),
      geometryreal        nvarchar( 1000 ),
      geometryrequired    nvarchar( 1000 ),
      geometryhaukka      nvarchar( 1000 ),
      sampleplotnumber    int,
      sampleplottype      int,
      sourceofinspection  nvarchar( 100 ),
      geometryreal_st     st_geometry,
      geometryrequired_st st_geometry,
      geometryhaukka_st   st_geometry
    );
    declare hoppers_t table (
      standnumber       int,
      sampleplotnumber nvarchar( 100 ),
      id               nvarchar( 100 ),
      hoppertype       nvarchar( 100 ),
      infotext         nvarchar( 100 ),
      volume           nvarchar( 100 ),
      geometry         nvarchar( 1000 ),
      geometry_st      st_geometry
    );

    contractid_with_decade = CONCAT(:contractid,:decade);
*prepare staging tables
    sampleplots_t = select standnumber, geometryreal, geometryrequired, geometryhaukka, sampleplotnumber, sampleplottype, sourceofinspection,
                    geometrydummy geometryreal_st, geometrydummy geometryrequired_st, geometrydummy geometryhaukka_st from :sampleplots;

    hoppers_t = select standnumber, sampleplotnumber, id, hoppertype, infotext, volume, geometry, geometrydummy geometry_st from :hoppers;

* setting up sample plots shape objects
* geometryreal
    for lv_index in 1..record_count(:sampleplots_t)
      do
        declare lv_poslist varchar( 1000 );
        declare lv_geoloc st_geometry;

        if LENGTH( :sampleplots_t.geometryreal[:lv_index] ) > 0
        then
            lv_poslist = :sampleplots_t.geometryreal[:lv_index];
            --Convert the geom string to geometric object
            call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                  poslist => :lv_poslist,
                  gtype   => 'pP',
                  geom_type => :lv_geom_type,
                  st_text => :lv_st_text,
                  geom    => :lv_geoloc
               );
            sampleplots_t.geometryreal_st[:lv_index] = lv_geoloc;
        end if;
* geometryrequired
        if LENGTH( :sampleplots_t.geometryrequired[:lv_index] ) > 0
        then
            lv_poslist = :sampleplots_t.geometryrequired[:lv_index];
            --Convert the geom string to geometric object
            call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                  poslist => :lv_poslist,
                  gtype   => 'pP',
                  geom_type => :lv_geom_type,
                  st_text => :lv_st_text,
                  geom    => :lv_geoloc
               );
            sampleplots_t.geometryrequired_st[:lv_index] = lv_geoloc;
        end if;
* geometryhaukka
        if LENGTH( :sampleplots_t.geometryhaukka[:lv_index] ) > 0
        then
            lv_poslist = :sampleplots_t.geometryhaukka[:lv_index];
            --Convert the geom string to geometric object
            call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                  poslist => :lv_poslist,
                  gtype   => 'pP',
                  geom_type => :lv_geom_type,
                  st_text => :lv_st_text,
                  geom    => :lv_geoloc
               );
            sampleplots_t.geometryhaukka_st[:lv_index] = lv_geoloc;
        end if;
    end for;
* setting up hoppers shape objects
* geometryreal
    for lv_index in 1..record_count(:hoppers_t)
      do
        declare lv_poslist varchar( 1000 );
        declare lv_geoloc st_geometry;

        if LENGTH( :hoppers_t.geometry[:lv_index] ) > 0
        then
            lv_poslist = :hoppers_t.geometry[:lv_index];
            --Convert the geom string to geometric object
            call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                  poslist => :lv_poslist,
                  gtype   => 'pP',
                  geom_type => :lv_geom_type,
                  st_text => :lv_st_text,
                  geom    => :lv_geoloc
               );
            hoppers_t.geometry_st[:lv_index] = lv_geoloc;
        end if;
     end for;
    contracts_t = SELECT * FROM MG_KOTKA.CONTRACT WHERE CONTRACTID=:contractid_with_decade;

    if NOT IS_EMPTY( :contracts_t )
    -- harvesting block
    then
        delete from MG_KOTKA.HOPPER where SAMPLEPLOTID in (Select SAMPLEPLOTID from MG_KOTKA.SAMPLEPLOT where
        HARVESTINGSTANDID in (Select HARVESTINGSTANDID from MG_KOTKA.HARVESTINGSTAND where
        HARVESTINGBLOCKID in (Select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID=:CONTRACTID_WITH_DECADE and BLOCKNUMBER=:blocknumber))
        AND (STATUS IS NULL OR STATUS != 3) AND (SOURCEOFINSPECTION IS NULL OR SOURCEOFINSPECTION != 'Haukka'));

        delete from MG_KOTKA.SAMPLEPLOT where
        HARVESTINGSTANDID in (Select HARVESTINGSTANDID from MG_KOTKA.HARVESTINGSTAND where
        HARVESTINGBLOCKID in (Select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID=:CONTRACTID_WITH_DECADE and BLOCKNUMBER=:blocknumber))
        AND (STATUS IS NULL OR STATUS != 3) AND (SOURCEOFINSPECTION IS NULL OR SOURCEOFINSPECTION != 'Haukka');

        -- merging sampleplots

        stage_hv =  select st.standnumber, st.geometryreal, st.geometryrequired, st.geometryhaukka, st.sampleplotnumber, st.sampleplottype, st.sourceofinspection,
                    st.geometryreal_st, st.geometryrequired_st, st.geometryhaukka_st, hv.harvestingstandid, MG_KOTKA.SAMPLEPLOT_SEQ.nextval SAMPLEPLOTID from :sampleplots_t st
                    left join MG_KOTKA.HARVESTINGSTAND hv on hv.HARVESTINGBLOCKID in (Select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID=:CONTRACTID_WITH_DECADE and BLOCKNUMBER=:blocknumber);

        merge into MG_KOTKA.SAMPLEPLOT sp using :stage_hv
                    on ( :stage_hv.standnumber = sp.standnumber or TO_NVARCHAR(sp.harvestingstandid) = :stage_hv.standnumber ) and :stage_hv.sampleplotnumber = sp.sampleplotnumber
        when matched then update set
                      sp.geoloc_real        = :stage_hv.geometryreal_st,
                      sp.geoloc_mj          = :stage_hv.geometryrequired_st,
                      sp.geoloc_haukka      = :stage_hv.geometryhaukka_st,
                      sp.sampleplotnumber   = :stage_hv.sampleplotnumber,
                      sp.sampleplottype     = :stage_hv.sampleplottype,
                      sp.sourceofinspection = :stage_hv.sourceofinspection,
                      sp.harvestingstandid  = :stage_hv.harvestingstandid,
                      sp.updated_on         = CURRENT_TIMESTAMP,
                      sp.resourceid         = :resourceid,
                      sp.status             = 1
                      -- sp.status = rq.status missing field, default 1 ( true )
        when not matched then
            insert(
                SAMPLEPLOTID,
                HARVESTINGSTANDID,
                SW_PLANNINGSTANDID,
                CREATED_BY,
                CREATED_ON,
                UPDATED_BY,
                UPDATED_ON,
                STATUS,
                GEOLOC_REAL,
                GEOLOC_MJ,
                MEASUREDATE,
                MEASURER,
                MEASURERTYPE,
                RADIUS,
                ISGPSLOCATION,
                PLANTCOUNT,
                SAMPLEPLOTNUMBER,
                STANDNUMBER,
                RESOURCEID,
                SAMPLEPLOTTYPE,
                SOURCEOFINSPECTION,
                GEOLOC_HAUKKA
                        )
            values(
                :stage_hv.sampleplotid,
                :stage_hv.harvestingstandid,
                null,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                1,
                :stage_hv.geometryreal_st,
                :stage_hv.geometryrequired_st,
                null,
                null,
                null,
                null,
                null,
                null,
                :stage_hv.sampleplotnumber,
                :stage_hv.standnumber,
                :resourceid,
                :stage_hv.sampleplottype,
                :stage_hv.sourceofinspection,
                :stage_hv.geometryhaukka_st
                        );

        -- merging hoppers

        stage_hp = select hp.standnumber, hp.sampleplotnumber, hp.id, hp.hoppertype, hp.infotext, hp.volume, hp.geometry_st,
        sp.SAMPLEPLOTID, MG_KOTKA.HOPPER_SEQ.nextval HOPPERID from :hoppers_t hp
        left join MG_KOTKA.SAMPLEPLOT sp on sp.STANDNUMBER = hp.standnumber and sp.sampleplotnumber = hp.sampleplotnumber and
        sp.HARVESTINGSTANDID in (Select HARVESTINGSTANDID from MG_KOTKA.HARVESTINGSTAND where
        HARVESTINGBLOCKID in (Select HARVESTINGBLOCKID from MG_KOTKA.HARVESTINGBLOCK where CONTRACTID=:CONTRACTID_WITH_DECADE and BLOCKNUMBER=:blocknumber));

        merge into MG_KOTKA.HOPPER hp using :stage_hp
            on hp.SAMPLEPLOTID = :stage_hp.sampleplotid and hp.HOPPERID = :stage_hp.id
            when matched then update set
                hp.hoppertype = :stage_hp.hoppertype,
                hp.infotext   = :stage_hp.infotext,
                hp.volume     = :stage_hp.volume,
                hp.geoloc     = :stage_hp.geometry_st,
                hp.updated_on = CURRENT_TIMESTAMP
            when not matched then
                insert(
                    GUID,
                    HOPPERID,
                    VOLUME,
                    HOPPERTYPE,
                    GEOLOC,
                    INFOTEXT,
                    SAMPLEPLOTID,
                    CREATED_BY,
                    CREATED_ON,
                    UPDATED_BY,
                    UPDATED_ON
                )
                values(
                NEWUID(),
                :stage_hp.hopperid,
                :stage_hp.volume,
                :stage_hp.hoppertype,
                :stage_hp.geometry_st,
                :stage_hp.infotext,
                :stage_hp.sampleplotid,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                'MG_KARHU',
                CURRENT_TIMESTAMP
                );

    elseif IS_EMPTY( :contracts_t )
    -- silviculture block
    then
        delete from MG_KOTKA.HOPPER where SAMPLEPLOTID in (Select SAMPLEPLOTID from MG_KOTKA.SAMPLEPLOT where
        SW_PLANNINGSTANDID in (Select SW_PLANNINGSTANDID from MG_KOTKA.SW_PLANNINGSTAND where
        SW_PLANNINGBLOCKID in (Select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where CONTRACTID=:CONTRACTID and BLOCKNUMBER=:blocknumber))
        AND (STATUS IS NULL OR STATUS != 3) AND (SOURCEOFINSPECTION IS NULL OR SOURCEOFINSPECTION != 'Haukka'));

        delete from MG_KOTKA.SAMPLEPLOT where
        SW_PLANNINGSTANDID in (Select SW_PLANNINGSTANDID from MG_KOTKA.SW_PLANNINGSTAND where
        SW_PLANNINGBLOCKID in (Select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where CONTRACTID=:CONTRACTID and BLOCKNUMBER=:blocknumber))
        AND (STATUS IS NULL OR STATUS != 3) AND (SOURCEOFINSPECTION IS NULL OR SOURCEOFINSPECTION != 'Haukka');

        -- merging sampleplots

        stage_pl =  select st.standnumber, st.geometryreal, st.geometryrequired, st.geometryhaukka, st.sampleplotnumber, st.sampleplottype, st.sourceofinspection,
                    st.geometryreal_st, st.geometryrequired_st, st.geometryhaukka_st, hv.sw_planningstandid, MG_KOTKA.SAMPLEPLOT_SEQ.nextval SAMPLEPLOTID from :sampleplots_t st
                    left join MG_KOTKA.SW_PLANNINGSTAND hv on hv.SW_PLANNINGBLOCKID in (Select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where CONTRACTID=:CONTRACTID and BLOCKNUMBER=:blocknumber);

        merge into MG_KOTKA.SAMPLEPLOT sp using :stage_pl
                    on ( :stage_pl.standnumber = sp.standnumber or TO_NVARCHAR(sp.harvestingstandid) = :stage_pl.standnumber ) and :stage_pl.sampleplotnumber = sp.sampleplotnumber
        when matched then update set
                      sp.geoloc_real        = :stage_pl.geometryreal_st,
                      sp.geoloc_mj          = :stage_pl.geometryrequired_st,
                      sp.geoloc_haukka      = :stage_pl.geometryhaukka_st,
                      sp.sampleplotnumber   = :stage_pl.sampleplotnumber,
                      sp.sampleplottype     = :stage_pl.sampleplottype,
                      sp.sourceofinspection = :stage_pl.sourceofinspection,
                      sp.sw_planningstandid = :stage_pl.sw_planningstandid,
                      sp.updated_on         = CURRENT_TIMESTAMP,
                      sp.resourceid         = :resourceid,
                      sp.status             = 1
                      -- sp.status = rq.status missing field, default 1 ( true )
        when not matched then
            insert(
                SAMPLEPLOTID,
                HARVESTINGSTANDID,
                SW_PLANNINGSTANDID,
                CREATED_BY,
                CREATED_ON,
                UPDATED_BY,
                UPDATED_ON,
                STATUS,
                GEOLOC_REAL,
                GEOLOC_MJ,
                MEASUREDATE,
                MEASURER,
                MEASURERTYPE,
                RADIUS,
                ISGPSLOCATION,
                PLANTCOUNT,
                SAMPLEPLOTNUMBER,
                STANDNUMBER,
                RESOURCEID,
                SAMPLEPLOTTYPE,
                SOURCEOFINSPECTION,
                GEOLOC_HAUKKA
                        )
            values(
                :stage_pl.sampleplotid,
                null,
                :stage_pl.sw_planningstandid,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                1,
                :stage_pl.geometryreal_st,
                :stage_pl.geometryrequired_st,
                null,
                null,
                null,
                null,
                null,
                null,
                :stage_pl.sampleplotnumber,
                :stage_pl.standnumber,
                :resourceid,
                :stage_pl.sampleplottype,
                :stage_pl.sourceofinspection,
                :stage_pl.geometryhaukka_st
                        );

        -- merging hoppers

        stage_hp = select hp.standnumber, hp.sampleplotnumber, hp.id, hp.hoppertype, hp.infotext, hp.volume, hp.geometry_st,
        sp.SAMPLEPLOTID, MG_KOTKA.HOPPER_SEQ.nextval HOPPERID from :hoppers_t hp
        left join MG_KOTKA.SAMPLEPLOT sp on sp.STANDNUMBER = hp.standnumber and sp.sampleplotnumber = hp.sampleplotnumber and
        sp.SW_PLANNINGSTANDID in (Select SW_PLANNINGSTANDID from MG_KOTKA.SW_PLANNINGSTAND where
        SW_PLANNINGBLOCKID in (Select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where CONTRACTID=:CONTRACTID and BLOCKNUMBER=:blocknumber));

        merge into MG_KOTKA.HOPPER hp using :stage_hp
            on hp.SAMPLEPLOTID = :stage_hp.sampleplotid and hp.HOPPERID = :stage_hp.id
            when matched then update set
                hp.hoppertype = :stage_hp.hoppertype,
                hp.infotext   = :stage_hp.infotext,
                hp.volume     = :stage_hp.volume,
                hp.geoloc     = :stage_hp.geometry_st,
                hp.updated_on = CURRENT_TIMESTAMP
            when not matched then
                insert(
                    GUID,
                    HOPPERID,
                    VOLUME,
                    HOPPERTYPE,
                    GEOLOC,
                    INFOTEXT,
                    SAMPLEPLOTID,
                    CREATED_BY,
                    CREATED_ON,
                    UPDATED_BY,
                    UPDATED_ON
                )
                values(
                NEWUID(),
                :stage_hp.hopperid,
                :stage_hp.volume,
                :stage_hp.hoppertype,
                :stage_hp.geometry_st,
                :stage_hp.infotext,
                :stage_hp.sampleplotid,
                'MG_KARHU',
                CURRENT_TIMESTAMP,
                'MG_KARHU',
                CURRENT_TIMESTAMP
                );

    end if;

  ENDMETHOD.

ENDCLASS.