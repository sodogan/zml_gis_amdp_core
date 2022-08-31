"! <p class="shorttext synchronized" lang="en">SaveResource</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveResource</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id536_i_resource/source/main#start=1046,11;end=1051,0 </p>
CLASS zcl_gis_amdp_id916 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS SaveResource
      IMPORTING
                VALUE(in_resourceid)     TYPE zzresource
                VALUE(contractors)    TYPE ziidt_id916_resource_gis_sav5
                VALUE(owncontid)      TYPE string
                VALUE(resourceid_sb)  TYPE zzresource
                VALUE(restype)        TYPE zzrestype
                VALUE(resname)        TYPE zzresname
                VALUE(reslocation)    TYPE string
                VALUE(action)         TYPE zzaction
                VALUE(restelephone)   TYPE zzrestelephone
                VALUE(resremoved)     TYPE zzresremoved
                VALUE(resremoveddate) TYPE string
      EXPORTING
                VALUE(out_resourceid)     TYPE zzresource
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id916 IMPLEMENTATION.

  METHOD SaveResource BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            USING   zcl_gis_amdp_util=>geoxml_to_geoshape.

* local variables
    declare geometry st_geometry;
    declare lv_st_text String;
    declare lv_geom_type string;
    declare removed_date timestamp;


    --Convert the geom string to geometric object
    call "ZCL_GIS_AMDP_UTIL=>GEOXML_TO_GEOSHAPE"(
          poslist => :reslocation,
          gtype   => 'pP',
          st_text => :lv_st_text,
          geom_type => :lv_geom_type,
          geom    => :geometry /*set the geom object*/
        );

    --Set removed timestmp
    if LENGTH( :resremoveddate ) > 0
    then
        removed_date = TO_TIMESTAMP( :resremoveddate, 'yyyy-mm-dd');
    else
        select TO_TIMESTAMP(TO_VARCHAR(CURRENT_DATE, 'yyyy-mm-dd'), 'yyyy-mm-dd') into removed_date from dummy;
    end if;

    if :action = 2 -- action delete
    then
        update GISDATA.WF_RESOURCE set REMOVED='K', REMOVEDATE = :removed_date where RESOURCEID = :in_resourceid;
    elseif :action = 1 -- action insert/update
    then
    -- insert/update resources
        merge into GISDATA.WF_RESOURCE using ( select
            :in_resourceid,
            :owncontid,
            :resourceid_sb,
            :resname,
            :restype,
            :geometry,
            :restelephone,
            :resremoved,
            :removed_date
        from dummy ) on ( GISDATA.WF_RESOURCE.RESOURCEID = :in_resourceid )
        when matched then
        update set
            GISDATA.WF_RESOURCE.OWNERCONTRACTORID =  :owncontid,
            GISDATA.WF_RESOURCE.SERVICEBUYERRESOURCEID = :resourceid_sb,
            GISDATA.WF_RESOURCE.RESOURCENAME = :resname,
            GISDATA.WF_RESOURCE.RESOURCETYPE = :restype,
            GISDATA.WF_RESOURCE.GEOLOC = :geometry,
            GISDATA.WF_RESOURCE.TELEPHONE = :restelephone,
            GISDATA.WF_RESOURCE.REMOVED = :resremoved,
            GISDATA.WF_RESOURCE.REMOVEDATE = :removed_date,
            GISDATA.WF_RESOURCE.UPDATED_ON = CURRENT_TIMESTAMP
        when not matched then
        insert
        (
        RESOURCEID,
        OWNERCONTRACTORID,
        SERVICEBUYERRESOURCEID,
        RESOURCENAME,
        RESOURCETYPE,
        GEOLOC,
        CREATED_BY,
        UPDATED_BY,
        CREATED_ON,
        UPDATED_ON,
        TELEPHONE,
        REMOVED,
        REMOVEDATE
        )
        values (
       :in_resourceid,
       :owncontid,
       :resourceid_sb,
       :restype,
       :resname,
       :geometry,
       'MG_KARHU',
       'MG_KARHU',
       CURRENT_TIMESTAMP,
       CURRENT_TIMESTAMP,
       :restelephone,
       :resremoved,
       :removed_date );

    -- insert/update contractor of resource

        contr_of_res = SELECT DISTINCT WF_CONTRACTOR_OF_RESOURCE.CONTRACTORID, :in_resourceid resourceid FROM GISDATA.WF_CONTRACTOR_OF_RESOURCE
            LEFT JOIN GISDATA.WF_COMPANY ON WF_COMPANY.CONTRACTORID = WF_CONTRACTOR_OF_RESOURCE.CONTRACTORID WHERE WF_CONTRACTOR_OF_RESOURCE.CONTRACTORID IN
            (select * from :contractors) AND WF_COMPANY.CONTRACTORID IS NOT NULL;

        DELETE FROM GISDATA.WF_CONTRACTOR_OF_RESOURCE WHERE WF_CONTRACTOR_OF_RESOURCE.RESOURCEID = :in_resourceid;

        INSERT INTO GISDATA.WF_CONTRACTOR_OF_RESOURCE SELECT GISDATA.WF_CONTRACTOR_OF_RESOURCE_SEQ.nextval, :contr_of_res.resourceid, :contr_of_res.contractorid from :contr_of_res;

    end if;

    out_resourceid = :in_resourceid;

  ENDMETHOD.

ENDCLASS.