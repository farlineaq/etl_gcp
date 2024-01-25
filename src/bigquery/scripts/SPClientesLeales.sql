-- Clientes leales sin E

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLealesSinE`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    included_CadenaCD STRING,
    sales_table STRING,
    segment_table STRING,
    model_segment_table STRING,
    temp_table STRING
)
BEGIN
  DECLARE formatted_date_expr STRING;
  DECLARE query STRING;
  DECLARE model_id_condition INT64;
  DECLARE model_segment_desc_condition ARRAY<STRING>;

  CASE
    WHEN included_CadenaCD = 'C' THEN
      SET model_id_condition = 3;
      SET model_segment_desc_condition = ['VERDE', 'DIAMANTE', 'BLACK'];
    WHEN included_CadenaCD = 'A' THEN
      SET model_id_condition = 25;
      SET model_segment_desc_condition = ['AAA', 'AA'];
    WHEN included_CadenaCD = 'S' THEN
      SET model_id_condition = 24;
      SET model_segment_desc_condition = ['AAA', 'AA'];
    ELSE
      RAISE USING MESSAGE = 'Valor de included_CadenaCD no reconocido.';
  END CASE;

  IF granularity = 'DAY' THEN
    SET formatted_date_expr = "Fecha";
  ELSEIF granularity = 'MONTH' THEN
    SET formatted_date_expr = "DATE_TRUNC(cv.Fecha, MONTH)";
  ELSEIF granularity = 'YEAR' THEN
    SET formatted_date_expr = "DATE(DATE_TRUNC(cv.Fecha, YEAR))";
  ELSE
    SET formatted_date_expr = "Fecha";
  END IF;

  SET query = FORMAT("""
    INSERT INTO `%s` (Fecha, CadenaCD, ModeloSegmentoid, Valor)
    WITH ClientesValidos AS (
        SELECT
            Fecha,
            CadenaCD,
            PartyId
        FROM
            `%s`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND Fecha BETWEEN ? AND ?
            AND SublineaCD NOT IN (SELECT * FROM UNNEST(?))
            AND DireccionCD IN (SELECT * FROM UNNEST(?))
            AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
            AND CadenaCD = ?
    ),
    SegmentosClientes AS (
        SELECT
            %s AS Fecha0,
            ms.ModeloSegmentoid,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes
        FROM
            ClientesValidos cv
            JOIN `%s` s ON cv.PartyId = s.PartyID
            JOIN `%s` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = ?
            AND ms.ModelSegmentoDesc IN (SELECT * FROM UNNEST(?))
        GROUP BY
            Fecha0,
            ms.ModeloSegmentoid
    )
    SELECT
        sc.Fecha0 as Fecha,
        ? AS CadenaCD,
        sc.ModeloSegmentoid,
        ROUND((sc.ConteoClientes / SUM(sc.ConteoClientes) OVER(PARTITION BY sc.Fecha0)) * 100, 2) AS Valor
    FROM
        SegmentosClientes sc
    """, temp_table, sales_table, formatted_date_expr, segment_table, model_segment_table);

  EXECUTE IMMEDIATE query USING start_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, included_CadenaCD, model_id_condition, model_segment_desc_condition, included_CadenaCD;
END;

-- Clientes leales con E

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPClientesLealesE`(
    start_date DATE,
    end_date DATE,
    granularity STRING,
    excluded_sublineaCD ARRAY<INT64>,
    included_direccionCD ARRAY<INT64>,
    excluded_tipoNegociacion ARRAY<INT64>,
    sales_table STRING,
    segment_table STRING,
    model_segment_table STRING,
    temp_table STRING
)
BEGIN
  DECLARE formatted_date_expr STRING;
  DECLARE query STRING;

  IF granularity = 'DAY' THEN
    SET formatted_date_expr = "vc.Fecha";
  ELSEIF granularity = 'MONTH' THEN
    SET formatted_date_expr = "DATE_TRUNC(Fecha, MONTH)";
  ELSEIF granularity = 'YEAR' THEN
    SET formatted_date_expr = "DATE(DATE_TRUNC(Fecha, YEAR))";
  ELSE
    SET formatted_date_expr = "vc.Fecha";
  END IF;

  SET query = FORMAT("""
    INSERT INTO `%s` (Fecha, CadenaCD, ModeloSegmentoid, Valor)
    WITH ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `%s` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE_SUB(?, INTERVAL 12 MONTH) AND ?
            AND vc.SublineaCD NOT IN (SELECT * FROM UNNEST(?))
            AND vc.DireccionCD IN (SELECT * FROM UNNEST(?))
            AND vc.TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
            AND vc.CadenaCD = 'E'
        GROUP BY
            vc.PartyId
        HAVING
            COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
    ),
    ClientesLeales AS (
        SELECT
            ct.PartyId,
            CASE
                WHEN ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10') THEN 'ClienteLeal'
                ELSE 'ClienteNoLeal'
            END AS Segmento
        FROM
            ClientesTop ct
            JOIN `%s` s ON ct.PartyId = s.PartyID
            JOIN `%s` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            %s AS Fecha,
            COUNT(DISTINCT vc.PartyId) AS ConteoClientes,
            cl.Segmento
        FROM
            `%s` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN ? AND ?
            AND vc.SublineaCD NOT IN (SELECT * FROM UNNEST(?))
            AND vc.DireccionCD IN (SELECT * FROM UNNEST(?))
            AND vc.TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
            AND vc.CadenaCD = 'E'
        GROUP BY
            %s,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            Fecha,
            'E' AS CadenaCD,
            0 AS ModeloSegmentoid,
            ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
    SELECT
        Fecha,
        CadenaCD,
        ModeloSegmentoid,
        PorcentajeClientesLeales AS Valor
    FROM
        DistribucionClientes
    WHERE
        Segmento = 'ClienteLeal'
  """, temp_table, sales_table, segment_table, model_segment_table, formatted_date_expr, sales_table, formatted_date_expr);

  EXECUTE IMMEDIATE query USING start_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, start_date, end_date, excluded_sublineaCD, included_direccionCD, excluded_tipoNegociacion, formatted_date_expr;
