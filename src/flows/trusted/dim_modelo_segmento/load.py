from typing import Callable

from pyspark.sql import DataFrame
from pyspark.sql.streaming import DataStreamWriter

from bubbaloo.pipeline.stages import Load


# noinspection SqlNoDataSourceInspection
class LoadStage(Load):

    def create_delta_table(self):
        return self.spark.sql(f"""
            CREATE TABLE IF NOT EXISTS {self.conf.paths.entity_names.dim_modelo_segmento} (
                ModeloSegmentoid INTEGER,
                Modelid INTEGER,
                ModelSegmentoDesc STRING,
                FechaActualizacion TIMESTAMP
            )
            USING DELTA
            LOCATION '{self.conf.paths.dim_modelo_segmento.trusted_data_path}'
        """)

    def execute(self, dataframe: DataFrame, transform: Callable[..., None]) -> DataStreamWriter:
        self.create_delta_table()
        return (
            dataframe
            .writeStream
            .format("delta")
            .option("checkpointLocation", f"{self.conf.paths.dim_modelo_segmento.trusted_data_path}/_checkpoint")
            .trigger(once=True)
            .foreachBatch(transform)
        )
