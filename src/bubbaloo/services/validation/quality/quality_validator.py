from great_expectations.data_context.types.base import (
    DataContextConfig,
    InMemoryStoreBackendDefaults,
)
from great_expectations.data_context import EphemeralDataContext
from great_expectations.checkpoint import Checkpoint
from typing import List, Dict
from great_expectations.validator.validator import Validator
from great_expectations.datasource.fluent.batch_request import BatchRequest
from great_expectations.datasource.fluent.spark_datasource import DataFrameAsset
from great_expectations.datasource.fluent import SparkDatasource
from great_expectations.core import ExpectationSuite, ExpectationSuiteValidationResult
from great_expectations.data_context import AbstractDataContext
from pyspark.sql import DataFrame

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class QualityValidator:
    def __init__(
            self,
            dataframe: DataFrame,
            project_name: str,
            ephemeral: bool = True,
            project_config: DataContextConfig | None = None
    ):
        self.project_name = project_name
        self.project_config = self._get_project_config(project_config)
        self.context = self._get_context(ephemeral)
        self.datasource = self._get_datasource(f"{project_name}_datasource")
        self.data_asset = self._get_data_asset(f"{project_name}_data_asset")
        self.batch_request = self._get_batch_request(dataframe)
        self.suite = self._get_suite(f"{project_name}_suite")
        self.validator = self._get_validator(self.batch_request, self.suite)
        self.checkpoint = self._get_checkpoint(f"{project_name}_checkpoint")
        self._results: ExpectationSuiteValidationResult | None = None
        self.expectations: Dict[str, Expectation] | None = None

    @property
    def success(self) -> bool:
        return self._results.success

    @property
    def results(self) -> List[Dict[str, str]]:

        _result: List[Dict[str, str]] = [
            {
                "expectation_name": result.expectation_config.meta["expectation_name"],
                "expectation_type": result.expectation_config.expectation_type,
                "description": result.expectation_config.meta["description"],
                "column": result.expectation_config.meta["column"],
                "success": result.success
            }
            for result in self._results.results
        ]

        return _result

    @staticmethod
    def _get_project_config(project_config: DataContextConfig | None) -> DataContextConfig:
        if project_config is None:
            return DataContextConfig(
                store_backend_defaults=InMemoryStoreBackendDefaults()
            )
        return project_config

    def _get_context(self, ephemeral) -> AbstractDataContext:
        if ephemeral:
            return self._get_ephemeral_context()
        else:
            raise NotImplementedError("No implemented yet")

    def _get_ephemeral_context(self) -> AbstractDataContext:
        if self.project_config is not None:
            return EphemeralDataContext(project_config=self.project_config)
        return EphemeralDataContext(
            project_config=DataContextConfig(
                store_backend_defaults=InMemoryStoreBackendDefaults()
            )
        )

    def _get_datasource(self, name: str) -> SparkDatasource:
        return self.context.sources.add_spark(name)

    def _get_data_asset(self, name: str) -> DataFrameAsset:
        return self.datasource.add_dataframe_asset(name=name)

    def _get_batch_request(self, dataframe: DataFrame) -> BatchRequest:
        return self.data_asset.build_batch_request(dataframe=dataframe)

    def _get_suite(self, name: str) -> ExpectationSuite:
        return self.context.add_expectation_suite(expectation_suite_name=name)

    def _get_validator(self, batch_request: BatchRequest, expectation_suite: ExpectationSuite) -> Validator:
        return self.context.get_validator(
            batch_request=batch_request,
            expectation_suite=expectation_suite
        )

    def _get_checkpoint(self, name: str) -> Checkpoint:

        return self.context.add_or_update_checkpoint(
            name=name,
            validations=[
                {
                    "batch_request": self.batch_request,
                    "expectation_suite_name": self.suite.expectation_suite_name
                },
            ],
            runtime_configuration={
                "result_format": "BOOLEAN_ONLY",
                "include_config": False,
            },
        )

    def validate_expectation_attributes(self):
        if not self.expectations:
            raise ValueError("No expectations are defined for validation.")

        for expectation_name, expectation_instance in self.expectations.items():
            if not hasattr(expectation_instance, 'description'):
                raise AttributeError(f"Expectation {expectation_name} must have 'description' attribute.")

            if not isinstance(expectation_instance.description, str):
                raise TypeError(f"The attribute 'description' of {expectation_name} must be strings.")

    def add_expectations(self, expectations: List[Expectation]) -> 'QualityValidator':

        self.expectations = {expectation.__class__.__name__: expectation for expectation in expectations}
        self.validate_expectation_attributes()

        for expectation in self.expectations.values():
            expectation(self.validator)

        self.validator.save_expectation_suite(discard_failed_expectations=False)

        return self

    def run(self) -> List[Dict[str, str]]:
        results = self.checkpoint.run()

        self._results = results.list_validation_results()[0]

        return self.results
