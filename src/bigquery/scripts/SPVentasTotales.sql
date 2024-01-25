CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralVentasTotalesSinIVA`(
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

  EXECUTE IMMEDIATE query USING start_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, included_CadenaCD;
END;

-- SP Carga diaria

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualVentasTotalesSinIVA`(
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

    CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralVentasTotalesSinIVA`(
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

        CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralVentasTotalesSinIVA`(
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
            INSERT (Fecha, CadenaCD, ModeloSegmentoid, IndicadorKey, Valor, FechaActualizacion)
            VALUES (temp.Fecha, temp.CadenaCD, 0, 1, temp.VentaTotalEnMilesDeMillones, CURRENT_TIMESTAMP());
    """, final_table);

    DROP TABLE IF EXISTS temp_table;

END;

-- SP Carga inicial

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialVentasTotalesSinIVA`(
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
    DECLARE second_end_date DATE;
    DECLARE second_start_date DATE;

    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        Fecha DATE,
        CadenaCD STRING,
        VentaTotalEnMilesDeMillones FLOAT64
    );

    CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralVentasTotalesSinIVA`(
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
          1 AS IndicadorKey,
          VentaTotalEnMilesDeMillones AS Valor,
          CURRENT_TIMESTAMP() AS FechaActualizacion
        FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;

-- Endpoints

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualVentasTotalesSinIVA`(
    DATE '2021-01-01',
    'YEAR',
    [1, 2, 3, 4, 5, 6, 99, 505],
    [10, 20, 30, 40, 50],
    [2],
    ['E', 'C', 'A', 'S'],
    'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
    'co-grupoexito-funnel-mercd-dev.refined.fact_years'
);
