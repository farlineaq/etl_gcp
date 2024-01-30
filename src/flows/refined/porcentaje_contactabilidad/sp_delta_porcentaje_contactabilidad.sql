CREATE OR REPLACE PROCEDURE `{sp_name}`(
    date_to_calculate DATE,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    contact_table STRING,
    sales_table STRING,
    final_table STRING
)

BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;

    SET start_date = DATE_TRUNC(date_to_calculate, MONTH);
    SET end_date = LAST_DAY(start_date);

    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        ModeloSegmentoid INT64,
        Valor FLOAT64
    );

    CALL `{sp_general_porcentaje_contactabilidad}`(
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD,
        contact_table,
        sales_table,
        'temp_table'
    );

    EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s`
        SELECT
            Fecha,
            CadenaCD,
            ModeloSegmentoid,
            7 AS IndicadorKey,
            Valor,
            CURRENT_TIMESTAMP() AS FechaActualizacion
        FROM temp_table;
    """, final_table);

END;