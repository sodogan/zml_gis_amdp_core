"! <p class="shorttext synchronized" lang="en">GetWorkingSiteImages</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteImages</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/zpi1_id756_imagesend/source/main#start=222,4;end=226,41</p>
CLASS zcl_gis_amdp_id902 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.


    METHODS GetWorkingSiteImages
      IMPORTING
                VALUE(in_contractid)  TYPE zmhobject
                VALUE(in_blocknumber) TYPE zmhblockno
                VALUE(in_decade)      TYPE zzostosopvk
      EXPORTING
       VALUE(out_contractid)  TYPE zmhobject
       VALUE(out_blocknumber) TYPE zmhblockno
       VALUE(images) type ZIIDT_ID902_MS_GIS_IMAGE__TAB
      RAISING   cx_amdp_error.






  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id902 IMPLEMENTATION.

  METHOD GetWorkingSiteImages BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            OPTIONS READ-ONLY
                            USING   zcl_gis_amdp_util=>geoshape_to_xml.

* local variables
    declare lv_index integer;
    declare contract_with_decade string;
    declare contracts_t table ( contract bigint );
    declare output_t table (
        STANDID nvarchar(100),
        CATEGORY nvarchar(100),
        SUBCATEGORY nvarchar(100),
        MAPSYMBOLTYPE nvarchar(100),
        MAPSYMBOLID nvarchar(100),
        POSITION nvarchar(10000),
        INFOTEXT nvarchar(100),
        PHOTOGRAPHER nvarchar(100),
        IMAGEDATE nvarchar(100),
        FILENAME nvarchar(100),
        FILEURL nvarchar(100),
        GEOMETRY st_geometry
     );

* The purpose of the service is to retrieve from the spatial database and the metadata of the image service the data that goes in the direction of WoodForce in the Image message.
* The service itself does not return image data, but links to images found in the Image Service

    contract_with_decade = CONCAT(:in_contractid,:in_decade);
    out_contractid = contract_with_decade;
    out_blocknumber = in_blocknumber;

    if in_decade is not null and LENGTH( in_decade ) > 0 then
        contracts_t = select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :contract_with_decade );
    else
        contracts_t =
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :in_contractid || '0')
            union
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :in_contractid || '1')
            union
            select contractid as contract from MG_KOTKA.CONTRACT where CONTRACT.CONTRACTID = TO_BIGINT( :in_contractid || '2')
            ;
    end if;

    if NOT IS_EMPTY(:contracts_t)
    then
        hv_blocks = SELECT HARVESTINGBLOCKID FROM MG_KOTKA.HARVESTINGBLOCK WHERE CONTRACTID IN ( select contract from :contracts_t where contract is not null );

        output_t = SELECT
            STANDID,
            CATEGORY,
            SUBCATEGORY,
            MAPSYMBOLTYPE,
            MAPSYMBOLID,
            null as POSITION,
            INFOTEXT,
            PHOTOGRAPHED_BY as PHOTOGRAPHER,
            PHOTOGRAPHED_ON as IMAGEDATE,
            NAME as FILENAME,
            REPLACE(IMAGE, '&', '&amp;') as FILEURL,
            GEOLOC as GEOMETRY
        FROM MG_KOTKA.VI_IMAGE_OF_HARVESTINGBLOCK o WHERE o.HARVESTINGBLOCKID IN ( select HARVESTINGBLOCKID from :hv_blocks );
    else
        pl_blocks = SELECT SW_PLANNINGBLOCKID FROM MG_KOTKA.SW_PLANNINGBLOCK WHERE SILVICULTURALORDERID = :in_contractid;

        output_t = SELECT
            STANDID,
            CATEGORY,
            SUBCATEGORY,
            MAPSYMBOLTYPE,
            MAPSYMBOLID,
            null as POSITION,
            INFOTEXT,
            PHOTOGRAPHED_BY as PHOTOGRAPHER,
            PHOTOGRAPHED_ON as IMAGEDATE,
            NAME as FILENAME,
            REPLACE(IMAGE, '&', '&amp;') as FILEURL,
            GEOLOC as GEOMETRY
        FROM MG_KOTKA.VI_IMAGE_OF_SILVICBLOCK o WHERE o.SW_PLANNINGBLOCKID IN ( select SW_PLANNINGBLOCKID from :pl_blocks );
    end if;

   --Loop the table to set the geometry
    for lv_index in 1..record_count(:output_t)
      do
        declare geom nvarchar ( 10000 );
        declare shape_orig st_geometry = :output_t.geometry[:lv_index];
        call "ZCL_GIS_AMDP_UTIL=>GEOSHAPE_TO_XML"(
            shape=>:shape_orig,
            st_text=>:geom
        );
        output_t.POSITION[:lv_index] = geom;
    end for ;

    images = select
    standid,
    category,
    subcategory,
    mapsymboltype,
    mapsymbolid,
    position,
    infotext,
    photographer,
    imagedate,
    filename,
    fileurl
  from :output_t;

  ENDMETHOD.


ENDCLASS.