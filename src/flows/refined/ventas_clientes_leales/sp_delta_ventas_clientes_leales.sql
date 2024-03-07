CREATE OR REPLACE PROCEDURE `{sp_name}`(
    date_to_calculate DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    sales_table STRING,
    segment_table STRING,
    model_segment_table STRING,
    segment_table_backup STRING,
    model_segment_table_backup STRING,
    final_table STRING
)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    DECLARE temp_start_date DATE;
    DECLARE temp_end_date DATE;

    IF granularity = 'DAY' THEN
        SET start_date = date_to_calculate;
        SET end_date = start_date;
        SET temp_start_date = DATE_SUB(start_date, INTERVAL 1 DAY);
        SET temp_end_date = DATE_SUB(end_date, INTERVAL 1 DAY);
    ELSEIF granularity = 'MONTH' THEN
        SET start_date = DATE_TRUNC(date_to_calculate, MONTH);
        SET end_date = LAST_DAY(start_date);
    ELSEIF granularity = 'YEAR' THEN
        SET start_date = DATE_TRUNC(date_to_calculate, YEAR);
        SET end_date = DATE_ADD(DATE_TRUNC(DATE_ADD(date_to_calculate, INTERVAL 1 YEAR), YEAR), INTERVAL -1 DAY);
    ELSE
        SET start_date = date_to_calculate;
        SET end_date = date_to_calculate;
    END IF;

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

    IF granularity = 'DAY' THEN
        CALL `{sp_general_ventas_clientes_leales}`(
            temp_start_date,
            temp_end_date,
            granularity,
            excluded_sublineaCD,
            included_direccionCD,
            excluded_tipoNegociacion,
            included_CadenaCD,
            sales_table,
            segment_table_backup,
            model_segment_table_backup,
            'temp_table'
        );
    END IF;

    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` AS final
        USING temp_table AS temp
            ON final.Fecha = temp.Fecha
            AND final.CadenaCD = temp.CadenaCD
            AND final.ModeloSegmentoid = temp.ModeloSegmentoid
            AND final.IndicadorKey = 6
        WHEN MATCHED THEN
            UPDATE SET
                final.Valor = temp.Valor,
                final.FechaActualizacion = TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))
        WHEN NOT MATCHED THEN
            INSERT (
                Fecha,
                CadenaCD,
                ModeloSegmentoid,
                IndicadorKey,
                Valor,
                FechaActualizacion
            )
            VALUES (
                temp.Fecha,
                temp.CadenaCD,
                temp.ModeloSegmentoid,
                6,
                temp.Valor,
                TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))
            );
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;