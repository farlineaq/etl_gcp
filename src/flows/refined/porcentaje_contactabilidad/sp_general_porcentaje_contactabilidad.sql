CREATE OR REPLACE PROCEDURE `{sp_name}`(
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
            Meses AS (
                SELECT DISTINCT DATE_TRUNC(Fecha, MONTH) AS FechaMes
                FROM UNNEST(GENERATE_DATE_ARRAY(?, ?, INTERVAL 1 MONTH)) AS Fecha
            ),
            MesesConDatos AS (
                SELECT DISTINCT DATE_TRUNC(Fecha, MONTH) AS FechaMes
                FROM `%s`
                WHERE Fecha BETWEEN ? AND ?
            ),
            ClientesActivos AS (
                SELECT
                    m.FechaMes,
                    s.CadenaCD,
                    COUNT(DISTINCT s.PartyID) AS TotalActivos
                FROM Meses m
                JOIN MesesConDatos md ON m.FechaMes = md.FechaMes
                JOIN `%s` s ON s.Fecha BETWEEN DATE_ADD(m.FechaMes, INTERVAL -365 DAY) AND m.FechaMes
            WHERE
                s.PartyId IS NOT NULL
                AND s.PartyId != 0
                AND s.SublineaCD NOT IN (SELECT * FROM UNNEST(?))
                AND s.DireccionCD IN (SELECT * FROM UNNEST(?))
                AND s.TipoNegociacion NOT IN (SELECT * FROM UNNEST(?))
                AND s.CadenaCD IN (SELECT * FROM UNNEST(?))
            GROUP BY
                m.FechaMes,
                s.CadenaCD
            ),
            ClientesContactables AS (
                SELECT
                    m.FechaMes,
                    s.CadenaCD,
                    COUNT(DISTINCT s.PartyID) AS TotalContactables
                FROM Meses m
                JOIN MesesConDatos md ON m.FechaMes = md.FechaMes
                JOIN `%s` s ON s.Fecha BETWEEN DATE_ADD(m.FechaMes, INTERVAL -365 DAY) AND m.FechaMes
                JOIN `%s` c ON s.PartyId = c.PartyID
                WHERE (c.indicadorcel = 1 OR c.indicadoremail = 1)
                GROUP BY
                    m.FechaMes,
                    s.CadenaCD
            )
            SELECT
                ca.FechaMes AS Fecha,
                ca.CadenaCD,
                0 AS ModeloSegmentoid,
                ROUND(SUM(cc.TotalContactables) / SUM(ca.TotalActivos) * 100, 2) AS Valor
            FROM ClientesActivos ca
            JOIN ClientesContactables cc ON ca.FechaMes = cc.FechaMes
            GROUP BY
                ca.FechaMes,
                ca.CadenaCD;
    """, temp_table, sales_table, sales_table, sales_table, contact_table);

    EXECUTE IMMEDIATE query
    USING
        start_date,
        end_date,
        start_date,
        end_date,
        excluded_sublineaCD,
        included_direccionCD,
        excluded_tipoNegociacion,
        included_CadenaCD;
END;