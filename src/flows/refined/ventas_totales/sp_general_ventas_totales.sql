CREATE OR REPLACE PROCEDURE `{sp_name}`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    sales_table STRING,
    temp_table STRING
)
BEGIN
    DECLARE query STRING;
    DECLARE formatted_date_expr STRING;

    IF granularity = 'DAY' THEN
        SET formatted_date_expr = "Fecha";
    ELSEIF granularity = 'MONTH' THEN
        SET formatted_date_expr = "DATE_TRUNC(Fecha, MONTH)";
        SET start_date = DATE_TRUNC(start_date, MONTH);
        SET end_date = LAST_DAY(end_date);
    ELSEIF granularity = 'YEAR' THEN
        SET formatted_date_expr = "DATE(DATE_TRUNC(Fecha, YEAR))";
        SET start_date = DATE_TRUNC(start_date, YEAR);
        SET end_date = DATE_ADD(DATE_TRUNC(DATE_ADD(end_date, INTERVAL 1 YEAR), YEAR), INTERVAL -1 DAY);
    ELSE
        SET formatted_date_expr = "Fecha";
    END IF;

    SET query = FORMAT("""
        INSERT INTO `%s` (Fecha, CadenaCD, VentaTotalEnMilesDeMillones)
        SELECT
            %s AS Fecha0,
            CadenaCD,
            ROUND(SUM(VentaSinImpuesto) / 1000000000, 2) AS VentaTotalEnMilesDeMillones
        FROM `%s`
        WHERE
            Fecha BETWEEN ? AND ?
            AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
            AND DireccionCD IN (SELECT * FROM UNNEST(?))
            AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
            AND CadenaCD IN (SELECT * FROM UNNEST(?))
        GROUP BY
            CadenaCD,
            Fecha0;
    """, temp_table, formatted_date_expr, sales_table);

    EXECUTE IMMEDIATE query
    USING
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD;
END;