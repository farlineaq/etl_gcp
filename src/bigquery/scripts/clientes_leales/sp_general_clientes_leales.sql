CREATE OR REPLACE PROCEDURE `{sp_name}`(
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

    WHILE idx < ARRAY_LENGTH(included_CadenaCD)
        DO
            SET cadena = included_CadenaCD[OFFSET(idx)];

            IF cadena = 'E' THEN
                CALL `{sp_clientes_leales_con_exito}`(
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
                CALL `{sp_clientes_leales_sin_exito}`(
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