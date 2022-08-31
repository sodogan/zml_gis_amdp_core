"! <p class="shorttext synchronized" lang="en">GIS_Save_Status_Send</p>
"! <p class="shorttext synchronized" lang="en">No Pseudocomments yet</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/programs/programs/z_paattyneet_proxy_call/source/main#start=459,2;end=463,42</p>
CLASS zcl_gis_amdp_id1191 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS call_ID1191 IMPORTING VALUE(is_id1191_request) TYPE zprmt_id1191_gissave_status_r1
                                  iref_log_wrapper         TYPE REF TO zcl_application_log_wrapper
                        EXPORTING VALUE(ev_success)        TYPE abap_bool"returns true or false
                                  VALUE(ev_error_msg)      TYPE string.

    METHODS gis_save_status_send
      IMPORTING
                VALUE(in_ostosopimukset_tt) TYPE  zprdtid1191_gissave_stat_tab2
                VALUE(in_lohkot_tt)         TYPE   zprdtid1191_gissave_stat_tab8
                VALUE(in_varastot_tt)       TYPE  zprdtid1191_gissave_statu_tab
                VALUE(in_mhtilaukset_tt)    TYPE zprdtid1191_gissave_stat_tab4
                VALUE(in_mhlohkot_tt)       TYPE zprdtid1191_gissave_stat_tab6
*      exporting
*       VALUE(success) type string/*No need for status as exception handling does it*/
*       VALUE(errortext) type string/*Error text is filled when exception is triggred and catch block handles*/
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_gis_amdp_id1191 IMPLEMENTATION.

  METHOD call_id1191.
    DATA: lt_in_ostosopimukset_tt TYPE  zprdtid1191_gissave_stat_tab2,
          lt_in_lohkot_tt         TYPE  zprdtid1191_gissave_stat_tab8,
          lt_in_varastot_tt       TYPE  zprdtid1191_gissave_statu_tab,
          lt_in_mhtilaukset_tt    TYPE  zprdtid1191_gissave_stat_tab4,
          lt_in_mhlohkot_tt       TYPE  zprdtid1191_gissave_stat_tab6,
          lv_error_short          TYPE string,
          lv_error_long           TYPE string,
          lv_fault_string         TYPE string
          .
    TRY.
        CLEAR: ev_error_msg.
        ev_success = abap_true.

        BREAK-POINT ID zml_gis_amdp.


        ASSERT ID zml_gis_amdp CONDITION  iref_log_wrapper  IS BOUND.

* Move the data into the internal table
        lt_in_ostosopimukset_tt = CORRESPONDING #(  is_id1191_request-mt_id1191_gissave_status_reque-ostosopimukset-ostosopimus ).
        lt_in_lohkot_tt = CORRESPONDING #(  is_id1191_request-mt_id1191_gissave_status_reque-lohkot-lohko ).
        lt_in_varastot_tt = CORRESPONDING #(  is_id1191_request-mt_id1191_gissave_status_reque-varastot-varasto ).
        lt_in_mhtilaukset_tt = CORRESPONDING #( is_id1191_request-mt_id1191_gissave_status_reque-mhtilaukset-mhtilaus  ).
        lt_in_mhlohkot_tt = CORRESPONDING #( is_id1191_request-mt_id1191_gissave_status_reque-mhlohkot-lohko ).


        ASSERT ID zml_gis_amdp CONDITION  lines( lt_in_ostosopimukset_tt ) > 0 AND
                                          lines( lt_in_lohkot_tt ) > 0 AND
                                          lines( lt_in_varastot_tt ) > 0 AND
                                          lines( lt_in_mhtilaukset_tt ) > 0 AND
                                          lines( lt_in_mhlohkot_tt ) > 0 .


**This has a DML operation(Insert or Update)
**Only case returns error is in the catch block otherwise always true
**So all error cases are handled in the catch block
        me->gis_save_status_send(
          EXPORTING
            in_ostosopimukset_tt = lt_in_ostosopimukset_tt
            in_lohkot_tt         = lt_in_lohkot_tt
            in_varastot_tt       = lt_in_varastot_tt
            in_mhtilaukset_tt    = lt_in_mhtilaukset_tt
            in_mhlohkot_tt       = lt_in_mhlohkot_tt
        ).

      CATCH cx_root INTO DATA(lref_cx_root).
        ROLLBACK WORK."All the changes needs to be rolled back
        ev_success = abap_false.
        ev_error_msg = lref_cx_root->get_text( ).
        iref_log_wrapper->add_free_text( type = 'E' string = ev_error_msg ).
        IF iref_log_wrapper->something_is_put_to_log( ) = abap_true.
          iref_log_wrapper->write( ).
        ENDIF.
    ENDTRY.


  ENDMETHOD.


  METHOD gis_save_status_send BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.


    --Local Data Declarations
*   success = 'false';