END;

-- Clientes leales general

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLeales`(
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
    temp_table STRING
)
BEGIN
  DECLARE cadena STRING;
  DECLARE idx INT64 DEFAULT 0;

  WHILE idx < ARRAY_LENGTH(included_CadenaCD) DO
    SET cadena = included_CadenaCD[OFFSET(idx)];

    IF cadena = 'E' THEN
      CALL `co-grupoexito-funnel-mercd-dev.procedures.SPClientesLealesE`(
          start_date,
          end_date,
          granularity,
          excluded_sublineaCD,
          included_direccionCD,
          excluded_tipoNegociacion,
          sales_table,
          segment_table,
          model_segment_table,
          temp_table
      );
    ELSE
      CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLealesSinE`(
          start_date,
          end_date,
          granularity,
          excluded_sublineaCD,
          included_direccionCD,
          excluded_tipoNegociacion,
          cadena,
          sales_table,
          segment_table,
          model_segment_table,
          temp_table
      );
    END IF;

    SET idx = idx + 1;
  END WHILE;
END;

-- Cálculo individual

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualClientesLeales`(
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

    CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLeales`(
        start_date, end_date, granularity, excluded_sublineaCD,
        included_direccionCD, excluded_tipoNegociacion,
        included_CadenaCD, sales_table, segment_table,
        model_segment_table, 'temp_table'
    );

    IF granularity = 'DAY' THEN
        CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLeales`(
            temp_start_date, temp_end_date, granularity, excluded_sublineaCD,
            included_direccionCD, excluded_tipoNegociacion,
            included_CadenaCD, sales_table, segment_table_backup,
            model_segment_table_backup, 'temp_table'
        );
    END IF;

    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` AS final
        USING temp_table AS temp
        ON final.Fecha = temp.Fecha AND final.CadenaCD = temp.CadenaCD AND final.IndicadorKey = 5
        WHEN MATCHED THEN
            UPDATE SET
                final.Valor = temp.Valor,
                final.FechaActualizacion = CURRENT_TIMESTAMP()
        WHEN NOT MATCHED THEN
            INSERT (Fecha, CadenaCD, ModeloSegmentoid, IndicadorKey, Valor, FechaActualizacion)
            VALUES (temp.Fecha, temp.CadenaCD, temp.ModeloSegmentoid, 5, temp.Valor, CURRENT_TIMESTAMP());
    """, final_table);

    DROP TABLE IF EXISTS temp_table;
END;

-- Carga inicial

CREATE OR REPLACE PROCEDURE `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialClientesLeales`(
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

  CALL `co-grupoexito-funnel-mercd-dev.procedures.SPGeneralClientesLeales`(
    start_date, end_date, granularity, excluded_sublineaCD,
    included_direccionCD, excluded_tipoNegociacion,
    included_CadenaCD, sales_table, segment_table,
    model_segment_table, 'temp_table'
  );

  EXECUTE IMMEDIATE FORMAT("""
    INSERT INTO `%s`
    SELECT
      Fecha,
      CadenaCD,
      ModeloSegmentoid,
      5 AS IndicadorKey,
      Valor,
      CURRENT_TIMESTAMP() AS FechaActualizacion
    FROM temp_table;
  """, final_table);

  DROP TABLE IF EXISTS temp_table;

END;

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPCargaInicialClientesLeales`(
    DATE '2021-01-01',
    DATE '2023-01-01',
    'MONTH',
    [1, 2, 3, 4, 5, 6, 99, 505],
    [10, 20, 30, 40, 50],
    [2],
    ['E', 'C', 'A', 'S'],
    'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
    'co-grupoexito-funnel-mercd-dev.external.segmentacion',
    'co-grupoexito-funnel-mercd-dev.external.dim_modelo_segmento',
    'co-grupoexito-funnel-mercd-dev.refined.fact_target_months'
);

CALL `co-grupoexito-funnel-mercd-dev.procedures.SPIndividualClientesLeales`(
    DATE '2021-12-01',
    'DAY',
    [1, 2, 3, 4, 5, 6, 99, 505],
    [10, 20, 30, 40, 50],
    [2],
    ['E', 'C', 'A', 'S'],
    'co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes',
    'co-grupoexito-funnel-mercd-dev.external.segmentacion',
    'co-grupoexito-funnel-mercd-dev.external.dim_modelo_segmento',
    'co-grupoexito-funnel-mercd-dev.external.segmentacion_backup',
    'co-grupoexito-funnel-mercd-dev.external.dim_modelo_segmento_backup',
    'co-grupoexito-funnel-mercd-dev.refined.fact_target_days'
);
