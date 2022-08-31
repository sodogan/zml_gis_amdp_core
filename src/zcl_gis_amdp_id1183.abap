"! <p class="shorttext synchronized" lang="en">ValidateForestUse</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/zpi1_id1183_requestsend/source/main#start=92,0;end=97,0 </p>
CLASS zcl_gis_amdp_id1183 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS validate_forest_use
      IMPORTING
                VALUE(in_contractid)                TYPE zmhobject
                VALUE(in_decade)                    TYPE zzostosopvk
                VALUE(in_harvesting_block_number)   TYPE string
                VALUE(in_variant)                   TYPE string
                VALUE(in_geometry)                  TYPE string
                VALUE(in_start_date)                TYPE string
                VALUE(in_end_date)                  TYPE string
      EXPORTING
                VALUE(out_contractid)                 TYPE zmhobject
                VALUE(out_decade)                     TYPE zzostosopvk
                VALUE(out_harvesting_block_number)    TYPE string
                VALUE(out_variant)                    TYPE string
                VALUE(out_start_date)                 TYPE string
                VALUE(out_end_date)                   TYPE string
                VALUE(harvesting_stands)              TYPE ziidtid1183_validate_for_tab4
                VALUE(forest_use_declaration_stands)  TYPE ziidtid1183_validate_for_tab1
                VALUE(is_valid)                       TYPE  string
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_gis_amdp_id1183 IMPLEMENTATION.


  METHOD validate_forest_use BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING zcl_gis_amdp_util=>geoxml_to_geoshape
                            .
-- output
    declare HarvestingStandResponse table (
    standNumber nvarchar( 100 ),
    validationErrorDate nvarchar( 10 ),
    validationErrorToBeOutdated nvarchar( 10 ),
    validationErrorStatus nvarchar( 10 ),
    validationErrorGeometry nvarchar( 10 ),
    validationErrorGeometryText nvarchar( 100 ),
    validationErrorHarvMethod nvarchar( 10 ),
    validationErrorHarvMethodText nvarchar( 100 ),
    validationErrorText nvarchar( 100 ),
    errorGeometry nvarchar( 10000 )
    );

    declare ForestUseDeclarationStandResp table (
    standNumber nvarchar( 100 ),
    cuttingMethod nvarchar( 100 ),
    forestUseDeclStatus nvarchar( 100 ),
    forestUseDeclStatusDescription nvarchar( 100 ),
    forestUseDeclDate nvarchar( 100 ),
    forestUseDeclId nvarchar( 100 ),
    forestUseDeclObjectId bigint,
    forestUseDeclReference nvarchar( 100 ),
    validationErrorDate nvarchar( 10 ),
    validationErrorToBeOutdated nvarchar( 10 ),
    validationErrorStatus nvarchar( 10 ),
    validationErrorGeometry nvarchar( 10 ),
    validationErrorGeometryText nvarchar( 100 ),
    validationErrorHarvMethod nvarchar( 10 ),
    validationErrorHarvMethodText nvarchar( 100 ),
    validationErrorText nvarchar( 100 ),
    geometry nvarchar( 10000 )
    );
    declare sapPurchaseId string;
    declare sapPurchaseDecade string;
    declare lv_index int;
    declare i, j int;
    declare lv_geom st_geometry;
    declare lv_geom_type string;
    declare lv_st_text string;
    declare harvestingStands table (
                        HARVESTINGSTANDID bigint,
                        HARVESTINGBLOCKID bigint,
                        STATUS int,
                        STANDNUMBER nvarchar( 100 ),
                        TRANSPORT_ACCESSIBILITY nvarchar( 100 ),
                        FORESTPLAN_STANDID nvarchar( 100 ),
                        OPERATION_ID bigint,
                        STAND_ID bigint,
                        ACCESSIBILITY nvarchar( 100 ),
                        SOIL_TYPE nvarchar( 100 ),
                        FERTILITY_CLASS nvarchar( 100 ),
                        KITUNNUS nvarchar( 100 ),
                        LABEL nvarchar( 100 ),
                        STANDAREA double,
                        GEOLOC st_geometry,
                        HARVESTINGMETHOD nvarchar( 10 )
    );
    declare hBlocks table (
                        HARVESTINGBLOCKID bigint,
                        CONTRACTID bigint,
                        STATUS int,
                        AREA double,
                        ISREADYTOHARVEST bigint,
                        INFOTEXT nvarchar( 100 ),
                        CUTTINGMETHOD nvarchar( 100 ),
                        CUTTINGABILITY nvarchar( 100 ),
                        TRANSPORTABILITY nvarchar( 100 ),
                        FORESTTYPE nvarchar( 100 ),
                        HARVESTINGMETHOD nvarchar( 10 ),
                        HARVESTINGCONDITION nvarchar( 100 ),
                        BLOCK_CODE nvarchar( 100 ),
                        BLOCKNUMBER bigint,
                        PRICEGROUPID int,
                        COPIED_FROM_BLOCKNUMBER int,
                        CUSTOMERID bigint,
                        CUSTOMERNAME nvarchar( 100 ),
                        THINNINGMETHOD nvarchar( 100 ),
                        FORESTENERGYTYPE int,
                        BLOCK_STATUS nvarchar( 100 )
   );
    declare forest_decl table (
                        OBJECTID bigint,
                        FORESTUSEDECLARATIONNUMBER nvarchar( 100 ),
                        DECLARATIONREFERENCE nvarchar( 100 ),
                        DECLARATIONSTATE nvarchar( 100 ),
                        CUTTINGPURPOSE int,
                        CUTTINGREALIZATIONPRACTICE int,
                        COMPLETIONYEAR int,
                        DECLARATIONARRIVALDATE timestamp,
                        GEOLOC st_geometry,
                        SOURCE nvarchar( 100 )
    );

