"! <p class="shorttext synchronized" lang="en">SaveWorkingSiteEndNotification</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveWorkingSiteEndNotification</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zii_cl_si_id730_working_site_e/source/main#start=580,8;end=585,0</p>
CLASS zcl_gis_amdp_id815 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS SaveWorkingSiteEndNotification
      IMPORTING
                VALUE(contractid)       TYPE zmhobject
                VALUE(blocknumber)      TYPE zmhblockno
                VALUE(decade)           TYPE zzostosopvk
                VALUE(fulfilledarea)    TYPE ziidt_id815_wse_gis_save_tab1
                VALUE(unfulfilledarea)  TYPE ziidt_id815_wse_gis_save__tab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id815 IMPLEMENTATION.

  METHOD SaveWorkingSiteEndNotification BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

* local variables
    declare contracts_t table ( contract bigint );
    declare harvestingblocks_t table  ( hvblockid bigint );
    declare planningblocks_t table  ( plblockid bigint );
    declare lv_index int;
    declare lv_st_text string;
    DECLARE no_data_found CONDITION FOR SQL_ERROR_CODE 10001;

* TODO fulfilledarea and unfulfilledarea columns size
* need to clarify, it can be huge, much more than 1000
    declare in_fulfilledarea table (
        fulfilledarea nvarchar( 1000 )
       ,fulfilledareavariant nvarchar( 10 )
       ,supported int
       ,geometry st_geometry
     );
    declare in_unfulfilledarea table (
        unfulfilledarea nvarchar( 1000 )
       ,unfulfilledareavariant nvarchar( 10 )
       ,geometry st_geometry
     );

    declare contract_with_decade string;
    contract_with_decade = CONCAT(:contractid,:decade);


*Validate that theres data
** if no records set the return
    if IS_EMPTY ( :fulfilledarea ) and IS_EMPTY ( :unfulfilledarea )
     then
      SIGNAL no_data_found SET MESSAGE_TEXT = 'No Matching data found';
     END IF ;

* fill in work tables
    in_fulfilledarea = select fulfilledarea,
                              fulfilledareavariant,
                              cast (supported as int) as supported,
                              cast(null as st_geometry) as geometry
                              from :fulfilledarea;
    in_unfulfilledarea = select unfulfilledarea,
                              unfulfilledareavariant,
                              cast(null as st_geometry) as geometry
                              from :unfulfilledarea;


* convert input geometry string to geometry object fulfilledarea
      for lv_index in 1..record_count(:in_fulfilledarea)
        do
          declare lv_poslist string = :in_fulfilledarea.fulfilledarea[:lv_index];
          declare lv_geom st_geometry =  :in_fulfilledarea.geometry[:lv_index];
          declare lv_geom_type string;
          declare lv_variant string = :in_fulfilledarea.fulfilledareavariant[:lv_index];
          --Convert the geom string to geometric object
           if :lv_poslist != CHAR(32)
            then
              call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                 poslist => :lv_poslist,
                 gtype   => :lv_variant,
                 st_text => :lv_st_text,
                 geom_type => :lv_geom_type,
                 geom    => :lv_geom /*set the geom object*/
              );
              --Assign fields
              in_fulfilledarea.geometry[:lv_index] = :lv_geom;
            else
              SIGNAL no_data_found SET MESSAGE_TEXT = 'No Geom string is found';
            end if;
      end for ;

* convert input geometry string to geometry object unfulfilledarea
      for lv_index in 1..record_count(:in_unfulfilledarea)
        do
          declare lv_poslist string = :in_unfulfilledarea.unfulfilledarea[:lv_index];
          declare lv_geom st_geometry =  :in_unfulfilledarea.geometry[:lv_index];
          declare lv_geom_type string;
          declare lv_variant string = :in_unfulfilledarea.unfulfilledareavariant[:lv_index];
          --Convert the geom string to geometric object
           if :lv_poslist != CHAR(32)
            then
              call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                 poslist => :lv_poslist,
                 gtype   => :lv_variant,
                 st_text => :lv_st_text,
                 geom_type => :lv_geom_type,
                 geom    => :lv_geom /*set the geom object*/
              );
              --Assign fields
              in_unfulfilledarea.geometry[:lv_index] = :lv_geom;
            else
                SIGNAL no_data_found SET MESSAGE_TEXT = 'No Geom string is found';
            end if;
      end for ;

    if decade is not null and LENGTH( decade ) > 0 then
        contracts_t = select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :contract_with_decade );
    else
        contracts_t =
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :contractid || '0')
            union
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :contractid || '1')
            union
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :contractid || '2')
            ;
    end if;


    if not is_empty ( :contracts_t ) then
