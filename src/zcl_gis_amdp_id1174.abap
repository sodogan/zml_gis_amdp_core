"! <p class="shorttext synchronized" lang="en">SaveKemeraDecision,SaveKemeraCompletionDeclaration</p>
"! <p class="shorttext synchronized" lang="en">https://confluence.shared.tds.metsagroup.com/display/MGEX/SaveResource</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_id536_i_resource/source/main#start=1046,11;end=1051,0 </p>
CLASS zcl_gis_amdp_id1174 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.
    METHODS save_kemera_decision
      IMPORTING
                VALUE(in_case_number)         TYPE  string
                VALUE(case_date)              TYPE  string
                VALUE(decision_number)        TYPE  string
                VALUE(decision_date)          TYPE  string
                VALUE(decision_geometries)    TYPE  zprdtid1174_gis_save_kem_tab1
                VALUE(works)                  TYPE  zprdtid1174_gis_save_keme_tab
                VALUE(action)                 TYPE  string

* TODO. input parameters are kind of replicating GML. Not correct.
*----------------------------------------------------
*                VALUE(point_properties)       TYPE  zprdtid1174_point_property_tt
*                VALUE(line_string_properties) TYPE  zprdtid1174_linestringprope_tt
*                VALUE(polygon_properties)     TYPE  zprdtid1174_polygonproperty_tt
**/*Deep nested structures */
*                VALUE(exterior)                       TYPE  zprdtid1174_xterior_tt
*                VALUE(exterior_ring_curve_member)     TYPE  ZPRDTID1174_RING_CURVE_MEM_TT
*                VALUE(exterior_linear_ring_pos)       TYPE  ZPRDTID1174_LRING_POS_TT
*                VALUE(exterior_linear_ring_pointprps) TYPE  zprdtid1174_lring_pointprop_tt
*                VALUE(exterior_linear_ring_pointreps) TYPE  ZPRDTID1174_LRING_POINTREPS_TT
*                VALUE(interior)               TYPE zprdtid1174_xterior_tab
*----------------------------------------------------
* TODO. Using decision_geometries table only instead, where geoloc column represents optional point line or polygon
* Assuming as st_geometry.As_Text(). Otherwise geoxml_to_geoshape function call and varinat_name column will be needed
      EXPORTING
                VALUE(out_case_number)        TYPE string
                VALUE(out_action)             TYPE string
*/No Need*/               VALUE(success)      TYPE string
                VALUE(infotext)               TYPE string
      RAISING   cx_amdp_error.


   METHODS save_kemera_completion_declare
      IMPORTING
                VALUE(financing_actnumber) TYPE string
                VALUE(completion_dec_ref) TYPE string
                VALUE(work_code) TYPE string
                VALUE(decision_date) TYPE string
                VALUE(sent_date) TYPE string
                VALUE(start_date) TYPE string
                VALUE(end_date) TYPE string
                VALUE(financing_act_completionStands) TYPE ZPRDTID1175_GIS_save_KEMERA_TT
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1174 IMPLEMENTATION.

  METHOD save_kemera_decision BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare KEMERA_ACTION_INSERT_OR_UPDATE string = '1';
    declare KEMERA_ACTION_DELETE string = '2';
    declare decision_date_d timestamp = TO_TIMESTAMP( :decision_date, 'YYYY-MM-DD' );
    declare case_date_d timestamp = TO_TIMESTAMP( :case_date, 'YYYY-MM-DD' );
    declare decision_geometries_t table(
          case_number            nvarchar( 50 ),
          stand_number_extension nvarchar( 50 ),
          stand_number           nvarchar( 50 ),
          stand_reference        nvarchar( 50 ),
          stand_id               nvarchar( 50 ),
          cost_type              nvarchar( 50 ),
          geoloc                 st_geometry
    );


    if :action = KEMERA_ACTION_INSERT_OR_UPDATE
    then

        merge into GISDATA.KEMERADECISION using
        ( select :in_case_number, :case_date_d, :decision_number, :decision_date_d from dummy )
        on :in_case_number = KEMERADECISION.CASENUMBER
        when matched then update set
            KEMERADECISION.CASEDATE = :case_date_d,
            KEMERADECISION.DECISIONNUMBER = :decision_number,
            KEMERADECISION.DECISIONDATE = :decision_date_d
        when not matched then insert (
            CASENUMBER,
            CASEDATE,
            DECISIONNUMBER,
            DECISIONDATE
        )
        values(
            :in_case_number,
            :case_date_d,
            :decision_number,
            :decision_date_d
        );

        --The existing KEMERADECISIONGEOMETRYs must be always deleted during inserts or updates
        DELETE FROM GISDATA.KEMERADECISIONGEOMETRY o WHERE o.CASENUMBER = :in_case_number;
        decision_geometries_t = select case_number, stand_number_extension, stand_number, stand_reference,
                    stand_id, cost_type, ST_GeomFromText( geoloc, 3067) geoloc from :decision_geometries;
        insert into GISDATA.KEMERADECISIONGEOMETRY select stand_reference STANDREFERENCE, stand_id STANDID, case_number CASENUMBER,
                    GEOLOC, cost_type COSTTYPE, null STATUS, stand_number STANDNUMBER, stand_number_extension STANDNUMBEREXTENSION from :decision_geometries_t;

        --The existing KEMERADECISIONWORKs must be always deleted during inserts or updates
        DELETE FROM GISDATA.KEMERADECISIONWORK o WHERE o.CASENUMBER = :in_case_number;
        insert into GISDATA.KEMERADECISIONWORK select work_code WORKCODE, case_number CASENUMBER, work_code_group WORKCODEGROUP from :works;

        infotext = 'OK';

    elseif :action = KEMERA_ACTION_DELETE
    then
        DELETE FROM GISDATA.KEMERADECISIONGEOMETRY WHERE CASENUMBER = :in_case_number;
        DELETE FROM GISDATA.KEMERADECISIONWORK WHERE CASENUMBER = :in_case_number;
        DELETE FROM GISDATA.KEMERADECISION WHERE CASENUMBER = :in_case_number;

        infotext = 'OK';

    else

        infotext = 'Error';

    end if;

    out_case_number = :in_case_number;
    out_action = :action;

  ENDMETHOD.

  METHOD save_kemera_completion_declare BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables

    declare decision_date_d timestamp = TO_TIMESTAMP( :decision_date, 'YYYY-MM-DD' );
    declare sent_date_d timestamp = TO_TIMESTAMP( :sent_date, 'YYYY-MM-DD' );
    declare start_date_d timestamp = TO_TIMESTAMP( :start_date, 'YYYY-MM-DD' );
    declare end_date_d timestamp = TO_TIMESTAMP( :end_date, 'YYYY-MM-DD' );
    declare completionStands_t table (
      financing_actnumber nvarchar( 100 ),
      stand_reference     nvarchar( 100 ),
      stand_number        nvarchar( 100 ),
      cost_type           nvarchar( 100 ),
      geoloc              st_geometry,
      status              int
     );

