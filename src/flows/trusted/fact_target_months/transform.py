from typing import Callable, Any

from pyspark.sql import DataFrame

from bubbaloo.pipeline.stages import Transform
from bubbaloo.utils.functions import get_metrics_from_delta_table


class TransformStage(Transform):

    def dedup_batch_query(self):
        self.spark.sql("""
            CREATE OR REPLACE GLOBAL TEMPORARY VIEW deduplicated_batch AS
            SELECT DISTINCT
                Fecha,
                CadenaId,
                IndicadorId,
                0 AS ModeloSegmentoId,
                Valor,
                CASE WHEN Actualizacion = 'SI' THEN 1 ELSE 0 END AS Estado,
                DATE_FORMAT(
                    FROM_UTC_TIMESTAMP(
                        FROM_UNIXTIME(
                            UNIX_TIMESTAMP(CURRENT_TIMESTAMP(), 'yyyy-MM-dd HH:mm:ss.SSSSSS')
                        ), 
                        'America/Bogota'
                    ), 
                    'yyyy-MM-dd HH:mm:ss'
                ) AS FechaActualizacion
            FROM global_temp.batch
        """)

    def merge_query(self):
        self.spark.sql(f"""
            MERGE INTO default.{self.conf.paths.entity_names.fact_target_months} AS target
            USING global_temp.deduplicated_batch AS source
                ON target.IndicadorId = source.IndicadorId 
                AND target.Fecha = source.Fecha 
                AND target.CadenaId = source.CadenaId
            WHEN MATCHED AND source.Estado = 1 THEN
                UPDATE SET
                    target.Fecha = source.Fecha,
                    target.CadenaId = source.CadenaId,
                    target.IndicadorId = source.IndicadorId,
                    target.ModeloSegmentoId = source.ModeloSegmentoId,
                    target.Valor = source.Valor,
                    target.FechaActualizacion = source.FechaActualizacion
            WHEN NOT MATCHED AND source.Estado = 0 THEN
                INSERT (
                    Fecha,
                    CadenaId,
                    IndicadorId,
                    ModeloSegmentoId,
                    Valor,
                    FechaActualizacion
                ) VALUES (
                    source.Fecha,
                    source.CadenaId,
                    source.IndicadorId,
                    source.ModeloSegmentoId,
                    source.Valor,
                    source.FechaActualizacion
                )
        """)

    def optimize_query(self):
        self.spark.sql(f"OPTIMIZE default.{self.conf.paths.entity_names.fact_target_months}")
        self.spark.sql(f"""
            VACUUM default.{self.conf.paths.entity_names.fact_target_months} 
            RETAIN {self.conf.table_history_retention_time} HOURS
        """)

    def register_metrics(self, batch_id: int):
        self.context.count.update(
            get_metrics_from_delta_table(
                self.spark,
                self.conf.paths.fact_target_months.trusted_data_path
            )
        )
        self.context.batch_id = batch_id

    def execute(self, *args) -> Callable[..., Any]:
        def batch_func(dataframe: DataFrame, batch_id: int):
            dataframe.createOrReplaceGlobalTempView("batch")
            self.dedup_batch_query()
            self.merge_query()
            self.optimize_query()
            self.register_metrics(batch_id)

        return batch_func