* algorithm specific
    declare numberOfUnsupported int;
    declare numberOfOutdatedForestUseDecl int;
    declare numberOfToBeOutdatedForestUseDecl int;
    declare geomunion st_geometry;
    declare tester table(
        test1 nvarchar( 10 )
     );
* forest classificators
    declare FOREST_USE_IGNORABLE VARCHAR(10) ARRAY = ARRAY('10', '20', '31', '32', '33', '34', '50');
    --FOREST_STANDARD_CUTTING_REALIZATION_PRACTICES_TO_SAP_CUTTING_METHODS
    declare FSCRPTOSAPCM_ID VARCHAR(10) ARRAY = ARRAY( '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12',
                                            '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23' );
    declare FSCRPTOSAPCM_VAL VARCHAR(10) ARRAY = ARRAY( '4', '1,2,7', '2,1,7', '5', '5', '5', '3,8', '3', '6', '6', '6',
                                            '6,2', '2,1', '6', '6', '6', '6,2', '6', '5', '2,1', '5', '5', '2,1' );
    --FOREST_USE_DECLARATION_STATUS_DESCRIPTIONS
    declare FUDSD_ID VARCHAR(10) ARRAY = ARRAY('10', '20', '31', '32', '33', '34', '40', '41', '50');
    declare FUDSD_VAL VARCHAR(40) ARRAY = ARRAY('Automaattisesti tarkastettu', 'Asiatarkastettu', 'Kasittelyssa', 'Tarpeeton',
                                            'Siirretty toiselle viranomaiselle', 'Hakkuu kielletty', 'Voimassa', 'Voimassa muutettuna', 'Vanhentunut');

    declare wrong_variant CONDITION FOR SQL_ERROR_CODE 10001;


    if :in_variant IN ( 'pP','lSP' )
     then
       SIGNAL wrong_variant SET MESSAGE_TEXT = 'Variant can not be Point or LSP';
     END IF ;


* forest classificator tables
    FOREST_USE_IGNORABLE_T = UNNEST ( :FOREST_USE_IGNORABLE ) AS ( IGNORABLE );
    FSCRPTOSAPCM_T = UNNEST ( :FSCRPTOSAPCM_ID, :FSCRPTOSAPCM_VAL ) AS ( ID, VAL );
    FUDSD_T = UNNEST ( :FUDSD_ID, :FUDSD_VAL ) AS ( ID, VAL );

* input parameters
* SAP purchase ID is 9 symbols long and must be always padded with prefix zeros.
   select LPAD( :in_contractid, '0', 9 ) into sapPurchaseId default null from dummy;
   sapPurchaseDecade = :in_decade;
*   Let's be optimistic
   is_valid = 'true';
