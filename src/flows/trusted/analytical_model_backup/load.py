from typing import Callable

from pyspark.sql import DataFrame
from pyspark.sql.streaming import DataStreamWriter

from quind_data_library.pipeline.stages import Load


# noinspection SqlNoDataSourceInspection
class LoadStage(Load):

    def create_delta_table(self):
        return self.spark.sql(f"""
            CREATE TABLE IF NOT EXISTS {self.conf.paths.entity_names.analytical_model_backup} (
                modelid INTEGER,
                ModelDdesc STRING,
                IndicadorAgregada STRING,
                FechaActualizacion TIMESTAMP
            )
            USING DELTA
            LOCATION '{self.conf.paths.analytical_model_backup.trusted_data_path}'
        """)

    def execute(self, dataframe: DataFrame, transform: Callable[..., None]) -> DataStreamWriter:
        self.create_delta_table()
        return (
            dataframe
            .writeStream
            .format("delta")
            .option("checkpointLocation", f"{self.conf.paths.analytical_model_backup.trusted_data_path}/_checkpoint")
            .trigger(once=True)
            .foreachBatch(transform)
        )
