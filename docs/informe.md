# Informe de Indicadores Clave de Desempeño (KPIs)

## Introducción

Este documento ha sido elaborado con el objetivo de ofrecer una comprensión integral de los Indicadores Clave de
Desempeño (KPIs) asociados a nuestro proyecto. Esta recopilación de KPIs busca servir como una herramienta esencial
para una visión panorámica y detallada del proyecto.

> **Nota:** Las consultas de SQL presentadas son preliminares.

## Tabla de Contenido

1. [Ventas Totales sin IVA MM](#ventas-totales-sin-iva-mm)
2. [Transacciones Monitoreadas MM](#transacciones-monitoreadas-mm)
3. [Clientes Monitoreados MM](#clientes-monitoreados-mm)
4. [Tasa de Retención](#tasa-de-retención)
5. [Clientes Leales](#clientes-leales)
6. [Porcentaje de las Ventas de los Clientes Leales](#porcentaje-de-las-ventas-de-los-clientes-leales)
7. [Porcentaje de Contactabilidad](#porcentaje-de-contactabilidad)
8. [SOV (Share Of Voice)](#sov-(share-of-voice))
9. [SOI (Share Of Investment)](#soi-(share-of-investment))
10. [TOM (Top of Mind)](#tom-(top-of-mind))
11. [BPD (Brand Purchase Decision)](#bpd-(brand-purchase-decision))
12. [Engagement Rate en Redes Sociales (Social Media)](#engagement-rate-en-redes-sociales-(social-media))
13. [CLV (Customer Life Time Value)](#clv-(customer-life-time-value))
14. [Market Share (Nielsen)](#market-share-(nielsen))
15. [INS (Índice de Satisfacción)](#ins-(índice-de-satisfacción))
16. [Valor de la Marca (BEA)](#valor-de-la-marca-(bea))
17. [TOH (Top of Heart)](#toh-(top-of-heart))
18. [NPS (Net Promoter Score)](#nps-(net-promoter-score))
19. [INS Omnicanal](#ins-omnicanal)

## Ventas Totales sin IVA MM

### Descripción

Este indicador calcula las ventas totales sin IVA, expresadas en miles de millones (MM), por cadena de tiendas a lo
largo del año actual hasta la fecha.

### Observaciones

- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M' para el cálculo de este indicador.
- La consulta se adaptará para reflejar un rango de fechas dinámico una vez que se implemente en el entorno de
  producción. Actualmente, se usa un rango de fechas fijo para propósitos de prueba.
- Solo se tienen en cuenta las transacciones válidas.

### Temporalidad

- El indicador se actualiza diariamente y proporciona una visión acumulativa de las ventas, reiniciándose al comienzo
  de cada nuevo año fiscal.

### Entidades implicadas

- ventaLineaConClientes

### Consulta

```sql
WITH VentasClientes AS (
    SELECT 
        CadenaCD,
        VentaSinImpuesto,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        Fecha >= DATE_FORMAT(CURRENT_DATE, '%Y-01-01')
        AND Fecha <= CURRENT_DATE
        -- Consulta financiera
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
)

SELECT 
    Fecha,
    CadenaCD,
    ROUND(SUM(VentaSinImpuesto) / 1000000000, 2) AS VentaTotalEnMilesDeMillones
FROM VentasClientes
GROUP BY Fecha, CadenaCD;
```

## Transacciones Monitoreadas MM

### Descripción

Este KPI mide el número de transacciones realizadas donde los clientes han registrado su documento al momento de la
compra, lo que nos permite monitorear la actividad de compra y la lealtad del cliente a lo largo del año. Este indicador
excluye transacciones sin identificación del cliente.

### Observaciones

- La consulta se actualizará para reflejar un rango dinámico de fechas cuando se implemente completamente.
  Actualmente, se utiliza un rango fijo para fines de prueba.
- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. Estos últimos también se descartan.

### Temporalidad

- Se calcula diario. Para el cálculo acumulado del mes y año solo se deben sumar los días correspondientes al rango.
- se reinicia cada año, proporcionando un análisis acumulativo desde el comienzo del año en curso hasta la fecha actual.

### Entidades implicadas

- VentaLineaConClientes

### Consulta

```sql
WITH VentasClientes AS (
    SELECT 
        PartyId,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        -- Hay PartyId de 2 dígitos y es normal
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha >= DATE_FORMAT(CURRENT_DATE, '%Y-01-01')
        AND Fecha <= CURRENT_DATE
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
)

SELECT 
    Fecha,
    COUNT(PartyId) AS NumeroTransacciones
FROM VentasClientes
GROUP BY Fecha;

```

## Tasa de Retención

### Descripción

La Tasa de Retención es un indicador clave del compromiso y la lealtad de los clientes año tras año. Este KPI analiza
el porcentaje de clientes del año anterior que continúan realizando compras en el año en curso. Se calcula de forma
acumulativa y se reinicia con cada nuevo año. Además, proporciona un desglose mes a mes para un seguimiento más
detallado y permite una comparación directa de la retención entre periodos específicos.

### Observaciones

- El acumulado mensual consiste comparar el mes corrido con el mes anterior.
- Las consultas proporcionadas utilizan rangos de fechas fijos para las pruebas preliminares, pero se ajustarán
  para calcular dinámicamente el rango actual a medida que el KPI se implemente completamente.

### Temporalidad

- Se calculan los acumulados mes a mes y el año. No es necesario calcular el indicador diariamente.
- Se reinicia cada año, proporcionando un análisis acumulativo desde el comienzo del año en curso hasta la fecha actual.

### Entidades implicadas

- VentaLineaConClientes

### Consulta SQL para el KPI Anual

```sql
WITH ClientesAnoAnterior AS (
    SELECT DISTINCT PartyId
    FROM `indicadores.ventaLineaConClientes`
    WHERE
        EXTRACT(YEAR FROM Fecha) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
        AND PartyId IS NOT NULL
        AND PartyId != 0
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
),

ClientesAnoActual AS (
    SELECT DISTINCT PartyId
    FROM `indicadores.ventaLineaConClientes`
    WHERE
        EXTRACT(YEAR FROM Fecha) = EXTRACT(YEAR FROM CURRENT_DATE)
        AND PartyId IS NOT NULL
        AND PartyId != 0
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
),

ClientesRetenidos AS (
    SELECT a.PartyId
    FROM ClientesAnoAnterior a
    JOIN ClientesAnoActual b ON a.PartyId = b.PartyId
)

SELECT 
    FORMAT_DATE('%Y-01-01', CURRENT_DATE()) AS PrimerDiaAno,
    (COUNT(DISTINCT a.PartyId) / (
        SELECT COUNT(DISTINCT PartyId) 
        FROM ClientesAnoAnterior
    )) * 100 AS PorcentajeRetencion
FROM ClientesRetenidos a;
```

### Consulta SQL para el KPI Mensual

```sql
WITH ClientesMesAnterior AS (
    SELECT 
        DISTINCT PartyId,
        DATE_TRUNC(Fecha, MONTH) AS PrimerDiaMes
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha BETWEEN DATE '2022-01-01' AND DATE '2022-12-01'
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
),
ClientesMesActual AS (
    SELECT 
        DISTINCT PartyId,
        DATE_TRUNC(Fecha, MONTH) AS PrimerDiaMes
    FROM `indicadores.ventaLineaConClientes`
    WHERE PartyId IS NOT NULL
      AND PartyId != 0
      AND Fecha BETWEEN DATE '2022-01-01' AND DATE '2022-12-01'
      AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
      AND DireccionCD IN (10, 20, 30, 40, 50)
      AND TipoNegociacion NOT IN (2)
      AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
),
ClientesRetenidos AS (
    SELECT 
        a.PartyId,
        b.PrimerDiaMes AS PrimerDiaMesActual
    FROM ClientesMesAnterior a
    JOIN ClientesMesActual b 
        ON a.PartyId = b.PartyId
        AND a.PrimerDiaMes = DATE_SUB(b.PrimerDiaMes, INTERVAL 1 MONTH)
)

SELECT cr.PrimerDiaMesActual AS PrimerDiaMes,
       COUNT(DISTINCT cr.PartyId) / (
           SELECT COUNT(DISTINCT cma.PartyId)
           FROM ClientesMesAnterior cma
           WHERE cma.PrimerDiaMes = DATE_SUB(cr.PrimerDiaMesActual, INTERVAL 1 MONTH)
       ) * 100 AS PorcentajeRetencion
FROM ClientesRetenidos cr
GROUP BY cr.PrimerDiaMesActual;
```

## Clientes Monitoreados MM

### Descripción

Este KPI mide la cantidad de clientes únicos que han realizado transacciones en distintos periodos: diariamente,
mensualmente y anualmente. Se centra en las transacciones donde el cliente ha proporcionado su identificación,
excluyendo las anónimas. Este indicador es vital para entender la participación del cliente y la eficacia de las
estrategias de retención y se actualiza diariamente.

### Observaciones

- Solo se tienen en cuenta las transacciones válidas.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M'.
- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. En ambos casos se descarta la transacción.
- Las consultas proporcionadas utilizan un rango de fechas fijo para pruebas preliminares, pero se ajustarán
  para calcular dinámicamente desde el inicio del año hasta la fecha actual en la implementación final.

### Temporalidad

- Dada la naturaleza del indicador, se calculan los acumulados diarios, mensuales y anuales por separado para evitar
  contar clientes duplicados.

### Entidades implicadas

- VentaLineaConClientes

### Consulta SQL para el KPI Diario

```sql
WITH TransaccionesVivas AS (
    SELECT 
        PartyId,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha BETWEEN DATE '2022-01-01' AND DATE '2022-12-01'
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
)

SELECT 
    Fecha,
    COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM 
    TransaccionesVivas
GROUP BY 
    Fecha;
```

### Consulta SQL para el KPI Mensual

```sql
WITH TransaccionesVivas AS (
    SELECT 
        PartyId,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha BETWEEN DATE '2022-01-01' AND DATE '2022-12-01'
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
)

SELECT 
    FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(Fecha, MONTH)) AS FechaMes,
    COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM 
    TransaccionesVivas
GROUP BY 
    FechaMes;
```

### Consulta SQL para el KPI Anual

```sql
WITH TransaccionesVivas AS (
    SELECT 
        PartyId,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha BETWEEN DATE '2022-01-01' AND DATE '2022-12-01'
        AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
        AND DireccionCD IN (10, 20, 30, 40, 50)
        AND TipoNegociacion NOT IN (2)
        AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
)

SELECT 
    FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
    COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM 
    TransaccionesVivas
GROUP BY 
    AnoId;
```

## Clientes Leales

### Descripción

Este KPI identifica a los clientes leales a través de su actividad de compra en la cadena en el caso de la cadena Éxito,
e identifica la segmentación de los clientes en caso de Carulla, Surtimax y Superinter.

### Observaciones

- Para la cadena 'E' Los clientes leales se definen como aquellos en los deciles superiores (8, 9, 10)  del modelo de
  segmentación 26 y que han realizado compras en más de un mes durante el año.
- Para las cadenas 'C', 'A' y 'S' se calcula el porcentaje de clientes totales atribuibles a cada segmento en función
  del total de clientes.
- Para la cadena 'C' se tiene el modelo de segmentación 3 con los segmentos BLACK, VERDE Y DIAMANTE.
- Para la cadena 'A' se tiene el modelo de segmentación 24 con los segmentos AAA Y AA.
- Para la cadena 'S' se tiene el modelo de segmentación 25 con los segmentos AAA y AA.
- Solo se tienen en cuenta las transacciones vivas y los PartyId válidos.
- Las consultas proporcionadas utilizan un rango de fechas fijo para pruebas preliminares, pero se ajustarán
  para calcular dinámicamente el rango actual a medida que el KPI se implemente completamente.

### Temporalidad

- Dada la naturaleza del indicador, se calculan los acumulados diarios, mensuales y anuales por separado para evitar
  contar clientes duplicados.

### Entidades implicadas

- VentaLineaConClientes
- Segmentacion
- ModeloSegmento

### Cadena

#### Éxito

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            vc.Fecha,
            COUNT(DISTINCT vc.PartyId) AS ConteoClientes,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            vc.Fecha,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            Fecha,
            ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    Fecha,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal';
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(Fecha, MONTH)) AS FechaMes,
            COUNT(DISTINCT vc.PartyId) AS ConteoClientes,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            FechaMes,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            FechaMes,
            ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY FechaMes)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    FechaMes,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal';

```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
            COUNT(DISTINCT vc.PartyId) AS ConteoClientes,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            AnoId,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            AnoId,
            ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY AnoId)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    AnoId,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal';
```

#### Carulla

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),
    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )
SELECT
    Fecha,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )
SELECT
    FechaMes,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY FechaMes)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )
SELECT
    AnoId,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY AnoId)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

#### Surtimax

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),
    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )
SELECT
    Fecha,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
  
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )
SELECT
    FechaMes,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY FechaMes)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;

```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )
SELECT
    AnoId,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY AnoId)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;

```

#### Superinter

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),
    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )
SELECT
    Fecha,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )
SELECT
    FechaMes,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY FechaMes)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            vc.Fecha,
            vc.PartyId
        FROM
            `indicadores.ventaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),
    SegmentosClientes AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
            COUNT(DISTINCT cv.PartyId) AS ConteoClientes,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )
SELECT
    AnoId,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY AnoId)) * 100, 2) AS PorcentajePorSegmento,
    ModelSegmentoDesc
FROM
    SegmentosClientes;
```

## Porcentaje de las Ventas de los Clientes Leales

### Descripción

Este KPI calcula el porcentaje de ventas totales atribuibles a clientes leales en el caso de la cadena Éxito, y a ventas
por segmento en el caso de Carulla, Surtimax y Superinter.


### Observaciones

- Para la cadena 'E' Los clientes leales se definen como aquellos en los deciles superiores (8, 9, 10)  del modelo de
  segmentación 26 y que han realizado compras en más de un mes durante el año.
- Para las cadenas 'C', 'A' y 'S' se calcula el porcentaje de ventas totales atribuibles a cada segmento en función del
  total de ventas.
- Para la cadena 'C' se tiene el modelo de segmentación 3 con los segmentos BLACK, VERDE Y DIAMANTE.
- Para la cadena 'A' se tiene el modelo de segmentación 24 con los segmentos AAA Y AA.
- Para la cadena 'S' se tiene el modelo de segmentación 25 con los segmentos AAA y AA.
- Solo se tienen en cuenta las transacciones vivas y los PartyId válidos.
- Las consultas proporcionadas utilizan un rango de fechas fijo para pruebas preliminares, pero se ajustarán
  para calcular dinámicamente el rango actual a medida que el KPI se implemente completamente.

### Temporalidad

- Esta consulta calcula el porcentaje de ventas diarias, mensuales y anuales.
- Se reinicia cada año.


### Entidades implicadas

- VentaLineaConClientes
- Segmentacion
- ModeloSegmento

### Cadena

#### Éxito

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            vc.Fecha,
            SUM(vc.VentaSinImpuesto) AS Ventas,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            vc.Fecha,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            Fecha,
            ROUND((Ventas / SUM(Ventas) OVER(PARTITION BY Fecha)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    Fecha,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal'
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(vc.Fecha, MONTH)) AS FechaMes,
            SUM(vc.VentaSinImpuesto) AS Ventas,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            FechaMes,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            FechaMes,
            ROUND((Ventas / SUM(Ventas) OVER(PARTITION BY FechaMes)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    FechaMes,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal';
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesTop AS (
        SELECT
            vc.PartyId
        FROM
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
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
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 26
    ),
    TransanccionesTotales AS (
        SELECT
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(vc.Fecha, YEAR)) AS AnoId,
            SUM(vc.VentaSinImpuesto) AS Ventas,
            cl.Segmento
        FROM 
            `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        JOIN ClientesLeales cl
            ON vc.PartyId = cl.PartyId
        WHERE
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND vc.Fecha BETWEEN DATE '2020-01-01' AND DATE '2023-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY
            AnoId,
            cl.Segmento
    ),
    DistribucionClientes AS (
        SELECT
            AnoId,
            ROUND((Ventas / SUM(Ventas) OVER(PARTITION BY AnoId)) * 100, 2) AS PorcentajeClientesLeales,
            Segmento
        FROM
            TransanccionesTotales
    )
SELECT
    AnoId,
    PorcentajeClientesLeales
FROM
    DistribucionClientes
WHERE
    Segmento = 'ClienteLeal';
```

#### Carulla

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),

    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )

SELECT
    Fecha,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY Fecha)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )

SELECT
    FechaMes,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY FechaMes)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('C')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(cv.Fecha, YEAR)) AS AnoId,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 3
            AND ms.ModelSegmentoDesc IN ('VERDE', 'DIAMANTE', 'BLACK')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )

SELECT
    AnoId,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY AnoId)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

#### Surtimax

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),

    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )

SELECT
    Fecha,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY Fecha)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )

SELECT
    FechaMes,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY FechaMes)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('S')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(cv.Fecha, YEAR)) AS AnoId,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 24
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )

SELECT
    AnoId,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY AnoId)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

#### Superinter

##### Consulta SQL para el KPI Diario

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),

    SegmentosClientes AS (
        SELECT
            cv.Fecha,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            cv.Fecha,
            ms.ModelSegmentoDesc
    )

SELECT
    Fecha,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY Fecha)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Mensual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(cv.Fecha, MONTH)) AS FechaMes,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            FechaMes,
            ms.ModelSegmentoDesc
    )

SELECT
    FechaMes,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY FechaMes)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

##### Consulta SQL para el KPI Anual

```sql
WITH
    ClientesValidos AS (
        SELECT
            Fecha,
            PartyId,
            VentaSinImpuesto
        FROM
            `indicadores.ventaLineaConClientes`
        WHERE
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2023-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('A')
    ),

    SegmentosClientes AS (
        SELECT            
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(cv.Fecha, YEAR)) AS AnoId,
            sum(cv.VentaSinImpuesto) as VentasSegmentadas,
            ms.ModelSegmentoDesc
        FROM
            ClientesValidos cv
            JOIN `indicadores.Segmentacion` s ON cv.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE
            ms.Modelid = 25
            AND ms.ModelSegmentoDesc IN ('AAA', 'AA')
        GROUP BY
            AnoId,
            ms.ModelSegmentoDesc
    )

SELECT
    AnoId,
    ModelSegmentoDesc,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY AnoId)) * 100, 2) AS VentasPorSegmento
    
FROM
    SegmentosClientes;
```