* initialize output tables
    harvesting_stands_output = select standNumber standnumber,
                               validationErrorGeometry validation_error_geometry,
                               validationErrorStatus validation_error_status,
                               validationErrorToBeOutdated validation_error_tobe_outdated,
                               validationErrorDate validation_error_date,
                               validationErrorText validation_error_text,
                               validationErrorGeometryText validation_error_geometrytext,
                               validationErrorHarvMethod validation_error_harv_method,
                               validationErrorHarvMethodText validation_error_harvmethodtxt,
                               errorGeometry errorgeometry
                               from :HarvestingStandResponse LIMIT 0;
   forest_decl_stands_out = select standNumber as standnumber,
                                          forestUseDeclStatus as forestuse_decl_status,
                                          cuttingMethod as cutting_method,
                                          forestUseDeclDate as forestuse_decl_date,
                                          forestUseDeclId as forestuse_decl_id,
                                          forestUseDeclStatusDescription as forestuse_decl_statdesc,
                                          TO_NVARCHAR(forestUseDeclObjectId) as forestuse_decl_objectid,
                                          forestUseDeclReference as forestuse_decl_ref,
                                          validationErrorDate as validation_error_date,
                                          validationErrorToBeOutdated as validation_error_tobe_outdated,
                                          validationErrorStatus as validation_error_status,
                                          validationErrorGeometry as validation_error_geometry,
                                          validationErrorGeometryText as validation_error_geometry_text,
                                          validationErrorHarvMethod as validation_error_harv_method,
                                          validationErrorHarvMethodText as validation_err_harv_methodtext,
                                          validationErrorText as validation_error_text,
                                          geometry as geometry
                                          from :ForestUseDeclarationStandResp LIMIT 0;
   hBlocks = SELECT
                    HARVESTINGBLOCKID,
                    CONTRACTID,
                    STATUS,
                    AREA,
                    ISREADYTOHARVEST,
                    INFOTEXT,
                    CUTTINGMETHOD,
                    CUTTINGABILITY,
                    TRANSPORTABILITY,
                    FORESTTYPE,
                    HARVESTINGMETHOD,
                    HARVESTINGCONDITION,
                    BLOCK_CODE,
                    BLOCKNUMBER,
                    PRICEGROUPID,
                    COPIED_FROM_BLOCKNUMBER,
                    CUSTOMERID,
                    CUSTOMERNAME,
                    THINNINGMETHOD,
                    FORESTENERGYTYPE,
                    BLOCK_STATUS
    FROM MG_KOTKA.HARVESTINGBLOCK WHERE CONTRACTID = CONCAT( :in_contractid, :in_decade) and BLOCKNUMBER = TO_BIGINT( :in_harvesting_block_number );

   if length(:in_geometry) < 1 --no geometry parameter
   then
       harvestingStands = SELECT
                            HS.HARVESTINGSTANDID,
                            HS.HARVESTINGBLOCKID,
                            HS.STATUS,
                            HS.STANDNUMBER,
                            HS.TRANSPORT_ACCESSIBILITY,
                            HS.FORESTPLAN_STANDID,
                            HS.OPERATION_ID,
                            HS.STAND_ID,
                            HS.ACCESSIBILITY,
                            HS.SOIL_TYPE,
                            HS.FERTILITY_CLASS,
                            HS.KITUNNUS,
                            HS.LABEL,
                            HS.STANDAREA,
                            HS.GEOLOC,
                            CASE WHEN HB.HARVESTINGMETHOD IS NULL THEN '0' ELSE HB.HARVESTINGMETHOD END HARVESTINGMETHOD FROM MG_KOTKA.HARVESTINGSTAND HS
                            LEFT JOIN MG_KOTKA.HARVESTINGBLOCK HB ON HS.HARVESTINGBLOCKID = HB.HARVESTINGBLOCKID
                            WHERE HS.HARVESTINGBLOCKID IN ( select harvestingblockid from :hBlocks ) AND HS.STATUS != 3;
   else --creating new harvesting stand
          call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
              poslist => :in_geometry,
              gtype   => :in_variant,
              st_text => :lv_st_text,
              geom_type => :lv_geom_type,
              geom    => :lv_geom /*set the geom object*/
              );

       harvestingStands = SELECT
                            0 HARVESTINGSTANDID,
                            null HARVESTINGBLOCKID,
                            null STATUS,
                            null STANDNUMBER,
                            null TRANSPORT_ACCESSIBILITY,
                            null FORESTPLAN_STANDID,
                            null OPERATION_ID,
                            null STAND_ID,
                            null ACCESSIBILITY,
                            null SOIL_TYPE,
                            null FERTILITY_CLASS,
                            null KITUNNUS,
                            null LABEL,
                            null STANDAREA,
                            :lv_geom GEOLOC,
                            '0' HARVESTINGMETHOD FROM DUMMY;
   end if;
   -- two result tables
   harvesting_stands_out = select * from :HarvestingStandResponse LIMIT 0;
   forest_use_decl_stands_out = select * from :ForestUseDeclarationStandResp LIMIT 0;
