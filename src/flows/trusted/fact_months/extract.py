from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType, DoubleType

from bubbaloo.pipeline.stages import Extract
from bubbaloo.services.cloud.google.storage.storage import CloudStorageManager
from bubbaloo.services.validation import CSV
from bubbaloo.utils.functions import get_blobs_days_ago


class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.fact_months.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta))

    @staticmethod
    def read_options():
        return {
            'header': True,
            'sep': ','
        }

    @staticmethod
    def spark_schema():
        return StructType(
            [
                StructField('Actualizacion', StringType(), True),
                StructField('Fecha', DateType(), True),
                StructField('Cadena', StringType(), True),
                StructField('CadenaId', StringType(), True),
                StructField('Indicador', StringType(), True),
                StructField('IndicadorId', IntegerType(), True),
                StructField('Valor', DoubleType(), True)
            ]
        )

    def execute(self) -> DataFrame:
        validator = CSV(
            objects_to_validate=self.filtered_blobs(),
            read_options=self.read_options(),
            spark_schema=self.spark_schema(),
            spark=self.spark,
            logger=self.logger,
            storage_client=self.client(),
            context=self.context,
            error_path=self.conf.paths.fact_months.error_data_path
        )

        validator.execute()

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .csv(self.conf.paths.fact_months.raw_data_path, header=True, sep=',')
        )
