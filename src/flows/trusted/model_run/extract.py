from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType

from quind_data_library.pipeline.stages import Extract
from quind_data_library.services.cloud.google.storage.storage import CloudStorageManager
from quind_data_library.services.validation.structure import Parquet
from quind_data_library.utils.functions import get_blobs_days_ago


# noinspection SqlNoDataSourceInspection
class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.model_run.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta[self.granularity]))

    @staticmethod
    def spark_schema():
        return StructType(
            [
                StructField("Modelid", IntegerType(), True),
                StructField("ModelRunid", IntegerType(), True),
                StructField("ModelRunDt", DateType(), True),
                StructField("LoyaltyProgramCD", IntegerType(), True),
                StructField("ChainCD", StringType(), True),
                StructField("bolClifre", IntegerType(), True),
                StructField("TipoSegmentaCarulla", IntegerType(), True),
            ]
        )

    @staticmethod
    def pa_schema():
        import pyarrow as pa

        return pa.schema([
            ('Modelid', pa.int32()),
            ('ModelRunid', pa.int32()),
            ('ModelRunDt', pa.date32()),
            ('LoyaltyProgramCD', pa.int32()),
            ('ChainCD', pa.string()),
            ('bolClifre', pa.int32()),
            ('TipoSegmentaCarulla', pa.int32())
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
            error_path=self.conf.paths.model_run.error_data_path,
        )

        validator.execute()

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .parquet(self.conf.paths.model_run.raw_data_path)
        )