* update status date or insert new STATUS_HARVESTINGBLOCK
      merge into MLOAPTERI.STATUS_HARVESTINGBLOCK using :in_lohkot_tt
      on STATUS_HARVESTINGBLOCK.CONTRACTID = TO_BIGINT(CONCAT( :in_lohkot_tt.ostosopimus, :in_lohkot_tt.ostosopvk ) )
      and STATUS_HARVESTINGBLOCK.BLOCK_NUMBER = TO_INTEGER( :in_lohkot_tt.lohkonro )
      and STATUS_HARVESTINGBLOCK.BLOCK_STATUS = TO_NVARCHAR( :in_lohkot_tt.status )
      when matched then update set
      STATUS_HARVESTINGBLOCK.STATUS_DATE = TO_TIMESTAMP( :in_lohkot_tt.statuspvm, 'YYYY-MM-DD')
      when not matched then insert
      (
          CONTRACTID,
          BLOCK_NUMBER,
          BLOCK_STATUS,
          STATUS_DATE
       )
      values(
          TO_BIGINT(CONCAT( :in_lohkot_tt.ostosopimus, :in_lohkot_tt.ostosopvk ) ),
          TO_INTEGER( :in_lohkot_tt.lohkonro ),
          TO_NVARCHAR( :in_lohkot_tt.status ),
          TO_TIMESTAMP( :in_lohkot_tt.statuspvm, 'YYYY-MM-DD')
       );

* update status date or insert new STATUS_CONTRACT
      merge into MLOAPTERI.STATUS_CONTRACT using :in_ostosopimukset_tt
      on STATUS_CONTRACT.CONTRACTID = TO_BIGINT(CONCAT( :in_ostosopimukset_tt.ostosopimus, :in_ostosopimukset_tt.ostosopvk ) )
      when matched then update set
      STATUS_CONTRACT.STATUS_DATE = TO_TIMESTAMP( :in_ostosopimukset_tt.statuspvm, 'YYYY-MM-DD')
      when not matched then insert(
          CONTRACTID,
          CONTRACT_STATUS,
          STATUS_DATE
       )
       values(
          TO_BIGINT(CONCAT( :in_ostosopimukset_tt.ostosopimus, :in_ostosopimukset_tt.ostosopvk ) ),
          1,
          TO_TIMESTAMP( :in_ostosopimukset_tt.statuspvm, 'YYYY-MM-DD')
        );

* update status date or insert new STATUS_STORAGE
      merge into MLOAPTERI.STATUS_STORAGE using :in_varastot_tt
      on STATUS_STORAGE.CONTRACTID = TO_BIGINT(CONCAT( :in_varastot_tt.ostosopimus, :in_varastot_tt.ostosopvk ) )
      and STATUS_STORAGE.STORAGE_NUMBER = TO_DECIMAL( :in_varastot_tt.sopnovarpa )
      when matched then update set
      STATUS_STORAGE.STATUS_DATE = TO_DATE( :in_varastot_tt.statuspvm, 'YYYY-MM-DD')
      when not matched then insert(
          CONTRACTID,
          STORAGE_NUMBER,
          STORAGE_STATUS,
          STATUS_DATE
       )
       values(
          TO_BIGINT(CONCAT( :in_varastot_tt.ostosopimus, :in_varastot_tt.ostosopvk ) ),
          TO_DECIMAL( :in_varastot_tt.sopnovarpa ),
          1,
          TO_TIMESTAMP( :in_varastot_tt.statuspvm, 'YYYY-MM-DD')
        );

* update status date or insert new STATUS_SWORDER
      merge into MLOAPTERI.STATUS_SWORDER using :in_mhtilaukset_tt
      on STATUS_SWORDER.SILVICULTURALORDERID = TO_BIGINT( :in_mhtilaukset_tt.mhtilaus )
      when matched then update set
      STATUS_SWORDER.STATUS_DATE = TO_TIMESTAMP( :in_mhtilaukset_tt.statuspvm, 'YYYY-MM-DD')
      when not matched then insert(
          SILVICULTURALORDERID,
          SWORDER_STATUS,
          STATUS_DATE
       )
       values(
          TO_BIGINT( :in_mhtilaukset_tt.mhtilaus ),
          1,
          TO_TIMESTAMP( :in_mhtilaukset_tt.statuspvm, 'YYYY-MM-DD')
        );

* update status date or insert new STATUS_SW_PLANNINGBLOCK
      merge into MLOAPTERI.STATUS_SW_PLANNINGBLOCK using :in_mhlohkot_tt
      on STATUS_SW_PLANNINGBLOCK.SILVICULTURALORDERID = TO_BIGINT( :in_mhlohkot_tt.mhtilaus )
      and STATUS_SW_PLANNINGBLOCK.BLOCK_NUMBER = TO_INTEGER( :in_mhlohkot_tt.lohkonro )
      and STATUS_SW_PLANNINGBLOCK.BLOCK_STATUS = TO_NVARCHAR( :in_mhlohkot_tt.status )
      when matched then update set
      STATUS_SW_PLANNINGBLOCK.STATUS_DATE = TO_TIMESTAMP( :in_mhlohkot_tt.statuspvm, 'YYYY-MM-DD')
      when not matched then insert
      (
          SILVICULTURALORDERID,
          BLOCK_NUMBER,
          BLOCK_STATUS,
          STATUS_DATE
       )
      values(
          TO_BIGINT( :in_mhlohkot_tt.mhtilaus ),
          TO_INTEGER( :in_mhlohkot_tt.lohkonro ),
          TO_NVARCHAR( :in_mhlohkot_tt.status ),
          TO_TIMESTAMP( :in_mhlohkot_tt.statuspvm, 'YYYY-MM-DD')
       );

* finishing staus updates
      call  MLOAPTERI.setGisDataFinished();

* creating sucess responses
*   success = 'true';

  ENDMETHOD.

ENDCLASS.