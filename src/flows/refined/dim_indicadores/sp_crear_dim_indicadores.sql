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
        INSERT INTO `%s` (
            IndicadorKey,
            Indicador,
            Tipo,
            Descripcion,
            FechaActualizacion
        )
        VALUES
            (1, 'Ventas Totales sin IVA', 'Monto', 'Ventas totales sin IVA por cadena YTD en miles de millones', CURRENT_TIMESTAMP()),
            (2, 'Transacciones Monitoreadas', 'Conteo', 'Transacciones en miles de millones donde el cliente pasa el documento al pagar', CURRENT_TIMESTAMP()),
            (3, 'Clientes Monitoreados', 'Conteo', 'Número de clientes que pasan el documento al momento de pagar en miles de millones', CURRENT_TIMESTAMP()),
            (4, 'Tasa de Retención', 'Porcentaje', 'Porcentaje de Clientes del año anterior que también compraron en el año actual. Clientes actuales dividido por Clientes del año anterior total', CURRENT_TIMESTAMP()),
            (5, 'Clientes Leales', 'Conteo', 'Clientes TOP según la segmentación de la Cadena con más de 2 meses de permanencia que han comprado en al menos dos meses en los 12 meses anteriores', CURRENT_TIMESTAMP()),
            (6, 'Porcentaje de las ventas de los Clientes Leales', 'Porcentaje', 'Proporción de Ventas Lealtad sobre el Total de ventas monitoreadas en miles de millones. Aplica solo para éxito y se requieren clientes leales para este indicador', CURRENT_TIMESTAMP()),
            (7, 'Porcentaje de Contactabilidad', 'Porcentaje', 'Proporción de clientes activos con email o celular sobre el total de clientes activos', CURRENT_TIMESTAMP()),
            (8, 'SOV ATL Share Of Voice', 'Porcentaje', 'Proporción de nuestra participación en la inversión publicitaria de toda la categoría. Se calcula sobre el ruido nacional para Exito, Carulla y Surtimax, y regional para Super Inter', CURRENT_TIMESTAMP()),
            (9, 'SOI Share Of Investment', 'Porcentaje', 'Proporción de nuestra participación en la inversión publicitaria de toda la categoría. Se calcula sobre la inversión nacional para Exito, Carulla y Surtimax, y regional para Super Inter', CURRENT_TIMESTAMP()),
            (10, 'TOM Top of Mind', 'Porcentaje', 'Porcentaje de personas que mencionaron nuestra marca como primera opción al pensar en Retails. El indicador se presenta con un mes de retraso', CURRENT_TIMESTAMP()),
            (11, 'BPD Brand Purchase Decision', 'Índice', 'Indice que agrupa diferentes opciones de uso que dan a nuestras marcas incluyendo Ha comprado Alguna Vez, Compró en los últimos 3 meses, Comprará la Próxima vez, Compra con Mayor Frecuencia, Cuál es tu marca favorita. Se presenta con un mes de retraso', CURRENT_TIMESTAMP()),
            (12, 'Engagement Rate en Redes Sociales', 'Porcentaje', 'Promedio del porcentaje de interacción en cada Red social calculado como total interacciones propias de cada red dividido por su alcance total. No incluye YouTube. El rango normal es 2 a 3', CURRENT_TIMESTAMP()),
            (13, 'CLTV Customer Life Time Value', 'Índice', 'Valor del ciclo de vida de los clientes en un periodo de tiempo determinado, presentado por cadena', CURRENT_TIMESTAMP()),
            (14, 'Market Share', 'Porcentaje', 'Porcentaje de participación de la marca en el mercado Retail según el universo Nielsen, dato por cada una de las cadenas', CURRENT_TIMESTAMP()),
            (15, 'INS Indice Neto de Satisfacción', 'Índice', 'Indice neto de satisfacción, oscila entre 0 y 100 y se busca estar por encima del 70 por ciento. Agregación mensual', CURRENT_TIMESTAMP()),
            (16, 'BEA Valor de la Marca', 'Índice', 'El Brand Equity Audit es un índice que resume en un número las variables de conocimiento, uso, posicionamiento y conexión emocional. Oscila entre 0 y 100 puntos donde 0 significa que la marca no existe en la mente de los consumidores y 100 es el máximo reconocimiento y conexión emocional. Se presenta con un mes de retraso', CURRENT_TIMESTAMP()),
            (17, 'TOH Top of Heart', 'Índice', 'Indicador de la conexión emocional de los consumidores con nuestras marcas. Oscila entre 0 y 100, donde 0 es una relación emocional baja y 100 una relación alta', CURRENT_TIMESTAMP()),
            (18, 'NPS Net Promose Score', 'Índice', 'Indicador de recomendación de marca, oscila entre menos de 100 y 100, donde menos de 30 indica falta de recomendación, entre 30 y 60 es regular y más de 60 es positivo', CURRENT_TIMESTAMP()),
            (19, 'INS Omnicanal', 'Índice', 'Indice neto de satisfacción total de la compañía, oscila entre 0 y 100 y se busca estar por encima del 70 por ciento', CURRENT_TIMESTAMP());
      """, table_name);
END;