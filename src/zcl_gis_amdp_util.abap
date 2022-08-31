"! <p class="shorttext synchronized" lang="en">Utility Class-All the Common code goes here</p>
CLASS zcl_gis_amdp_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_gis_amdp.
    CLASS-METHODS: geoshape_to_xml  IMPORTING VALUE(shape)   TYPE geom_ewkb
                                    EXPORTING VALUE(st_text) TYPE string
                                    RAISING   cx_amdp_error .


    CLASS-METHODS: geoxml_to_geoshape IMPORTING VALUE(poslist)   TYPE zgis_amdp_poslist
                                                VALUE(gtype)     TYPE zgis_amdp_gtype
                                      EXPORTING VALUE(st_text)   TYPE string
                                                VALUE(geom)      TYPE geom_ewkb
                                                VALUE(geom_type) TYPE string
                                      RAISING   cx_amdp_error .

    CLASS-METHODS: is_numeric IMPORTING VALUE(value)   TYPE string
                              EXPORTING VALUE(is_numeric) TYPE abap_bool
                              RAISING   cx_amdp_error .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_util IMPLEMENTATION.
  METHOD geoxml_to_geoshape BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.



    BEGIN
      DECLARE OBJECT_TYPE NVARCHAR(50);
      DECLARE OBJECT_END NVARCHAR(10);
      DECLARE LV_LOOP INT;
      DECLARE LV_POS INT;
      DECLARE invalid_shape CONDITION FOR SQL_ERROR_CODE 10001;

  -- check object type
      IF :gtype='lSP' THEN
         GEOM_TYPE  := 'LineString';
         OBJECT_TYPE := 'LineString ( ';
         OBJECT_END := ' ) ';
      ELSEIF :gtype='PGE' OR :gtype='PGI' THEN
         GEOM_TYPE  := 'Polygon';
         OBJECT_TYPE := 'Polygon ((';
         OBJECT_END := ' )) ';
      ELSEIF :gtype='pP' THEN
         GEOM_TYPE  := 'Point';
         OBJECT_TYPE := 'Point (';
         OBJECT_END := ' ) ';
      ELSE
       SIGNAL invalid_shape SET MESSAGE_TEXT = 'Invalid shape type';
      END IF;
  -- group tuples
      ST_TEXT := '';
      LV_POS := 0;
         FOR LV_LOOP IN 1..LENGTH(:poslist) DO
            IF SUBSTRING(:poslist, :LV_LOOP, 1) = CHAR(32) AND LV_POS = 0
            THEN
               LV_POS := 1;
               ST_TEXT := :ST_TEXT || SUBSTRING(:poslist, :LV_LOOP, 1);
            ELSEIF SUBSTRING(:poslist, :LV_LOOP, 1) = CHAR(32) AND LV_POS = 1
            THEN
            ST_TEXT := :ST_TEXT || ' , ';
               LV_POS := 0;
            ELSE
               ST_TEXT := :ST_TEXT || SUBSTRING(:poslist, :LV_LOOP, 1);
            END IF;
         END FOR;
  -- create final statement
      ST_TEXT := :OBJECT_TYPE || :ST_TEXT || :OBJECT_END;
   END;


     --Convert it to Geom object
      SELECT
      ST_GeomFromText(:st_text , 3067) AS "SHAPE"
      into geom
      FROM DUMMY;


  ENDMETHOD.





  METHOD geoshape_to_xml BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.


    -- Declare Local Variables
           DECLARE geometry NVARCHAR(10000);
           DECLARE variant NVARCHAR(10000);
           DECLARE input_string NVARCHAR(10000);
           DECLARE input_separator NVARCHAR(10);

           declare geomemetry_str_t TABLE ( OUTPUT_SPLIT NVARCHAR(10000) ) ;
           declare object_type nvarchar(20);
           declare output_split NVARCHAR( 1000 );
           DECLARE COUNTER INT := 1;
           DECLARE NEEDLE INT := 1;
           DECLARE invalid_shape CONDITION FOR SQL_ERROR_CODE 10001;

           input_separator = ']], [[';


           SELECT JSON_VALUE(shape.ST_AsGeoJSON(), '$.type') INTO variant FROM DUMMY;
           SELECT shape.ST_AsGeoJSON() INTO geometry FROM DUMMY;

           IF :variant = 'Point'
           THEN
            SELECT SUBSTR_REGEXPR('(\"coordinates\"\:\s*)(\[)(.*)(\])' IN geometry GROUP 3) INTO input_string FROM DUMMY;
            SELECT '<GEOMETRY>' || REPLACE(:input_string, ',', '') || '</GEOMETRY>' INTO st_text FROM DUMMY;

          ELSE
               IF :variant = 'LineString'
               THEN
                    SELECT SUBSTR_REGEXPR('(\"coordinates\"\:\s*)(\[\[)(.*)(\]\])' IN :geometry GROUP 3) INTO input_string FROM DUMMY;
               ELSE
                    SELECT SUBSTR_REGEXPR('(\"coordinates\"\:\s*)(\[\[\[)(.*)(\]\]\])' IN :geometry GROUP 3) INTO input_string FROM DUMMY;
               END IF;

               SELECT LOCATE(:input_string, :input_separator) INTO NEEDLE FROM DUMMY;
               IF :NEEDLE = 0 THEN
                   geomemetry_str_t = SELECT '<GEOMETRY>' || REPLACE(REPLACE(REPLACE(INPUT_STRING, ',', ''), '[', ''), ']', '') || '</GEOMETRY>' "OUTPUT_SPLIT" FROM DUMMY;
               ELSE
                   SPLIT_VALUES = SELECT SUBSTR_BEFORE(:INPUT_STRING,:INPUT_SEPARATOR) SINGLE_VAL FROM DUMMY;
                   SELECT SUBSTR_AFTER(:INPUT_STRING,:INPUT_SEPARATOR) || :INPUT_SEPARATOR INTO INPUT_STRING FROM DUMMY;
                   WHILE( LENGTH(:INPUT_STRING) > 0 )
                       DO
                          SPLIT_VALUES =
                                     SELECT SUBSTR_BEFORE(:INPUT_STRING,:INPUT_SEPARATOR) SINGLE_VAL FROM DUMMY
                                        UNION
                                     SELECT SINGLE_VAL FROM :SPLIT_VALUES;
                          SELECT SUBSTR_AFTER(:INPUT_STRING,:INPUT_SEPARATOR) INTO INPUT_STRING FROM DUMMY;
                   END WHILE;
                   geomemetry_str_t = SELECT '<GEOMETRY>' || REPLACE(REPLACE(REPLACE(SINGLE_VAL, ',', ''), '[', ''), ']', '') || '</GEOMETRY>' "OUTPUT_SPLIT" FROM :SPLIT_VALUES;
               END IF;

               select STRING_AGG(OUTPUT_SPLIT) into st_text from :geomemetry_str_t;

         END IF;

      -- check object type, multi shapes not yet implemented

          IF :variant='LineString' THEN
             OBJECT_TYPE  := 'lSP';
          ELSEIF :variant='Polygon' THEN
             OBJECT_TYPE  := 'PGE';
          ELSEIF :variant='Point' THEN
             OBJECT_TYPE  := 'pP';
          ELSE
             SIGNAL invalid_shape SET MESSAGE_TEXT = 'Invalid shape type';
          END IF;

        ST_TEXT := :ST_TEXT || '<VARIANT_NAME>' || :OBJECT_TYPE || '</VARIANT_NAME>';


  ENDMETHOD.



  METHOD is_numeric BY DATABASE PROCEDURE
                             FOR HDB LANGUAGE SQLSCRIPT
                             OPTIONS READ-ONLY.

    DECLARE trimmed_length integer := length(ltrim(value,'+-.0123456789'));

    IF trimmed_length > 0
       then
     is_numeric := '';
    Else
     is_numeric := 'X';
    END IF;


  ENDMETHOD.

ENDCLASS.