** Finds forest declarations intersecting the given geometry.
   for lv_index in 1..record_count(:harvestingStands)
   do
        declare geom st_geometry = :harvestingStands.GEOLOC[:lv_index];
        declare hvmethod nvarchar( 10 ) = :harvestingStands.HARVESTINGMETHOD[:lv_index];
        declare standNumber nvarchar( 100 ) = :harvestingStands.STANDNUMBER[:lv_index];
        resultHvResponse = select * from :HarvestingStandResponse LIMIT 0;
        resultForestUseDeclStandResponses = select * from :ForestUseDeclarationStandResp LIMIT 0;
                -- check MG
        forest_decl_mg = SELECT OBJECTID,
                            FORESTUSEDECLARATIONNUMBER,
                            DECLARATIONREFERENCE,
                            DECLARATIONSTATE,
                            CUTTINGPURPOSE,
                            CUTTINGREALIZATIONPRACTICE,
                            COMPLETIONYEAR,
                            DECLARATIONARRIVALDATE,
                            GEOLOC,
                            SOURCE FROM MG_SPATIAL.V_FORESTDECLARATION WHERE GEOLOC.ST_Intersects( :geom ) = 1 and SOURCE= 'MG';
        -- check OPENDATA
        forest_decl_opendata = SELECT OBJECTID,
                            FORESTUSEDECLARATIONNUMBER,
                            DECLARATIONREFERENCE,
                            DECLARATIONSTATE,
                            CUTTINGPURPOSE,
                            CUTTINGREALIZATIONPRACTICE,
                            COMPLETIONYEAR,
                            DECLARATIONARRIVALDATE,
                            GEOLOC,
                            SOURCE FROM MG_SPATIAL.V_FORESTDECLARATION WHERE GEOLOC.ST_Intersects( :geom ) = 1 and SOURCE= 'OPENDATA';

        --validate, MG and OPENDATA iteration
        for i in 1..2
        -- MG OPENDATA LOOP
        do
        -- response fields
        declare validationErrorDate nvarchar( 10 ) = 'false';
        declare validationErrorToBeOutdated nvarchar( 10 ) = 'false';
        declare validationErrorStatus nvarchar( 10 ) = 'false';
        declare validationErrorGeometry nvarchar( 10 ) = 'false';
        declare validationErrorGeometryText nvarchar( 100 );
        declare validationErrorHarvMethod nvarchar( 10 ) = 'false';
        declare validationErrorHarvMethodText nvarchar( 100 );
        declare validationErrorText nvarchar( 100 );
        declare errorGeometry st_geometry;

        --staging tables
        forest_decl_flow = select * from :forest_decl_mg;
        forest_decl_accepted = select * from :forest_decl LIMIT 0;
        forest_decl_valid = select * from :forest_decl LIMIT 0;
        forestUseDeclStandResponses = select * from :ForestUseDeclarationStandResp LIMIT 0;
        hvResponse = select * from :HarvestingStandResponse LIMIT 0;
        finalForestUseDeclStandResponses = select * from :ForestUseDeclarationStandResp LIMIT 0;
        numberOfUnsupported = 0;

          if :i = 2 then
            forest_decl_flow = select * from :forest_decl_opendata;
          end if;

          for j in 1..record_count( :forest_decl_flow )
          -- validation loop 1
          do
            declare objectid bigint = :forest_decl_flow.OBJECTID[:j];
            declare forestnumber nvarchar( 100 ) = :forest_decl_flow.FORESTUSEDECLARATIONNUMBER[:j];
            declare dreference nvarchar( 100 ) = :forest_decl_flow.DECLARATIONREFERENCE[:j];
            declare dstate nvarchar( 100 ) = :forest_decl_flow.DECLARATIONSTATE[:j];
            declare cutpurpose int = :forest_decl_flow.CUTTINGPURPOSE[:j];
            declare cutpractice int = :forest_decl_flow.CUTTINGREALIZATIONPRACTICE[:j];
            declare compyear int  = :forest_decl_flow.COMPLETIONYEAR[:j];
            declare decldate timestamp = :forest_decl_flow.DECLARATIONARRIVALDATE[:j];
            declare geoloc_st st_geometry = :forest_decl_flow.GEOLOC[:j];
            declare src nvarchar( 100 ) = :forest_decl_flow.SOURCE[:j];

            ignorable = select IGNORABLE from :FOREST_USE_IGNORABLE_T where IGNORABLE = :dstate;

            if LENGTH( :dstate ) > 0 and not IS_EMPTY( :ignorable ) then
                continue;  --Skip ignorable forest use declaration
            end if;
            if LENGTH( :dreference ) = 0 then
                if src = 'OPENDATA' and LENGTH( :forestnumber ) > 0 then
                    forest_decl_flow.DECLARATIONREFERENCE[:j] = :forestnumber;
                else
                    continue; --Skip ignorable forest use declaration
                end if;
           end if;

            sap_methods = select ID from :FSCRPTOSAPCM_T where ID = :hvmethod;

            if    ( LENGTH( :cutpractice ) = 0 and :src = 'MG' )
               OR ( LENGTH( :cutpractice ) > 0 and LENGTH( :hvmethod ) > 0 and not IS_EMPTY( :sap_methods ) )
               OR ( :cutpurpose = 3 OR ( :cutpurpose = 6 AND ( :cutpractice = 21 OR :cutpractice = 22 ) ) )
               OR ( :cutpurpose = 4 OR :cutpurpose = 5 )
               OR ( ( :cutpurpose = 1 OR :cutpurpose = 2 ) AND :hvmethod = 6 )
            then
                forest_decl_accepted = select * from :forest_decl_accepted
                                       union
                                       select :objectid, :forestnumber, :dreference, :dstate, :cutpurpose,
                                              :cutpractice, :compyear, :decldate, :geoloc_st,:src from dummy;
            else
                numberOfUnsupported = :numberOfUnsupported + 1;
            end if;
          -- validation loop 1 end
          end for;

          forest_decl_compare = select * from :forest_decl_accepted;
          for j in 1..record_count( :forest_decl_accepted )
          -- validation loop 2
          do
               declare objectid bigint = :forest_decl_accepted.OBJECTID[:j];
               declare forestnumber nvarchar( 100 ) = :forest_decl_accepted.FORESTUSEDECLARATIONNUMBER[:j];
               declare dreference nvarchar( 100 ) = :forest_decl_accepted.DECLARATIONREFERENCE[:j];
               declare dstate nvarchar( 100 ) = :forest_decl_accepted.DECLARATIONSTATE[:j];
               declare cutpurpose int = :forest_decl_accepted.CUTTINGPURPOSE[:j];
               declare cutpractice int = :forest_decl_accepted.CUTTINGREALIZATIONPRACTICE[:j];
               declare compyear int  = :forest_decl_accepted.COMPLETIONYEAR[:j];
               declare decldate timestamp = :forest_decl_accepted.DECLARATIONARRIVALDATE[:j];
               declare geoloc_st st_geometry = :forest_decl_accepted.GEOLOC[:j];
               declare src nvarchar( 100 ) = :forest_decl_accepted.SOURCE[:j];

              invalid_geometries = select * from :forest_decl_compare where OBJECTID <> :objectid
              and GEOLOC.ST_Intersection( :geoloc_st ).ST_Buffer(1.0).ST_Area( ) > 10000 * 0.15 and DECLARATIONARRIVALDATE IS NOT NULL
              and :decldate IS NOT NULL and :decldate < DECLARATIONARRIVALDATE;

              if IS_EMPTY( :invalid_geometries ) then
                forest_decl_valid = select * from :forest_decl_valid
                                       union
                                       select :objectid, :forestnumber, :dreference, :dstate, :cutpurpose,
                                              :cutpractice, :compyear, :decldate, :geoloc_st,:src from dummy;
              end if;

          -- validation loop 2 end
          end for;

          geomunion = null;
          for j in 1..record_count( :forest_decl_valid )
          -- validation loop 3 , union
          do
              if :geomunion is null then
                  geomunion = :forest_decl_valid.GEOLOC[:j];
              else
                  geomunion = :geomunion.ST_Union( :forest_decl_valid.GEOLOC[:j] );
              end if;
          -- validation loop 3 , union end
          end for;
          -- MGSUITE-419 The forest use declaration must cover more than 60% of the harvesting stand
          if :geomunion is not null and :geomunion.ST_Buffer(1.0).ST_Intersection( :geom ).ST_Buffer(1.0).ST_Area( ) < 0.6 *  :geom.ST_Buffer(1.0).ST_Area( )
          then
            forest_decl_valid = select * from :forest_decl LIMIT 0;
          end if;

          if IS_EMPTY( :forest_decl_valid ) and :numberOfUnsupported > 0
          then
            ValidationErrorHarvMethod = 'true';
            ValidationErrorHarvMethodText = 'Lohkon ja MKI:n hakkuutavat eivat tasmaa';
            ValidationErrorText = 'Lohkon ja MKI:n hakkuutavat eivat tasmaa';
          elseif IS_EMPTY( :forest_decl_valid )
          then
            ValidationErrorHarvMethod = 'true';
            ValidationErrorHarvMethodText = 'MKI puuttuu';
            ValidationErrorText = 'MKI puuttuu';
          end if;

          if :geomunion is not null or :geomunion.ST_Intersects( :geom ) = 0
          then
            validationErrorGeometry = 'true';
            validationErrorGeometryText = 'Lohkon geometrian alueelle ei osu lainkaan MKI-geometriaa';
            validationErrorText = 'Lohkon geometrian alueelle ei osu lainkaan MKI-geometriaa';
            errorGeometry = :geom;
          else
            if :geomunion.ST_Buffer( 2.0 ).ST_Contains( :geom ) = 0
            then
              declare intersection st_geometry = :geomunion.ST_Intersection(:geom);
              declare intersectionArea double = :intersection.ST_Buffer(1.0).ST_Area();
              declare  harvestingStandArea double = :geom.ST_Buffer(1.0).ST_Area();
              declare harvestingStandUncoveredArea double = :harvestingStandArea - :intersectionArea;
              declare harvestingStandCoverityPercentage double = (100 * :intersectionArea) / :harvestingStandArea;
              if :harvestingStandCoverityPercentage <= 90.0 and harvestingStandUncoveredArea > 10000 * 0.15
              then
                ValidationErrorGeometry = 'true'; -- Having geometry error
                ValidationErrorGeometryText = 'Lohkon pinta-alasta puuttuu 10% tai suurempi osuus MKI-geometriaa';
                ValidationErrorText = 'Lohkon pinta-alasta puuttuu 10% tai suurempi osuus MKI-geometriaa';
                ErrorGeometry = :geom;
              elseif harvestingStandUncoveredArea > 10000
              then
                ValidationErrorGeometry = 'true'; -- Having geometry error
                ValidationErrorGeometryText = 'Lohkon pinta-alasta puuttuu yli hehtaarin osuus MKI geometriaa';
                ValidationErrorText = 'Lohkon pinta-alasta puuttuu yli hehtaarin osuus MKI geometriaa';
                ErrorGeometry = :geom;
              end if;
            end if;
          end if;

          for j in 1..record_count( :forest_decl_valid )
          -- validation loop 4 , union
          do
            declare forest_cuttingMethod nvarchar( 100 );
            declare forestUseDeclStatus nvarchar( 100 ) = :forest_decl_valid.DECLARATIONSTATE[:j];
            declare forestUseDeclStatusDescription nvarchar( 100 );
            declare forestUseDeclDate nvarchar( 100 );
            declare forestUseDeclId nvarchar( 100 ) = :forest_decl_valid.FORESTUSEDECLARATIONNUMBER[:j];
            declare forestUseDeclObjectId bigint = :forest_decl_valid.OBJECTID[:j];
            declare forestUseDeclReference nvarchar( 100 ) = :forest_decl_valid.DECLARATIONREFERENCE[:j];
            declare forest_validationErrorDate nvarchar( 10 ) = 'false';
            declare forest_validationErrorToBeOutdated nvarchar( 10 ) = 'false';
            declare forest_validationErrorStatus nvarchar( 10 ) = 'false';
            declare forest_validationErrorGeometry nvarchar( 10 ) = 'false';
            declare forest_validationErrorGeometryText nvarchar( 100 );
            declare forest_validationErrorHarvMethod nvarchar( 10 ) = 'false';
            declare forest_validationErrorHarvMethodText nvarchar( 100 );
            declare forest_validationErrorText nvarchar( 100 );
            declare forest_Geometry st_geometry = :forest_decl_valid.GEOLOC[:j];
            declare forest_tmp nvarchar( 100 );
            declare forest_tmp_date timestamp = :forest_decl_valid.DECLARATIONARRIVALDATE[:j];
            declare forestDeclarationExpirationDate timestamp;
            declare forestDeclarationToBeExpiredDate timestamp;
            declare requestStartDate timestamp = TO_TIMESTAMP( :in_start_date, 'YYYY-MM-DD' );
            declare requestEndDate timestamp = TO_TIMESTAMP( :in_end_date, 'YYYY-MM-DD' );

            if :forest_decl_valid.CUTTINGREALIZATIONPRACTICE[:j] is not null
            then
                forest_cuttingMethod = TO_NVARCHAR( :forest_decl_valid.CUTTINGREALIZATIONPRACTICE[:j] );
            end if;
            if :forest_decl_valid.DECLARATIONARRIVALDATE[:j] is not null
            then
                forestUseDeclDate = TO_NVARCHAR( :forest_decl_valid.DECLARATIONARRIVALDATE[:j] );
            end if;

            forest_tmp = :forest_decl_valid.DECLARATIONSTATE[:j];
            select o.VAL into forestUseDeclStatusDescription default null from :FUDSD_T o where o.ID = :forest_tmp;

            if :forest_tmp_date is not null
            then
                select ADD_YEARS( :forest_tmp_date, 3 ) into forestDeclarationExpirationDate default null from dummy;
                select ADD_DAYS( ADD_YEARS( :forest_tmp_date, 3 ), -14 ) into forestDeclarationToBeExpiredDate default null from dummy;

                if :requestStartDate is null and :requestEndDate is null
                then
                    -- Set request start date to current date
                    select CURRENT_TIMESTAMP into requestStartDate default null from dummy;
                end if;

                if :requestStartDate is not null
                then
                    if :forestDeclarationExpirationDate > :requestStartDate
                    then
                        forest_ValidationErrorDate = 'false';
                    else
                        forest_ValidationErrorDate = 'true'; -- Having error with expiration dates
                        forest_ValidationErrorText = 'MKI ei ole voimassa';
                    end if;
                end if;

                if :requestEndDate is not null
                then
                    if :forestDeclarationExpirationDate > :requestEndDate
                    then
                        forest_ValidationErrorDate = 'false';
                    else
                        forest_ValidationErrorDate = 'true'; -- Having error with expiration dates
                        forest_ValidationErrorText = 'MKI ei ole voimassa';
                    end if;
                end if;
                -- ToBeOutdated perform this additional check only if MKI has not been already expired
                if :forest_ValidationErrorDate = 'false'
                then
                    if :requestStartDate is not null
                    then
                        if :forestDeclarationToBeExpiredDate > :requestStartDate
                        then
                            forest_ValidationErrorToBeOutdated = 'false';
                        else
                            forest_ValidationErrorToBeOutdated = 'true'; -- Having error with start and end dates
                            forest_ValidationErrorText = 'MKI tarkistettava';
                        end if;
                    end if;
                    if :requestEndDate is not null
                    then
                        if :forestDeclarationToBeExpiredDate > :requestEndDate
                        then
                            forest_ValidationErrorToBeOutdated = 'false';
                        else
                            forest_ValidationErrorToBeOutdated = 'true'; -- Having error with start and end dates
                            forest_ValidationErrorText = 'MKI tarkistettava';
                        end if;
                    end if;
                end if;

                if :forestUseDeclStatus = '40' or :forestUseDeclStatus = '41'
                then
                    forest_ValidationErrorStatus = 'false';
                else
                    forest_tmp = :forest_decl_valid.DECLARATIONSTATE[:j];
                    select o.VAL into forestUseDeclStatusDescription default null from :FUDSD_T o where o.ID = :forest_tmp;

                    forest_ValidationErrorStatus = 'true';
                    forest_ValidationErrorText = 'MKI ei ole voimassa, MKI:n tila: ' || :forestUseDeclStatus || ', ' || forest_tmp;
                end if;

                -- If DECLARATIONARRIVALDATE is not available, we have invalid forest use declaration
                if :forest_tmp_date is null
                then
                    forestUseDeclStatus = '0';
                    forestUseDeclStatusDescription = 'Lahettamaton metsankayttoilmoitus';
                    forest_ValidationErrorStatus = 'true'; -- Having error with the state
                    forest_ValidationErrorText = 'Loytyi lahettamaton metsankayttoilmoitus';
                end if;
            end if;

            :forestUseDeclStandResponses.INSERT((  :standNumber, :forest_cuttingMethod, :forestUseDeclStatus, :forestUseDeclStatusDescription, :forestUseDeclDate,
                                                        :forestUseDeclId, :forestUseDeclObjectId, :forestUseDeclReference, :forest_validationErrorDate,
                                                        :forest_validationErrorToBeOutdated, :forest_validationErrorStatus, :forest_validationErrorGeometry, :forest_validationErrorGeometryText,
                                                        :forest_validationErrorHarvMethod, :forest_validationErrorHarvMethodText, :forest_validationErrorText, :forest_Geometry.ST_AsText() ));

          -- validation loop 4 , union end
          end for;

          numberOfOutdatedForestUseDecl = 0;
          numberOfToBeOutdatedForestUseDecl = 0;

          for j in 1..record_count( :forestUseDeclStandResponses )
          -- response finalizing loop
          do
            declare forest_cuttingMethod nvarchar( 100 ) = :forestUseDeclStandResponses.cuttingMethod[:j];
            declare forestUseDeclStatus nvarchar( 100 ) = :forestUseDeclStandResponses.forestUseDeclStatus[:j];
            declare forestUseDeclStatusDescription nvarchar( 100 ) = :forestUseDeclStandResponses.forestUseDeclStatusDescription[:j];
            declare forestUseDeclDate nvarchar( 100 ) = :forestUseDeclStandResponses.forestUseDeclDate[:j];
            declare forestUseDeclId nvarchar( 100 ) = :forestUseDeclStandResponses.forestUseDeclId[:j];
            declare forestUseDeclObjectId bigint = :forestUseDeclStandResponses.forestUseDeclObjectId[:j];
            declare forestUseDeclReference nvarchar( 100 ) = :forestUseDeclStandResponses.forestUseDeclReference[:j];
            declare forest_validationErrorDate nvarchar( 10 ) = :forestUseDeclStandResponses.validationErrorDate[:j];
            declare forest_validationErrorToBeOutdated nvarchar( 10 ) = :forestUseDeclStandResponses.validationErrorToBeOutdated[:j];
            declare forest_validationErrorStatus nvarchar( 10 ) = :forestUseDeclStandResponses.validationErrorStatus[:j];
            declare forest_validationErrorGeometry nvarchar( 10 ) = :forestUseDeclStandResponses.validationErrorGeometry[:j];
            declare forest_validationErrorGeometryText nvarchar( 100 ) = :forestUseDeclStandResponses.validationErrorGeometryText[:j];
            declare forest_validationErrorHarvMethod nvarchar( 10 ) = :forestUseDeclStandResponses.validationErrorHarvMethod[:j];
            declare forest_validationErrorHarvMethodText nvarchar( 100 ) = :forestUseDeclStandResponses.validationErrorHarvMethodText[:j];
            declare forest_validationErrorText nvarchar( 100 ) = :forestUseDeclStandResponses.validationErrorText[:j];
            declare forest_geometry nvarchar( 10000 ) = :forestUseDeclStandResponses.geometry[:j];

            if :forestUseDeclStandResponses.ValidationErrorDate[:j] = 'true'
            then
                numberOfOutdatedForestUseDecl = :numberOfOutdatedForestUseDecl + 1;
                continue; -- Skip from the final results
            end if;
            if :forestUseDeclStandResponses.ValidationErrorToBeOutdated[:j] = 'true'
            then
                numberOfToBeOutdatedForestUseDecl = numberOfToBeOutdatedForestUseDecl + 1;
                continue; -- Skip from the final results
            end if;

            -- Check other validation errors
            if :forestUseDeclStandResponses.ValidationErrorStatus[:j] = 'true'  -- Having status errors
            then
                ValidationErrorStatus = 'true';
                ValidationErrorText = :forestUseDeclStandResponses.ValidationErrorText[:j];
            end if;

            :finalForestUseDeclStandResponses.INSERT((  :standNumber, :forest_cuttingMethod, :forestUseDeclStatus, :forestUseDeclStatusDescription, :forestUseDeclDate,
                                                        :forestUseDeclId, :forestUseDeclObjectId, :forestUseDeclReference, :forest_validationErrorDate,
                                                        :forest_validationErrorToBeOutdated, :forest_validationErrorStatus, :forest_validationErrorGeometry, :forest_validationErrorGeometryText,
                                                        :forest_validationErrorHarvMethod, :forest_validationErrorHarvMethodText, :forest_validationErrorText, :forest_geometry ));
          -- response finalizing loop end
          end for;


         --Report in the final message if all MKI stands are outdated or soon to be outdated
        if IS_EMPTY(:finalForestUseDeclStandResponses) and :numberOfOutdatedForestUseDecl > 0
        then
            ValidationErrorDate = 'true'; -- Having error with expiration dates
            ValidationErrorText = 'MKI ei ole voimassa';
        elseif IS_EMPTY(:finalForestUseDeclStandResponses) and :numberOfToBeOutdatedForestUseDecl > 0
        then
            ValidationErrorToBeOutdated = 'true'; --Having error with start and end dates
            ValidationErrorText = 'MKI tarkistettava';
        elseif IS_EMPTY(:finalForestUseDeclStandResponses)
        then
            ValidationErrorGeometry = 'true'; --Having geometry error
            ValidationErrorGeometryText = 'MKI puuttuu';
            ValidationErrorText = 'MKI puuttuu';
        end if;

        :hvResponse.INSERT(( :standNumber, :ValidationErrorDate, :ValidationErrorToBeOutdated, :ValidationErrorStatus, :ValidationErrorGeometry,
                             :ValidationErrorGeometryText, :ValidationErrorHarvMethod, :ValidationErrorHarvMethodText, :ValidationErrorText, :ErrorGeometry.ST_AsText( ) ));

        if :i = 1 -- first loop MG
        then
            resultHvResponse = select * from :hvResponse;
            resultForestUseDeclStandResponses = select * from :finalForestUseDeclStandResponses;
        end if;

        if :ValidationErrorDate = 'true' or :ValidationErrorToBeOutdated = 'true' or  :ValidationErrorStatus = 'true' or  :ValidationErrorGeometry = 'true'
            or  :ValidationErrorHarvMethod = 'true' or LENGTH( :ValidationErrorGeometryText ) > 0 or LENGTH( :ValidationErrorHarvMethodText ) > 0
            or LENGTH( :ValidationErrorText ) > 0 or :ErrorGeometry is not null
        then
            is_valid = 'false';
            continue;
        else
            resultHvResponse = select * from :hvResponse;
            resultForestUseDeclStandResponses = select * from :finalForestUseDeclStandResponses;
            break;
        end if;
        -- MG OPENDATA LOOP  END
        end for;

