CREATE OR REPLACE PROCEDURE `{sp_name}`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    sales_table STRING,
    final_table STRING
)
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        NumeroClientesUnicos INT64
    );

    CALL `{sp_general_clientes_monitoreados}`(
        start_date,
        end_date,
        granularity,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD,
        sales_table,
        'temp_table'
    );

    EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s`
        SELECT
            Fecha,
            CadenaCD,
            0 AS ModeloSegmentoid,
            3 AS IndicadorKey,
            NumeroClientesUnicos AS Valor,
            TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota')) AS FechaActualizacion
        FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;
