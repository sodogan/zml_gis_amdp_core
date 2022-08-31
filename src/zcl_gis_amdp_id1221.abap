"! <p class="shorttext synchronized" lang="en">SaveResourceLocation</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveResourceLocation</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/z_paattyneet_proxy_call/source/main#start=459,2;end=463,42</p>
CLASS zcl_gis_amdp_id1221 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS call_ID1221 IMPORTING
                                VALUE(resourceloc_request_tt) TYPE ziidt_id1221_gis_resloc_tab
                                iref_log_wrapper              TYPE REF TO zcl_application_log_wrapper.

    METHODS save_resource_location
      IMPORTING
                VALUE(resourceloc_request_tt) TYPE ziidt_id1221_gis_resloc_tab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1221 IMPLEMENTATION.


  METHOD call_id1221.
    BREAK-POINT ID zml_gis_amdp.
**First Getimestamp should be in timestampl format like lv_geotimestamp =  |20190708054349|.
* then format like   DATA(lv_timestamp_str)  = |{ lv_geotimestamp TIMESTAMP =  ISO } | .
* So just before transforming - |2019-07-08T05:43:49.556Z| or |2019-07-08T05:43:49|
* Notice the T in between
    TRY.
        LOOP AT resourceloc_request_tt ASSIGNING FIELD-SYMBOL(<lfs_resourceloc>).
* check the timestamp
*           DATA(lv_timestamp) = |{ <lfs_resourceloc>-geotimestamp TIMESTAMP =  ISO } | .
            DATA(lv_timestamp)  =  zcl_gis_abap_trigger_utility=>transform_timestamp_forhana( geo_timestamp = <lfs_resourceloc>-geotimestamp ).
          <lfs_resourceloc>-geotimestamp = lv_timestamp.
        ENDLOOP.

** Now we can call
        me->save_resource_location( resourceloc_request_tt = resourceloc_request_tt ).
      CATCH cx_root INTO DATA(lref_cx_root).
       ROLLBACK WORK."All the changes needs to be rolled back
        iref_log_wrapper->add_free_text( type = 'E' string = lref_cx_root->get_text( ) ).
        IF iref_log_wrapper->something_is_put_to_log( ) = abap_true.
          iref_log_wrapper->write( ).
        ENDIF.
    ENDTRY.

  ENDMETHOD.

  METHOD save_resource_location BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                             USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

* Rquest XML
*                    <ResourceLocation>
*                        <!-- Mandatory resource ID in the WoodForce system -->
*                        <ResourceId>262501</ResourceId>
*                        <!-- Optional wood purchase contract's ID -->
*                        <ContractId>123456789</ContractId>
*                        <!-- Mandatory decade of the wood purchase contract if ContractId was provided -->
*                        <Decade>1</Decade>
*                        <!-- Optional wood purchase block's number -->
*                        <BlockNumber>1</BlockNumber>
*                        <!-- Mandatory timestamp of the geometry point -->
*                        <GeometryTimestamp>2019-07-08T05:43:49.556Z</GeometryTimestamp>
*                        <!-- Mandatory geometry point -->
*                        <Geometry>
*                            <gml:pos>327656.0 6822418.0</gml:pos>
*                        </Geometry>
*
* Response XML
*                <ResourceLocation>
*                    <!-- Copy of provided resource ID -->
*                    <ResourceId>262501</ResourceId>
*                    <!-- Copy of provided contract ID -->
*                    <ContractId>123456789</ContractId>
*                    <!-- Copy of provided contract decade -->
*                    <Decade>1</Decade>
*                    <!-- Copy of provided wood purchase block's number -->
*                    <BlockNumber>1</BlockNumber>
*                    <!-- 1 means resource location was inserted/updated -->
*                    <Status>1</Status>
*                </ResourceLocation>

    --Local Data Declarations

      declare lv_index int;
      declare lv_st_text string;
      declare no_data_found CONDITION FOR SQL_ERROR_CODE 10001;

