"! <p class="shorttext synchronized" lang="en">GetPinQuery</p>
"! <p class="shorttext synchronized" lang="en">No Pseudocomments</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id745_wso_harvesting/source/main#start=2286,2;end=2301,24</p>
CLASS zcl_gis_amdp_id871 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.


    METHODS get_pin_query
      IMPORTING
                VALUE(compartment_id)       TYPE string
                VALUE(logistic_unit)        TYPE string
                VALUE(harvesting_method_group)    TYPE string
                VALUE(assortments) TYPE  zdt_pin_request_assortm_tab
      EXPORTING VALUE(pin_query_table)  TYPE zdt_pin_response_pin_tab
      RAISING   cx_amdp_error.




  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id871 IMPLEMENTATION.


  METHOD get_pin_query BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT.
    --Local data declarations
    declare lv_index integer;


    --select * FROM MLOAPTERI.F_ID871_DATA_2($LOHKO$,$TEHDAS$,$PTL$,$LOGY$,$HAKKUUTAPA$,$LAATU$,$TYYPPILEIMIKKO$,$HINNOITTELUMUOTO$))

    declare output_t table(
        assortment_code  nvarchar( 100 ),
        delivery_destination_code  nvarchar( 100 ),
        grade_code  nvarchar( 100 ),
        pin_file_name  nvarchar( 100 ),
        modification_date  nvarchar( 100 )
);

-- return pin file and modification time foreach assortiment
    for lv_index in 1..record_count(:assortments)
      do
        declare tehdas string = :assortments.delivery_destination_code[:lv_index];
        declare ptl string = :assortments.assortment_code[:lv_index];
        declare laatu string = :assortments.grade_code[:lv_index];
        declare tyyppileimikko string = :assortments.model_compartment_type[:lv_index];
        declare hinnoittelumuoto string = :assortments.pricing_method[:lv_index];

        output_t = select * from :output_t
        union
        select PTLKOODI assortment_code, TEHDAS delivery_destination_code, LAATU grade_code, PRODUCTUSERID pin_file_name, MUUTOS_PVM modification_date
        FROM MLOAPTERI.F_ID871_DATA_2( :compartment_id, :tehdas, ptl, :logistic_unit, :harvesting_method_group, :laatu, :tyyppileimikko, 1 );

      end for;

    pin_query_table = select * from :output_t;

  ENDMETHOD.




ENDCLASS.