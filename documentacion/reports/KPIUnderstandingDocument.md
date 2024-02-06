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
8. [SOV (Share Of Voice)](#sov-atl-(share-of-voice))
9. [SOI (Share Of Investment)](#soi-(share-of-investment))
10. [TOM (Top of Mind)](#tom-(top-of-mind))
11. [BPD (Brand Purchase Decision)](#bpd-(brand-purchase-decision))
12. [Engagement Rate en Redes Sociales (Social Media)](#engagement-rate-en-redes-sociales-(social-media))
13. [CLV (Customer Life Time Value)](#clv-(customer-life-time-value))
14. [Market Share (Nielsen)](#market-share-(nielsen))
15. [INS (Índice de Satisfacción)](#ins-(índice-de-satisfacción))
16. [Valor de la Marca (BEA)](#bea-(valor-de-la-marca))
17. [TOH (Top of Heart)](#toh-(top-of-heart))
18. [NPS (Net Promoter Score)](#nps-(net-promoter-score))
19. [INS Omnicanal](#ins-omnicanal)

## Ventas Totales sin IVA MM

### Descripción

Este indicador calcula las ventas totales sin IVA, expresadas en miles de millones (MM), por cadena de tiendas a lo
largo del año actual hasta la fecha.

### Observaciones

- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S' para el cálculo de este indicador.
- Solo se tienen en cuenta las transacciones válidas.
- Se hace una agrupación por cadena.

### Temporalidad

- El indicador se actualiza diaria, mensual y anualmente y proporciona una visión acumulativa de las ventas,
  reiniciándose al comienzo de cada nuevo año fiscal.

### Entidades implicadas

- ventaLineaConClientes

### Consulta

Esta consulta realiza lo siguiente:

1. **Aplicación de filtros**: Selecciona registros dentro del rango de fechas `@start_date` y `@end_date`, excluyendo e
   incluyendo específicamente ciertas sublíneas, direcciones, tipos de negociación y cadenas, según los arrays
   proporcionados.

2. **Agrupación por granularidad**: Agrupa los datos por día, mes o año, según el parámetro `@granularity`, para
   calcular el total de ventas sin IVA en esos períodos.

3. **Cálculo del indicador**: Calcula el total de ventas sin IVA, dividiendo la suma de `VentaSinImpuesto` por
   1.000.000.000 para obtener el total en miles de millones y redondeando el resultado a dos decimales.

```sql
WITH FiltrosAplicados AS (
  SELECT
    CASE
      WHEN @granularity = 'DAY' THEN Fecha
      WHEN @granularity = 'MONTH' THEN DATE_TRUNC(Fecha, MONTH)
      WHEN @granularity = 'YEAR' THEN DATE(DATE_TRUNC(Fecha, YEAR))
      ELSE Fecha
    END AS FechaAgrupada,
    CadenaCD,
    VentaSinImpuesto
  FROM
    `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
  WHERE
    Fecha BETWEEN @start_date AND @end_date
    AND SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
    AND DireccionCD IN UNNEST(@included_direccionCD)
    AND TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
    AND CadenaCD IN UNNEST(@included_CadenaCD)
)

, CalculoVentas AS (
  SELECT
    FechaAgrupada AS Fecha,
    CadenaCD,
    ROUND(SUM(VentaSinImpuesto) / 1000000000, 2) AS VentaTotalEnMilesDeMillones
  FROM
    FiltrosAplicados
  GROUP BY
    Fecha,
    CadenaCD
)

SELECT
  Fecha,
  CadenaCD,
  VentaTotalEnMilesDeMillones
FROM
  CalculoVentas;
```

## Transacciones Monitoreadas MM

### Descripción

Este KPI mide el número de transacciones realizadas donde los clientes han registrado su documento al momento de la
compra, lo que nos permite monitorear la actividad de compra y la lealtad del cliente a lo largo del año. Este indicador
excluye transacciones sin identificación del cliente.

### Observaciones

- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. Estos últimos también se descartan.
- Se hace una agrupación por cadena.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S' para el cálculo de este indicador.

### Temporalidad

- Se calcula diario. Para el cálculo acumulado del mes y año solo se deben sumar los días correspondientes al rango.
- se reinicia cada año, proporcionando un análisis acumulativo desde el comienzo del año en curso hasta la fecha actual.

### Entidades implicadas

- VentaLineaConClientes

### Consulta

Esta consulta realiza los siguientes pasos para calcular el indicador:

1. **Configuración de la Granularidad**: Dependiendo del valor del parámetro `@granularity`, la fecha se ajusta para
   agrupar los datos por día, mes o año. Esto se realiza mediante una condición `CASE` que modifica la columna `Fecha`
   para reflejar la granularidad deseada (`DAY`, `MONTH`, `YEAR`).

2. **Filtrado de Datos**: Se aplican filtros para excluir e incluir registros según los criterios
   proporcionados (`SublineaCD`, `DireccionCD`, `TipoNegociacion`, `CadenaCD`). También se asegura que el `PartyId` sea
   no nulo y diferente de 0 para considerar solo transacciones válidas.

3. **Agrupación y Conteo**: Los datos filtrados se agrupan por la fecha ajustada (según la granularidad) y `CadenaCD`.
   Se cuenta el número de `PartyId` por grupo, lo que representa el número de transacciones realizadas.

4. **Selección de Resultados**: Finalmente, la consulta selecciona las fechas agrupadas, el código de
   cadena (`CadenaCD`), y el número de transacciones calculado (`NumeroTransacciones`) para cada combinación de fecha y
   cadena.

```sql
WITH ConfiguracionGranularidad AS (
  SELECT
    CASE
      WHEN @granularity = 'DAY' THEN Fecha
      WHEN @granularity = 'MONTH' THEN DATE_TRUNC(Fecha, MONTH)
      WHEN @granularity = 'YEAR' THEN DATE(DATE_TRUNC(Fecha, YEAR))
      ELSE Fecha
    END AS FechaAgrupada,
    CadenaCD,
    PartyId
  FROM
    `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
  WHERE
    Fecha BETWEEN @start_date AND @end_date
    AND PartyId IS NOT NULL AND PartyId != 0
    AND SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
    AND DireccionCD IN UNNEST(@included_direccionCD)
    AND TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
    AND CadenaCD IN UNNEST(@included_CadenaCD)
),

AgrupacionTransacciones AS (
  SELECT
    FechaAgrupada AS Fecha,
    CadenaCD,
    COUNT(PartyId) AS NumeroTransacciones
  FROM
    ConfiguracionGranularidad
  GROUP BY
    Fecha,
    CadenaCD
)

SELECT
  Fecha,
  CadenaCD,
  NumeroTransacciones
FROM
  AgrupacionTransacciones;

```

## Tasa de Retención

### Descripción

La Tasa de Retención es un indicador clave del compromiso y la lealtad de los clientes año tras año. Este KPI analiza
el porcentaje de clientes del año anterior que continúan realizando compras en el año en curso. Se calcula de forma
acumulativa y se reinicia con cada nuevo año. Además, proporciona un desglose mes a mes para un seguimiento más
detallado y permite una comparación directa de la retención entre periodos específicos.

### Observaciones

- El acumulado mensual consiste comparar el mes corrido con el mes anterior.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S'.
- Se hace una agrupación por cadena.

### Temporalidad

- Se calculan los acumulados mes a mes y el año. No es necesario calcular el indicador diariamente.
- Se reinicia cada año, proporcionando un análisis acumulativo desde el comienzo del año en curso hasta la fecha actual.

### Entidades implicadas

- VentaLineaConClientes

### Consulta SQL

Esta consulta sigue los siguientes pasos para calcular el indicador de tasa de retención:

1. **Clientes del Mes Anterior (`ClientesMesAnterior`)**: Selecciona clientes únicos que realizaron transacciones en el
   mes (o año) anterior al periodo de interés. Esta selección se ajusta a los filtros de sublínea, dirección, tipo de
   negociación y cadena especificados.

2. **Clientes del Mes Actual (`ClientesMesActual`)**: Identifica clientes únicos que realizaron transacciones en el
   mes (o año) actual. Aplica los mismos filtros que el paso anterior.

3. **Cruce de Clientes Retenidos (`ClientesRetenidos`)**: Realiza un JOIN entre los clientes del mes anterior y los del
   mes actual para identificar aquellos que están presentes en ambos conjuntos, es decir, los clientes retenidos.

4. **Cálculo de la Tasa de Retención**: Calcula el porcentaje de retención agrupando por fecha (primer día del mes o
   año, según la granularidad) y cadena. Este porcentaje se obtiene dividiendo el número de clientes retenidos por el
   número total de clientes únicos del mes anterior, multiplicado por 100 para obtener un porcentaje.

```sql
WITH ClientesMesAnterior AS (
  SELECT DISTINCT 
    PartyId, 
    CadenaCD,
    DATE_TRUNC(Fecha, @granularity) AS PrimerDiaMes
  FROM
    `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
  WHERE
    Fecha >= DATE_TRUNC(@start_date, @granularity) - INTERVAL 1 @granularity
    AND Fecha < DATE_TRUNC(@start_date, @granularity)
    AND PartyId IS NOT NULL 
    AND PartyId != 0 
    AND SublineaCD NOT IN (SELECT * FROM UNNEST(@excluded_sublineaCD))
    AND DireccionCD IN (SELECT * FROM UNNEST(@included_direccionCD))
    AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(@excluded_tipoNegociacion))
    AND CadenaCD IN (SELECT * FROM UNNEST(@included_CadenaCD))
),
ClientesMesActual AS (
  SELECT DISTINCT 
    PartyId,
    CadenaCD,
    DATE_TRUNC(Fecha, @granularity) AS PrimerDiaMes
  FROM
    `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
  WHERE
    Fecha >= DATE_TRUNC(@start_date, @granularity)
    AND Fecha < LEAST(DATE_TRUNC(@start_date, @granularity) + INTERVAL 1 @granularity, @end_date + INTERVAL 1 DAY)
    AND PartyId IS NOT NULL 
    AND PartyId != 0 
    AND SublineaCD NOT IN (SELECT * FROM UNNEST(@excluded_sublineaCD))
    AND DireccionCD IN (SELECT * FROM UNNEST(@included_direccionCD))
    AND TipoNegociacion NOT IN (SELECT * FROM UNNEST(@excluded_tipoNegociacion))
    AND CadenaCD IN (SELECT * FROM UNNEST(@included_CadenaCD))
),
ClientesRetenidos AS (
  SELECT
    a.PartyId,
    b.CadenaCD,
    b.PrimerDiaMes AS PrimerDiaMesActual
  FROM
    ClientesMesAnterior a
  JOIN
    ClientesMesActual b ON a.PartyId = b.PartyId
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

```

## Clientes Monitoreados MM

### Descripción

Este KPI mide la cantidad de clientes únicos que han realizado transacciones en distintos periodos: diariamente,
mensualmente y anualmente. Se centra en las transacciones donde el cliente ha proporcionado su identificación,
excluyendo las anónimas. Este indicador es vital para entender la participación del cliente y la eficacia de las
estrategias de retención y se actualiza diariamente.

### Observaciones

- Solo se tienen en cuenta las transacciones válidas.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S'.
- Cuando un cliente no pasa el documento de identidad el PartyId es nulo, pero se puede dar el caso de que el PartyId
  sea cero. En ambos casos se descarta la transacción.
- Se hace una agrupación por cadena.

### Temporalidad

- Dada la naturaleza del indicador, se calculan los acumulados diarios, mensuales y anuales por separado para evitar
  contar clientes duplicados.

### Entidades implicadas

- VentaLineaConClientes

### Consulta SQL

La lógica detrás de esta consulta se puede desglosar en los siguientes pasos:

1. **Configuración de la Granularidad**: Basado en el parámetro `@granularity`, la fecha de las transacciones se ajusta
   para agrupar los datos por el día, mes o año correspondiente. Esto permite analizar el indicador en diferentes
   niveles de agregación temporal.

2. **Filtrado de Datos**: Se aplican múltiples filtros para excluir ciertas sublíneas de productos (`SublineaCD`),
   incluir ciertas direcciones (`DireccionCD`), excluir tipos de negociación (`TipoNegociacion`), y limitar el análisis
   a ciertas cadenas (`CadenaCD`). Además, se asegura de contar solo con `PartyId` válidos (no nulos y diferentes de 0),
   lo cual garantiza que solo se consideren transacciones legítimas de clientes.

3. **Conteo de Clientes Únicos**: Se cuenta la cantidad de `PartyId` únicos para cada combinación de fecha agrupada y
   cadena. Esto resulta en el número de clientes únicos que realizaron transacciones en cada periodo y cadena
   específicos.

4. **Agrupación y Resultados**: Finalmente, los datos se agrupan por la fecha ajustada y `CadenaCD`, y se presenta el
   conteo de clientes únicos para estas agrupaciones.

```sql
WITH DatosFiltrados AS (
  SELECT
    CASE
      WHEN @granularity = 'DAY' THEN Fecha
      WHEN @granularity = 'MONTH' THEN DATE_TRUNC(Fecha, MONTH)
      WHEN @granularity = 'YEAR' THEN DATE(DATE_TRUNC(Fecha, YEAR))
      ELSE Fecha
    END AS FechaAgrupada,
    CadenaCD,
    PartyId
  FROM
    `co-grupoexito-datalake-dev.VistasDesdeOtrosProyectos.vwVentaLineaConClientes`
  WHERE
    Fecha BETWEEN @start_date AND @end_date
    AND PartyId IS NOT NULL AND PartyId != 0
    AND SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
    AND DireccionCD IN UNNEST(@included_direccionCD)
    AND TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
    AND CadenaCD IN UNNEST(@included_CadenaCD)
)

SELECT
  FechaAgrupada AS Fecha,
  CadenaCD,
  COUNT(DISTINCT PartyId) AS NumeroClientesUnicos
FROM
  DatosFiltrados
GROUP BY
  FechaAgrupada, CadenaCD;

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
- Para la cadena 'A' se tiene el modelo de segmentación 25 con los segmentos AAA Y AA.
- Para la cadena 'S' se tiene el modelo de segmentación 24 con los segmentos AAA y AA.
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

### Consulta SQL para todas las cadenas excepto Éxito

1. **Clientes Válidos**: Filtra los clientes según las condiciones dadas, incluyendo el rango de fechas, sublíneas
   excluidas, direcciones incluidas, tipos de negociación excluidos, y la cadena específica.

2. **Segmentos de Clientes**: Para los clientes filtrados, se unen con las tablas de segmentación y modelo de segmento
   para contar los clientes únicos que cumplen con los criterios de segmentos específicos (por ejemplo, "VERDE", "
   DIAMANTE", "BLACK" para la cadena "C").

3. **Selección y Agrupación**: Los datos se agrupan por fecha (ajustada por la granularidad especificada) y modelo de
   segmentoid, calculando el porcentaje de clientes dentro de cada segmento sobre el total de clientes leales en ese
   periodo.

```sql
WITH ClientesValidos AS (
    SELECT
        CASE
            WHEN @granularity = 'DAY' THEN Fecha
            WHEN @granularity = 'MONTH' THEN DATE_TRUNC(Fecha, MONTH)
            WHEN @granularity = 'YEAR' THEN DATE_TRUNC(Fecha, YEAR)
        END AS FechaAgrupada,
        CadenaCD,
        PartyId
    FROM
        `sales_table`
    WHERE
        PartyId IS NOT NULL
        AND PartyId != 0
        AND Fecha BETWEEN @start_date AND @end_date
        AND SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND DireccionCD IN UNNEST(@included_direccionCD)
        AND TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND CadenaCD = @included_CadenaCD
),
SegmentosClientes AS (
    SELECT
        FechaAgrupada,
        ms.ModeloSegmentoid,
        COUNT(DISTINCT cv.PartyId) AS ConteoClientes
    FROM
        ClientesValidos cv
        JOIN `segment_table` s ON cv.PartyId = s.PartyID
        JOIN `model_segment_table` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
    WHERE
        ms.Modelid = @model_id_condition
        AND ms.ModelSegmentoDesc IN UNNEST(@model_segment_desc_condition)
    GROUP BY
        FechaAgrupada,
        ms.ModeloSegmentoid
)
SELECT
    sc.FechaAgrupada AS Fecha,
    @included_CadenaCD AS CadenaCD,
    sc.ModeloSegmentoid,
    ROUND((sc.ConteoClientes / SUM(sc.ConteoClientes) OVER(PARTITION BY sc.FechaAgrupada)) * 100, 2) AS Valor
FROM
    SegmentosClientes sc;
```

### Consulta para la cadena Éxito

1. **Clientes Top**: Identifica clientes con transacciones en más de un mes en el último año para la cadena "E".

2. **Clientes Leales**: Filtra esos clientes según su segmentación, considerando solo aquellos en los segmentos más
   altos como leales.

3. **Transacciones Totales**: Cuenta el número de clientes leales y calcula su proporción sobre el total de
   transacciones para cada período.

4. **Resultado Final**: Calcula el porcentaje de clientes leales en la cadena "E" para cada período según la
   granularidad especificada.

```sql
WITH ClientesTop AS (
    SELECT
        vc.PartyId
    FROM
        `sales_table` vc
    WHERE
        vc.PartyId IS NOT NULL
        AND vc.PartyId != 0
        AND DATE(vc.Fecha) BETWEEN DATE_SUB(@start_date, INTERVAL 12 MONTH) AND @end_date
        AND vc.SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND vc.DireccionCD IN UNNEST(@included_direccionCD)
        AND vc.TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND vc.CadenaCD = 'E'
    GROUP BY
        vc.PartyId
    HAVING
        COUNT(DISTINCT EXTRACT(MONTH FROM vc.Fecha)) > 1
),
ClientesLeales AS (
    SELECT
        ct.PartyId,
        'ClienteLeal' AS Segmento
    FROM
        ClientesTop ct
        JOIN `segment_table` s ON ct.PartyId = s.PartyID
        JOIN `model_segment_table` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
    WHERE
        ms.Modelid = 26
        AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
),
TransanccionesTotales AS (
    SELECT
        CASE
            WHEN @granularity = 'DAY' THEN vc.Fecha
            WHEN @granularity = 'MONTH' THEN DATE_TRUNC(vc.Fecha, MONTH)
            WHEN @granularity = 'YEAR' THEN DATE_TRUNC(vc.Fecha, YEAR)
        END AS Fecha,
        COUNT(DISTINCT vc.PartyId) AS ConteoClientes
    FROM 
        `sales_table` vc
    JOIN ClientesLeales cl ON vc.PartyId = cl.PartyId
    WHERE
        vc.Fecha BETWEEN @start_date AND @end_date
        AND vc.CadenaCD = 'E'
    GROUP BY
        Fecha
)
SELECT
    Fecha,
    'E' AS CadenaCD,
    0 AS ModeloSegmentoid,
    ROUND((ConteoClientes / SUM(ConteoClientes) OVER(PARTITION BY Fecha)) * 100, 2) AS Valor
FROM
    TransanccionesTotales;
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
- Para la cadena 'A' se tiene el modelo de segmentación 25 con los segmentos AAA Y AA.
- Para la cadena 'S' se tiene el modelo de segmentación 24 con los segmentos AAA y AA.
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

### Consulta SQL para todas las cadenas excepto Éxito

1. **Clientes Válidos**: Selecciona las ventas y clientes que cumplen con los filtros especificados, incluido el rango
   de fechas y los criterios de inclusión y exclusión.

2. **Segmentos de Clientes**: Agrupa las ventas por fecha (ajustada por la granularidad) y por modelo de segmento,
   sumando las ventas para los segmentos de clientes leales definidos.

3. **Cálculo del Porcentaje**: Calcula el porcentaje que representan las ventas a clientes leales sobre el total de
   ventas segmentadas por fecha.

```sql
WITH ClientesValidos AS (
    SELECT
        cv.PartyId,
        cv.VentaSinImpuesto,
        CASE
            WHEN @granularity = 'DAY' THEN cv.Fecha
            WHEN @granularity = 'MONTH' THEN DATE_TRUNC(cv.Fecha, MONTH)
            WHEN @granularity = 'YEAR' THEN DATE_TRUNC(cv.Fecha, YEAR)
        END AS FechaAgrupada
    FROM
        `sales_table` cv
    WHERE
        cv.PartyId IS NOT NULL AND cv.PartyId != 0
        AND cv.Fecha BETWEEN @start_date AND @end_date
        AND cv.SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND cv.DireccionCD IN UNNEST(@included_direccionCD)
        AND cv.TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND cv.CadenaCD = @included_CadenaCD
),
SegmentosClientes AS (
    SELECT
        FechaAgrupada,
        ms.ModeloSegmentoid,
        SUM(cv.VentaSinImpuesto) AS VentasSegmentadas
    FROM
        ClientesValidos cv
        JOIN `segment_table` s ON cv.PartyId = s.PartyID
        JOIN `model_segment_table` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
    WHERE
        ms.Modelid = @model_id_condition
        AND ms.ModelSegmentoDesc IN UNNEST(@model_segment_desc_condition)
    GROUP BY
        FechaAgrupada,
        ms.ModeloSegmentoid
)
SELECT
    FechaAgrupada AS Fecha,
    @included_CadenaCD AS CadenaCD,
    ModeloSegmentoid,
    ROUND((VentasSegmentadas / SUM(VentasSegmentadas) OVER(PARTITION BY FechaAgrupada)) * 100, 2) AS Valor
FROM
    SegmentosClientes;
```

### Consulta para la cadena Éxito

1. **Clientes Top**: Identifica clientes con transacciones recurrentes en más de un mes durante el último año para la
   cadena "E".

2. **Clientes Leales**: Filtra esos clientes según su segmentación, considerando solo aquellos en los deciles más altos.

3. **Transacciones Totales**: Agrupa las ventas por fecha (ajustada por la granularidad), sumando las ventas a estos
   clientes leales.

4. **Cálculo del Porcentaje**: Calcula el porcentaje que representan estas ventas sobre el total de ventas a clientes
   leales por fecha.

```sql
WITH ClientesTop AS (
    SELECT
        vc.PartyId
    FROM
        `sales_table` vc
    WHERE
        vc.PartyId IS NOT NULL AND vc.PartyId != 0
        AND DATE(vc.Fecha) BETWEEN DATE_SUB(@start_date, INTERVAL 12 MONTH) AND @end_date
        AND vc.SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND vc.DireccionCD IN UNNEST(@included_direccionCD)
        AND vc.TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND vc.CadenaCD = 'E'
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
        JOIN `segment_table` s ON ct.PartyId = s.PartyID
        JOIN `model_segment_table` ms ON s.ModeloSegmentoid = ms.ModeloSegmentoid
    WHERE
        ms.Modelid = 26 AND ms.ModelSegmentoDesc IN ('Decil 8', 'Decil 9', 'Decil 10')
),
TransaccionesTotales AS (
    SELECT
        CASE
            WHEN @granularity = 'DAY' THEN vc.Fecha
            WHEN @granularity = 'MONTH' THEN DATE_TRUNC(vc.Fecha, MONTH)
            WHEN @granularity = 'YEAR' THEN DATE_TRUNC(vc.Fecha, YEAR)
        END AS Fecha,
        SUM(vc.VentaSinImpuesto) AS Ventas
    FROM 
        `sales_table` vc
    JOIN ClientesLeales cl ON vc.PartyId = cl.PartyId
    WHERE
        vc.Fecha BETWEEN @start_date AND @end_date
        AND vc.CadenaCD = 'E'
    GROUP BY
        Fecha
)
SELECT
    Fecha,
    'E' AS CadenaCD,
    0 AS ModeloSegmentoid,
    ROUND((Ventas / SUM(Ventas) OVER(PARTITION BY Fecha)) * 100, 2) AS Valor
FROM
    TransaccionesTotales;
```

## Porcentaje de Contactabilidad

### Descripción

Mide la eficacia con la que la empresa puede comunicarse con sus clientes, basándose en la proporción de clientes
activos que tienen al menos un canal de comunicación registrado (email o celular) frente al total de clientes activos.

### Observaciones

- Al tratar con datos sensibles, desde la integración se ocultan los datos sensibles email y teléfono, si cuenta con
  email se reemplaza el dato por 1, si no, con 0. De la misma manera con el teléfono.
- Solo se tienen en cuenta las cadenas 'E', 'C', 'A', 'S'.
- Se hace una agrupación por cadena.

### Temporalidad

- Agrupación mensual.
- Los clientes activos son aquellos que compraron al menos una vez en los últimos 365 días.
- El indicador es acumulado al cierre del mes durante el año calendario, es decir, cada cálculo mensual refleja el
  porcentaje de contactabilidad acumulado hasta el mes en curso.

### Entidades implicadas

- Contactabilidad
- ventaLineaConClientes

### Consulta SQL

```sql
WITH Meses AS (
    SELECT DISTINCT DATE_TRUNC(Fecha, MONTH) AS FechaMes
    FROM UNNEST(GENERATE_DATE_ARRAY(@start_date, @end_date, INTERVAL 1 MONTH)) AS Fecha
),
ClientesActivos AS (
    SELECT 
        DATE_TRUNC(s.Fecha, MONTH) AS FechaMes,
        s.CadenaCD,
        COUNT(DISTINCT s.PartyID) AS TotalActivos
    FROM `sales_table` s
    WHERE
        s.Fecha BETWEEN @start_date AND @end_date
        AND s.PartyId IS NOT NULL 
        AND s.PartyId != 0 
        AND s.SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND s.DireccionCD IN UNNEST(@included_direccionCD)
        AND s.TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND s.CadenaCD IN UNNEST(@included_CadenaCD)
    GROUP BY 
        FechaMes, 
        s.CadenaCD
),
ClientesContactables AS (
    SELECT 
        DATE_TRUNC(c.Fecha, MONTH) AS FechaMes,
        c.CadenaCD,
        COUNT(DISTINCT c.PartyID) AS TotalContactables
    FROM `contact_table` c
    JOIN `sales_table` s ON c.PartyId = s.PartyID AND s.Fecha BETWEEN @start_date AND @end_date
    WHERE
        (c.indicadorcel = 1 OR c.indicadoremail = 1)
        AND s.SublineaCD NOT IN UNNEST(@excluded_sublineaCD)
        AND s.DireccionCD IN UNNEST(@included_direccionCD)
        AND s.TipoNegociacion NOT IN UNNEST(@excluded_tipoNegociacion)
        AND s.CadenaCD IN UNNEST(@included_CadenaCD)
    GROUP BY 
        FechaMes,
        c.CadenaCD
)
SELECT
    ca.FechaMes AS Fecha,
    ca.CadenaCD,
    0 AS ModeloSegmentoid,
    ROUND((SUM(cc.TotalContactables) / NULLIF(SUM(ca.TotalActivos), 0)) * 100, 2) AS Valor
FROM ClientesActivos ca
LEFT JOIN ClientesContactables cc ON ca.FechaMes = cc.FechaMes AND ca.CadenaCD = cc.CadenaCD
GROUP BY 
    ca.FechaMes,
    ca.CadenaCD
ORDER BY 
    ca.FechaMes,
    ca.CadenaCD;
```

## SOV ATL (Share Of Voice)

### Descripción

Mide la presencia y el impacto de la publicidad de la marca en comparación con el total del sector, reflejando su
presencia en el mercado publicitario. Este indicador es crucial para entender cómo se posiciona la marca en términos de
visibilidad frente a sus competidores.

### Observaciones

- La información proviene de IBOPE.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax y Superinter.

### Temporalidad

- Se actualiza mensualmente, sin acumulación anual.
- Actualización mensual y probablemente diaria.

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
- Sólo aplicará para Éxito y Carulla mensual, por negociación desde el 2024 se seguira recibiendo información trimestral
  para SP y SX.

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
- Sólo aplicará para Éxito y Carulla mensual, por negociación desde el 2024 se seguira recibiendo información trimestral
  para SP y SX.

### Entidades implicadas

- Integración manual en aras de implementar una integración automática.
- Externas.

## BEA (Valor de la Marca)

### Descripción

El Brand Equity Audit es un indicador comprensivo que mide la fuerza de la marca a través de varios factores, incluyendo
el conocimiento de la marca, el uso, el posicionamiento y la conexión emocional con los consumidores.

### Observaciones

- El indicador proviene de INVAMER.
- Solo se tienen en cuenta las cadenas Éxito, Carulla, Surtimax, Superinter y Surtimayorista.

### Temporalidad

- Acumulado mensual, el anual es un promedio de los meses corridos del año.
- Sólo aplicará para Éxito y Carulla mensual, por negociación desde el 2024 se seguira recibiendo información trimestral
  para SP y SX.

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
- Sólo aplicará para Éxito y Carulla mensual, por negociación desde el 2024 se seguira recibiendo información trimestral
  para SP y SX.

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
