CREATE OR REPLACE PROCEDURE `{sp_name}`(
    source_table STRING,
    target_table STRING
)
BEGIN
    EXECUTE IMMEDIATE FORMAT("""
        MERGE INTO `%s` AS target
        USING `%s` AS source
            ON target.Fecha = source.Fecha
            AND target.CadenaCD = source.CadenaId
            AND target.IndicadorKey = source.IndicadorId
            AND target.ModeloSegmentoid = source.ModeloSegmentoId
        WHEN MATCHED THEN
            UPDATE SET
                target.Valor = source.Valor,
                target.FechaActualizacion = TIMESTAMP(FORMAT_TIMESTAMP('%%F %%X', CURRENT_TIMESTAMP(), 'America/Bogota'))
        WHEN NOT MATCHED THEN
            INSERT (
                Fecha,
                CadenaCD,
                ModeloSegmentoid,
                IndicadorKey,
                Valor,
                FechaActualizacion
            )
            VALUES (
                source.Fecha,
                source.CadenaId,
                source.ModeloSegmentoId,
                source.IndicadorId,
                source.Valor,
                source.FechaActualizacion
            );
    """, target_table, source_table);
END;
