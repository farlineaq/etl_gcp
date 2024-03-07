CREATE OR REPLACE PROCEDURE `{sp_name}`(
    cadena_table STRING,
    dim_cadena_table STRING
)
BEGIN
    EXECUTE IMMEDIATE FORMAT("""
        CREATE OR REPLACE VIEW `%s` AS
        SELECT DISTINCT
            CorporacionCD,
            IF(CadenaCD IN ('E', 'C', 'A', 'S'), CadenaCD, 'ACES') AS CadenaCD,
            IF(CadenaCD IN ('E', 'C', 'A', 'S'), CadenaDesc, 'CONJUNTO DE LAS CADENAS A, C, E Y S') AS CadenaDesc
        FROM
            `%s`;
    """, dim_cadena_table, cadena_table);
END;