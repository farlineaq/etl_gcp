from typing import Dict, Any, List

from pyspark.sql import DataFrame
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType, DoubleType

from quind_data_library.pipeline.stages import Extract
from quind_data_library.services.cloud.google.storage.storage import CloudStorageManager
from quind_data_library.services.validation.quality.expectations import (
    RegexExpectation,
    DistinctValuesExpectation,
    UniqueExpectation,
    NotNullExpectation
)
from quind_data_library.services.validation.structure import CSV
from quind_data_library.utils.functions import get_blobs_days_ago
from quind_data_library.utils.interfaces.quality_expectation import Expectation


class ExtractStage(Extract):

    def client(self):
        return CloudStorageManager(self.conf.variables.project)

    def filtered_blobs(self):
        client = self.client()
        blobs = client.list(self.conf.paths.fact_target_months.raw_data_path)
        return client.filter(blobs, lambda blob: get_blobs_days_ago(blob, self.conf.timedelta[self.granularity]))

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
    def read_options():
        return {
            'header': True,
            'sep': ','
        }

    def expectations(self) -> List[Expectation]:
        not_null_expectation = NotNullExpectation(
            columns=self.conf.expectations.not_null_expectation.columns,
            mostly=1
        )
        in_set_expectation_cadena_id = DistinctValuesExpectation(
            columns=[self.conf.expectations.in_set_expectation.columns.cadena_id.name],
            value_set=self.conf.expectations.in_set_expectation.columns.cadena_id.value_set
        )
        in_set_expectation_indicador_id = DistinctValuesExpectation(
            columns=[self.conf.expectations.in_set_expectation.columns.indicador_id.name],
            value_set=self.conf.expectations.in_set_expectation.columns.indicador_id.value_set
        )
        in_set_expectation_actualizacion = DistinctValuesExpectation(
            columns=[self.conf.expectations.in_set_expectation.columns.actualizacion.name],
            value_set=self.conf.expectations.in_set_expectation.columns.actualizacion.value_set
        )
        unique_expectation = UniqueExpectation(
            columns=self.conf.expectations.unique_expectation.columns
        )
        regex_expectation = RegexExpectation(
            columns=[self.conf.expectations.regex_expectation.columns.fecha.name],
            pattern=self.conf.expectations.regex_expectation.columns.fecha.pattern
        )

        expectations = [
            not_null_expectation,
            in_set_expectation_cadena_id,
            in_set_expectation_indicador_id,
            in_set_expectation_actualizacion,
            unique_expectation,
            regex_expectation
        ]

        return expectations

    def expectation_config(self) -> Dict[str, Any]:
        return {
            "expectations": self.expectations(),
            "project_name": str(self.conf.paths.entity_names.fact_target_months).lower()
        }

    def execute(self) -> DataFrame:
        validator = CSV(
            objects_to_validate=self.filtered_blobs(),
            read_options=self.read_options(),
            spark_schema=self.spark_schema(),
            spark=self.spark,
            logger=self.logger,
            storage_client=self.client(),
            context=self.context,
            error_path=self.conf.paths.fact_target_months.error_data_path,
            expectation_config=self.expectation_config()
        )

        validator.execute()

        return (
            self.spark
            .readStream
            .schema(self.spark_schema())
            .csv(self.conf.paths.fact_target_months.raw_data_path, header=True, sep=',')
        )
