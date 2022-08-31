"! <p class="shorttext synchronized" lang="en">SaveWorkingsiteOperationUpdate</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveWorkingsiteOperationUpdate</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger:adt://WSD/sap/bc/adt/oo/classes/zcl_id712_i_wsou/source/main#start=798,0;end=875,10</p>
"! <p class="shorttext synchronized" lang="en">Gtype is always set as pP!</p>
CLASS zcl_gis_amdp_id736 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.


    "! <p class="shorttext synchronized" lang="en"></p>
    "! Storage update logic for HarvestingBlockStorages
    "! @parameter decade | <p class="shorttext synchronized" lang="en">OPTIONAL</p>
    METHODS saveworkingsiteoperationalup_h
      IMPORTING
                VALUE(contractid)       TYPE zmhobject
                VALUE(blocknumber)      TYPE zmhblockno
                VALUE(decade)           TYPE zzostosopvk
                VALUE(request_storages) TYPE zdt_id736_gis_wsou_save_tab
      RAISING   cx_amdp_error
      .


    "! <p class="shorttext synchronized" lang="en"></p>
    "! Storage update logic for SilvicultureBlockStorages
    "! @parameter decade | <p class="shorttext synchronized" lang="en">OPTIONAL</p>
    METHODS saveworkingsiteoperationalup_s
      IMPORTING
                VALUE(contractid)       TYPE zmhobject
                VALUE(blocknumber)      TYPE zmhblockno
                VALUE(decade)           TYPE zzostosopvk
                VALUE(request_storages) TYPE zdt_id736_gis_wsou_save_tab
      RAISING   cx_amdp_error
      .


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id736 IMPLEMENTATION.


  METHOD saveworkingsiteoperationalup_h BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.
    --Local data declarations
    DECLARE lv_index INTEGER;
    DECLARE  lv_contractid string ;
    DECLARE lv_st_text string;
    DECLARE lv_geom_type string;
    DECLARE no_data_found CONDITION FOR SQL_ERROR_CODE 10001;
    --Steps to follow
    select CONCAT(:contractid,:decade) "concat" into lv_contractid default null from dummy;


    --LOOP Request.Storages
    for lv_index in 1..record_count(:request_storages)
      do
       --declare lv_geoloc st_geometry  = :request_storages.geometry[:lv_index];
       declare lv_infotext varchar(500)  = :request_storages.storageinfo[:lv_index];
       declare lv_storage_number bigint  = TO_INTEGER( :request_storages.storagenumber[:lv_index] );

        declare lv_poslist varchar( 10000 ) = :request_storages.geometry[:lv_index];
        declare lv_geoloc st_geometry;
        --Convert the geom string to geometric object
         call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
              poslist => :lv_poslist,
              gtype   => 'pP',
              geom_type => :lv_geom_type,
              st_text => :lv_st_text,
              geom    => :lv_geoloc
            );


       -- Do a select ensuring that theres at least a record to update
       lt_data = SELECT TOP 1 * FROM MG_KOTKA.STORAGE s
                 WHERE s.CONTRACTID=:LV_CONTRACTID and s.STORAGE_NUMBER = :lv_storage_number and s.STATUS=1
                 and s.STORAGEID in (select STORAGEID from MG_KOTKA.HARVESTINGBLOCKSTORAGE
                 where harvestingblockid in
                 (select harvestingblockid from MG_KOTKA.harvestingblock where contractid=:LV_CONTRACTID and blocknumber=:blocknumber));

         IF NOT IS_EMPTY(:lt_data) THEN
           UPDATE MG_KOTKA.STORAGE s set s.GEOLOC = :lv_geoloc,s.INFOTEXT = :lv_infotext
           WHERE s.CONTRACTID=:LV_CONTRACTID and s.STORAGE_NUMBER = :lv_storage_number and s.STATUS=1
           and s.STORAGEID in (select STORAGEID from MG_KOTKA.HARVESTINGBLOCKSTORAGE
          where harvestingblockid in (select harvestingblockid from MG_KOTKA.harvestingblock where contractid=:LV_CONTRACTID and blocknumber=:blocknumber));
         else
          SIGNAL no_data_found SET MESSAGE_TEXT = 'No Matching data found';
         END IF;


    end for ;

  ENDMETHOD.

  METHOD saveworkingsiteoperationalup_s BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

    --Local data declarations
      DECLARE lv_index INTEGER;
      --Steps to follow

      DECLARE lv_st_text string;
      DECLARE lv_geom_type string;
      DECLARE no_data_found CONDITION FOR SQL_ERROR_CODE 10001;

      --LOOP Request.Storages
      for lv_index in 1..record_count(:request_storages)
        do
         declare lv_infotext varchar(500)  = :request_storages.storageinfo[:lv_index];
         declare lv_storage_number bigint  = TO_INTEGER( :request_storages.storagenumber[:lv_index] );

         declare lv_poslist varchar( 10000 ) = :request_storages.geometry[:lv_index];
         declare lv_geoloc st_geometry;
        --Convert the geom string to geometric object
         call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
              poslist => :lv_poslist,
              gtype   => 'pP',
              st_text => :lv_st_text,
              geom_type => :lv_geom_type,
              geom    => :lv_geoloc
            );


          -- Do a select ensuring that theres at least a record to update
         lt_data = SELECT TOP 1 * FROM MG_KOTKA.STORAGE s
                WHERE s.CONTRACTID=:CONTRACTID and s.STORAGE_NUMBER = :lv_storage_number and s.STATUS=1
               and s.STORAGEID in (select STORAGEID from MG_KOTKA.SW_PLANNINGBLOCKSTORAGE
              where SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID=:CONTRACTID and blocknumber=:BLOCKNUMBER));
         IF NOT IS_EMPTY(:lt_data) THEN
           UPDATE MG_KOTKA.STORAGE s set s.GEOLOC = :lv_geoloc,s.INFOTEXT = :lv_infotext
           WHERE s.CONTRACTID=:CONTRACTID and s.STORAGE_NUMBER = :lv_storage_number and s.STATUS=1
           and s.STORAGEID in (select STORAGEID from MG_KOTKA.SW_PLANNINGBLOCKSTORAGE
           where SW_PLANNINGBLOCKID in (select SW_PLANNINGBLOCKID from MG_KOTKA.SW_PLANNINGBLOCK where SILVICULTURALORDERID=:CONTRACTID and blocknumber=:BLOCKNUMBER));
         else
           SIGNAL no_data_found SET MESSAGE_TEXT = 'No Matching data found';
         END IF;
      end for ;
  endmethod.


ENDCLASS.