"! <p class="shorttext synchronized" lang="en">Project: GIS Openshift to HANA</p>
"! <p class="shorttext synchronized" lang="en">Base AMDP class for all Interfaces</p>
CLASS zcl_gis_amdp_base DEFINITION
  PUBLIC
   CREATE PUBLIC  ABSTRACT.

  PUBLIC SECTION.


    INTERFACES zif_gis_amdp.

    ALIASES ty_instances  FOR zif_gis_amdp~ty_instances.
    ALIASES tt_instances  FOR zif_gis_amdp~tt_instances.

    CLASS-METHODS: get_instance IMPORTING iv_id              TYPE csequence
                                RETURNING VALUE(rv_instance) TYPE REF TO zcl_gis_amdp_base
                                RAISING   zcx_unexpected_exception
                                .


    "! <p class="shorttext synchronized" lang="en"></p>
    "! Get the Planing block Data from MG_KOTKA.SW_PLANNINGBLOCK
    "! @parameter contractid | <p class="shorttext synchronized" lang="en"> ContractID-Mandatory</p>
    "! @parameter blocknumber | <p class="shorttext synchronized" lang="en">block Number-Mandatory</p>
    "! @parameter planning_table | <p class="shorttext synchronized" lang="en"></p>
    CLASS-METHODS get_mgkotka_sw_planningblock IMPORTING VALUE(contractid)     TYPE int8
                                                         VALUE(blocknumber)    TYPE zmhblockno
                                               EXPORTING
                                                         VALUE(planning_table) TYPE zmgkotka_planningblock_tt
                                               RAISING   cx_amdp_error.


    CLASS-METHODS  findsampleplotswithStandid IMPORTING VALUE(stand_id)                   TYPE int8
                                                        VALUE(is_harvesting)              TYPE abap_bool DEFAULT ''
                                              EXPORTING VALUE(matching_sampleplots_table) TYPE zmgkotka_sampleplots_tt
                                              RAISING   cx_amdp_error.

    CLASS-METHODS  find_actualgeometry FOR TABLE FUNCTION zfind_actualgeometry_tf.

    CLASS-METHODS  get_actualgeometries FOR TABLE FUNCTION zget_actualgeometries_tf.


    CLASS-METHODS  findsampleplotswithStandid_tf FOR TABLE FUNCTION  zfindsampleplotswithStandid_tf.

    CLASS-METHODS: get_mgkotka_logy_harvestblock  IMPORTING
                                                            VALUE(contractid)               TYPE int8
                                                            VALUE(blocknumber)              TYPE zmhblockno
                                                  EXPORTING
                                                            VALUE(logy_harvest_block_table) TYPE zmgkotka_logyharvestblck_tt
                                                  RAISING   cx_amdp_error.


    CLASS-METHODS: get_mgkotka_logy_silviblock  IMPORTING
                                                          VALUE(contractid)             TYPE int8
                                                          VALUE(blocknumber)            TYPE zmhblockno
                                                EXPORTING
                                                          VALUE(logy_silvi_block_table) TYPE zmgkotka_logyharvestblck_tt
                                                RAISING   cx_amdp_error.

    CLASS-METHODS: get_mvk_stand                IMPORTING
                                                          VALUE(stand_id)    TYPE int8
                                                EXPORTING
                                                          VALUE(stand_table) TYPE zmvk_stand_tt
                                                RAISING   cx_amdp_error.


    CLASS-METHODS: get_mgkotka_harvesting_block  IMPORTING
                                                           VALUE(contractid)          TYPE int8
                                                           VALUE(blocknumber)         TYPE zmhblockno
                                                 EXPORTING
                                                           VALUE(harvest_block_table) TYPE zmgkotka_harvesting_tt
                                                 RAISING   cx_amdp_error.



    CLASS-METHODS: findStoragesWithContractid      IMPORTING
                                                             VALUE(contractid)    TYPE int8
                                                   EXPORTING
                                                             VALUE(storage_table) TYPE zmgkotka_storage_tt
                                                   RAISING   cx_amdp_error.




  PROTECTED SECTION.



    CLASS-METHODS _lookupId
      IMPORTING
        iv_id           TYPE csequence
      RETURNING
        VALUE(r_result) TYPE REF TO zcl_gis_amdp_base.
    "! <p class="shorttext synchronized" lang="en"></p>
    "! For each Interface subclass this is the main place that creates the implementation class
    "! Each time new interface implementtaion is created it should be added to the COND
    "! @parameter iv_id | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter r_result | <p class="shorttext synchronized" lang="en"></p>
    "! @raising zcx_gis_invalid_param | <p class="shorttext synchronized" lang="en"></p>
    CLASS-METHODS create_matching_impl
      IMPORTING
        iv_id           TYPE csequence
      RETURNING
        VALUE(r_result) TYPE REF TO zcl_gis_amdp_base
      RAISING
        zcx_gis_invalid_param.
    CLASS-DATA: mt_instances TYPE  tt_instances.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_gis_amdp_base IMPLEMENTATION.


  METHOD create_matching_impl.

    r_result =  COND #(
     WHEN iv_id CS '1036' THEN  NEW zcl_gis_amdp_id1036(  )
     WHEN iv_id CS '1135' THEN  NEW zcl_gis_amdp_id1135(  )
     WHEN iv_id CS '1142' THEN  NEW zcl_gis_amdp_id1142(  )
     WHEN iv_id CS '1174' THEN  NEW zcl_gis_amdp_id1174(  )
     WHEN iv_id CS '1175' THEN  NEW zcl_gis_amdp_id1175(  )
     WHEN iv_id CS '1181' THEN  NEW zcl_gis_amdp_id1181(  )
     WHEN iv_id CS '1182' THEN  NEW zcl_gis_amdp_id1182(  )
     WHEN iv_id CS '1183' THEN  NEW zcl_gis_amdp_id1183(  )
     WHEN iv_id CS '1191' THEN  NEW zcl_gis_amdp_id1191(  )
     WHEN iv_id CS '1221' THEN  NEW zcl_gis_amdp_id1221(  )
     WHEN iv_id CS '1470' THEN  NEW zcl_gis_amdp_id1470(  )
     WHEN iv_id CS '211'  THEN  NEW zcl_gis_amdp_id211(  )
     WHEN iv_id CS '408'  THEN  NEW zcl_gis_amdp_id408(  )
     WHEN iv_id CS '409'  THEN  NEW zcl_gis_amdp_id409(  )
     WHEN iv_id CS '410'  THEN  NEW zcl_gis_amdp_id410(  )
     WHEN iv_id CS '411'  THEN  NEW zcl_gis_amdp_id411(  )
     WHEN iv_id CS '736'  THEN  NEW zcl_gis_amdp_id736(  )
     WHEN iv_id CS '744'  THEN  NEW zcl_gis_amdp_id744(  )
     WHEN iv_id CS '746'  THEN  NEW zcl_gis_amdp_id746(  )
     WHEN iv_id CS '813'  THEN  NEW zcl_gis_amdp_id813(  )
     WHEN iv_id CS '815'  THEN  NEW zcl_gis_amdp_id815(  )
     WHEN iv_id CS '817'  THEN  NEW zcl_gis_amdp_id817(  )
     WHEN iv_id CS '869'  THEN  NEW zcl_gis_amdp_id869(  )
     WHEN iv_id CS '871'  THEN  NEW zcl_gis_amdp_id871(  )
     WHEN iv_id CS '882'  THEN  NEW zcl_gis_amdp_id882(  )
     WHEN iv_id CS '902'  THEN  NEW zcl_gis_amdp_id902(  )
     WHEN iv_id CS '916'  THEN  NEW zcl_gis_amdp_id916(  )
     WHEN iv_id CS '917'  THEN  NEW zcl_gis_amdp_id917(  )
        ELSE THROW zcx_gis_invalid_param( parameter = |{ iv_id }| ) ).

  ENDMETHOD.


  METHOD findsampleplotswithStandid BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.

    if :IS_HARVESTING  =  'X'
        then
         matching_sampleplots_table = SELECT o.standnumber as stand_number,
                                             1 as test_area_number,
                                             o.GEOLOC_MJ as GEOLOC_MJ,
                                             TO_NCLOB(o.GEOLOC_MJ.ST_AsWKT()) as GEOLOC_MJ_string
                                          FROM
                                      "MG_KOTKA"."SAMPLEPLOT" o
                                 WHERE o.SW_PLANNINGSTANDID=:STAND_ID AND (o.STATUS IS NULL OR o.STATUS != 3)
                                 AND (o.SOURCEOFINSPECTION IS NULL OR o.SOURCEOFINSPECTION != 'Haukka');
        else
          matching_sampleplots_table = SELECT o.standnumber as stand_number,
                                              1 as test_area_number,
                                              o.GEOLOC_MJ as GEOLOC_MJ,
                                              TO_NCLOB(o.GEOLOC_MJ.ST_AsWKT()) as GEOLOC_MJ_string
                                          FROM
                                      "MG_KOTKA"."SAMPLEPLOT" o
                                 WHERE o.SW_PLANNINGSTANDID=:STAND_ID AND (o.STATUS IS NULL OR o.STATUS != 3)
                                 AND (o.SOURCEOFINSPECTION IS NULL OR o.SOURCEOFINSPECTION != 'Haukka');
     end if;
  ENDMETHOD.


  METHOD findsampleplotswithstandid_tf BY DATABASE FUNCTION FOR HDB
                              LANGUAGE SQLSCRIPT USING
                              zcl_gis_amdp_base=>findsampleplotswithstandid.


    --find sw_planningblock: from mg_kotka.sw_planningblock
     call "ZCL_GIS_AMDP_BASE=>FINDSAMPLEPLOTSWITHSTANDID"
              ( stand_id => :p_STANDID
               ,is_harvesting => :p_is_harvesting
               ,matching_sampleplots_table => :lt_matching_sampleplots_table
              );



       return select stand_number,
                     geoloc_mj,
                     geoloc_mj_string
                     from :lt_matching_sampleplots_table;


  ENDMETHOD.


  METHOD findStoragesWithContractid BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
    storage_table =     SELECT  o.storage_number as storage_number,
                        o.infotext as storage_info,
                        o.geoloc as GEOMETRY_ewkb,
                        to_nclob(o.geoloc.ST_AsWKT()) as geometry
                        FROM
                    "MG_KOTKA"."STORAGE" o
                    WHERE o.contractid=:contractid;


  ENDMETHOD.





  METHOD get_mgkotka_harvesting_block BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
    if :contractid is not null and :blocknumber is not null
     then
      harvest_block_table = SELECT contractid as contractid,
                                     harvestingblockid as harvesting_blockid,
                                     blocknumber
                                    FROM "MG_KOTKA"."HARVESTINGBLOCK"
                                    WHERE contractid = :contractid and blocknumber = :blocknumber;
    end if;

  ENDMETHOD.


  METHOD get_mgkotka_logy_harvestblock BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.

    -- apply_filter("SAP_HANA_DEMO"."sap.hana.democontent.epm.data::MD.Products", :im_filter_string) ;
      if :contractid is not null and :blocknumber is not null
       then
        logy_harvest_block_table = SELECT h.contractid,
                                     h.blocknumber,
                                     h.logy_code
                                  FROM
                                   "MG_KOTKA"."VI_LOGY_OF_HARVESTINGBLOCK" h
                                   WHERE contractid =:contractid and blocknumber=:blocknumber;
       end if;
  ENDMETHOD.


  METHOD get_mgkotka_logy_silviblock BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
    if :contractid is not null and :blocknumber is not null
     then
      logy_silvi_block_table = SELECT h.silviculturalorderid as contractid,
                                   h.blocknumber,
                                   h.logy_code
                                FROM
                                 "MG_KOTKA"."VI_LOGY_OF_SILVICBLOCK" h
                                 WHERE silviculturalorderid =:contractid and blocknumber=:blocknumber;
     end if;

  ENDMETHOD.


  METHOD get_mgkotka_sw_planningblock BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
    --Check the parameters
      if :contractid is not null and :blocknumber is not null
            then
                planning_table = SELECT silviculturalorderid as contractid,
                                     sw_planningblockid as planning_blockid,
                                     blocknumber
                                    FROM "MG_KOTKA"."SW_PLANNINGBLOCK"
                                    WHERE silviculturalorderid = :contractid and blocknumber = :blocknumber;
        end if;

  ENDMETHOD.


  METHOD get_mvk_stand BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
    if :stand_id is not null
     then
      stand_table = SELECT   s.stand_id as stand_id,
                             s.fertility_class as fertility_class,
                             s.development_class as development_class,
                             s.soil_type as soil_type
                             FROM mvk.stand s
                              WHERE stand_id = :stand_id;
     end if;

  ENDMETHOD.

  METHOD get_instance.
    DATA(ls_instances) =  VALUE ty_instances( ).

    BREAK-POINT ID zml_gis_amdp.

