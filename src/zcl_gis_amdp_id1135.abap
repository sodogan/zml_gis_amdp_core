"! <p class="shorttext synchronized" lang="en">GdprDeleteGISData</p>
"! <p class="shorttext synchronized" lang="en">No Pseudocomments yet</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/functions/groups/zml_gdpr/includes/lzml_gdprf01/source/main#start=1286,1;end=1290,40</p>
"! <p class="shorttext synchronized" lang="en">REST API is created for  in_callforoffers_tt and in_forestplans_tt</p>
"! <p class="shorttext synchronized" lang="en">REST API is  called from ABAP trigger independently</p>
CLASS zcl_gis_amdp_id1135 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS gdpr_delete_gisdata
      IMPORTING
        value(key)                       type string
        value(user)                      type string
        value(in_customer)               type lifnr
*        value(in_callforoffers_tt)       type zprcodt_id1135_gdpr_del_tab11
        value(in_contracts_tt)           type zprcodt_id1135_gdpr_dele_tab9
        value(in_draftoffers_tt)         type zprcodt_id1135_gdpr_dele_tab7
*        value(in_forestplans_tt)         type zprcodt_id1135_gdpr_dele_tab5
        value(in_offers_tt)              type zprcodt_id1135_gdpr_dele_tab3
        value(in_silviculturalorders_tt) type zprcodt_id1135_gdpr_dele_tab1
      exporting
        value(out_customer)               type int8
        value(out_status)                 type string
*        value(out_callforoffers)          type zprcodt_id1135_gdpr_del_tab10
        value(out_contracts)              type zprcodt_id1135_gdpr_dele_tab8
        value(out_draftoffers)            type zprcodt_id1135_gdpr_dele_tab6
*        value(out_forestplans)            TYPE zprcodt_id1135_gdpr_dele_tab4
        value(out_offers)                 TYPE zprcodt_id1135_gdpr_dele_tab2
        value(out_silviculturalorders)    TYPE zprcodt_id1135_gdpr_delet_tab
       RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_gis_amdp_id1135 IMPLEMENTATION.

  METHOD gdpr_delete_gisdata by database PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.

    declare in_id BIGINT;
    declare in_decade nvarchar;
    declare out_id int;
    declare index_id int;
    DECLARE lv_deleted_records_num DECIMAL;
    declare out_tt TABLE (
       contractid BIGINT,
       decade nvarchar( 75 ),
       status nvarchar( 10 )
        );


* 6 procedures from DeleteGisDataAction

* deleteCustomerData
    in_id = TO_BIGINT( :in_customer);
    call mg_spatial.deleteCustomerData(:in_id, out_id);
    out_customer = cast ( out_id as nvarchar );
    call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteCustomerData', :out_customer);

*  REST API, will be moved to another component
*        for (CallForOffer cfo: callforoffers){
*            log.debug(label + "Deleting callforoffer: " + cfo.getCallforofferidsap());
*            try {
*                retStr=deleteForestPlanData("IQ" + cfo.getCallforofferidsap());
*                cfo.setStatus(retStr);

*deleteContractData
    for index_id in 1..record_count( :in_contracts_tt )
        do
          if :in_contracts_tt.decade[:index_id]  is not NULL
            then
              in_id = TO_BIGINT(CONCAT( :in_contracts_tt.contractid[:index_id], :in_contracts_tt.decade[:index_id] ));
           else
              in_id = TO_BIGINT( :in_contracts_tt.contractid[:index_id] );
           end if ;

            in_decade = cast( :in_contracts_tt.decade[:index_id] as int);
            call mg_spatial.deleteContractData(:in_id, out_id);
            :out_contracts.insert( ( :in_id  , :in_decade, cast ( :out_id as nvarchar ( 10 ) )));
            call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteContractData', cast ( :out_id as nvarchar ( 10 ) ));
    end for;

* deleteDraftOfferData
    for index_id in 1..record_count( :in_draftoffers_tt )
        do
            in_id = TO_BIGINT( :in_draftoffers_tt.draftoffer[:index_id] );
            call mg_spatial.deleteDraftOfferData(:in_id, out_id);
            :out_draftoffers.insert( ( :in_id, cast ( :out_id as nvarchar ( 10 ) ) ));
            call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteDraftOfferData', cast ( :out_id as nvarchar ( 10 ) ));
    end for;

* deleteForestPlanData
* TODO - REST API, will be moved to another component
*        for (ForestPlan f: forestplans){
*            log.debug(label + "Deleting forestplan: " + f.getKitunnus());
*            try {
*                retStr=deleteForestPlanData(f.getKitunnus());
*                f.setStatus(retStr);

* deleteOfferData
    for index_id in 1..record_count( :in_offers_tt )
        do
            in_id = TO_BIGINT( :in_offers_tt.offerid[:index_id] );
            call mg_spatial.deleteOfferData(:in_id, out_id);
            :out_offers.insert( ( :in_id, cast ( :out_id as nvarchar ( 10 ) ) ));
            call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteOfferData', cast ( :out_id as nvarchar ( 10 ) ));
    end for;

* deleteSilviculturalorderData
    for index_id in 1..record_count( :in_silviculturalorders_tt )
        do
            in_id = TO_BIGINT( :in_silviculturalorders_tt.silviculturalorder[:index_id] );
            call mg_spatial.deleteSilviculturalorderData(:in_id, out_id);
            :out_silviculturalorders.insert ( ( :in_id, cast ( :out_id as nvarchar ( 10 ) ) ));
            call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteSilviculturalorderData', cast ( :out_id as nvarchar ( 10 ) ));
    end for;

    in_id = TO_BIGINT( :in_customer);
* cleanByCustomerid
    call mg_spatial.cleanByCustomerid(:in_id, :user );
    call mg_spatial.deleteRowsLogProc(:user,:in_customer, 'deleteCustomerData', :in_id);

*Set the customer ID and status
     out_customer = :in_customer;
     out_status = 'DELETED';

    --TODO: two output parameters will be moved to REST API class
*     out_callforoffers = select '' as callforoffer,
*                                ''  as status
*                            from dummy;
*     out_forestplans = select '' as kitunnus,
*                               ''  as status
*                            from dummy;

  ENDMETHOD.

ENDCLASS.