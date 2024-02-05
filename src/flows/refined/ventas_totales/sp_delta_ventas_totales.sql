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
    DECLARE end_date DATE;
    DECLARE start_date DATE;
    DECLARE temp_end_date DATE;
    DECLARE temp_start_date DATE;

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
        RAISE USING MESSAGE = 'Valor de granularity no reconocido.';
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        VentaTotalEnMilesDeMillones FLOAT64
    );

    CALL `{sp_general_ventas_totales}`(
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

    IF granularity = 'DAY' THEN

        CALL `{sp_general_ventas_totales}`(
            temp_start_date,
            temp_end_date,
            granularity,
            excluded_sublineaCD,
            included_direccionCD,
            excluded_tipoNegociacion,
            included_CadenaCD,
            sales_table,
            'temp_table'
        );

    END IF;

    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` AS final
        USING temp_table AS temp
        ON final.Fecha = temp.Fecha AND final.CadenaCD = temp.CadenaCD AND final.IndicadorKey = 1
        WHEN MATCHED THEN
            UPDATE SET
                final.Valor = temp.VentaTotalEnMilesDeMillones,
                final.FechaActualizacion = CURRENT_TIMESTAMP()
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
                0,
                1,
                temp.VentaTotalEnMilesDeMillones,
                CURRENT_TIMESTAMP()
            );
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;
