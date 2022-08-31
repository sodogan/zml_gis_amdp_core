"! <p class="shorttext synchronized" lang="en">ModelCompartmentUp</p>
"! <p class="shorttext synchronized" lang="en">https://mgubc.sharepoint.com/:w:/r/sites/mforwserp/_layouts/15/doc2.aspx?sourcedoc=%7B73921827-70EB-42A7-9D90-C960E1F9ED4F%7D&file=ID1036%20changes%20-%20WSD.docx&action=default&mobileredirect=true&cid=6a7b1
"!340-1896-4e85-b978-9b41199efbcf</p>
"! <p class="shorttext synchronized" lang="en">ABAP Trigger: adt://WSD/sap/bc/adt/oo/classes/zcl_hocfetch/source/main#start=615,9;end=620,0 </p>
CLASS zcl_gis_amdp_id1036 DEFINITION
  PUBLIC
  CREATE PRIVATE INHERITING FROM zcl_gis_amdp_base GLOBAL FRIENDS  zif_gis_amdp.

  PUBLIC SECTION.

    METHODS ModelCompartmentUp
      IMPORTING
                VALUE(in_workingsiteid)    TYPE  ZZWORKINGSITEID
                VALUE(in_logy)             TYPE  ZZLOGY
                VALUE(in_treespeciesitems) TYPE  ziidtid1036_model_compart_tab
      EXPORTING
                VALUE(out_workingsiteid)     TYPE  ZZWORKINGSITEID
                VALUE(out_logy)              TYPE  ZZLOGY
                VALUE(out_treespeciesitems) TYPE   ziidtid1036_model_compar_tab1
      RAISING   cx_amdp_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gis_amdp_id1036 IMPLEMENTATION.

  METHOD ModelCompartmentUp BY DATABASE PROCEDURE
                            FOR HDB LANGUAGE SQLSCRIPT
                            .

* local variables
    declare logy string;
    declare lv_index int;
    declare treespecies table ( treespecie nvarchar( 100) );
    declare treespecies_result table (
        treespecie nvarchar( 100 ),
        modelCompartment nvarchar( 100),
        priority int);
    declare JAREYS string;
    declare HYVA_TYVI string;
    declare HUONO_TYVI string;
    declare KESKI_LPM string;
    declare KERTYMA string;
    declare PITUUS string;
    declare PUULAJIOSUUS string;
    declare IKA string;
    declare LAHON_OSUUS string;
    declare METSATYYPPI string;
    declare HAKKUUTAPARYHMA string;
    declare OJITUSALUE string;
    -- additional fileds
    declare NIMI string;
    declare KOODI string;
    declare MUUTTAJA string;
    declare TUOTANTO_VERSIO string;
    declare SIMULOINTI_VERSIO string;
    declare TALLETTAJA string;
    declare SIMULOINTI string;
    declare TUOTANTO string;

    logy = :in_logy;
    --SAP may send LOGY with zeros in prefix
    WHILE LEFT(logy, 1) = '0' DO
            logy = SUBSTR_AFTER( :logy, '0');
    END WHILE;

    treespecies = select distinct TO_NVARCHAR( :in_treespeciesitems.treespecies ) treespecie from :in_treespeciesitems;
    --for each specified tree specie (PTL)
    for lv_index in 1..record_count(:treespecies)
        do
        --inititlaize known parameters
        declare tree nvarchar( 100 ) = :treespecies.treespecie[:lv_index];
        JAREYS_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'JAREYS';
        IF NOT IS_EMPTY( :JAREYS_t ) THEN select TOP 1 value into JAREYS default null from :JAREYS_t; END IF;
        HYVA_TYVI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'HYVA_TYVI';
        IF NOT IS_EMPTY( :HYVA_TYVI_t ) THEN select TOP 1 value into HYVA_TYVI default null from :HYVA_TYVI_t; END IF;
        HUONO_TYVI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'HUONO_TYVI';
        IF NOT IS_EMPTY( :HUONO_TYVI_t ) THEN select TOP 1 value into HUONO_TYVI default null from :HUONO_TYVI_t; END IF;
        KESKI_LPM_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'KESKI_LPM';
        IF NOT IS_EMPTY( :KESKI_LPM_t ) THEN select TOP 1 value into KESKI_LPM default null from :KESKI_LPM_t; END IF;
        KERTYMA_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'KERTYMA';
        IF NOT IS_EMPTY( :KERTYMA_t ) THEN select TOP 1 value into KERTYMA default null from :KERTYMA_t; END IF;
        PITUUS_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'PITUUS';
        IF NOT IS_EMPTY( :PITUUS_t ) THEN select TOP 1 value into PITUUS default null from :PITUUS_t; END IF;
        PUULAJIOSUUS_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'PUULAJIOSUUS';
        IF NOT IS_EMPTY( :PUULAJIOSUUS_t ) THEN select TOP 1 value into PUULAJIOSUUS default null from :PUULAJIOSUUS_t; END IF;
        IKA_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'IKA';
        IF NOT IS_EMPTY( :IKA_t ) THEN select TOP 1 value into IKA default null from :IKA_t; END IF;
        LAHON_OSUUS_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'LAHON_OSUUS';
        IF NOT IS_EMPTY( :LAHON_OSUUS_t ) THEN select TOP 1 value into LAHON_OSUUS default null from :LAHON_OSUUS_t; END IF;
        METSATYYPPI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'METSATYYPPI';
        IF NOT IS_EMPTY( :METSATYYPPI_t ) THEN select TOP 1 value into METSATYYPPI default null from :METSATYYPPI_t; END IF;
        HAKKUUTAPARYHMA_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'HAKKUUTAPARYHMA';
        IF NOT IS_EMPTY( :HAKKUUTAPARYHMA_t ) THEN select TOP 1 value into HAKKUUTAPARYHMA default null from :HAKKUUTAPARYHMA_t; END IF;
        OJITUSALUE_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'OJITUSALUE';
        IF NOT IS_EMPTY( :OJITUSALUE_t ) THEN select TOP 1 value into OJITUSALUE default null from :OJITUSALUE_t; END IF;
