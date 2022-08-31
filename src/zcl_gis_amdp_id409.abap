"! <p class="shorttext synchronized" lang="en">ManageStorageLocation</p>
"! <p class="shorttext synchronized" lang="en"></p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_gis_control_3/source/main#start=234,3;end=238,36 </p>
CLASS zcl_gis_amdp_id409 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS MANAGE_STORAGE_LOCATION
      IMPORTING
                VALUE(contract_number)        TYPE zzprcontract_number_type
                VALUE(decade)                 TYPE zzprdecade_type
                VALUE(storage_number)         TYPE zzprstorage_number_type
*  TODO: Not needed as Not used from the JAVA side
*                VALUE(transport_condition)    TYPE zzprtransport_condition_type
*                VALUE(transport_restriction)  TYPE xsdboolean
*                VALUE(ploughing_need)         TYPE xsdboolean
*                VALUE(ploughing_name)         TYPE string
*                VALUE(ploughing_phone)        TYPE string
*                VALUE(ploughing_date)         TYPE string
                VALUE(coordinate_system)      TYPE zzprcoordinate_system_type
                VALUE(coordinates)            TYPE string
                VALUE(in_action)              TYPE string
    EXPORTING
                VALUE(code)                  TYPE string
                VALUE(out_action)            TYPE string
                VALUE(info)                  TYPE string
                VALUE(status)                TYPE string
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id409 IMPLEMENTATION.

  METHOD MANAGE_STORAGE_LOCATION BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare cs nvarchar( 10 );
    declare srs int = 2393;
    declare xcoordinput double;
    declare ycoordinput double;
    declare xcoord double;
    declare ycoord double;
    declare action nvarchar( 20 ) = :in_action;
    declare contract_decade bigint = TO_BIGINT( :contract_number || :decade );
    declare rowscount bigint;

    if length( :coordinates ) > 0
    then
        SELECT TO_DOUBLE(SUBSTR_BEFORE(:coordinates, CHAR(32))), TO_DOUBLE(SUBSTR_AFTER(:coordinates, CHAR(32))) into xcoordinput, ycoordinput default null, null FROM dummy;

        if :coordinate_system = 'EUREF'
        then
            xcoord = :xcoordinput;
            ycoord = :ycoordinput;
        else
            select a.geoloc.ST_X( ), a.geoloc.ST_Y( ) into xcoord, ycoord default null, null  from
                  (
                  select NEW ST_Point( 'Point (' || TO_NVARCHAR(:xcoordinput) || CHAR(32) || TO_NVARCHAR(:ycoordinput) || ')', :srs).ST_Transform( 3067 ) as geoloc from dummy
                  ) a;
        end if;
    end if;

    if :action = 'INSERT'
    then
        declare storageaccount bigint;

        select count(*) into storageaccount default null from mg_kotka.STORAGE WHERE CONTRACTID = :contract_decade and STORAGE_NUMBER = :storage_number;

        if :storageaccount > 0
        then
            action = 'UPDATE';
        else
            if :xcoord is not null
            then
                INSERT INTO mg_kotka.storage (CONTRACTID, STORAGE_NUMBER, GEOLOC, STORAGEID, STATUS)
                VALUES (:contract_decade, :storage_number, NEW ST_Point( 'Point (' || TO_NVARCHAR(:xcoord) || CHAR(32) || TO_NVARCHAR(:ycoord) || ')', 3067), mg_kotka.storage_seq.nextval,1);
            else
                INSERT INTO mg_kotka.storage (CONTRACTID, STORAGE_NUMBER, STORAGEID, STATUS) VALUES (:contract_decade,:storage_number,mg_kotka.storage_seq.nextval,1);
            end if;
            SELECT ::ROWCOUNT into rowscount FROM DUMMY;
            code = :contract_number || :storage_number;
            out_action = :action;
            info = TO_NVARCHAR( :rowscount ) || ' row(s) affected';
            status = 'OK';
        end if;
    end if;

    if :action = 'UPDATE'
    then
        declare storageaccount bigint;

        select count(*) into storageaccount default null from mg_kotka.STORAGE WHERE CONTRACTID = :contract_decade and STORAGE_NUMBER = :storage_number;

        if :xcoord is not null
        then
            UPDATE mg_kotka.STORAGE SET
                            geoloc = NEW ST_Point( 'Point (' || TO_NVARCHAR(:xcoord) || CHAR(32) || TO_NVARCHAR(:ycoord) || ')', 3067), status= 2
                            WHERE CONTRACTID = :contract_decade and STORAGE_NUMBER = :storage_number;
        else
            UPDATE mg_kotka.STORAGE SET geoloc = NULL, status=2 WHERE CONTRACTID = :contract_decade and STORAGE_NUMBER = :storage_number;
        end if;
        SELECT ::ROWCOUNT into rowscount FROM DUMMY;
        code = :contract_number || :storage_number;
        out_action = :action;
        info = TO_NVARCHAR( :rowscount ) || ' row(s) affected';
        status = 'OK';
    end if;

    if :action = 'DELETE'
    then
        delete from mg_kotka.HARVESTINGBLOCKSTORAGE where STORAGEID in(select storageid from mg_kotka.STORAGE where CONTRACTID=:contract_decade and STORAGE_NUMBER=:storage_number);
        delete from mg_kotka.STORAGE where CONTRACTID=:contract_decade and STORAGE_NUMBER=:storage_number;
        SELECT ::ROWCOUNT into rowscount FROM DUMMY;
        code = :contract_number || :storage_number;
        out_action = :action;
        info = TO_NVARCHAR( :rowscount ) || ' row(s) affected';
        status = 'OK';
    end if;

    if :action != 'INSERT' and :action != 'UPDATE' and :action != 'DELETE'
    then
        code = :contract_number || :storage_number;
        out_action = :action;
        info = '0 row(s) affected';
        status = 'Error';
    end if;

   ENDMETHOD.

ENDCLASS.