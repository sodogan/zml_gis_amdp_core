"! <p class="shorttext synchronized" lang="en">GetWorkingSiteOperational</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteOperational</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger:adt://WSD/sap/bc/adt/oo/classes/zcl_id745_wso_harvesting/source/main#start=1880,0;end=1921,0</p>
"! <p class="shorttext synchronized" lang="en">TODO: Test_area_number is unknown</p>
"! <p class="shorttext synchronized" lang="en">Do we need to convert Geometry to GML</p>
CLASS zcl_gis_amdp_id744 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">For SilviCulture</p>
    "! Logic to get silviculture block spatial data from database-ZII_DT_ID744_WSOGISRESPONSE_SE
    "! @parameter contractid | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter blocknumber | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decade | <p class="shorttext synchronized" lang="en">OPTIONAL</p>
    "! @parameter logyonly | <p class="shorttext synchronized" lang="en">OPTIONAL-Default empty</p>
    "! @parameter sampleplotlevel | <p class="shorttext synchronized" lang="en">OPTIONAL DEFAULT 9999</p>
    "! @parameter response_stand | <p class="shorttext synchronized" lang="en"></p>
    METHODS getworkingsiteoperational_s
      IMPORTING
                VALUE(contractid)      TYPE zmhobject" ContractID = contractid + decade
                VALUE(blocknumber)     TYPE zmhblockno
                VALUE(decade)          TYPE zzostosopvk
                VALUE(logyonly)        TYPE zzlogy
                VALUE(sampleplotlevel) TYPE int4 DEFAULT 0
      EXPORTING
                VALUE(response_stand)  TYPE zdt_id744_wsogisrespons_tab
                VALUE(sampleplots)     TYPE zdt_id744_wsogisrespon_tab2
      RAISING   cx_amdp_error. "zgisamdp_id744_resp_tt.

    "! <p class="shorttext synchronized" lang="en">For Harvesting</p>
    "! Logic to get harvesting block spatial data from database
    "! @parameter contractid | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter blocknumber | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decade | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter logyonly | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter sampleplotlevel | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter response_stand | <p class="shorttext synchronized" lang="en"></p>
    METHODS getworkingsiteoperational_h
      IMPORTING
                VALUE(contractid)       TYPE zmhobject" ContractID = contractid + decade
                VALUE(blocknumber)      TYPE zmhblockno
                VALUE(decade)           TYPE zzostosopvk
                VALUE(logyonly)         TYPE zzlogy
                VALUE(sampleplotlevel)  TYPE int4 DEFAULT 0
      EXPORTING
                VALUE(response_stand)   TYPE  zdt_id744_wsogisrespons_tab
                VALUE(sampleplots)      TYPE  zdt_id744_wsogisrespon_tab2
                VALUE(response_storage) TYPE  zdt_id744_wsogisrespon_tab1
      RAISING   cx_amdp_error .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id744 IMPLEMENTATION.




  METHOD getworkingsiteoperational_s BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING
                            zcl_gis_amdp_base=>get_mgkotka_sw_planningblock
                            zcl_gis_amdp_base=>get_mgkotka_logy_silviblock
                            zcl_gis_amdp_base=>get_mvk_stand
                            zcl_gis_amdp_base=>findsampleplotswithStandid
                            zcl_gis_amdp_util=>geoshape_to_xml
                            .

    --Local data declarations
       declare GV_DEFAULT_SAMPLEPLOT_LEVEL INTEGER default 0;
       declare lv_contractid BIGINT;
       declare lv_contractid_string string;
       declare lv_index INTEGER;
       declare lv_plot_index INTEGER;
       declare lv_number_of_stands integer;
       declare lv_fertility_class nvarchar( 2 );
       declare lv_development_class nvarchar( 2 );
       declare lv_soil_type  nvarchar( 2 );
       declare lv_logy_code varchar( 75 );
       declare lv_geometry_string STRING;
       declare lv_label_position STRING;

     --conversion to string
       declare lv_blocknumber string;
     --Cast the type to the string type
       SELECT CAST (:blocknumber AS VARCHAR) "cast"
           into lv_blocknumber
           FROM DUMMY;



      --Steps to follow

     --Check whether the decade is supplied
      --CONTRACTID=request.CONTRACTID+request.DECADE
        select CONCAT(:contractid,:decade) "concat" into  lv_contractid_string from dummy;


       --convert to bigint
       SELECT TO_BIGINT (lv_contractid_string) "to int"  into lv_contractid  FROM DUMMY;


      --FIND SW_PLANNINGBLOCK: from MG_KOTKA.SW_PLANNINGBLOCK
        call "ZCL_GIS_AMDP_BASE=>GET_MGKOTKA_SW_PLANNINGBLOCK"
                 ( contractid => :lv_contractid
                  ,blocknumber => :blocknumber
                  ,planning_table => :lt_sw_planningblock
                 );

      --FIND LOGY_OF_SW_PLANNINGBLOCK: Get Data for LOGY!

        call "ZCL_GIS_AMDP_BASE=>GET_MGKOTKA_LOGY_SILVIBLOCK"
                 ( contractid => lv_contractid
                  ,blocknumber => :blocknumber
                 , logy_silvi_block_table => :lt_logy_silvi_block
                 );

      --IF SAMPLEPLOTLEVEL has value > 0
        if :sampleplotlevel > :GV_DEFAULT_SAMPLEPLOT_LEVEL
          then
            call mg_kotka.createsampleplots(
                  IN_CONTRACTID => lv_contractid,
                  IN_SILVICULTURALORDERID =>0,--pass 0
                  IN_BLOCKNUMBER =>:blocknumber ,
                  IN_SAMPLEPLOTLEVEL => :sampleplotlevel
                );
        end if;


      --IF LOGYONLY is set  Fill the data and return
        IF LENGTH( :LOGYONLY ) > 0
         then
           IF  NOT IS_EMPTY ( :lt_logy_silvi_block  )
            then
              select top 1 logy_code
              into lv_logy_code
              from :lt_logy_silvi_block;
           end if;
           :response_stand.INSERT((:lv_contractid, :lv_blocknumber, null,null, null, null,null, null, null,null,null,null,:lv_logy_code));
           return;
        end if;

      --FIND SW_PLANNINGSTAND: join with the LT_SW_PLANNINGBLOCK line 97
        lt_sw_planningstands = SELECT stand.forestplan_standid,
                                      stand.standnumber,
                                      stand.SW_PLANNINGSTANDID,
                                      stand.geoloc
                                   FROM "MG_KOTKA"."SW_PLANNINGSTAND" as stand
                                 INNER JOIN :LT_SW_PLANNINGBLOCK AS block
                                 on stand.SW_PLANNINGBLOCKID = block.PLANNING_BLOCKID
                                   where stand.GEOLOC IS NOT NULL AND stand.STATUS != 3;

    --LOOP SW_PLANNINGSTANDS
       for lv_index in 1..record_count(:lt_sw_planningstands)
         do
          declare lv_forestplan_standid nvarchar( 10 ) = :lt_sw_planningstands.forestplan_standid[:lv_index];
          declare lv_standnumber varchar( 10 ) = :lt_sw_planningstands.standnumber[:lv_index];
          declare lv_planningstandid bigint = :lt_sw_planningstands.SW_PLANNINGSTANDID[:lv_index];
          declare lv_geom st_geometry = :lt_sw_planningstands.geoloc[:lv_index];
          /*declare lv_geometry_string string =  TO_NCLOB(:lv_geom.ST_AsWKT());*/
          declare lv_centroid st_geometry = :lv_geom.ST_Centroid();
          declare lv_area string = :lv_geom.ST_Area();

           /*Convert Geometry to GML */
          call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:lv_geom,
            st_text=>:lv_geometry_string
          );
          call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:lv_centroid,
            st_text=>:lv_label_position
          );
          if  lv_forestplan_standid is not null
             then
                  call "ZCL_GIS_AMDP_BASE=>GET_MVK_STAND"
                 ( stand_id => :lv_forestplan_standid
                  ,stand_table => :lt_stand_table
                 );
                  IF NOT IS_EMPTY( :lt_stand_table)
                    THEN
                      lv_fertility_class = :lt_stand_table.fertility_class[1];
                      lv_development_class = :lt_stand_table.development_class[1];
                      lv_soil_type   = :lt_stand_table.soil_type[1];
                  end if ;
              --FIND SAMPLEPLOTS of the stand:
                  call "ZCL_GIS_AMDP_BASE=>FINDSAMPLEPLOTSWITHSTANDID"
                  (
                   stand_id => :lv_forestplan_standid
                   ,matching_sampleplots_table => :lt_matching_sample_plots
                  );
                --LOOP SAMPLEPLOTS
                     for lv_plot_index in 1..record_count(:lt_matching_sample_plots)
                      do
                         declare lv_geometry st_geometry  = :lt_matching_sample_plots.geoloc_mj[:lv_plot_index];
                         declare lv_geometry_string string = :lt_matching_sample_plots.geoloc_mj_string[:lv_plot_index];
                         -- FINAL OUTPUT-Create SamplePlots
                        /*TODO: Test_area_number is unknown?*/
                        :sampleplots.INSERT((:lv_standnumber,1,:lv_geometry_string));
                     end for ;
             end if ;
            -- FINAL OUTPUT-Create Response.Stand- ref to zgisamdp_id744_resp_s
           :response_stand.INSERT((:lv_contractid, :lv_blocknumber, :lv_standnumber,:lv_geometry_string,  :lv_forestplan_standid,:lv_area, :lv_fertility_class, :lv_development_class,:lv_soil_type,:lv_label_position ,null,null,:lv_logy_code));

       end for ;




  ENDMETHOD.

  METHOD getworkingsiteoperational_h BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING
                            ZCL_GIS_AMDP_BASE=>get_mgkotka_harvesting_block
                            zcl_gis_amdp_base=>get_mgkotka_logy_harvestblock
                            zcl_gis_amdp_base=>get_mvk_stand
                            zcl_gis_amdp_base=>findsampleplotswithStandid
                            zcl_gis_amdp_base=>findstorageswithcontractid
                            zcl_gis_amdp_util=>geoshape_to_xml
                            .

    --Local data declarations
       declare GV_DEFAULT_SAMPLEPLOT_LEVEL INTEGER default 0;
       declare lv_contractid BIGINT;
       declare lv_contractid_string string;
       declare lv_index INTEGER;
       declare lv_plot_index INTEGER;
       declare lv_number_of_stands integer;
       declare lv_fertility_class nvarchar( 2 );
       declare lv_development_class nvarchar( 2 );
       declare lv_soil_type  nvarchar( 2 );
       declare lv_logy_code varchar( 75 );
       declare lv_geometry_string STRING;
       declare lv_label_position STRING;

     --conversion to string
       declare lv_blocknumber string;
     --Cast the type to the string type
       SELECT CAST (:blocknumber AS VARCHAR) "cast"
           into lv_blocknumber
           FROM DUMMY;



      --Steps to follow

      --Check whether the decade is supplied
      --CONTRACTID=request.CONTRACTID+request.DECADE
        select CONCAT(:contractid,:decade) "concat" into  lv_contractid_string from dummy;


        SELECT TO_BIGINT (lv_contractid_string) "to int"  into lv_contractid  FROM DUMMY;

      --FIND HARVESTINGBLOCK: from MG_KOTKA.HARVESTINGBLOCK
        call "ZCL_GIS_AMDP_BASE=>GET_MGKOTKA_HARVESTING_BLOCK"
                 ( contractid => :lv_contractid
                  ,blocknumber => :blocknumber
                  ,harvest_block_table => :lt_harvestingblock
                 );

      --FIND LOGY_OF_HARVESTBLOCK: Get Data for LOGY!
        call "ZCL_GIS_AMDP_BASE=>GET_MGKOTKA_LOGY_HARVESTBLOCK"
                 ( contractid => lv_contractid
                  ,blocknumber => :blocknumber
                 , logy_harvest_block_table => :lt_logy_harvest_block
                 );


        if :sampleplotlevel > :GV_DEFAULT_SAMPLEPLOT_LEVEL
          then
            call mg_kotka.createsampleplots(
                  IN_CONTRACTID => lv_contractid,
                  IN_SILVICULTURALORDERID =>0,--pass 0
                  IN_BLOCKNUMBER =>:blocknumber ,
                  IN_SAMPLEPLOTLEVEL => :sampleplotlevel
                );
        end if;

      --IF LOGYONLY is set  Fill the data and return
        IF LENGTH( :LOGYONLY ) > 0
         then
           IF NOT IS_EMPTY ( :lt_logy_harvest_block  )
            then
               select top 1 logy_code
               into lv_logy_code
               from :lt_logy_harvest_block ;
           end if;
           :response_stand.INSERT((:lv_contractid, :lv_blocknumber, null,null, null, null,null, null, null,null,null,null,:lv_logy_code));
           return;
        end if;

          --FIND HARVESTINGSTAND: join with the LT_HARVESTINGBLOCK
        lt_harvestingstands = SELECT stand.forestplan_standid,
                                      stand.standnumber,
                                      stand.harvestingstandid,
                                      stand.geoloc
                                   FROM "MG_KOTKA"."HARVESTINGSTAND" as stand
                                 INNER JOIN :LT_HARVESTINGBLOCK AS block
                                 on stand.harvestingBLOCKID = block.Harvesting_BLOCKID
                                   where stand.GEOLOC IS NOT NULL AND stand.STATUS != 3;

    --LOOP HARVESTINGSTANDS
       for lv_index in 1..record_count(:lt_harvestingstands)
         do
          declare lv_forestplan_standid nvarchar( 10 ) = :lt_harvestingstands.forestplan_standid[:lv_index];
          declare lv_standnumber varchar( 10 ) = :lt_harvestingstands.standnumber[:lv_index];
          declare lv_HARVESTINGSTANDID bigint = :lt_harvestingstands.HARVESTINGSTANDID[:lv_index];
          declare lv_geom st_geometry = :lt_harvestingstands.geoloc[:lv_index];
          declare lv_area string = :lv_geom.ST_Area();
          declare lv_centroid st_geometry = :lv_geom.ST_Centroid();
           /*Convert Geometry to GML */
          call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:lv_geom,
            st_text=>:lv_geometry_string
          );
          call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:lv_centroid,
            st_text=>:lv_label_position
          );

           if  lv_forestplan_standid is not null
             then
                  call "ZCL_GIS_AMDP_BASE=>GET_MVK_STAND"
                 ( stand_id => :lv_forestplan_standid
                  ,stand_table => :lt_stand_table
                 );
                  IF NOT IS_EMPTY( :lt_stand_table)
                    THEN
                      lv_fertility_class = :lt_stand_table.fertility_class[1];
                      lv_development_class = :lt_stand_table.development_class[1];
                      lv_soil_type   = :lt_stand_table.soil_type[1];
                   end if ;
                   --FIND SAMPLEPLOTS of the stand:
                   call "ZCL_GIS_AMDP_BASE=>FINDSAMPLEPLOTSWITHSTANDID"
                    (
                      stand_id => :lv_forestplan_standid
                      ,matching_sampleplots_table => :lt_matching_sample_plots
                     );
                    --LOOP SAMPLEPLOTS
                     for lv_plot_index in 1..record_count(:lt_matching_sample_plots)
                      do
                         declare lv_geometry st_geometry  = :lt_matching_sample_plots.geoloc_mj[:lv_plot_index];
                         declare lv_geometry_string string = :lt_matching_sample_plots.geoloc_mj_string[:lv_plot_index];
                         -- FINAL OUTPUT-Create SamplePlots
                        :sampleplots.INSERT((:lv_standnumber,1,:lv_geometry_string));
                     end for ;
            end if ;
            -- FINAL OUTPUT-Create Response.Stand- ref to zgisamdp_id744_resp_s
           :response_stand.INSERT((:lv_contractid, :lv_blocknumber, :lv_standnumber,:lv_geometry_string,  :lv_forestplan_standid,:lv_area, :lv_fertility_class, :lv_development_class,:lv_soil_type,:lv_label_position ,null,null,:lv_logy_code));

       end for ;
    -- Need to add the storages
     call "ZCL_GIS_AMDP_BASE=>FINDSTORAGESWITHCONTRACTID"
                 ( contractid => :contractid
                  ,storage_table => :lt_storage_table
                 );


      SELECT CAST (:blocknumber AS VARCHAR) "cast"
               into lv_blocknumber
               FROM DUMMY;

    response_storage = SELECT  CAST (storage_number AS VARCHAR) as storagenumber,
                               Geometry
                           from :lt_storage_table;


  ENDMETHOD.

ENDCLASS.