-- additional fileds
        NIMI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'NIMI';
        IF NOT IS_EMPTY( :NIMI_t ) THEN select TOP 1 value into NIMI default null from :NIMI_t; END IF;
        KOODI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'KOODI';
        IF NOT IS_EMPTY( :KOODI_t ) THEN select TOP 1 value into KOODI default null from :KOODI_t; END IF;
        MUUTTAJA_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'MUUTTAJA';
        IF NOT IS_EMPTY( :MUUTTAJA_t ) THEN select TOP 1 value into MUUTTAJA default null from :MUUTTAJA_t; END IF;
        TUOTANTO_VERSIO_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'TUOTANTO_VERSIO';
        IF NOT IS_EMPTY( :TUOTANTO_VERSIO_t ) THEN select TOP 1 value into TUOTANTO_VERSIO default null from :TUOTANTO_VERSIO_t; END IF;
        SIMULOINTI_VERSIO_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'SIMULOINTI_VERSIO';
        IF NOT IS_EMPTY( :SIMULOINTI_VERSIO_t ) THEN select TOP 1 value into SIMULOINTI_VERSIO default null from :SIMULOINTI_VERSIO_t; END IF;
        TALLETTAJA_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'TALLETTAJA';
        IF NOT IS_EMPTY( :TALLETTAJA_t ) THEN select TOP 1 value into TALLETTAJA default null from :TALLETTAJA_t; END IF;
        SIMULOINTI_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'SIMULOINTI';
        IF NOT IS_EMPTY( :SIMULOINTI_t ) THEN select TOP 1 value into SIMULOINTI default null from :SIMULOINTI_t; END IF;
        TUOTANTO_t = select t.value from :in_treespeciesitems t where TO_NVARCHAR( t.treespecies ) = :tree and TO_NVARCHAR( t.valuename ) = 'TUOTANTO';
        IF NOT IS_EMPTY( :TUOTANTO_t ) THEN select TOP 1 value into TUOTANTO default null from :TUOTANTO_t; END IF;

        --Run database query
        result_t = SELECT p.PRIORITY, p.TYYPPILEIMIKKOLUOKKA FROM MLOAPTERI.LOGY_OF_TL_LUOKKARYHMA l, MLOAPTERI.PRIORITY_OF_TL_LUOKKARYHMA p WHERE
        l.LOGY = :logy
        AND p.TYYPPILEIMIKKOLUOKKA IN (SELECT tl.KOODI FROM MLOAPTERI.TYYPPILEIMIKKO2 tl WHERE
        tl.TUOTANTO = 1
        AND
        tl.PUULAJI = :tree
        AND
        (
        (tl.JAREYS_ALARAJA <= :JAREYS OR :JAREYS IS NULL) AND
        (tl.HYVA_TYVI_ALARAJA <= :HYVA_TYVI OR :HYVA_TYVI IS NULL) AND
        (tl.HUONO_TYVI_ALARAJA <= :HUONO_TYVI OR :HUONO_TYVI IS NULL) AND
        (tl.KESKI_LPM_ALARAJA <= :KESKI_LPM OR :KESKI_LPM IS NULL) AND
        (tl.KERTYMA_ALARAJA <= :KERTYMA OR :KERTYMA IS NULL) AND
        (tl.PITUUS_ALARAJA <= :PITUUS OR :PITUUS IS NULL) AND
        (tl.PUULAJIOSUUS_ALARAJA <= :PUULAJIOSUUS OR :PUULAJIOSUUS IS NULL) AND
        (tl.IKA_ALARAJA <= :IKA OR :IKA IS NULL) AND
        (tl.LAHON_OSUUS_ALARAJA <= :LAHON_OSUUS OR :LAHON_OSUUS IS NULL) AND
        (tl.JAREYS_YLARAJA >= :JAREYS OR :JAREYS IS NULL) AND
        (tl.HYVA_TYVI_YLARAJA >= :HYVA_TYVI OR :HYVA_TYVI IS NULL) AND
        (tl.HUONO_TYVI_YLARAJA >= :HUONO_TYVI OR :HUONO_TYVI IS NULL) AND
        (tl.KESKI_LPM_YLARAJA >= :KESKI_LPM OR :KESKI_LPM IS NULL) AND
        (tl.KERTYMA_YLARAJA >= :KERTYMA OR :KERTYMA IS NULL) AND
        (tl.PITUUS_YLARAJA >= :PITUUS OR :PITUUS IS NULL) AND
        (tl.PUULAJIOSUUS_YLARAJA >= :PUULAJIOSUUS OR :PUULAJIOSUUS IS NULL) AND
        (tl.IKA_YLARAJA >= :IKA OR :IKA IS NULL) AND
        (tl.LAHON_OSUUS_YLARAJA >= :LAHON_OSUUS OR :LAHON_OSUUS IS NULL) AND
        (tl.HAKKUUTAPARYHMA = :HAKKUUTAPARYHMA OR :HAKKUUTAPARYHMA IS NULL) AND
        (tl.OJITUSALUE = :OJITUSALUE OR :OJITUSALUE IS NULL) AND
-- additional fileds
        (tl.NIMI = :NIMI OR :NIMI IS NULL) AND
        (tl.KOODI = :KOODI OR :KOODI IS NULL) AND
        (tl.NIMI = :MUUTTAJA OR :MUUTTAJA IS NULL) AND
        (tl.TUOTANTO_VERSIO = :TUOTANTO_VERSIO OR :TUOTANTO_VERSIO IS NULL) AND
        (tl.SIMULOINTI_VERSIO = :SIMULOINTI_VERSIO OR :SIMULOINTI_VERSIO IS NULL) AND
        (tl.TALLETTAJA = :TALLETTAJA OR :TALLETTAJA IS NULL) AND
        (tl.SIMULOINTI = :SIMULOINTI OR :SIMULOINTI IS NULL) AND
        (tl.TUOTANTO = :TUOTANTO OR :TUOTANTO IS NULL)
        )
        AND
        CASE
        WHEN :METSATYYPPI = 1 AND MOD(tl.METSATYYPPI, 2) = 1 THEN 1
        WHEN :METSATYYPPI = 2 AND tl.METSATYYPPI IN (2,3,6,7,10,11,14,15) THEN 1
        WHEN :METSATYYPPI = 3 AND tl.METSATYYPPI IN (4,5,6,7,12,13,14,15) THEN 1
        WHEN :METSATYYPPI = 4 AND tl.METSATYYPPI > 7 THEN 1
        WHEN :METSATYYPPI IS NULL THEN 1
        ELSE 0
        END = 1
        ) AND p.TYYPPILEIMIKKOLUOKKARYHMA_ID = l.TYYPPILEIMIKKOLUOKKARYHMA_ID ORDER BY p.PRIORITY;

                --Results may contain multiple tree specie items with different priorities
                --Here we should pickup a single tree specie with the smallest priority value
                --(the smallest priority value means with the highest priority)
        result_t = SELECT MIN(p.PRIORITY) PRIORITY, p.TYYPPILEIMIKKOLUOKKA FROM :result_t p GROUP BY p.TYYPPILEIMIKKOLUOKKA;

        treespecies_result = select * from :treespecies_result union select :tree, TYYPPILEIMIKKOLUOKKA, PRIORITY from :result_t;

    end for;

    out_workingsiteid = :in_workingsiteid;
    out_logy = :in_logy;
    --TODO must check priority column, missing in output
    out_treespeciesitems = select treespecie treespecies, modelCompartment from :treespecies_result;

    INSERT INTO MLOAPTERI.LOHKON_TL_LOG(LOHKO, LOGY, AIKALEIMA, REQUEST, RESPONSE)
    VALUES (:in_workingsiteid, :in_logy, CURRENT_TIMESTAMP, (SELECT * FROM :in_treespeciesitems FOR JSON), (SELECT * FROM :out_treespeciesitems FOR JSON));

  ENDMETHOD.

ENDCLASS.