*   harvesting_stands_out = select * from :HarvestingStandResponse LIMIT 0;
*   forest_use_decl_stands_out = select * from :ForestUseDeclarationStandResp LIMIT 0;

        harvesting_stands_out = select * from :harvesting_stands_out union select standNumber standnumber,
                               validationErrorGeometry validation_error_geometry,
                               validationErrorStatus validation_error_status,
                               validationErrorToBeOutdated validation_error_tobe_outdated,
                               validationErrorDate validation_error_date,
                               validationErrorText validation_error_text,
                               validationErrorGeometryText validation_error_geometrytext,
                               validationErrorHarvMethod validation_error_harv_method,
                               validationErrorHarvMethodText validation_error_harvmethodtxt,
                               errorGeometry errorgeometry
                               from :resultHvResponse;

        forest_use_decl_stands_out = select * from :forest_use_decl_stands_out union select standNumber as standnumber,
                              forestUseDeclStatus as forestuse_declaration_status,
                              cuttingMethod as cutting_method,
                              forestUseDeclDate as forestuse_declaration_date,
                              forestUseDeclId as forestuse_declaration_id,
                              forestUseDeclStatusDescription as forestuse_declaration_statdesc,
                              TO_NVARCHAR(forestUseDeclObjectId) as forestuse_declaration_objectid,
                              forestUseDeclReference as forestuse_declaration_ref,
                              validationErrorDate as validation_error_date,
                              validationErrorToBeOutdated as validation_error_tobe_outdated,
                              validationErrorStatus as validation_error_status,
                              validationErrorGeometry as validation_error_geometry,
                              validationErrorGeometryText as validation_error_geometry_text,
                              validationErrorHarvMethod as validation_error_harv_method,
                              validationErrorHarvMethodText as validation_err_harv_methodtext,
                              validationErrorText as validation_error_text,
                              geometry geometry
                              from :resultForestUseDeclStandResponses;


        -- response is ready starting optional tasks
