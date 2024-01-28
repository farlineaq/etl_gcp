CREATE OR REPLACE PROCEDURE `{sp_name}`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD STRING,
    sales_table STRING,
    segment_table STRING,
    model_segment_table STRING,
    temp_table STRING
)
BEGIN
    DECLARE formatted_date_expr STRING;
    DECLARE query STRING;
    DECLARE model_id_condition INT64;
    DECLARE model_segment_desc_condition ARRAY<STRING>;

    CASE
        WHEN included_CadenaCD = 'C' THEN
            SET model_id_condition = 3;
            SET model_segment_desc_condition = ['VERDE', 'DIAMANTE', 'BLACK'];
        WHEN included_CadenaCD = 'A' THEN
            SET model_id_condition = 25;
            SET model_segment_desc_condition = ['AAA', 'AA'];
        WHEN included_CadenaCD = 'S' THEN
            SET model_id_condition = 24;
            SET model_segment_desc_condition = ['AAA', 'AA'];
        ELSE
            RAISE USING MESSAGE = 'Valor de included_CadenaCD no reconocido.';
    END CASE;

    IF granularity = 'DAY' THEN
        SET formatted_date_expr = "Fecha";
    ELSEIF granularity = 'MONTH' THEN
        SET formatted_date_expr = "DATE_TRUNC(cv.Fecha, MONTH)";
    ELSEIF granularity = 'YEAR' THEN
        SET formatted_date_expr = "DATE(DATE_TRUNC(cv.Fecha, YEAR))";
    ELSE
        SET formatted_date_expr = "Fecha";
    END IF;

    SET query = FORMAT("""
        INSERT INTO `%s` (Fecha, CadenaCD, ModeloSegmentoid, Valor)
        WITH ClientesValidos AS (
            SELECT
                Fecha,
                CadenaCD,
                PartyId
            FROM
                `%s`
            WHERE
                PartyId IS NOT NULL
                AND PartyId != 0
                AND Fecha BETWEEN ? AND ?
                AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
                AND DireccionCD IN (SELECT * FROM UNNEST(?))
                AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
                AND CadenaCD = ?
        ),
        SegmentosClientes AS (
            SELECT
                %s AS Fecha0,
                ms.ModeloSegmentoid,
                COUNT(DISTINCT cv.PartyId) AS ConteoClientes
            FROM
                ClientesValidos cv
                JOIN `%s` s ON cv.PartyId = s.PartyID
                JOIN `%s` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
            WHERE
                ms.Modelid = ?
                AND ms.ModelSegmentoDesc IN (SELECT * FROM UNNEST(?))
            GROUP BY
                Fecha0,
                ms.ModeloSegmentoid
        )
        SELECT
            sc.Fecha0 as Fecha,
            ? AS CadenaCD,
            sc.ModeloSegmentoid,
            ROUND((sc.ConteoClientes / SUM(sc.ConteoClientes) OVER(PARTITION BY sc.Fecha0)) * 100, 2) AS Valor
        FROM
            SegmentosClientes sc
        """, temp_table, sales_table, formatted_date_expr, segment_table, model_segment_table);

        EXECUTE IMMEDIATE query USING
            start_date,
            end_date,
            excluded_sublineaCD,
            included_direccionCD,
            excluded_tipoNegociacion,
            included_CadenaCD,
            model_id_condition,
            model_segment_desc_condition,
            included_CadenaCD;
END;