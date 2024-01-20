from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType

from bubbaloo.pipeline.stages import Extract
from bubbaloo.services.cloud.gcp.storage import CloudStorageManager
from bubbaloo.services.validation import Parquet
from bubbaloo.utils.functions import get_blobs_days_ago


# noinspection SqlNoDataSourceInspection
class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.segmentacion.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta))

    @staticmethod
    def spark_schema():
        return StructType(
            [
                StructField('PartyID', IntegerType(), True),
                StructField('ModeloSegmentoid', IntegerType(), True),
                StructField('ModelRunid', IntegerType(), True),
                StructField('LoyaltyProgramCD', IntegerType(), True)
            ]
        )

    @staticmethod
    def pa_schema():
        import pyarrow as pa

        return pa.schema(
            [
                ('PartyID', pa.int32()),
                ('ModeloSegmentoid', pa.int32()),
                ('ModelRunid', pa.int32()),
                ('LoyaltyProgramCD', pa.int32())
            ]
        )

    def execute(self) -> DataFrame:
        validator = Parquet(
            objects_to_validate=self.filtered_blobs(),
            spark_schema=self.spark_schema(),
            pyarrow_schema=self.pa_schema(),
            spark=self.spark,
            logger=self.logger,
            storage_client=self.client(),
            context=self.context,
            error_path=self.conf.paths.segmentacion.error_data_path,
        )

        validator.execute()

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .parquet(self.conf.paths.segmentacion.raw_data_path)
        )