** Check whether the id exists in the cache
    rv_instance = _lookupId( iv_id = iv_id ).
    IF  rv_instance IS BOUND.
      RETURN.
    ENDIF.

**if come here then it doesnot exist yet
***Create the amdp object
    try.
        ls_instances-ref = create_matching_impl( iv_id = iv_id ).
        IF ls_instances-ref IS BOUND.
          ls_instances-id = iv_id.
          INSERT ls_instances INTO TABLE  mt_instances.
          rv_instance = ls_instances-ref.
          RETURN.
        ENDIF.
      catch cx_root into data(lo_exception).
**Exception area
        " Raise an Exception or not
        raise exception type zcx_unexpected_exception MESSAGE e002(zml_gis_amdp) with iv_id.

    endtry.
  ENDMETHOD.
  METHOD _lookupId.
*    r_result = xsdbool( line_exists( mt_instances[ id =  iv_id ] ) ).

    LOOP AT mt_instances ASSIGNING FIELD-SYMBOL(<lfs_instances>) WHERE id CS iv_id.
    ENDLOOP.

    IF sy-subrc IS INITIAL.
      r_result = <lfs_instances>-ref.
    ENDIF.
  ENDMETHOD.
  METHOD find_actualgeometry BY DATABASE FUNCTION
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.


  return  SELECT  actualgeometryid,
                  actualblockid,
                  geoloc
          from "GISDATA"."ACTUALGEOMETRY"
          where actualgeometryid = :p_actualgeometryid;


  ENDMETHOD.



  method get_actualgeometries BY DATABASE FUNCTION
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.
* Declare local variables
    declare lv_record_number integer DEFAULT 10;


   select count( actualgeometryid )
     from "GISDATA"."ACTUALGEOMETRY";

      if ::rowcount > 100.
        then
        lv_record_number = 100;
      end IF ;

  return  SELECT  actualgeometryid,
                  actualblockid,
                  gpsquality
          from "GISDATA"."ACTUALGEOMETRY"
          limit :lv_record_number;


  ENDMETHOD.

ENDCLASS.