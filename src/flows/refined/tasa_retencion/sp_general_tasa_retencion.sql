CREATE OR REPLACE PROCEDURE `{sp_name}`(
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
        """, temp_table, granularity, sales_table, granularity, granularity, granularity,
             granularity, sales_table, granularity, granularity, granularity)
        USING
            initial_date,
            initial_date,
            excluded_sublineaCD,
            included_direccionCD,
            excluded_tipoNegociacion,
            included_CadenaCD,
            initial_date,
            initial_date,
            end_date,
            excluded_sublineaCD,
            included_direccionCD,
            excluded_tipoNegociacion,
            included_CadenaCD;

        SET initial_date = IF(
            granularity = 'MONTH',
            DATE_ADD(DATE_TRUNC(initial_date, MONTH), INTERVAL 1 MONTH),
            DATE_ADD(DATE_TRUNC(initial_date, YEAR), INTERVAL 1 YEAR)
        );
    END WHILE;
END;