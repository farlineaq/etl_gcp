CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralPorcentajeContactabilidad`(
    start_date DATE,
    end_date DATE,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    contact_table STRING,
    sales_table STRING,
    temp_table STRING
)
BEGIN
  DECLARE query STRING;

  SET query = FORMAT("""
    INSERT INTO `%s` (Fecha, CadenaCD, ModeloSegmentoid, Valor)
    WITH
      ClientesActivos AS (
          SELECT
              DATE_TRUNC(Fecha, MONTH) AS FechaMes,
              EXTRACT(YEAR FROM Fecha) AS Year,
              PartyID
          FROM `%s`
          WHERE
              Fecha BETWEEN DATE_TRUNC(?, YEAR) AND ?
              AND PartyId IS NOT NULL
              AND PartyId != 0
              AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
              AND DireccionCD IN (SELECT * FROM UNNEST(?))
              AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
              AND CadenaCD IN (SELECT * FROM UNNEST(?))
          GROUP BY FechaMes, Year, PartyID
      ),
      ClientesContactables AS (
          SELECT
              d.FechaMes,
              d.Year,
              d.PartyID,
              COUNT(d.PartyID) OVER (PARTITION BY d.Year, d.FechaMes ORDER BY d.FechaMes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS AcumuladoContactables
          FROM ClientesActivos d
          JOIN `%s` c ON d.PartyId = c.PartyID
          WHERE
              (c.indicadorcel = 1 OR c.indicadoremail = 1)
      ),
      TotalClientes AS (
          SELECT
              DATE_TRUNC(Fecha, MONTH) AS FechaMes,
              EXTRACT(YEAR FROM Fecha) AS Year,
              COUNT(DISTINCT PartyID) AS TotalClientes
          FROM `%s`
          WHERE
              Fecha BETWEEN DATE_TRUNC(?, YEAR) AND ?
              AND PartyId IS NOT NULL
              AND PartyId != 0
              AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
              AND DireccionCD IN (SELECT * FROM UNNEST(?))
              AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
              AND CadenaCD IN (SELECT * FROM UNNEST(?))
          GROUP BY FechaMes, Year
      )
    SELECT
        cc.FechaMes AS Fecha,
        'NA' AS CadenaCD,
        0 AS ModeloSegmentoid,
        ROUND(MAX(cc.AcumuladoContactables) / MAX(tc.TotalClientes) * 100, 2) AS Valor
    FROM ClientesContactables cc
    JOIN TotalClientes tc ON cc.FechaMes = tc.FechaMes AND cc.Year = tc.Year
    WHERE cc.FechaMes >= DATE_TRUNC(?, MONTH)
    GROUP BY cc.FechaMes;
  """, temp_table, sales_table, contact_table, sales_table);

  EXECUTE IMMEDIATE query USING
    start_date,
    end_date,
    excluded_sublineaCD,
    included_direccionCD,
    excluded_tipoNegociacion,
    included_CadenaCD,
    start_date,
    end_date,
    excluded_sublineaCD,
    included_direccionCD,
    excluded_tipoNegociacion,
    included_CadenaCD,
    start_date;
END;

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualPorcentajeContactabilidad`(
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

  CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralPorcentajeContactabilidad`(
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

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialPorcentajeContactabilidad`(
    start_date DATE,
    end_date DATE,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD ARRAY<STRING>,
    contact_table STRING,
    sales_table STRING,
    final_table STRING
)

BEGIN

  CREATE TEMP TABLE IF NOT EXISTS temp_table (
    Fecha DATE,
    CadenaCD STRING,
    ModeloSegmentoid INT64,
    Valor FLOAT64
  );

  CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralPorcentajeContactabilidad`(
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

  DROP TABLE IF EXISTS temp_table;
END;

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialPorcentajeContactabilidad`(
  DATE '2021-01-01',
  DATE '2023-01-01',
  [1, 2, 3, 4, 5, 6, 99, 505],
  [10, 20, 30, 40, 50],
  [2],
  ['E', 'C', 'A', 'S'],
  'co-grupoexito-funnel-mercd-dev.external.contactabilidad',
  'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
  'co-grupoexito-funnel-mercd-dev.refined.fact_months'
);

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualPorcentajeContactabilidad`(
  DATE '2021-10-01',
  [1, 2, 3, 4, 5, 6, 99, 505],
  [10, 20, 30, 40, 50],
  [2],
  ['E', 'C', 'A', 'S'],
  'co-grupoexito-funnel-mercd-dev.external.contactabilidad',
  'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
  'co-grupoexito-funnel-mercd-dev.refined.fact_months'
);