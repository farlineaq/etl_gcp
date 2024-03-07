CREATE OR REPLACE PROCEDURE `{sp_name}`(
    date_to_calculate DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    sales_table STRING,
    final_table STRING
)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;

    IF granularity = 'MONTH' THEN
        SET start_date = DATE_TRUNC(date_to_calculate, MONTH);
        SET end_date = LAST_DAY(start_date);
    ELSEIF granularity = 'YEAR' THEN
        SET start_date = DATE(DATE_TRUNC(date_to_calculate, YEAR));
        SET end_date = DATE_ADD(DATE_TRUNC(DATE_ADD(date_to_calculate, INTERVAL 1 YEAR), YEAR), INTERVAL -1 DAY);
    ELSE
        SET start_date = DATE_TRUNC(date_to_calculate, MONTH);
        SET end_date = LAST_DAY(start_date);
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        PorcentajeRetencion FLOAT64
    );

    CALL `{sp_general_tasa_retencion}`(
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
        MERGE INTO `%s` AS target
        USING temp_table AS source
        ON target.Fecha = source.Fecha AND target.CadenaCD = source.CadenaCD AND target.IndicadorKey = 4
        WHEN MATCHED THEN
            UPDATE SET
                target.Valor = source.PorcentajeRetencion,
                target.FechaActualizacion = TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))
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
                source.Fecha,
                source.CadenaCD,
                0,
                4,
                source.PorcentajeRetencion,
                TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))
            );
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;