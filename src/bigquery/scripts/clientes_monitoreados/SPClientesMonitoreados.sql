CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.ClientesMonitoreados`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY <INT64>,
    included_direccionCD ARRAY <INT64>,
    excluded_tipoNegociacion ARRAY <INT64>,
    included_CadenaCD ARRAY <STRING>,
    sales_table STRING,
    temp_table STRING
)
BEGIN
    DECLARE formatted_date_expr STRING;
    DECLARE query STRING;

    -- Determinar cómo formatear la fecha basado en la granularidad
    IF granularity = 'DAY' THEN
        SET formatted_date_expr = "Fecha";
    ELSEIF granularity = 'MONTH' THEN
        SET formatted_date_expr = "FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(Fecha, MONTH))";
    ELSEIF granularity = 'YEAR' THEN
        SET formatted_date_expr = "FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR))";
    ELSE
        -- Opción por defecto o manejar error
        SET formatted_date_expr = "Fecha";
    END IF;

    -- Construir la consulta
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
            %s, CadenaCD;
    """, temp_table, formatted_date_expr, sales_table, formatted_date_expr);

    EXECUTE IMMEDIATE query USING start_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, included_CadenaCD;
END;

-- SP Cálculo individual


CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPClientesMonitoreados`(
    date_to_calculate DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY <INT64>,
    included_direccionCD ARRAY <INT64>,
    excluded_tipoNegociacion ARRAY <INT64>,
    included_CadenaCD ARRAY <STRING>,
    sales_table STRING,
    final_table STRING
)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    DECLARE temp_start_date DATE;
    DECLARE temp_end_date DATE;

    -- Configurar las fechas de inicio y fin
    SET start_date = date_to_calculate;
    SET end_date = start_date;
    SET temp_start_date = DATE_SUB(start_date, INTERVAL 1 DAY);
    SET temp_end_date = DATE_SUB(end_date, INTERVAL 1 DAY);


    CREATE TEMP TABLE IF NOT EXISTS temp_table
    (
        Fecha                DATE,
        CadenaCD             STRING,
        NumeroClientesUnicos INT64
    );

    -- Lógica para procesar los datos
    CALL `co-grupoexito-funnel-mercd-dev.procedures.ClientesMonitoreados`(
            start_date, end_date, granularity, excluded_sublineaCD,
            included_direccionCD, excluded_tipoNegociacion,
            included_CadenaCD, sales_table, 'temp_table'
         );

    -- Procesar el día anterior si la granularidad es 'DAY'
    IF granularity = 'DAY' THEN
        CALL `co-grupoexito-funnel-mercd-dev.procedures.ClientesMonitoreados`(
                temp_start_date, temp_end_date, granularity, excluded_sublineaCD,
                included_direccionCD, excluded_tipoNegociacion,
                included_CadenaCD, sales_table, 'temp_table'
             );
    END IF;

    -- Realizar la operación MERGE
    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` AS final
        USING temp_table AS temp
        ON final.Fecha = temp.Fecha AND final.CadenaCD = temp.CadenaCD AND final.IndicadorKey = 3
        WHEN MATCHED THEN
            UPDATE SET
                final.Valor = temp.NumeroClientesUnicos,
                final.FechaActualizacion = CURRENT_TIMESTAMP()
        WHEN NOT MATCHED THEN
            INSERT (Fecha, CadenaCD, ModeloSegmentoid, IndicadorKey, Valor, FechaActualizacion)
            VALUES (temp.Fecha, temp.CadenaCD, 0, 3, temp.NumeroClientesUnicos, CURRENT_TIMESTAMP());
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;

-- SP Carga inicial

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialClientesMonitoreados`(
    start_date DATE, end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY <INT64>,
    included_direccionCD ARRAY <INT64>,
    excluded_tipoNegociacion ARRAY <INT64>,
    included_CadenaCD ARRAY <STRING>,
    sales_table STRING,
    final_table STRING
)
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_table
    (
        Fecha                DATE,
        CadenaCD             STRING,
        NumeroClientesUnicos INT64
    );

    CALL `co-grupoexito-funnel-mercd-dev.procedures.ClientesMonitoreados`(
            start_date, end_date, granularity, excluded_sublineaCD,
            included_direccionCD, excluded_tipoNegociacion,
            included_CadenaCD, sales_table, 'temp_table'
         );

    EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s`
        SELECT
            Fecha,
            CadenaCD,
            0 AS ModeloSegmentoid,
            3 AS IndicadorKey,
            NumeroClientesUnicos AS Valor,
            CURRENT_TIMESTAMP() AS FechaActualizacion
        FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;


