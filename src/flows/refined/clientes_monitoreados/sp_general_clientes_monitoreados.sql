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
    DECLARE formatted_date_expr STRING;
    DECLARE query STRING;

    IF granularity = 'DAY' THEN
        SET formatted_date_expr = "Fecha";
    ELSEIF granularity = 'MONTH' THEN
        SET formatted_date_expr = "DATE_TRUNC(Fecha, MONTH)";
    ELSEIF granularity = 'YEAR' THEN
        SET formatted_date_expr = "DATE(DATE_TRUNC(Fecha, YEAR))";
    ELSE
        SET formatted_date_expr = "Fecha";
    END IF;

    SET query = FORMAT("""
        INSERT INTO `%s` (Fecha, CadenaCD, NumeroClientesUnicos)
        SELECT
            %s AS Fecha,
            CadenaCD,
            COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
        FROM `%s`
        WHERE
            Fecha BETWEEN ? AND ?
            AND PartyId IS NOT NULL AND PartyId != 0
            AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
            AND DireccionCD IN (SELECT * FROM UNNEST(?))
            AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
            AND CadenaCD IN (SELECT * FROM UNNEST(?))
        GROUP BY
            %s,
            CadenaCD;
    """, temp_table, formatted_date_expr, sales_table, formatted_date_expr);

    EXECUTE IMMEDIATE query USING
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD;
END;