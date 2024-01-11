from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType, DoubleType

from bubbaloo.pipeline.stages import Extract
from bubbaloo.services.cloud.gcp.storage import CloudStorageManager
from bubbaloo.utils.functions import get_blobs_days_ago


class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.fact_target_months.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta))

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

    @staticmethod
    def pa_schema():
        import pyarrow as pa

        return pa.schema(
            [
                ('Actualizacion', pa.string()),
                ('Fecha', pa.date32()),
                ('Cadena', pa.string()),
                ('CadenaId', pa.string()),
                ('Indicador', pa.string()),
                ('IndicadorId', pa.int32()),
                ('Valor', pa.float64())
            ]
        )

    def execute(self) -> DataFrame:
        validator = ...

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .csv(self.conf.paths.fact_target_months.raw_data_path, header=True, sep=',')
        )
