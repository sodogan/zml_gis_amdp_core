"! <p class="shorttext synchronized" lang="en">GetKemeraCompletionDeclaration, GetKemeraDecision</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MFORIS/GetKemeraCompletionDeclaration</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_fc_notification/source/main#start=4272,8;end=4276,29 </p>
CLASS zcl_gis_amdp_id1175 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.


    "! <p class="shorttext synchronized" lang="en">Get Kemera Completion Decision</p>
    "!
    "! @parameter in_financing_actNumber | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter out_financing_actnumber | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter completion_dec_ref | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter work_code | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decision_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter sent_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter start_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter end_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter financing_act_completionStands | <p class="shorttext synchronized" lang="en"></p>
    "! @raising cx_amdp_error | <p class="shorttext synchronized" lang="en"></p>
    METHODS get_kemera_completion_dec
      IMPORTING
                VALUE(in_financing_actNumber) TYPE string
      EXPORTING
                VALUE(out_financing_actnumber) TYPE string
                VALUE(completion_dec_ref) TYPE string
                VALUE(work_code) TYPE string
                VALUE(decision_date) TYPE string
                VALUE(sent_date) TYPE string
                VALUE(start_date) TYPE string
                VALUE(end_date) TYPE string
                VALUE(financing_act_completionStands) TYPE ZPRDTID1175_GIS_GET_KEMERA_TT
      RAISING   cx_amdp_error.


    "! <p class="shorttext synchronized" lang="en">Get Kemera Decision</p>
    "!
    "! @parameter in_case_number | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter work_code_groups | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter out_case_number | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decision_number | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter case_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decision_date | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter decision_geometries | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter harvestingblocks | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter silviculturalblocks | <p class="shorttext synchronized" lang="en"></p>
    "! @raising cx_amdp_error | <p class="shorttext synchronized" lang="en"></p>
    METHODS get_kemera_decision
          IMPORTING
                VALUE(in_case_number)                TYPE string
                VALUE(work_code_groups)              TYPE zprstring_workcode_group_tt
          EXPORTING
                VALUE(out_case_number)               TYPE  string
                VALUE(decision_number)               TYPE  string
                VALUE(case_date)                     TYPE  string
                VALUE(decision_date)                 TYPE  string
                VALUE(decision_geometries)           TYPE  zprdtid1175_gis_get_kem_tab1
                VALUE(harvestingblocks)              TYPE  zprdtid1175_gis_get_keme_tab2
                VALUE(silviculturalblocks)           TYPE  zprdtid1175_gis_get_keme_tab1
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1175 IMPLEMENTATION.

  METHOD get_kemera_decision BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare index int;
    declare hvblock table(
        contract nvarchar(100),
        decade nvarchar(10),
        block_number nvarchar(100)
    );
    declare swblock table(
        silvicultural_order nvarchar(100),
        block_number nvarchar(100)
    );

    SELECT :in_case_number, DECISIONNUMBER, TO_NVARCHAR(CASEDATE), TO_NVARCHAR(DECISIONDATE) INTO
    out_case_number, decision_number, case_date, decision_date
    FROM GISDATA.KEMERADECISION o WHERE o.CASENUMBER = :in_case_number;

    decision_geometries_stg = SELECT STANDREFERENCE, STANDID, GEOLOC, '' geometry_reference_error ,COSTTYPE
                             FROM GISDATA.KEMERADECISIONGEOMETRY WHERE CASENUMBER = :in_case_number;

   -- initialize hvblock and swblock
   hvblocks = select null contract, null decade, null block_number from dummy limit 0;
   swblocks = select null silvicultural_order, null block_number from dummy limit 0;

   for index in 1..record_count( :decision_geometries_stg )
    do
    declare geometry st_geometry = :decision_geometries_stg.geoloc[:index];
        if :decision_geometries_stg.costtype[:index] = 323 --Harvestingblock
        then
           tmp_hv = SELECT TO_NVARCHAR(hb.CONTRACTID) contract, RIGHT( TO_NVARCHAR(hb.CONTRACTID), 1 ) decade,
           TO_NVARCHAR(hb.BLOCKNUMBER) block_number --, (SELECT ST_UNIONAGGR(a.GEOLOC) -- ? not used in output table
           --FROM MG_KOTKA.HARVESTINGSTAND a WHERE a.STATUS!=3 and a.HARVESTINGBLOCKID = hb.HARVESTINGBLOCKID) AS standgeometry  -- ? not used in output table
                                        FROM MG_KOTKA.HARVESTINGSTAND s
                                        LEFT JOIN MG_KOTKA.HARVESTINGBLOCK hb ON (s.HARVESTINGBLOCKID = hb.HARVESTINGBLOCKID)
                                        WHERE hb.STATUS != 3 AND s.STATUS != 3 -- Undeleted blocks and stands
                                        AND hb.CREATED_ON > ADD_YEARS(CURRENT_TIMESTAMP, -3) -- Block created before 3 years limit
                                        AND s.GEOLOC.ST_Intersects(:geometry) = 1; -- And matching the given geometry

           if IS_EMPTY( :tmp_hv )
           then
               decision_geometries_stg.geometry_reference_error[:index] = '2';
           end if;
           hvblocks = select * from :hvblocks union select * from :tmp_hv;

        else --silvicultureblock
           tmp_sw = SELECT sb.SILVICULTURALORDERID, sb.BLOCKNUMBER
                 --,(SELECT ST_UNIONAGGR(a.GEOLOC) FROM MG_KOTKA.SW_PLANNINGSTAND a WHERE a.STATUS!=3 and a.SW_PLANNINGBLOCKID = sb.SW_PLANNINGBLOCKID) AS standgeometry
                                       FROM MG_KOTKA.SW_PLANNINGSTAND s
                                       LEFT JOIN MG_KOTKA.SW_PLANNINGBLOCK sb ON (s.SW_PLANNINGBLOCKID = sb.SW_PLANNINGBLOCKID)
                                       WHERE sb.STATUS != 3 AND s.STATUS != 3 -- Undeleted blocks and stands
                                       AND sb.WORKTYPEGROUP = 6 -- Having given worktype group (MGGISPALV-476)
                                       AND sb.CREATED_ON > ADD_YEARS(CURRENT_TIMESTAMP, -3) -- Block created before 3 years limit
                                       AND s.GEOLOC.ST_Intersects(:geometry) = 1 -- And matching the given geometry
                                       AND sb.WORKTYPEGROUP IN ( select TO_NVARCHAR(workcode_group) from :work_code_groups );

           if IS_EMPTY( :tmp_sw )
           then
               decision_geometries_stg.geometry_reference_error[:index] = '2';
           end if;
           swblocks = select * from :swblocks union select * from :tmp_sw;

        end if;
    end for;

   --geolocation object was missing, added to table type definition
    decision_geometries =  select STANDREFERENCE stand_reference, STANDID stand_id, TO_NVARCHAR(GEOLOC.ST_AsText()) geoloc, geometry_reference_error
                          from :decision_geometries_stg;

   harvestingblocks    =  select distinct * from :hvblocks;
   silviculturalblocks =  select distinct * from :swblocks;


  ENDMETHOD.

  METHOD get_kemera_completion_dec BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.


* local variables

    SELECT COMPLETIONDECLARATIONREFERENCE, workcode, :in_financing_actNumber, TO_NVARCHAR(DECISIONDATE),
           TO_NVARCHAR(SENTDATE), TO_NVARCHAR(STARTDATE), TO_NVARCHAR(ENDDATE)
           into work_code, completion_dec_ref, out_financing_actnumber, decision_date, sent_date, start_date, end_date default null, null, null, null, null, null, null
           FROM GISDATA.KEMERACOMPLETIONDECLARATION WHERE FINANCINGACTNUMBER = :in_financing_actNumber;

    financing_act_completionStands = -- returning geometry as text
           SELECT STANDREFERENCE stand_reference, STANDNUMBER stand_number, COSTTYPE cost_type_number, TO_NVARCHAR(GEOLOC.ST_AsText()) polygon_property
           FROM GISDATA.KEMERACOMPLDECLARGEOMETRY WHERE FINANCINGACTNUMBER = :in_financing_actNumber;


  ENDMETHOD.

ENDCLASS.