-- TODO in_geometry 10000, is it enough?
* input parameters
      declare input_t table (
       in_resourceid nvarchar ( 20 )
      ,in_contractid nvarchar ( 20 )
      ,in_decade nvarchar
      ,in_blocknumber int
      ,in_geotimestmp nvarchar ( 50 )
      ,in_geometry nvarchar( 10000 )
      ,in_geom st_geometry
      );


      declare output_t table (
       out_resourceid nvarchar( 20 )
      ,out_contractid nvarchar ( 20 )
      ,out_decade nvarchar
      ,out_blocknumber int
      ,out_status int
      ,out_error nvarchar
      );

*Validate that theres data
** if no records set the return
    if IS_EMPTY ( :resourceloc_request_tt )
     then
       SIGNAL no_data_found SET MESSAGE_TEXT = 'No Input data found';
     END IF ;


* Get the input
     input_t = select resource_id as in_resourceid,
                      contract_id as in_contractid,
                      decade as in_decade,
                      block_num as in_blocknumber,
                      geotimestamp as in_geotimestmp,
                      geometry as in_geometry,
                      cast(null as st_geometry) as in_geom
                      from :resourceloc_request_tt;


* convert input geometry string to geometry object
      for lv_index in 1..record_count(:input_t)
        do
          declare lv_poslist string = :input_t.in_geometry[:lv_index];
          declare lv_geom st_geometry =  :input_t.in_geom[:lv_index];
          declare lv_geom_type string;
          --Convert the geom string to geometric object
           if :lv_poslist != CHAR(32)
            then
              call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
                 poslist => :lv_poslist,
                 gtype   => 'pP', -- assuming Point only
                 st_text => :lv_st_text,
                 geom_type => :lv_geom_type,
                 geom    => :lv_geom /*set the geom object*/
              );
              --Assign fields
              input_t.in_geom[:lv_index] = :lv_geom;
            else
             SIGNAL no_data_found SET MESSAGE_TEXT = 'No Geometry data found';
            end if;
      end for ;


* update/insert GISDATA.WF_RESOURCE_LOCATION
      merge into GISDATA.WF_RESOURCE_LOCATION using :input_t on WF_RESOURCE_LOCATION.RESOURCEID = :input_t.in_resourceid
      and WF_RESOURCE_LOCATION.LOCATION_TIME = TO_TIMESTAMP( :input_t.in_geotimestmp, 'YYYY-MM-DD HH24:MI:SS.FF3' )
      when matched then update set
      WF_RESOURCE_LOCATION.CONTRACTID = case
      when :input_t.in_contractid is not null and :input_t.in_decade is not null then CONCAT( :input_t.in_contractid, :input_t.in_decade ) else WF_RESOURCE_LOCATION.CONTRACTID end,
      WF_RESOURCE_LOCATION.SILVICULTURALORDERID = case
      when :input_t.in_contractid is not null and :input_t.in_decade is null then :input_t.in_contractid else WF_RESOURCE_LOCATION.SILVICULTURALORDERID end,
      WF_RESOURCE_LOCATION.BLOCKNUMBER = case
      when :input_t.in_blocknumber is not null then :input_t.in_blocknumber else WF_RESOURCE_LOCATION.BLOCKNUMBER end,
      WF_RESOURCE_LOCATION.GEOLOC = :input_t.in_geom
      when not matched then insert values (
      :input_t.in_resourceid,
      TO_TIMESTAMP( :input_t.in_geotimestmp, 'YYYY-MM-DD HH24:MI:SS.FF3' ),
      case
      when :input_t.in_contractid is not null and :input_t.in_decade is not null then CONCAT( :input_t.in_contractid, :input_t.in_decade ) else null end,
      case
      when :input_t.in_contractid is not null and :input_t.in_decade is null then :input_t.in_contractid else null end,
      :input_t.in_blocknumber,
      :input_t.in_geom
      );

* success output
      output_t =
            select in_resourceid out_resourceid,
                  in_contractid out_contractid,
                  in_decade out_decade,
                  in_blocknumber out_blocknumber,
                  1 as out_status,
                  null as out_error
                  from :input_t;


*if exception is thrown then status will be  failed

  ENDMETHOD.

ENDCLASS.