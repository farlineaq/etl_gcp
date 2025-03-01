from typing import Callable, Any

from pyspark.sql import DataFrame

from quind_data_library.pipeline.stages import Transform
from quind_data_library.utils.functions import get_metrics_from_delta_table


class TransformStage(Transform):

    def dedup_batch_query(self):
        self.spark.sql("""
            CREATE OR REPLACE GLOBAL TEMPORARY VIEW deduplicated_batch AS
            SELECT DISTINCT
                *,
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

    def overwrite_query(self):
        self.spark.sql(f"""
            INSERT OVERWRITE TABLE default.{self.conf.paths.entity_names.model_run_backup}
            SELECT * FROM global_temp.deduplicated_batch
        """)

    def optimize_query(self):
        self.spark.sql(f"OPTIMIZE default.{self.conf.paths.entity_names.model_run_backup}")
        self.spark.sql(f"""
            VACUUM default.{self.conf.paths.entity_names.model_run_backup} 
            RETAIN {self.conf.table_history_retention_time} HOURS
        """)

    def register_metrics(self, batch_id: int):
        self.context.count.update(
            get_metrics_from_delta_table(
                self.spark,
                self.conf.paths.model_run_backup.trusted_data_path
            )
        )
        self.context.batch_id = batch_id

    def execute(self, *args) -> Callable[..., Any]:
        def batch_func(dataframe: DataFrame, batch_id: int):
            dataframe.createOrReplaceGlobalTempView("batch")
            self.dedup_batch_query()
            self.overwrite_query()
            self.optimize_query()
            self.register_metrics(batch_id)

        return batch_func
