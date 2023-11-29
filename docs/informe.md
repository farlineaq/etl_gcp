# Informe de Indicadores Clave de Desempeño (KPIs)

## Introducción 

Este documento ha sido elaborado con el objetivo de ofrecer una comprensión integral de los Indicadores Clave de
Desempeño (KPIs) asociados a nuestro proyecto. Esta recopilación de KPIs busca servir como una herramienta esencial
para una visión panorámica y detallada del proyecto.

> **Nota:** Las consultas de SQL presentadas son preliminares.

## Tabla de Contenido

1. [Ventas Totales sin IVA MM](#ventas-totales-sin-iva-mm)
2. [Transacciones Monitoreadas MM](#transacciones-monitoreadas-mm)
3. [% de las Ventas de los Clientes Leales](#-de-las-ventas-de-los-clientes-leales)
4. [Clientes Monitoreados MM](#clientes-monitoreados-mm)
5. [Tasa de Retención](#tasa-de-retención)
6. [Clientes Leales](#clientes-leales)
7. [SOV (Share Of Voice)](#sov-share-of-voice)
8. [SOI (Share Of Investment)](#soi-share-of-investment)
9. [TOM (Top of Mind)](#tom-top-of-mind)
10. [Porcentaje de Contactabilidad](#-contactabilidad)
11. [BPD (Brand Purchase Decision)](#bpd-brand-purchase-decision)
12. [Engagement Rate en Redes Sociales (Social Media)](#engagement-rate-en-redes-sociales-social-media)
13. [CLV (Customer Life Time Value)](#clv-customer-life-time-value)
14. [Market Share (Nielsen)](#market-share-nielsen)
15. [INS (Índice de Satisfacción)](#ins-índice-de-satisfacción)
16. [Valor de la Marca (BEA)](#valor-de-la-marca-bea)
17. [TOH (Top of Heart)](#toh-top-of-heart)
18. [NPS (Net Promoter Score)](#nps-net-promoter-score)
19. [INS Omnicanal](#ins-omnicanal)

## Ventas Totales sin IVA MM

### Descripción

Este indicador calcula las ventas totales sin IVA, expresadas en miles de millones (MM), por cadena de tiendas a lo
largo del año actual hasta la fecha. El indicador se actualiza diariamente y proporciona una visión acumulativa de las
ventas, reiniciándose al comienzo de cada nuevo año fiscal.

### Observaciones

- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M' para el cálculo de este indicador.
- La consulta se adaptará para reflejar un rango de fechas dinámico una vez que se implemente en el entorno de
  producción. Actualmente, se usa un rango de fechas fijo para propósitos de prueba.

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
excluye transacciones sin identificación del cliente y se reinicia cada año, proporcionando un análisis acumulativo
desde el comienzo del año en curso hasta la fecha actual.

### Observaciones

- Se calcula diario. Para el cálculo acumulado del mes y año solo se deben sumar los días correspondientes al rango.
- La consulta se actualizará para reflejar un rango dinámico de fechas cuando se implemente completamente.
  Actualmente, se utiliza un rango fijo para fines de prueba.
- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. Estos últimos también se descartan.
- Tablas fuente: VentaLineaConClientes.

### Consulta

```sql
WITH VentasClientes AS (
    SELECT 
        PartyId,
        Fecha
    FROM `indicadores.ventaLineaConClientes`
    WHERE 
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

- Se calculan los acumulados mes a mes y el año.
- Para el acumulado anual se hace el cálculo del año corrido comparado con el año anterior. Es decir, si hoy es 22 de
  noviembre de 2023, se compara desde el 1 de enero de 2023 hasta el 22 de nov de 2023 con todo el año 2022.
- El acumulado mensual consiste comparar el mes corrido con el mes anterior.
- Las consultas proporcionadas utilizan rangos de fechas fijos para las pruebas preliminares, pero se ajustarán
  para calcular dinámicamente el rango actual a medida que el KPI se implemente completamente.
- Tablas fuente: VentaLineaConClientes.

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

- Dada la naturaleza del indicador, se calculan los acumulados diarios, mensuales y anuales por separado.
- Solo se tienen en cuenta las transacciones válidas.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M'.
- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. En ambos casos se descarta la transacción.
- Las consultas proporcionadas utilizan un rango de fechas fijo para pruebas preliminares, pero se ajustarán
  para calcular dinámicamente desde el inicio del año hasta la fecha actual en la implementación final.
- Tablas fuente: VentaLineaConClientes.

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

Este KPI identifica a los clientes leales a través de su actividad de compra en la cadena. Se centra en los clientes de
los deciles superiores (8, 9, 10) y mide su actividad de compra durante diferentes periodos. Los clientes leales se
definen como aquellos que han realizado compras en más de un mes durante el último año, lo que indica un alto grado de
fidelidad y compromiso con la marca.

### Observaciones

- El cálculo solo se hace para la cadena 'E'.
- Solo se tiene en cuenta el modelo 26 de segmentación.
- Solo se tienen en cuenta las transacciones vivas y los PartyId válidos.
- Se hace el cálculos de los acumulados diarios, mensuales y anuales dada la naturaleza del indicador.
- Las consultas proporcionadas utilizan un rango de fechas fijo para pruebas preliminares, pero se ajustarán
  para calcular dinámicamente el rango actual a medida que el KPI se implemente completamente.
- Tablas fuente: VentaLineaConClientes, Segmentacion, ModeloSegmento.

### Consulta SQL para el KPI Diario

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
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('E')
        GROUP BY 
            vc.PartyId
        HAVING 
            COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
    ),
    ClientesLeales AS (
        SELECT 
            ct.PartyId
        FROM 
            ClientesTop ct
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE 
            ms.Modelid = 26
            AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
    ),
    TransaccionesClientesLeales AS (
        SELECT 
            vc.PartyId,
            vc.Fecha
        FROM 
            `indicadores.ventaLineaConClientes` vc
            JOIN ClientesLeales cl ON vc.PartyId = cl.PartyId
    )

SELECT 
    Fecha,
    COUNT(DISTINCT PartyId) AS NumeroClientesLeales
FROM 
    TransaccionesClientesLeales
GROUP BY 
    Fecha;
```

### Consulta SQL para el KPI Mensual

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
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('E')
        GROUP BY 
            vc.PartyId
        HAVING 
            COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
    ),
    ClientesLeales AS (
        SELECT 
            ct.PartyId
        FROM 
            ClientesTop ct
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE 
            ms.Modelid = 26
            AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
    ),
    TransaccionesClientesLeales AS (
        SELECT 
            vc.PartyId,
            vc.Fecha
        FROM 
            `indicadores.ventaLineaConClientes` vc
            JOIN ClientesLeales cl ON vc.PartyId = cl.PartyId
    )

SELECT 
    FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(Fecha, MONTH)) AS FechaMes,
    COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM 
    TransaccionesClientesLeales
GROUP BY 
    FechaMes;
```

### Consulta SQL para el KPI Anual

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
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND CadenaCD IN ('E')
        GROUP BY 
            vc.PartyId
        HAVING 
            COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
    ),
    ClientesLeales AS (
        SELECT 
            ct.PartyId
        FROM 
            ClientesTop ct
            JOIN `indicadores.Segmentacion` s ON ct.PartyId = s.PartyID
            JOIN `indicadores.ModeloSegmento` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE 
            ms.Modelid = 26
            AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
    ),
    TransaccionesClientesLeales AS (
        SELECT 
            vc.PartyId,
            vc.Fecha
        FROM 
            `indicadores.ventaLineaConClientes` vc
            JOIN ClientesLeales cl ON vc.PartyId = cl.PartyId
    )

SELECT 
    FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(Fecha, YEAR)) AS AnoId,
    COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM TransaccionesClientesLeales
GROUP BY 
    AnoId;
```

## % de las Ventas de los Clientes Leales

### Descripción

Este KPI calcula el porcentaje de ventas totales atribuibles a clientes leales en la cadena Éxito. Los clientes leales
se definen como aquellos en los deciles superiores (8, 9, 10) y que han realizado compras en más de un mes durante el
año. Este indicador es crucial para entender el impacto de los clientes más valiosos en las ventas totales.

### Observaciones

- Cálculo del indicador solo para la cadena 'E'.
- Solo se calcula el diario. Los acumulados del mes y del año se pueden calcular sumando los diarios en el rango
  específico.
- Se cálcula el año corrido y se reinicia cada año.
- Tal como el indicador anterior, solo se tiene en cuenta el modelo de segmentación 26 y los deciles 8, 9 y 10.
- Esta consulta calcula el porcentaje de ventas diarias a clientes leales. Las consultas para el cálculo mensual
  y anual aún están pendientes de desarrollo y se ajustarán para reflejar dinámicamente el rango actual de fechas.
- Tablas fuente: VentaLineaConClientes, Segmentacion, ModeloSegmento.

### Consulta SQL para el KPI Diario

```sql
WITH
    -- Clientes top
    ClientesTop AS (
        SELECT 
            vc.PartyId
        FROM `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes` vc
        WHERE 
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY 
            vc.PartyId
        HAVING 
            COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
    ),

    -- Clientes leales
    ClientesLeales AS (
        SELECT 
            ct.PartyId
        FROM ClientesTop ct
        JOIN `indicadores.Segmentacion` s 
            ON ct.PartyId = s.PartyID
        JOIN `indicadores.ModeloSegmento` ms 
            ON s.ModeloSegmentoid = ms.ModeloSegmentoid
        WHERE 
            ms.Modelid = 26
            AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
    ),

    -- Ventas totales
    VentasTotales AS (
        SELECT 
            Fecha,
            SUM(VentaSinImpuesto) AS VentaTotal
        FROM `indicadores.ventaLineaConClientes`
        WHERE 
            PartyId IS NOT NULL
            AND PartyId != 0
            AND DATE(Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2)
            AND CadenaCD = 'E'
        GROUP BY 
            Fecha
    ),

    -- Ventas totales clientes leales
    VentasTotalesClientesLeales AS (
        SELECT 
            vc.Fecha,
            SUM(vc.VentaSinImpuesto) AS VentaTotal
        FROM `indicadores.ventaLineaConClientes` vc
        JOIN ClientesLeales cl 
            ON vc.PartyId = cl.PartyId
        WHERE 
            vc.PartyId IS NOT NULL
            AND vc.PartyId != 0
            AND DATE(vc.Fecha) BETWEEN DATE '2021-01-01' AND DATE '2022-01-01'
            AND vc.SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505)
            AND vc.DireccionCD IN (10, 20, 30, 40, 50)
            AND vc.TipoNegociacion NOT IN (2)
            AND vc.CadenaCD = 'E'
        GROUP BY 
            vc.Fecha
    )

-- % ventas clientes leales
SELECT 
    vt.Fecha,
    ROUND(vtcl.VentaTotal / vt.VentaTotal * 100, 2) AS PorcentajeVentaLeales
FROM VentasTotales vt
JOIN VentasTotalesClientesLeales vtcl 
    ON vt.Fecha = vtcl.Fecha


```

## % Contactabilidad

### Descripción

Mide la eficacia con la que la empresa puede comunicarse con sus clientes, basándose en la proporción de clientes
activos que tienen al menos un canal de comunicación registrado (email o celular) frente al total de clientes activos.

### Observaciones

- Integración manual.
- Al tratar con datos sensibles, desde la integración se ocultan los datos sensibles email y teléfono, si cuenta con
  email se reemplaza el dato por 1, si no, con 0. De la misma manera con el teléfono.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S', 'M'.
- Agrupación diaria, mensual y anual.
- Se calcula el año inmediatamente anterior (365 días).

### Consulta SQL para el KPI Diario

```sql
WITH 
    ClientesActivos AS (
        SELECT 
            DISTINCT PartyId,
            Fecha
        FROM `indicadores.ventaLineaConClientes`
        WHERE 
          Fecha BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY) AND CURRENT_DATE
          AND PartyId IS NOT NULL 
          AND PartyId != 0 
          AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505) 
          AND DireccionCD IN (10, 20, 30, 40, 50)
          AND TipoNegociacion NOT IN (2) 
          AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
    ),
    ClientesActivosContactables AS (
        SELECT 
            ca.Fecha,
            ca.PartyID
        FROM ClientesActivos ca
        JOIN `indicadores.Contactabilidad` c ON ca.PartyId = c.PartyID
        WHERE
            indicadorcel = 1 OR indicadoremail = 1
    )

SELECT 
    cac.Fecha, 
    ROUND(COUNT(cac.PartyId) / (
        SELECT COUNT(PartyID) 
        FROM ClientesActivos ca 
        WHERE ca.Fecha = cac.Fecha
    ) * 100, 2) AS PorcentajeContactabilidad
FROM ClientesActivosContactables cac
GROUP BY
    cac.Fecha;
```

### Consulta SQL para el KPI Mensual

```sql
WITH 
    ClientesActivos AS (
        SELECT 
            DISTINCT PartyId,
            Fecha
        FROM `indicadores.ventaLineaConClientes`
        WHERE 
            Fecha BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY) AND CURRENT_DATE
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
            indicadorcel = 1 OR indicadoremail = 1
    )

SELECT
    cac.FechaMes,
    ROUND(COUNT(cac.PartyId) / (
        SELECT COUNT(PartyID) 
        FROM ClientesActivos ca 
        WHERE 
            CAST(FORMAT_TIMESTAMP('%Y-%m-01', TIMESTAMP_TRUNC(ca.Fecha, MONTH)) AS DATE) = CAST(cac.FechaMes AS DATE)
    ) * 100, 2) AS PorcentajeContactabilidad
FROM ClientesActivosContactables cac
GROUP BY
    cac.FechaMes;
```

### Consulta SQL para el KPI Anual

```sql
WITH 
    ClientesActivos AS (
        SELECT 
            DISTINCT PartyId,
            Fecha
        FROM `indicadores.ventaLineaConClientes`
        WHERE 
            Fecha BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY) AND CURRENT_DATE
            AND PartyId IS NOT NULL 
            AND PartyId != 0 
            AND SublineaCD NOT IN (1, 2, 3, 4, 5, 6, 99, 505) 
            AND DireccionCD IN (10, 20, 30, 40, 50)
            AND TipoNegociacion NOT IN (2) 
            AND CadenaCD IN ('E', 'C', 'A', 'S', 'M')
    ),
    ClientesActivosContactables AS (
        SELECT 
            FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(ca.Fecha, YEAR)) AS AnoId,
            ca.PartyID
        FROM ClientesActivos ca
        JOIN `indicadores.Contactabilidad` c ON ca.PartyId = c.PartyID
        WHERE
            indicadorcel = 1 OR indicadoremail = 1
    )
SELECT
    cac.AnoId,
    ROUND(COUNT(cac.PartyId) / (
        SELECT COUNT(PartyID) 
        FROM ClientesActivos ca 
        WHERE 
            CAST(FORMAT_TIMESTAMP('%Y-01-01', TIMESTAMP_TRUNC(ca.Fecha, YEAR)) AS DATE) = CAST(cac.AnoId AS DATE)
    ) * 100, 2) AS PorcentajeContactabilidad
FROM ClientesActivosContactables cac
GROUP BY
    cac.AnoId;
```

## SOV (Share Of Voice)

### Descripción

Mide la presencia y el impacto de la publicidad de la marca en comparación con el total del sector, reflejando su
presencia en el mercado publicitario. Este indicador es crucial para entender cómo se posiciona la marca en términos de
visibilidad frente a sus competidores.

### Observaciones

- La información proviene de IBOPE.
- Se actualiza mensualmente, sin acumulación anual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.
- Actualización mensual y probablemente diaria.

## SOI (Share Of Investment)

### Descripción

Similar al SOV, el SOI evalúa la participación de la marca en el total de inversiones publicitarias del sector. Este
indicador es fundamental para entender cómo la marca distribuye sus recursos publicitarios en comparación con el total
del mercado.

### Observaciones

- La información proviene de IBOPE.
- Se actualiza mensualmente, sin acumulación anual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.
- Actualización mensual y probablemente diaria.
- Integración manual.

## TOM (Top of Mind)

### Descripción

Indica el porcentaje de consumidores que identifican a la marca como su primera opción al pensar en el sector retail.
Este indicador es un termómetro clave de la notoriedad y el posicionamiento de la marca en la mente de los consumidores.

### Observaciones

- El indicador proviene de INVAMER.
- Integración manual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Acumulado mensual, el anual es un promedio de los meses corridos del año.

## BPD (Brand Purchase Decision)

### Descripción

Este indicador sintetiza las diferentes maneras en que los clientes interactúan con la marca, incluyendo compras
recientes, compras planificadas, frecuencia de compra y preferencia de marca. Es un barómetro valioso de la lealtad y la
preferencia del cliente hacia la marca.

### Observaciones

- El indicador proviene de INVAMER.
- Integración manual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Acumulado mensual, el anual es un promedio de los meses corridos del año.

## Valor de la Marca (BEA)

### Descripción

El Brand Equity Audit es un indicador comprensivo que mide la fuerza de la marca a través de varios factores, incluyendo
el conocimiento de la marca, el uso, el posicionamiento y la conexión emocional con los consumidores.

### Observaciones

- El indicador proviene de INVAMER.
- Integración manual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Acumulado mensual, el anual es un promedio de los meses corridos del año.

## TOH (Top of Heart)

### Descripción

Este indicador evalúa la conexión emocional y la afinidad que los consumidores sienten hacia la marca, siendo un reflejo
importante de la lealtad y el compromiso del cliente con la marca.

### Observaciones

- El indicador proviene de INVAMER.
- Integración manual.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Acumulado mensual, el anual es un promedio de los meses corridos del año.

## Engagement Rate en Redes Sociales (Social Media)

### Descripción

Calcula el promedio de interacciones (como me gusta, comentarios, compartidos) en relación con el alcance total en las
redes sociales, proporcionando una medida de qué tan efectivamente la marca involucra a su audiencia en estos canales.

### Observaciones

- Solo va el Engagement Rate (Impresiones totales) de cada mes, sin considerar un acumulado.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.
- Integración manual.

## CLV (Customer Life Time Value)

### Descripción

Representa el valor total que se espera obtener de un cliente a lo largo de su relación con la empresa. Este indicador
ayuda a entender el valor a largo plazo de mantener relaciones positivas con los clientes.

### Observaciones

- Se centra en el % Future CLV.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.
- Se actualiza mensualmente sin un acumulado anual.
- Integración manual.

## Market Share (Nielsen)

### Descripción

Este indicador refleja la cuota de mercado de la marca dentro del sector retail, proporcionando una medida clara de su
posición y éxito en comparación con sus competidores. Es un indicador clave para entender la dinámica del mercado y la
posición de la marca dentro de este.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Se actualiza mensualmente reflejando el comportamiento del mercado del mes anterior. El acumulado anual es el
  promedio de los meses corridos.
- Los datos provienen de Nielsen.
- Integración manual.

## INS (Índice de Satisfacción)

### Descripción

Mide el nivel de satisfacción general de los clientes con la marca, con el objetivo de superar un umbral del 70%. Este
indicador es vital para entender la percepción y la aceptación de la marca entre los consumidores.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Qualtrics.
- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- No se tiene en cuenta INS Canales, solo INS.
- Integración manual.
- La comparación interanual se realiza mes a mes.

## NPS (Net Promoter Score)

### Descripción

Mide la disposición de los clientes a recomendar la marca a otros, siendo un indicador clave del nivel de satisfacción y
lealtad del cliente. Un NPS alto indica una base de clientes leales y satisfechos.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Los datos provienen de Qualtrics.
- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- No se tiene en cuenta NPS Canales, solo NPS.
- Integración manual.
- La comparación interanual se realiza mes a mes.

## INS Omnicanal

### Descripción

Representa el índice neto de satisfacción de toda la compañía, abarcando todos los canales y puntos de contacto con los
clientes. Este indicador global proporciona una visión integral de la experiencia del cliente en todos los frentes.

### Observaciones

- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.
- Se actualiza mensualmente, reflejando el comportamiento acumulado del año.
- Integración manual.
- Los datos provienen de Qualtrics.
- La comparación interanual se realiza mes a mes.
