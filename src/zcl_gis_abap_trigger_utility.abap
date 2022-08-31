CLASS zcl_gis_abap_trigger_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:BEGIN OF is_harvesting_or_SilviCulture,
            is_harvesting   TYPE abap_bool,
            is_silviculture TYPE abap_bool,
          END OF IS_HARVESTING_OR_SILVICulture.
    "! <p class="shorttext synchronized" lang="en"> Decide whether Harvesting or SilviCulture</p>
    "! If workingSiteId starts with H then its Harvesting
    "! If workingSiteId starts with S then its SilviCulture
    "! @parameter workingsiteid | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter isharvestingorsilviculture | <p class="shorttext synchronized" lang="en"></p>
    CLASS-METHODS  isHarvestingOrSilviCulture IMPORTING workingsiteid                     TYPE zzworkingsiteid
                                              RETURNING VALUE(isharvestingorsilviculture) TYPE is_harvesting_or_SilviCulture
                                              RAISING   zcx_unexpected_exception.
    CLASS-METHODS transform_timestamp_forhana IMPORTING geo_timestamp                  TYPE string
                                              RETURNING VALUE(geo_timestamp_formatted) TYPE string
                                              RAISING   zcx_unexpected_exception.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_gis_abap_trigger_utility IMPLEMENTATION.


  METHOD transform_timestamp_forhana.
*/* This time stamp formatter can handle two formats
* 1-|2019-07-08T05:43:49.556Z| -HANA side SELECT to_timestamp('2019-07-08T05:43:49.556', 'YYYY-MM-DD"T"HH24:MI:SS.FF3')  "DATE Format" FROM DUMMY;
* 2- |2019-07-08T05:43:49|
* Hana can only work only with this format  |2019-07-08 05:43:49.556|
    TEST-SEAM transform_timestamp.
      DATA(lv_last) = substring( val = geo_timestamp off = strlen( geo_timestamp ) - 1 len = 1 ).
*remove the last char Z
      IF lv_last CA 'Z'.
        geo_timestamp_formatted = substring( val = geo_timestamp off = 0 len = strlen( geo_timestamp ) - 2 ).
      ELSE.
        geo_timestamp_formatted = substring( val = geo_timestamp off = 0 len = strlen( geo_timestamp ) - 1 ).
      ENDIF.
*remove the T in the middle
      FIND 'T' IN geo_timestamp_formatted.
      IF sy-subrc EQ 0.
        REPLACE FIRST OCCURRENCE OF 'T' IN geo_timestamp_formatted WITH ` `.
      ELSE.
        RAISE EXCEPTION TYPE zcx_unexpected_exception  MESSAGE e003(zml_gis_amdp).
      ENDIF.
    END-TEST-SEAM.
  ENDMETHOD.


  METHOD isharvestingorsilviculture.
    TEST-SEAM isharvestingornot.
*Set as default
      isharvestingorsilviculture-is_harvesting = abap_false.
      isharvestingorsilviculture-is_silviculture = abap_false.

      IF  workingsiteid(1) EQ 'H'.
        isharvestingorsilviculture-is_harvesting = abap_true.
      ELSEIF workingsiteid(1) EQ 'S'.
        isharvestingorsilviculture-is_silviculture = abap_true.
      ELSE.
        " Raise an Exception or not
        RAISE EXCEPTION TYPE zcx_unexpected_exception MESSAGE e001(zml_gis_amdp).
      ENDIF.
    END-TEST-SEAM.
  ENDMETHOD.




ENDCLASS.