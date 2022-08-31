"! <p class="shorttext synchronized" lang="en">SaveCompany</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveCompany</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zii_cl_si_id710_company_infor1/source/main#start=667,11;end=671,55 </p>
CLASS zcl_gis_amdp_id917 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS savecompany
      IMPORTING
                VALUE(in_contractorid)  TYPE string
                VALUE(organizationname) TYPE string
                VALUE(action)           TYPE int4
                VALUE(zyrittajasuco)    TYPE ziidt_id917_company_gis_s_tab
                VALUE(contract_id)      TYPE string
                VALUE(contractor_num)   TYPE /sdf/crmfield
      EXPORTING
                VALUE(out_contractorid) TYPE string
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id917 IMPLEMENTATION.

  METHOD savecompany BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare invalid_action CONDITION FOR SQL_ERROR_CODE 10001;

* Validate the action code
      if NOT :action IN (  1 , 2 )
        then
         SIGNAL invalid_action SET MESSAGE_TEXT = 'Invalid Action-only 1 and 2 are possible';
       END IF ;

     if :action = 2 -- action delete
     then
         delete from GISDATA.WF_SUBCONTRACTOR_OF_CONTRACTOR where WF_SUBCONTRACTOR_OF_CONTRACTOR.CONTRACTORID = :in_contractorid;
*It needs to delete also referencing rows from WF_CONTRACTOR_OF_RESOURCE before deleting referenced row from WF_COMPANY.
         delete from GISDATA.WF_CONTRACTOR_OF_RESOURCE where WF_CONTRACTOR_OF_RESOURCE.CONTRACTORID = :in_contractorid;

         delete from GISDATA.WF_COMPANY where WF_COMPANY.CONTRACTORID = :in_contractorid;
     elseif :action = 1 -- action insert/update
     then

        delete from GISDATA.WF_SUBCONTRACTOR_OF_CONTRACTOR where WF_SUBCONTRACTOR_OF_CONTRACTOR.CONTRACTORID = :in_contractorid;


*It needs to delete also referencing rows from WF_CONTRACTOR_OF_RESOURCE before deleting referenced row from WF_COMPANY.
* commenting this out besause we are not receiving resources in request, this is handeld by SaveResource class
*        delete from GISDATA.WF_CONTRACTOR_OF_RESOURCE where WF_CONTRACTOR_OF_RESOURCE.CONTRACTORID = :in_contractorid;

         merge into GISDATA.WF_COMPANY using ( select
             :in_contractorid,
             :organizationname,
             :contract_id,
             :contractor_num
         from dummy
         ) on ( WF_COMPANY.CONTRACTORID = :in_contractorid )
         when matched then update set
             WF_COMPANY.ORGANIZATIONNAME = :organizationname,
             WF_COMPANY.CONTRACTORCONTRACT = :contract_id,
             WF_COMPANY.CONTRACTORNUMBER = :contractor_num,
             WF_COMPANY.UPDATED_BY = 'MG_KARHU',
             WF_COMPANY.UPDATED_ON = CURRENT_TIMESTAMP
         WHEN NOT MATCHED THEN INSERT VALUES(
             :in_contractorid,
             :organizationname,
             'MG_KARHU',
             'MG_KARHU',
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP,
             :contract_id,
             :contractor_num
             );



         insert into GISDATA.WF_SUBCONTRACTOR_OF_CONTRACTOR select
                                                            GISDATA.WF_SUBCONTRACTOR_SEQ.nextval,
                                                            :in_contractorid contractorid,
                                                            subconid subcontractor
                                                            from :zyrittajasuco;


     end if;

     out_contractorid = :in_contractorid;

  ENDMETHOD.

ENDCLASS.