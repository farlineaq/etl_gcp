CREATE OR REPLACE PROCEDURE `{sp_name}`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    sales_table STRING,
    segment_table STRING,
    model_segment_table STRING,
    final_table STRING
)
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        ModeloSegmentoid INT64,
        Valor FLOAT64
    );

    CALL `{sp_general_ventas_clientes_leales}`(
        start_date,
        end_date,
        granularity,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD,
        sales_table,
        segment_table,
        model_segment_table,
        'temp_table'
    );

    EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s`
        SELECT
            Fecha,
            CadenaCD,
            ModeloSegmentoid,
            6 AS IndicadorKey,
            Valor,
            CURRENT_TIMESTAMP() AS FechaActualizacion
        FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;

END;