* contract exists, harvesting blocks
*     find harvestingblocks related to contract
        harvestingblocks_t = select HARVESTINGBLOCK.HARVESTINGBLOCKID as hvblockid from MG_KOTKA.HARVESTINGBLOCK
        where HARVESTINGBLOCK.CONTRACTID in ( select contract from :contracts_t )
        and HARVESTINGBLOCK.BLOCKNUMBER is not null and HARVESTINGBLOCK.BLOCKNUMBER = :blocknumber;

*     delete from areas
        delete from MG_KOTKA.FULFILLEDAREA where FULFILLEDAREA.HARVESTINGBLOCKID in ( select hvblockid from :harvestingblocks_t );
        delete from MG_KOTKA.UNFULFILLEDAREA where UNFULFILLEDAREA.HARVESTINGBLOCKID in ( select hvblockid from :harvestingblocks_t );

*     insert harvestingblocks related to areas
        for lv_index in 1..record_count(:harvestingblocks_t)
        do
            declare blockid bigint = :harvestingblocks_t.hvblockid[:lv_index];
            insert into MG_KOTKA.FULFILLEDAREA select
            SYSUUID,
            MG_KOTKA.FULFILLEDAREA_SEQ.nextval,
            null,
            blockid,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            null,
            :in_fulfilledarea.geometry,
            :in_fulfilledarea.supported
            from
            :in_fulfilledarea ;

            insert into MG_KOTKA.UNFULFILLEDAREA select
            SYSUUID,
            MG_KOTKA.FULFILLEDAREA_SEQ.nextval,
            null,
            blockid,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            null,
            :in_unfulfilledarea.geometry
            from
            :in_unfulfilledarea ;
        end for ;
    else
* no contract, planning blocks
*     find planningblocks related to contract
        planningblocks_t = select SW_PLANNINGBLOCK.SW_PLANNINGBLOCKID as plblockid from MG_KOTKA.SW_PLANNINGBLOCK
        where SW_PLANNINGBLOCK.SILVICULTURALORDERID = :contractid
        and SW_PLANNINGBLOCK.BLOCKNUMBER is not null and SW_PLANNINGBLOCK.BLOCKNUMBER = :blocknumber;

*     delete from areas
        delete from MG_KOTKA.FULFILLEDAREA where FULFILLEDAREA.SW_PLANNINGBLOCKID in ( select plblockid from :planningblocks_t );
        delete from MG_KOTKA.UNFULFILLEDAREA where UNFULFILLEDAREA.SW_PLANNINGBLOCKID in ( select plblockid from :planningblocks_t );

*     insert planningblocks related to areas
        for lv_index in 1..record_count(:planningblocks_t)
        do
            declare blockid bigint = :planningblocks_t.plblockid[:lv_index];
            insert into MG_KOTKA.FULFILLEDAREA select
            SYSUUID,
            MG_KOTKA.FULFILLEDAREA_SEQ.nextval,
            null,
            blockid,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            null,
            :in_fulfilledarea.geometry,
            :in_fulfilledarea.supported
            from
            :in_fulfilledarea ;

            insert into MG_KOTKA.UNFULFILLEDAREA select
            SYSUUID,
            MG_KOTKA.FULFILLEDAREA_SEQ.nextval,
            null,
            blockid,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            'MG_KARHU',
            CURRENT_TIMESTAMP,
            null,
            :in_unfulfilledarea.geometry
            from
            :in_unfulfilledarea ;
        end for ;
    end if;


  ENDMETHOD.

ENDCLASS.