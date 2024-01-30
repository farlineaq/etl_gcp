CREATE OR REPLACE PROCEDURE `{sp_name}`(
    cadena_table STRING,
    target_view STRING
)
BEGIN
    EXECUTE IMMEDIATE FORMAT("""
        CREATE OR REPLACE VIEW `%s` AS
        SELECT DISTINCT
            CorporacionCD,
            IF(CadenaCD IN ('E', 'C', 'A', 'S'), CadenaCD, 'NA') AS CadenaCD,
            IF(CadenaCD IN ('E', 'C', 'A', 'S'), CadenaDesc, 'NO APLICA CADENA') AS CadenaDesc
        FROM
            `%s`;
    """, target_view, cadena_table);
END;