* Service is used to Save Kemera Completion Declaration geometries to database

    merge into GISDATA.KEMERACOMPLETIONDECLARATION using
    (select :financing_actnumber, :completion_dec_ref, :work_code, :decision_date_d, :sent_date_d, :start_date_d, :end_date_d from dummy)
    on :financing_actnumber = KEMERACOMPLETIONDECLARATION.FINANCINGACTNUMBER
    when matched then update set
        KEMERACOMPLETIONDECLARATION.COMPLETIONDECLARATIONREFERENCE = :completion_dec_ref,
        KEMERACOMPLETIONDECLARATION.WORKCODE = :work_code,
        KEMERACOMPLETIONDECLARATION.DECISIONDATE = :decision_date_d,
        KEMERACOMPLETIONDECLARATION.SENTDATE = :sent_date_d,
        KEMERACOMPLETIONDECLARATION.STARTDATE = :start_date_d,
        KEMERACOMPLETIONDECLARATION.ENDDATE = :end_date_d
    when not matched then insert (
        FINANCINGACTNUMBER,
        COMPLETIONDECLARATIONREFERENCE,
        WORKCODE,
        DECISIONDATE,
        SENTDATE,
        STARTDATE,
        ENDDATE
    )
    values(
        :financing_actnumber,
        :completion_dec_ref,
        :work_code,
        :decision_date_d,
        :sent_date_d,
        :start_date_d,
        :end_date_d
    )
    ;


    completionStands_t = --TODO ST_GeomFromText function used here to create a shape. What is really in "geoloc" string not known
    select financing_actnumber, stand_reference, stand_number, cost_type, ST_GeomFromText( geoloc, 3067) geoloc, TO_INTEGER( status ) status
    from :financing_act_completionStands;

    merge into GISDATA.KEMERACOMPLDECLARGEOMETRY using :completionStands_t
    on :completionStands_t.stand_reference = KEMERACOMPLDECLARGEOMETRY.STANDREFERENCE
    when matched then update set
        KEMERACOMPLDECLARGEOMETRY.FINANCINGACTNUMBER = :completionStands_t.financing_actnumber,
        KEMERACOMPLDECLARGEOMETRY.STANDNUMBER = :completionStands_t.stand_number,
        KEMERACOMPLDECLARGEOMETRY.GEOLOC = :completionStands_t.geoloc,
        KEMERACOMPLDECLARGEOMETRY.STATUS = :completionStands_t.status,
        KEMERACOMPLDECLARGEOMETRY.COSTTYPE = :completionStands_t.cost_type
    when not matched then insert (
        STANDREFERENCE,
        FINANCINGACTNUMBER,
        STANDNUMBER,
        GEOLOC,
        STATUS,
        COSTTYPE
    )
    values(
        :completionStands_t.stand_reference,
        :completionStands_t.financing_actnumber,
        :completionStands_t.stand_number,
        :completionStands_t.geoloc,
        :completionStands_t.status,
        :completionStands_t.cost_type
    )
        ;

  ENDMETHOD.

ENDCLASS.