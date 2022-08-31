"! <p class="shorttext synchronized" lang="en">GetWorkingSiteMapSymbolModifications</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/GetWorkingSiteMapSymbolModifications</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_gisfetch01/source/main#start=195,3;end=199,39</p>
CLASS zcl_gis_amdp_id869 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">For Harvesting </p>
    "! <p class="shorttext synchronized" lang="en">Time in the "dd.mm.yyyy HH:MM:SS" format</p>
    "! @parameter start_time | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter end_time | <p class="shorttext synchronized" lang="en"></p>
    "! @raising cx_amdp_error | <p class="shorttext synchronized" lang="en"></p>
    METHODS GetWorkingSiteMapSymModify
      IMPORTING
                VALUE(start_time) TYPE string
                VALUE(end_time)   TYPE string
      EXPORTING VALUE(response_contracts) type ZIIDT_ID869_MSMOD_GIS_GET_TAB
      RAISING   cx_amdp_error.




  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id869 IMPLEMENTATION.



  METHOD getworkingsitemapsymModify BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            OPTIONS READ-ONLY
                            .
* local variables
    declare start_date timestamp = TO_TIMESTAMP( start_time, 'dd.mm.yyyy HH:MI:SS' );
    declare end_date timestamp = TO_TIMESTAMP( end_time, 'dd.mm.yyyy HH:MI:SS' );

* harvesting contract rows (ContractType "H") are searched for the rows modified during the given time range

* VI_HARVESTINGBLOCK_OF_STORAGE
    contracts_t = SELECT 'H' contracttype, CASE WHEN LENGTH(contractid) > 1 THEN LEFT (contractid, LENGTH(contractid) - 1) ELSE contractid END contractid,
                        CASE WHEN LENGTH(contractid) > 1 THEN RIGHT (contractid, 1) ELSE contractid END decade, blocknumber
                        FROM MG_KOTKA.VI_HARVESTINGBLOCK_OF_STORAGE o WHERE o.UPDATED_ON between start_date and end_date;

    harvesting_stands = SELECT DISTINCT HARVESTINGBLOCKID FROM MG_KOTKA.HARVESTINGSTAND WHERE GEOLOC IS NOT NULL AND UPDATED_ON BETWEEN start_date and end_date;

* HARVESTINGBLOCK
    contracts_t = select * from :contracts_t
                        union
                        select 'H' contracttype, CASE WHEN LENGTH(contractid) > 1 THEN LEFT (contractid, LENGTH(contractid) - 1) ELSE contractid END contractid,
                        CASE WHEN LENGTH(contractid) > 1 THEN RIGHT (contractid, 1) ELSE contractid END decade, blocknumber
                        FROM MG_KOTKA.HARVESTINGBLOCK where harvestingblockid in ( select harvestingblockid from :harvesting_stands );

* VI_HARVESTINGBLOCK_OF_GISDATA
    contracts_t = select * from :contracts_t
                        union
                        SELECT 'H' contracttype, CASE WHEN LENGTH(contractid) > 1 THEN LEFT (contractid, LENGTH(contractid) - 1) ELSE contractid END contractid,
                        CASE WHEN LENGTH(contractid) > 1 THEN RIGHT (contractid, 1) ELSE contractid END decade, blocknumber
                        FROM MG_KOTKA.VI_HARVESTINGBLOCK_OF_GISDATA o WHERE o.UPDATED_ON between start_date and end_date;

* VI_HARVBLOCK_OF_OLD_GISDATA
    contracts_t = select * from :contracts_t
                        union
                        SELECT 'H' contracttype, CASE WHEN LENGTH(contractid) > 1 THEN LEFT (contractid, LENGTH(contractid) - 1) ELSE contractid END contractid,
                        CASE WHEN LENGTH(contractid) > 1 THEN RIGHT (contractid, 1) ELSE contractid END decade, blocknumber
                        FROM MG_KOTKA.VI_HARVBLOCK_OF_OLD_GISDATA o WHERE o.UPDATED_ON between start_date and end_date;

* silviculture contract (silviculturalorderid) rows (ContractType "S") are searched for the rows modified during the given time range

* VI_SILVICBLOCK_OF_STORAGE
    contracts_t = select * from :contracts_t
                        union
                        SELECT 'S' contracttype, silviculturalorderid contractid, null decade, blocknumber
                        FROM MG_KOTKA.VI_SILVICBLOCK_OF_STORAGE o WHERE o.UPDATED_ON between start_date and end_date;

    planning_stands = SELECT DISTINCT SW_PLANNINGBLOCKID FROM MG_KOTKA.SW_PLANNINGSTAND WHERE GEOLOC IS NOT NULL AND UPDATED_ON BETWEEN start_date and end_date;

* PLANNINGBLOCK
    contracts_t = select * from :contracts_t
                        union
                        select 'S' contracttype, silviculturalorderid contractid, null decade, blocknumber
                        FROM MG_KOTKA.SW_PLANNINGBLOCK where sw_planningblockid in ( select sw_planningblockid from :planning_stands );

* VI_SILVICBLOCK_OF_GISDATA
    contracts_t = select * from :contracts_t
                        union
                        SELECT 'S' contracttype, silviculturalorderid contractid, null decade, blocknumber
                        FROM MG_KOTKA.VI_SILVICBLOCK_OF_GISDATA o WHERE o.UPDATED_ON between start_date and end_date;

* VI_SILVICBLOCK_OF_OLD_GISDATA
    contracts_t = select * from :contracts_t
                        union
                        SELECT 'S' contracttype, silviculturalorderid contractid, null decade, blocknumber
                        FROM MG_KOTKA.VI_SILVICBLOCK_OF_OLD_GISDATA o WHERE o.UPDATED_ON between start_date and end_date;

    response_contracts = select distinct
      contracttype,
      contractid,
      decade,
      blocknumber
      from :contracts_t;

  ENDMETHOD.

ENDCLASS.