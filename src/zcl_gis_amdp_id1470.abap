"! <p class="shorttext synchronized" lang="en">SaveActualBlock</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveActualBlock</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/zkaato_query_dlo/source/main#start=202,2;end=212,9 </p>
CLASS zcl_gis_amdp_id1470 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS save_actual_block
      IMPORTING
                VALUE(actual_block_order_id)  TYPE   string
                VALUE(contract_id)            TYPE   zmhobject
                VALUE(silvicultural_order_id) TYPE   zmhobject
                VALUE(block_number)           TYPE   zmhblockno
                VALUE(action)                 TYPE   int4
                VALUE(actual_geometries)      TYPE   zpractual_geometrytype_tab
      EXPORTING
*/* Not Needed               VALUE(status)                 TYPE int4  "if status is 0, write error field to variable
*/* Not Needed                 VALUE(error)                  TYPE string
                VALUE(output_t)               TYPE zprresponse_savetype_tab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1470 IMPLEMENTATION.

  METHOD save_actual_block BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

* local variables
    declare actualid int;
    declare lv_index int;
    declare lv_st_text string;
    declare lv_silviculturalorderid bigint;
    declare lv_contractid BIGINT;
    declare invalid_action CONDITION FOR SQL_ERROR_CODE 10001;

**Validate the Action- can only be 1 or 2
    if :action > 2
     then
      SIGNAL invalid_action SET MESSAGE_TEXT = 'Invalid Action-only 1 and 2 are possible';
    end if;

   lv_contractid = TO_BIGINT(contract_id);

** if SILVICULTURALORDERID is empty string then set it to null
   if LENGTH( :silvicultural_order_id ) > 1
     then
      lv_silviculturalorderid = TO_BIGINT( :silvicultural_order_id );
   else
     lv_SILVICULTURALORDERID = null;
   end  if;

    --Loop the table to set the geometry
      for lv_index in 1..record_count(:actual_geometries)
        do
          declare lv_poslist string = :actual_geometries.geometry[:lv_index];
          declare lv_variant_name varchar( 5 ) = :actual_geometries.variantname[:lv_index];
          declare lv_geom st_geometry =  :actual_geometries.geom[:lv_index];
          declare lv_geom_type string =  :actual_geometries.geom_type[:lv_index];
          --Convert the geom string to geometric object
           call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                poslist => :lv_poslist,
                gtype   => :lv_variant_name,
                st_text => :lv_st_text,
                geom_type => :lv_geom_type,
                geom    => :lv_geom /*set the geom object*/
              );

         --Assign fields
         actual_geometries.geom[:lv_index] = :lv_geom;
         actual_geometries.geom_type[:lv_index] = :lv_geom_type;
      end for ;

* insert or update
    if :action = 1
    then
    --Logic change 20.4.2022 Always delete existing ACTUALBLOCK and ACTUALGEOMETRY rows from database before insert
      delete from GISDATA.ACTUALGEOMETRY where ACTUALGEOMETRY.ACTUALBLOCKID IN (
          select ACTUALBLOCK.ACTUALBLOCKID from GISDATA.ACTUALBLOCK
          where ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
          and ACTUALBLOCK.BLOCKNUMBER = :block_number);
      delete from GISDATA.ACTUALBLOCK
          where ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
          and ACTUALBLOCK.BLOCKNUMBER = :block_number;

      select ACTUALBLOCKID into actualid default null from GISDATA.ACTUALBLOCK where
           ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
           and ACTUALBLOCK.CONTRACTID = :contract_id
           and COALESCE(ACTUALBLOCK.SILVICULTURALORDERID, -1) = COALESCE(:lv_silviculturalorderid, -1)
           and ACTUALBLOCK.BLOCKNUMBER = :block_number;

      if :actualid is not null
      then
* update actual block
          update GISDATA.ACTUALBLOCK set
          ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id,
          ACTUALBLOCK.CONTRACTID = :contract_id,
          ACTUALBLOCK.SILVICULTURALORDERID = :lv_silviculturalorderid,
          ACTUALBLOCK.BLOCKNUMBER = :block_number,
          ACTUALBLOCK.UPDATED_ON = CURRENT_TIMESTAMP
          ;
      else
* insert actual block
          insert into GISDATA.ACTUALBLOCK values (
          GISDATA.ACTUALBLOCK_SEQ.nextval,
          :actual_block_order_id,
          :contract_id,
          :lv_silviculturalorderid,
          :block_number,
          'zcl_gis_amdp_id1470',
          CURRENT_TIMESTAMP,
          'zcl_gis_amdp_id1470',
          CURRENT_TIMESTAMP );

          select ACTUALBLOCKID into actualid default null from GISDATA.ACTUALBLOCK where
          ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
          and ACTUALBLOCK.CONTRACTID = :contract_id
          and COALESCE(ACTUALBLOCK.SILVICULTURALORDERID, -1) = COALESCE(:lv_silviculturalorderid, -1)
          and ACTUALBLOCK.BLOCKNUMBER = :block_number;
      end if;
* insert actual geometries
      insert into GISDATA.ACTUALGEOMETRY select
      GISDATA.ACTUALGEOMETRY_SEQ.nextval,
      :actualid,
      gps_quality,
      logging_form_code,
      geom,
      'zcl_gis_amdp_id1470',
      CURRENT_TIMESTAMP,
      'zcl_gis_amdp_id1470',
      CURRENT_TIMESTAMP from :actual_geometries;

* delete
    elseif :action = 2
    then

      delete from GISDATA.ACTUALGEOMETRY where ACTUALGEOMETRY.ACTUALBLOCKID IN (
          select ACTUALBLOCK.ACTUALBLOCKID from GISDATA.ACTUALBLOCK
          where ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
          and ACTUALBLOCK.BLOCKNUMBER = :block_number);
      delete from GISDATA.ACTUALBLOCK
          where ACTUALBLOCK.ACTUALBLOCKORDERID = :actual_block_order_id
          and ACTUALBLOCK.BLOCKNUMBER = :block_number;

    end if;

* success output
     output_t = select :actual_block_order_id as actual_block_order_id,
                       :contract_id as contract_id ,
                       :lv_silviculturalorderid as silvicultural_order_id,
                       :block_number as block_number
                       from dummy;

* error output on catch exception the same but status is false and error message filled in
**Success message as 1


  ENDMETHOD.

ENDCLASS.