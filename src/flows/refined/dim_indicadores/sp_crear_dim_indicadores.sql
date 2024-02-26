CREATE OR REPLACE PROCEDURE `{sp_name}`(table_name STRING)
BEGIN
    EXECUTE IMMEDIATE FORMAT("""
        CREATE TABLE IF NOT EXISTS `%s` (
            IndicadorKey INTEGER,
            Indicador STRING,
            Tipo STRING,
            Descripcion STRING,
            FechaActualizacion TIMESTAMP
        );
        """, table_name);

    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` T
        USING (
            SELECT * FROM UNNEST(ARRAY<STRUCT<IndicadorKey INT64, Indicador STRING, Tipo STRING, Descripcion STRING, FechaActualizacion TIMESTAMP>>[
                (1, 'Ventas Totales', 'Monto', 'Ventas totales sin IVA por cadena YTD en miles de millones', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (2, 'Transacciones Monitoreados', 'Conteo', 'Transacciones en miles de millones donde el cliente pasa el documento al pagar', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (3, 'Clientes Monitoreados', 'Conteo', 'Número de clientes que pasan el documento al momento de pagar en miles de millones', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (4, 'Retención', 'Porcentaje', 'Porcentaje de Clientes del año anterior que también compraron en el año actual. Clientes actuales dividido por Clientes del año anterior total', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (5, 'Clientes Leales', 'Conteo', 'Clientes TOP según la segmentación de la Cadena con más de 2 meses de permanencia que han comprado en al menos dos meses en los 12 meses anteriores', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (6, 'Ventas Clientes Leales', 'Porcentaje', 'Proporción de Ventas Lealtad sobre el Total de ventas monitoreadas en miles de millones. Aplica solo para éxito y se requieren clientes leales para este indicador', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (7, 'Contactabilidad', 'Porcentaje', 'Proporción de clientes activos con email o celular sobre el total de clientes activos', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (8, 'SOV', 'Porcentaje', 'Proporción de nuestra participación en la inversión publicitaria de toda la categoría. Se calcula sobre el ruido nacional para Exito, Carulla y Surtimax, y regional para Super Inter', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (9, 'SOI', 'Porcentaje', 'Proporción de nuestra participación en la inversión publicitaria de toda la categoría. Se calcula sobre la inversión nacional para Exito, Carulla y Surtimax, y regional para Super Inter', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (10, 'TOM', 'Porcentaje', 'Porcentaje de personas que mencionaron nuestra marca como primera opción al pensar en Retails. El indicador se presenta con un mes de retraso', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (11, 'BPD', 'Índice', 'Indice que agrupa diferentes opciones de uso que dan a nuestras marcas incluyendo Ha comprado Alguna Vez, Compró en los últimos 3 meses, Comprará la Próxima vez, Compra con Mayor Frecuencia, Cuál es tu marca favorita. Se presenta con un mes de retraso', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (12, 'Engagement Rate', 'Índice', 'Promedio del porcentaje de interacción en cada red social calculado como total interacciones propias de cada red dividido por su alcance total. No incluye YouTube. El rango normal es 2 a 3', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (13, 'CLV', 'Índice', 'Valor del ciclo de vida de los clientes en un periodo de tiempo determinado, presentado por cadena', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (14, 'Market Share', 'Porcentaje', 'Porcentaje de participación de la marca en el mercado Retail según el universo Nielsen, dato por cada una de las cadenas', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (15, 'INS', 'Índice', 'Indice neto de satisfacción, oscila entre 0 y 100 y se busca estar por encima del 70 por ciento. Agregación mensual', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (16, 'BEA', 'Índice', 'El Brand Equity Audit es un índice que resume en un número las variables de conocimiento, uso, posicionamiento y conexión emocional. Oscila entre 0 y 100 puntos donde 0 significa que la marca no existe en la mente de los consumidores y 100 es el máximo reconocimiento y conexión emocional. Se presenta con un mes de retraso', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (17, 'TOH', 'Índice', 'Indicador de la conexión emocional de los consumidores con nuestras marcas. Oscila entre 0 y 100, donde 0 es una relación emocional baja y 100 una relación alta', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (18, 'NPS', 'Índice', 'Indicador de recomendación de marca, oscila entre menos de 100 y 100, donde menos de 30 indica falta de recomendación, entre 30 y 60 es regular y más de 60 es positivo', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))),
                (19, 'INS Omnicanal', 'Índice', 'Indice neto de satisfacción total de la compañía, oscila entre 0 y 100 y se busca estar por encima del 70 por ciento', TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota')))
            ])
        ) S
        ON T.IndicadorKey = S.IndicadorKey
        WHEN MATCHED THEN
            UPDATE SET
                T.Indicador = S.Indicador,
                T.Tipo = S.Tipo,
                T.Descripcion = S.Descripcion,
                T.FechaActualizacion = S.FechaActualizacion
        WHEN NOT MATCHED THEN
            INSERT (IndicadorKey, Indicador, Tipo, Descripcion, FechaActualizacion)
            VALUES (S.IndicadorKey, S.Indicador, S.Tipo, S.Descripcion, S.FechaActualizacion);
      """, table_name);
END;
