"! <p class="shorttext synchronized" lang="en">GetMapSymbolModif</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_gisfetch03/source/main#start=144,5;end=148,40 </p>
CLASS zcl_gis_amdp_id1182 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS get_map_symbol_modif
      IMPORTING
                VALUE(in_starttime)  TYPE string
                VALUE(in_endtime)    TYPE string
      EXPORTING
                VALUE(out_starttime)  TYPE string
                VALUE(out_endtime)    TYPE string
                VALUE(contracts)      TYPE zprdtid1182_gisget_map_sy_tab
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1182 IMPLEMENTATION.

  METHOD get_map_symbol_modif BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables

    out_starttime = :in_starttime;
    out_endtime = :in_endtime;
    edited_t = SELECT SUBSTRING(TO_NVARCHAR(contractid), 1, LENGTH(TO_NVARCHAR(contractid)) - 1) contractid,
                           SUBSTRING(TO_NVARCHAR(contractid), LENGTH(TO_NVARCHAR(contractid))) decade
                           FROM MG_KOTKA.VI_EDITED_GISDATA_OF_CONTRACT o
*                           WHERE o.UPDATED_ON between to_timestamp(:in_starttime, 'DD.MM.YYYY HH24:MI:SS') and to_timestamp(:in_endtime, 'DD.MM.YYYY HH24:MI:SS');
                           WHERE o.UPDATED_ON between to_timestamp(:in_starttime, 'YYYY-MM-DD"T"HH24:MI:SS') and to_timestamp(:in_endtime, 'YYYY-MM-DD"T"HH24:MI:SS');


* sort by contractid ascending
    contracts = select contractid, decade from :edited_t
                order by contractid asc;

  ENDMETHOD.

ENDCLASS.