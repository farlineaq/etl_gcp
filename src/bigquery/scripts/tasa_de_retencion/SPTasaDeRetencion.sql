CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralTasaDeRetencion`(
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
  DECLARE initial_date DATE;
  SET initial_date = start_date;

  WHILE initial_date <= end_date DO
    EXECUTE IMMEDIATE FORMAT("""
    INSERT INTO `%s` (Fecha, CadenaCD, PorcentajeRetencion)
    WITH ClientesMesAnterior AS (
      SELECT DISTINCT
        PartyId,
        CadenaCD,
        DATE_TRUNC(Fecha, %s) AS PrimerDiaMes
      FROM
        `%s`
      WHERE
        Fecha >= DATE_TRUNC(?, %s) - INTERVAL 1 %s
        AND Fecha < DATE_TRUNC(?, %s)
        AND PartyId IS NOT NULL
        AND PartyId != 0
        AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
        AND DireccionCD IN (SELECT * FROM UNNEST(?))
        AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
        AND CadenaCD IN (SELECT * FROM UNNEST(?))
    ),
    ClientesMesActual AS (
      SELECT DISTINCT
        PartyId,
        CadenaCD,
        DATE_TRUNC(Fecha, %s) AS PrimerDiaMes
      FROM
        `%s`
      WHERE
        Fecha >= DATE_TRUNC(?, %s)
        AND Fecha < LEAST(DATE_TRUNC(?, %s) + INTERVAL 1 %s, ? + INTERVAL 1 DAY)
        AND PartyId IS NOT NULL
        AND PartyId != 0
        AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
        AND DireccionCD IN (SELECT * FROM UNNEST(?))
        AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
        AND CadenaCD IN (SELECT * FROM UNNEST(?))
    ),
    ClientesRetenidos AS (
      SELECT
        a.PartyId,
        b.CadenaCD,
        b.PrimerDiaMes AS PrimerDiaMesActual
      FROM
        ClientesMesAnterior a
      JOIN
        ClientesMesActual b
      ON
        a.PartyId = b.PartyId
    )
    SELECT
      cr.PrimerDiaMesActual AS Fecha,
      cr.CadenaCD,
      ROUND((COUNT(DISTINCT cr.PartyId)/(
        SELECT
          COUNT(DISTINCT cma.PartyId)
        FROM
          ClientesMesAnterior cma
        )) * 100, 2) AS PorcentajeRetencion
    FROM
      ClientesRetenidos cr
    GROUP BY
      cr.PrimerDiaMesActual, cr.CadenaCD;
    """, temp_table, granularity, sales_table, granularity, granularity, granularity, granularity, sales_table, granularity, granularity, granularity)
    USING initial_date, initial_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, included_CadenaCD,
          initial_date, initial_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, included_CadenaCD;

    SET initial_date = IF(granularity = 'MONTH', DATE_ADD(DATE_TRUNC(initial_date, MONTH), INTERVAL 1 MONTH), DATE_ADD(DATE_TRUNC(initial_date, YEAR), INTERVAL 1 YEAR));
  END WHILE;
END;

-- Cálculo individual

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPTasaDeRetencion`(
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

    CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralTasaDeRetencion`(
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
        4 AS IndicadorKey,
        PorcentajeRetencion AS Valor,
        CURRENT_TIMESTAMP() AS FechaActualizacion
      FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;

-- Carga Inicial

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialTasaDeRetencion`(
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
      PorcentajeRetencion FLOAT64
    );

    CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralTasaDeRetencion`(
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
        4 AS IndicadorKey,
        PorcentajeRetencion AS Valor,
        CURRENT_TIMESTAMP() AS FechaActualizacion
      FROM temp_table;
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPTasaDeRetencion`(
  '2022-01-01',
  'YEAR',
  [1, 2, 3, 4, 5, 6, 99, 505],
  [10, 20, 30, 40, 50],
  [2],
  ['E', 'C', 'A', 'S', 'M'],
  'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
  'co-grupoexito-funnel-mercd-dev.refined.fact_target_years'
);