## Porcentaje de Contactabilidad

### Descripción

Mide la eficacia con la que la empresa puede comunicarse con sus clientes, basándose en la proporción de clientes
activos que tienen al menos un canal de comunicación registrado (email o celular) frente al total de clientes activos.

### Observaciones

- Al tratar con datos sensibles, desde la integración se ocultan los datos sensibles email y teléfono, si cuenta con
  email se reemplaza el dato por 1, si no, con 0. De la misma manera con el teléfono.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M'.

### Temporalidad

- Agrupación mensual.
- Los clientes activos son aquellos que compraron al menos una vez en los últimos 365 días.
- El indicador es acumulado al cierre del mes durante el año calendario, es decir, cada cálculo mensual refleja el
  porcentaje de contactabilidad acumulado hasta el mes en curso.

### Entidades implicadas

- Contactabilidad
- ventaLineaConClientes

### Consulta SQL para el KPI mensual

```sql
WITH 
    ClientesActivos AS (
        SELECT 
            DISTINCT PartyId,
            Fecha
        FROM `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
        WHERE 
            -- Fecha BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY) AND CURRENT_DATE
            Fecha BETWEEN DATE_SUB(DATE '2022-03-31', INTERVAL 365 DAY) AND DATE '2022-03-31'
            AND PartyId IS NOT NULL 
            AND PartyId != 0 
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505) 
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2) 
            AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
    ),
    ClientesActivosContactables AS (
        SELECT 
            FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(ca.Fecha, MONTH)) AS FechaMes,
            ca.PartyID
        FROM ClientesActivos ca
        JOIN `indicadores.Contactabilidad` c ON ca.PartyId = c.PartyID
        WHERE
            (indicadorcel = 1 OR indicadoremail = 1)
            -- AND ca.Fecha >= DATE_TRUNC(CURRENT_DATE, YEAR)
            AND ca.Fecha BETWEEN '2021-09-29' AND '2022-03-31'
    ),
    AcumuladoHastaMes AS (
        SELECT
            a.FechaMes,
            COUNT(DISTINCT b.PartyID) AS AcumuladoContactables
        FROM ClientesActivosContactables a
        JOIN ClientesActivosContactables b ON a.FechaMes >= b.FechaMes
        GROUP BY a.FechaMes
    )