*        if :in_create_crmtasks_from_errors = 'true' and :is_valid = 'false'
*        then
*        -- TODO JSON HTTP API calls should be implemented somewhere else
*        end if;

   end for;

    harvesting_stands = select standNumber standnumber,
                        validationErrorGeometry validation_error_geometry,
                        validationErrorStatus validation_error_status,
                        validationErrorToBeOutdated validation_error_tobe_outdated,
                        validationErrorDate validation_error_date,
                        validationErrorText validation_error_text,
                        validationErrorGeometryText validation_error_geometrytext,
                        validationErrorHarvMethod validation_error_harv_method,
                        validationErrorHarvMethodText validation_error_harvmethodtxt,
                        ST_GeomFromText(errorGeometry, 3067) errorgeometry
                        from :harvesting_stands_out;

   forest_use_declaration_stands = select standNumber as standnumber,
                       forestUseDeclStatus as forestuse_declaration_status,
                       cuttingMethod as cutting_method,
                       forestUseDeclDate as forestuse_declaration_date,
                       forestUseDeclId as forestuse_declaration_id,
                       forestUseDeclStatusDescription as forestuse_declaration_statdesc,
                       TO_NVARCHAR(forestUseDeclObjectId) as forestuse_declaration_objectid,
                       forestUseDeclReference as forestuse_declaration_ref,
                       validationErrorDate as validation_error_date,
                       validationErrorToBeOutdated as validation_error_tobe_outdated,
                       validationErrorStatus as validation_error_status,
                       validationErrorGeometry as validation_error_geometry,
                       validationErrorGeometryText as validation_error_geometry_text,
                       validationErrorHarvMethod as validation_error_harv_method,
                       validationErrorHarvMethodText as validation_err_harv_methodtext,
                       validationErrorText as validation_error_text,
                       ST_GeomFromText(geometry, 3067) geometry
                       from :forest_use_decl_stands_out;

*Add the outputs
     out_contractid = :in_contractid;
     out_decade     = :in_decade;
     out_harvesting_block_number = :in_harvesting_block_number;
     out_variant =  :in_variant;
     out_start_date = :in_start_date;
     out_end_date  = :in_end_date;

  ENDMETHOD.

ENDCLASS.