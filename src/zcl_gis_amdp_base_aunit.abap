CLASS zcl_gis_amdp_base_aunit DEFINITION
  PUBLIC
  INHERITING FROM cl_aunit_assert
  CREATE PUBLIC  ABSTRACT FOR TESTING
   DURATION SHORT RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ENUM commit BASE TYPE abap_bool,
        on  VALUE IS INITIAL,
        off VALUE abap_true,
      END OF ENUM commit.
    INTERFACES zif_gis_amdp_expectations_unit ALL METHODS ABSTRACT.

    ALIASES: create_expectations FOR zif_gis_amdp_expectations_unit~create_expectations,
             clear_expectations  FOR zif_gis_amdp_expectations_unit~clear_expectations.
    CLASS-METHODS assert_true IMPORTING
                                !msg TYPE string OPTIONAL
                                !act TYPE abap_bool .
    CLASS-METHODS assert_false     IMPORTING
                                     !msg TYPE string OPTIONAL
                                     !act TYPE abap_bool .


    CLASS-METHODS: assert_match   IMPORTING VALUE(exp)              TYPE any
                                            VALUE(act)              TYPE any
                                            msg                     TYPE csequence OPTIONAL
                                            level                   TYPE int1 DEFAULT if_aunit_constants=>severity-medium
                                  RETURNING VALUE(assertion_failed) TYPE abap_bool
                                  .

    CLASS-METHODS fail_test IMPORTING
                                      !iv_msg         TYPE string
                                      !iv_level       TYPE aunit_level DEFAULT cl_aunit_assert=>if_aunit_constants~critical
                                      !iv_flow        TYPE aunit_flowctrl DEFAULT cl_aunit_assert=>if_aunit_constants~method
                            RETURNING VALUE(ret_code) TYPE abap_bool
                            .

    CLASS-METHODS not_implemented_yet IMPORTING
                                                !iv_msg         TYPE string
                                                !iv_level       TYPE aunit_level DEFAULT cl_aunit_assert=>if_aunit_constants~critical
                                                !iv_flow        TYPE aunit_flowctrl DEFAULT cl_aunit_assert=>if_aunit_constants~method
                                      RETURNING VALUE(ret_code) TYPE abap_bool
                                      .

    CLASS-METHODS pass_test IMPORTING
                              !iv_msg   TYPE string DEFAULT 'This test result is a Pass no matterException'
                              !iv_level TYPE aunit_level DEFAULT cl_aunit_assert=>if_aunit_constants~critical
                              !iv_flow  TYPE aunit_flowctrl DEFAULT cl_aunit_assert=>if_aunit_constants~method
                              RETURNING VALUE(rv_return_code) TYPE abap_bool
                              .

    CLASS-METHODS assert_table_hasrecords IMPORTING
                              it_table   TYPE STANDARD TABLE
                              !iv_msg    TYPE string DEFAULT 'Table should contain values, no values found!'
                              !iv_level  TYPE aunit_level DEFAULT cl_aunit_assert=>if_aunit_constants~critical
                              !iv_flow   TYPE aunit_flowctrl DEFAULT cl_aunit_assert=>if_aunit_constants~method.

    CLASS-METHODS: check_table_has_records IMPORTING it_table              TYPE STANDARD TABLE
                                           RETURNING VALUE(rv_return_code) TYPE abap_bool.

    CLASS-METHODS: fail_exception IMPORTING io_exception TYPE REF TO cx_root quit
                                     TYPE aunit_flowctrl DEFAULT method.
    CLASS-METHODS assert_table_lines IMPORTING
                                       !msg  TYPE clike
                                       !exp  TYPE sytabix
                                       !act  TYPE ANY TABLE
                                       !quit TYPE aunit_flowctrl DEFAULT method .
    CLASS-METHODS assert_cs       IMPORTING
                                    !msg  TYPE clike
                                    !act  TYPE clike
                                    !exp  TYPE clike
                                    !quit TYPE aunit_flowctrl DEFAULT method .
  PROTECTED SECTION.
    DATA: mv_commit_switch TYPE abap_bool.
    METHODS: toggle_commit_on, toggle_commit_off.
    METHODS: commit_work.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_gis_amdp_base_aunit IMPLEMENTATION.


  METHOD assert_false.
    assert_equals( act = act exp = abap_false msg = 'Expected FALSE but was TRUE' ).
  ENDMETHOD.



  METHOD assert_true.
    assert_equals( act = act exp = abap_true msg = 'Expected TRUE but was FALSE' ).
  ENDMETHOD.


  METHOD fail_test.
*--------------------------------------------------------------------*
* Calls the fail method.  This wrapper method supplies default values
* for the level and the flow.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

    fail( msg   = iv_msg
          level = iv_level
          quit  = iv_flow ).
    ret_code = abap_true.
  ENDMETHOD.                    "fail_test

  METHOD not_implemented_yet.
    fail( msg   = iv_msg
          level = iv_level
          quit  = iv_flow ).
    ret_code = abap_true.
  ENDMETHOD.
  METHOD pass_test.

    assert_true(
      EXPORTING
        msg = iv_msg
        act = abap_true
    ).
   rv_return_code = abap_true.
  ENDMETHOD.                    "fail_test



  METHOD assert_table_hasrecords.
*check table has records
     DATA(ret_code) = cond #( WHEN check_table_has_records( it_table = it_table ) EQ abap_true then pass_test(  )
                               ELSE fail_test( iv_msg = iv_msg )
     )

     .


  ENDMETHOD.

  METHOD check_table_has_records.
    rv_return_code = xsdbool( line_exists( it_table[ 1 ] ) ).
  ENDMETHOD.

  METHOD fail_exception.
    fail_test( iv_msg  = |Exception: { io_exception->get_text(  ) }  |
               iv_flow = quit
               ).
  ENDMETHOD.

  METHOD assert_table_lines.
    DATA: lv_lines TYPE sytabix,
          lv_msg   TYPE string.
    lv_lines = lines( act ).
    lv_msg = 'Lines'.                                       "#EC NOTEXT
    IF msg IS NOT INITIAL.
      CONCATENATE lv_msg ` in ` msg INTO lv_msg.            "#EC NOTEXT
    ENDIF.
    assert_equals( msg  = lv_msg
                   exp  = exp
                   act  = lv_lines
                   quit = quit ).
  ENDMETHOD.

  METHOD assert_cs.
    DATA: lv_result TYPE flag.

    IF act CS exp.
      lv_result = 'X'.
    ENDIF.
    assert_equals( msg  = msg
                   exp  = 'X'
                   act  = lv_result
                   quit = quit ).
  ENDMETHOD.

  METHOD toggle_commit_off.
    mv_commit_switch = abap_false.
  ENDMETHOD.

  METHOD toggle_commit_on.
    mv_commit_switch = abap_true.
  ENDMETHOD.

  METHOD commit_work.
    IF mv_commit_switch = abap_true.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.





  METHOD assert_match.
    assert_equals(
      EXPORTING
        exp              = exp
        act              = act
        msg              = msg
        level            = if_aunit_constants=>severity-medium
      RECEIVING
        assertion_failed = assertion_failed
    ).
  ENDMETHOD.




ENDCLASS.