SELECT
    ahm.FechaMes,
    ROUND(ahm.AcumuladoContactables / (
        SELECT COUNT(DISTINCT PartyID) 
        FROM ClientesActivos
        WHERE 
          -- Fecha >= DATE_TRUNC(CURRENT_DATE, YEAR)
          Fecha BETWEEN '2021-09-29' AND '2022-03-31'
          AND CAST(FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(Fecha, MONTH)) AS DATE) <= CAST(ahm.FechaMes AS DATE)
    ) * 100, 2) AS PorcentajeContactabilidad
FROM AcumuladoHastaMes ahm;
```

## SOV (Share Of Voice)

### Descripción

Mide la presencia y el impacto de la publicidad de la marca en comparación con el total del sector, reflejando su
presencia en el mercado publicitario. Este indicador es crucial para entender cómo se posiciona la marca en términos de
visibilidad frente a sus competidores.

### Observaciones

- La información proviene de IBOPE.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.

### Temporalidad

- Se actualiza mensualmente, sin acumulación anual.
- Actualización mensual y probablemente diaria. **nota: Hágamos la estructura diaria, pero la montamos mensual**

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## SOI (Share Of Investment)

### Descripción

Similar al SOV, el SOI evalúa la participación de la marca en el total de inversiones publicitarias del sector. Este
indicador es fundamental para entender cómo la marca distribuye sus recursos publicitarios en comparación con el total
del mercado.

### Observaciones

- La información proviene de IBOPE.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.

### Temporalidad

- Se actualiza mensualmente, sin acumulación anual.
- Actualización mensual y probablemente diaria. **nota: Hágamos la estructura diaria, pero la montamos mensual**

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## TOM (Top of Mind)

### Descripción

Indica el porcentaje de consumidores que identifican a la marca como su primera opción al pensar en el sector retail.
Este indicador es un termómetro clave de la notoriedad y el posicionamiento de la marca en la mente de los consumidores.

### Observaciones

- El indicador proviene de INVAMER.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.

### Temporalidad

- Acumulado mensual, el anual es un promedio de los meses corridos del año.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## BPD (Brand Purchase Decision)

### Descripción

Este indicador sintetiza las diferentes maneras en que los clientes interactúan con la marca, incluyendo compras
recientes, compras planificadas, frecuencia de compra y preferencia de marca. Es un barómetro valioso de la lealtad y la
preferencia del cliente hacia la marca.

### Observaciones

- El indicador proviene de INVAMER.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.

### Temporalidad

- Acumulado mensual, el anual es un promedio de los meses corridos del año.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## Valor de la Marca (BEA)

### Descripción

El Brand Equity Audit es un indicador comprensivo que mide la fuerza de la marca a través de varios factores, incluyendo
el conocimiento de la marca, el uso, el posicionamiento y la conexión emocional con los consumidores.

### Observaciones

- El indicador proviene de INVAMER.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.

### Temporalidad

- Acumulado mensual, el anual es un promedio de los meses corridos del año.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## TOH (Top of Heart)

### Descripción

Este indicador evalúa la conexión emocional y la afinidad que los consumidores sienten hacia la marca, siendo un reflejo
importante de la lealtad y el compromiso del cliente con la marca.

### Observaciones

- El indicador proviene de INVAMER.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.

### Temporalidad

- Acumulado mensual, el anual es un promedio de los meses corridos del año.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## Engagement Rate en Redes Sociales (Social Media)

### Descripción

Calcula el promedio de interacciones (como me gusta, comentarios, compartidos) en relación con el alcance total en las
redes sociales, proporcionando una medida de qué tan efectivamente la marca involucra a su audiencia en estos canales.

### Observaciones

- Solo va el Engagement Rate (Impresiones totales).
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.

### Temporalidad

- Cálculo mensual.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## CLV (Customer Life Time Value)

### Descripción

Representa el valor total que se espera obtener de un cliente a lo largo de su relación con la empresa. Este indicador
ayuda a entender el valor a largo plazo de mantener relaciones positivas con los clientes.

### Observaciones

- Se centra en el % Future CLV.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.

### Temporalidad

- Se actualiza mensualmente sin un acumulado anual.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## Market Share (Nielsen)

### Descripción

Este indicador refleja la cuota de mercado de la marca dentro del sector retail, proporcionando una medida clara de su
posición y éxito en comparación con sus competidores. Es un indicador clave para entender la dinámica del mercado y la
posición de la marca dentro de este.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Nielsen.
- Integración manual.

### Temporalidad

- Se actualiza mensualmente reflejando el comportamiento del mercado del mes anterior. El acumulado anual es el
  promedio de los meses corridos.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## INS (Índice de Satisfacción)

### Descripción

Mide el nivel de satisfacción general de los clientes con la marca, con el objetivo de superar un umbral del 70%. Este
indicador es vital para entender la percepción y la aceptación de la marca entre los consumidores.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Qualtrics.
- No se tiene en cuenta INS Canales, solo INS.

### Temporalidad

- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- La comparación interanual se realiza mes a mes.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## NPS (Net Promoter Score)

### Descripción

Mide la disposición de los clientes a recomendar la marca a otros, siendo un indicador clave del nivel de satisfacción y
lealtad del cliente. Un NPS alto indica una base de clientes leales y satisfechos.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Qualtrics.
- No se tiene en cuenta NPS Canales, solo NPS.

### Temporalidad

- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- La comparación interanual se realiza mes a mes.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## INS Omnicanal

### Descripción

Representa el índice neto de satisfacción de toda la compañía, abarcando todos los canales y puntos de contacto con los
clientes. Este indicador global proporciona una visión integral de la experiencia del cliente en todos los frentes.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Qualtrics.

### Temporalidad

- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- La comparación interanual se realiza mes a mes.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.
