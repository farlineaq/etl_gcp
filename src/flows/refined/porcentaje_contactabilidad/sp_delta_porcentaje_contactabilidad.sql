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
        MERGE INTO `%s` AS target
        USING temp_table AS source
        ON target.Fecha = source.Fecha AND target.CadenaCD = source.CadenaCD AND target.IndicadorKey = 7
        WHEN MATCHED THEN
            UPDATE SET
                target.Valor = source.Valor,
                target.FechaActualizacion = CURRENT_TIMESTAMP()
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
                source.ModeloSegmentoid,
                7,
                source.Valor,
                CURRENT_TIMESTAMP()
            );
    """, final_table);

END;