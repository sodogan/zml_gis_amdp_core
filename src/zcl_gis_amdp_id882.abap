"! <p class="shorttext synchronized" lang="en">MG0882 Rungonosa</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/MG0882+Rungonosa</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger:adt://WSD/sap/bc/adt/oo/classes/zcl_id745_wso_harvesting/source/main#start=4746,0;end=4751,53</p>
CLASS zcl_gis_amdp_id882 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.


    METHODS MG0882_Rungonosa
      IMPORTING
                VALUE(logy)             TYPE zzlogy
                VALUE(hinnoittelumuoto) TYPE zzpricingtype
      EXPORTING VALUE(rungonosa_table)  TYPE ziirungonosa_type_tab
      RAISING   cx_amdp_error.




  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id882 IMPLEMENTATION.


  METHOD MG0882_Rungonosa BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.
    --Local data declarations
    DECLARE lv_index INTEGER;
    DECLARE lv_logisticsunit_id NVARCHAR( 20 ) = :LOGY;

    --Steps to follow
   --Get the district of logy-single record needed
    lt_districts =    select district_id
                           from
                      "MG_SPATIAL"."V_GIS_LOGISTICSUNIT"
                        where logisticsunit_id = :lv_logisticsunit_id;

    if not is_empty( :lt_districts )
      then
   --Get Diametersections of District
      lt_diametersections = select
                               piiri,
                               puulaji,
                               koodi,
                               nimi,
                               lpm as minimi_lpm,
                               MINPIT as minimi_pituus,
                               KAYTTOPUUKAUPASSA as puukauppa
                            from "MLOAPTERI"."APTEERAUS_RUNGONOSA_UUSI"
                            where piiri IN (  select
                                               district_id
                                             from :lt_districts
                                            )
                            order by puulaji, koodi;


      --Fill in the response
         rungonosa_table = select piiri,
                                  puulaji,
                                  koodi,
                                  nimi,
                                  TO_NVARCHAR( minimi_lpm  ) as minimi_lpm,
                                  TO_NVARCHAR( minimi_pituus ) as minimi_pituus,
                                  CASE WHEN ( puukauppa = 1.00 ) THEN 'X'
                                   ELSE ''
                                  END as puukauppa
                           from  :lt_diametersections;

    end if;



  ENDMETHOD.




ENDCLASS.