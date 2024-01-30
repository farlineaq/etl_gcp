CREATE OR REPLACE PROCEDURE `{sp_name}`(
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
                SUM(vc.VentaSinImpuesto) AS Ventas,
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
                ROUND((Ventas / SUM(Ventas) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajeClientesLeales,
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
    """, temp_table, sales_table, segment_table, model_segment_table,
         formatted_date_expr, sales_table, formatted_date_expr);

    EXECUTE IMMEDIATE query
    USING
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        formatted_date_expr;
END;