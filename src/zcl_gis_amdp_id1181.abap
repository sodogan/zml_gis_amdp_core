"! <p class="shorttext synchronized" lang="en">GetStorageModifica</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_gisfetch02/source/main#start=161,0;end=165,41 </p>
CLASS zcl_gis_amdp_id1181 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS GET_STORAGE_MODIFICA
      IMPORTING
                VALUE(in_starttime)   TYPE string
                VALUE(in_endtime)     TYPE string
      EXPORTING
                VALUE(out_starttime)  TYPE string
                VALUE(out_endtime)    TYPE string
                VALUE(storages)       type ZPRDTID1181_GISGET_STORAG_TAB
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1181 IMPLEMENTATION.

  METHOD GET_STORAGE_MODIFICA BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            OPTIONS READ-ONLY
                            .
* Time format 'YYYY-MM-DD"T"HH24:MI:SS'
* local variables


  out_starttime = :in_starttime;
  out_endtime = :in_endtime;

  storages_stg_storage = SELECT SUBSTRING(TO_NVARCHAR(contractid), 1, LENGTH(TO_NVARCHAR(contractid)) - 1) contractid,
                         SUBSTRING(TO_NVARCHAR(contractid), LENGTH(TO_NVARCHAR(contractid))) decade, TO_NVARCHAR(storage_number) storagenumber
                         FROM MG_KOTKA.STORAGE
                         WHERE UPDATED_ON between to_timestamp(:in_starttime, 'YYYY-MM-DD"T"HH24:MI:SS') and to_timestamp(:in_endtime, 'YYYY-MM-DD"T"HH24:MI:SS')
                         and contractid is not null and storage_number is not null;

  storages_stg_gis_point = SELECT SUBSTRING(TO_NVARCHAR(contractid), 1, LENGTH(TO_NVARCHAR(contractid)) - 1) contractid,
                           SUBSTRING(TO_NVARCHAR(contractid), LENGTH(TO_NVARCHAR(contractid))) decade, SUBSTRING(FEATUREINFO, 3)
                           FROM GISDATA.GIS_POINT
                           WHERE CONTRACTID is not null and FEATURECODE='10033' and FEATUREINFO like 'VP %' and UPDATED_ON between to_timestamp(:in_starttime, 'YYYY-MM-DD"T"HH24:MI:SS') and to_timestamp(:in_endtime, 'YYYY-MM-DD"T"HH24:MI:SS');

  storages = select * from :storages_stg_storage
             union
             select * from :storages_stg_gis_point where CONCAT(contractid, decade)
             not in ( select CONCAT(contractid, decade) from :storages_stg_storage )
* Sort the output by contractid ascending
             order by contractid asc;



  ENDMETHOD.

ENDCLASS.