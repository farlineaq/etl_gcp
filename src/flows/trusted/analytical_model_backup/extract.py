from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType, StringType

from bubbaloo.pipeline.stages import Extract
from bubbaloo.services.cloud.google.storage.storage import CloudStorageManager
from bubbaloo.services.validation.structure import Parquet
from bubbaloo.utils.functions import get_blobs_days_ago


# noinspection SqlNoDataSourceInspection
class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.analytical_model.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta[self.granularity]))

    @staticmethod
    def spark_schema():
        return StructType(
            [
                StructField('modelid', IntegerType(), True),
                StructField('ModelDdesc', StringType(), True),
                StructField('IndicadorAgregada', StringType(), True)
            ]
        )

    @staticmethod
    def pa_schema():
        import pyarrow as pa

        return pa.schema([
            ('modelid', pa.int32()),
            ('ModelDdesc', pa.string()),
            ('IndicadorAgregada', pa.string())
        ])

    def execute(self) -> DataFrame:
        validator = Parquet(
            objects_to_validate=self.filtered_blobs(),
            spark_schema=self.spark_schema(),
            pyarrow_schema=self.pa_schema(),
            spark=self.spark,
            logger=self.logger,
            storage_client=self.client(),
            context=self.context,
            error_path=self.conf.paths.analytical_model.error_data_path,
        )

        validator.execute()

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .parquet(self.conf.paths.analytical_model.raw_data_path)
        )
