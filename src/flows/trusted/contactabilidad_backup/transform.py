from typing import Callable, Any

from pyspark.sql import DataFrame

from quind_data_library.pipeline.stages import Transform
from quind_data_library.utils.functions import get_metrics_from_delta_table


class TransformStage(Transform):

    def dedup_batch_query(self):
        self.spark.sql("""
            CREATE OR REPLACE GLOBAL TEMPORARY VIEW deduplicated_batch AS
            SELECT 
                PartyID,
                indicadoremail,
                indicadorcel,
                fechaindicadoremail,
                fechaindicadorcel,
                DATE_FORMAT(
                    FROM_UTC_TIMESTAMP(
                        FROM_UNIXTIME(
                            UNIX_TIMESTAMP(CURRENT_TIMESTAMP(), 'yyyy-MM-dd HH:mm:ss.SSSSSS')
                        ),
                        'America/Bogota'
                    ),
                    'yyyy-MM-dd HH:mm:ss'
                ) AS FechaActualizacion
            FROM (
              SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY PartyID ORDER BY fechaindicadoremail, fechaindicadorcel DESC) AS row_num
              FROM global_temp.batch
            )
            WHERE row_num = 1
        """)

    def merge_query(self):
        self.spark.sql(f"""
            MERGE INTO default.{self.conf.paths.entity_names.contactabilidad_backup} AS target
            USING global_temp.deduplicated_batch AS source
            ON target.PartyID = source.PartyID
            WHEN MATCHED THEN
                UPDATE SET *
            WHEN NOT MATCHED THEN
                INSERT *
        """)

    def optimize_query(self):
        self.spark.sql(f"OPTIMIZE default.{self.conf.paths.entity_names.contactabilidad_backup}")
        self.spark.sql(f"""
            VACUUM default.{self.conf.paths.entity_names.contactabilidad_backup} 
            RETAIN {self.conf.table_history_retention_time} HOURS
        """)

    def register_metrics(self, batch_id: int):
        self.context.count.update(
            get_metrics_from_delta_table(
                self.spark,
                self.conf.paths.contactabilidad_backup.trusted_data_path
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
