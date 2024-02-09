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
    """
    A class for validating data quality using Great Expectations within a Spark environment.

    This class encapsulates the setup and execution of data validation checks using the
    Great Expectations library, tailored for use with PySpark DataFrames. It facilitates the creation
    of an ephemeral data context, data source configuration, expectation suite management, and execution
    of validation checks against the data.

    Attributes:
        project_name (str): The name of the project or validation context.
        project_config (DataContextConfig, optional): Configuration for the Great Expectations data context.
        context (AbstractDataContext): The Great Expectations data context for managing validation.
        datasource (SparkDatasource): The configured datasource for the validation.
        data_asset (DataFrameAsset): The data asset created from the input DataFrame.
        batch_request (BatchRequest): The batch request for processing the DataFrame.
        suite (ExpectationSuite): The expectation suite associated with the validation.
        validator (Validator): The Great Expectations validator configured for the validation.
        checkpoint (Checkpoint): The checkpoint configured for running the validation.
        _results (ExpectationSuiteValidationResult, optional): The results of the validation, if executed.
        expectations (Dict[str, Expectation], optional): Custom expectations defined for validation.
    """

    def __init__(
            self,
            dataframe: DataFrame,
            project_name: str,
            ephemeral: bool = True,
            project_config: DataContextConfig | None = None
    ):
        """
        Initializes the QualityValidator with a DataFrame, project name, and optional configurations.

        Args:
            dataframe (DataFrame): The PySpark DataFrame to validate.
            project_name (str): The name of the project or validation context.
            ephemeral (bool, optional): Whether to use an ephemeral data context. Defaults to True.
            project_config (DataContextConfig | None, optional): Optional configuration for the data context.
                If not provided, defaults will be used.
        """
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
        """Indicates whether the last validation run was successful."""
        return self._results.success

    @property
    def results(self) -> List[Dict[str, str]]:
        """
         Returns a list of dictionaries detailing the results of the last validation run.

         Each dictionary contains the name, type, and description of the expectation, the column it applies to,
         and whether the expectation was met.

         Returns:
             List[Dict[str, str]]: A list of dictionaries detailing the validation results.
         """
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
        """
        Retrieves or initializes the data context configuration.

        Args:
            project_config (DataContextConfig | None): The provided project configuration.

        Returns:
            DataContextConfig: The data context configuration to use.
        """
        if project_config is None:
            return DataContextConfig(
                store_backend_defaults=InMemoryStoreBackendDefaults()
            )
        return project_config

    def _get_context(self, ephemeral) -> AbstractDataContext:
        """
        Retrieves or initializes the data context.

        Args:
            ephemeral (bool): Indicates whether to use an ephemeral data context.

        Returns:
            AbstractDataContext: The initialized data context.
        """
        if ephemeral:
            return self._get_ephemeral_context()
        else:
            raise NotImplementedError("No implemented yet")

    def _get_ephemeral_context(self) -> AbstractDataContext:
        """
        Retrieves an ephemeral data context for temporary usage within the validation process.

        This method is designed to provide a lightweight, in-memory data context suitable for
        transient validation tasks. It initializes an EphemeralDataContext using the project's
        configuration if specified, or defaults if not.

        Returns:
            AbstractDataContext: An instance of EphemeralDataContext for managing temporary validation data.
        """
        if self.project_config is not None:
            return EphemeralDataContext(project_config=self.project_config)
        return EphemeralDataContext(
            project_config=DataContextConfig(
                store_backend_defaults=InMemoryStoreBackendDefaults()
            )
        )

    def _get_datasource(self, name: str) -> SparkDatasource:
        """
        Creates and retrieves a SparkDatasource within the Great Expectations context.

        This method adds a SparkDatasource to the Great Expectations context using the specified name. It is
        intended to enable the handling of Spark DataFrame validations within the Great Expectations framework.

        Args:
            name (str): The name to assign to the datasource.

        Returns:
            SparkDatasource: The created SparkDatasource instance.
        """
        return self.context.sources.add_spark(name)

    def _get_data_asset(self, name: str) -> DataFrameAsset:
        """
        Initializes and retrieves a DataFrameAsset for validation.

        This method adds a new DataFrameAsset to the configured datasource using the given name. It is
        utilized to represent a PySpark DataFrame as an asset within the Great Expectations ecosystem,
        allowing for the execution of validations against it.

        Args:
            name (str): The name to assign to the data asset.

        Returns:
            DataFrameAsset: The initialized DataFrameAsset instance.
        """
        return self.datasource.add_dataframe_asset(name=name)

    def _get_batch_request(self, dataframe: DataFrame) -> BatchRequest:
        """
        Constructs a BatchRequest for a given DataFrame.

        This method prepares a BatchRequest object for the provided DataFrame. The BatchRequest
        is used within the Great Expectations framework to specify the data batch to be validated.

        Args:
            dataframe (DataFrame): The PySpark DataFrame to be validated.

        Returns:
            BatchRequest: The constructed BatchRequest object.
        """
        return self.data_asset.build_batch_request(dataframe=dataframe)

    def _get_suite(self, name: str) -> ExpectationSuite:
        """
        Retrieves or creates an ExpectationSuite by name within the Great Expectations context.

        This method is responsible for either fetching an existing ExpectationSuite or initializing a new one
        within the Great Expectations data context. The suite is identified by the provided name, and it encapsulates
        the set of expectations that will be applied during data validation.

        Args:
            name (str): The name of the expectation suite to retrieve or create.

        Returns:
            ExpectationSuite: The retrieved or newly created ExpectationSuite instance.
        """
        return self.context.add_expectation_suite(expectation_suite_name=name)

    def _get_validator(self, batch_request: BatchRequest, expectation_suite: ExpectationSuite) -> Validator:
        """
        Retrieves a Validator configured for the provided batch request and expectation suite.

        This method creates a Validator instance using the specified BatchRequest and ExpectationSuite.
        The Validator is a key component in the Great Expectations framework, responsible for executing
        validation checks against a dataset.

        Args:
            batch_request (BatchRequest): The batch request specifying the data to validate.
            expectation_suite (ExpectationSuite): The suite of expectations to apply during validation.

        Returns:
            Validator: The configured Validator instance.
        """
        return self.context.get_validator(
            batch_request=batch_request,
            expectation_suite=expectation_suite
        )

    def _get_checkpoint(self, name: str) -> Checkpoint:
        """
        Configures and retrieves a Checkpoint for validation execution.

        This method sets up a Checkpoint in the Great Expectations context. Checkpoints are used to
        define and execute a validation process, including which data to validate and which expectations
        to apply. This setup includes specifying the batch request and the expectation suite name.

        Args:
            name (str): The name of the checkpoint.

        Returns:
            Checkpoint: The configured Checkpoint instance.
        """
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
        """
        Validates the attributes of the custom expectations defined for validation.

        This method checks each expectation defined in the 'expectations' attribute to ensure
        they have the required 'description' attribute, and that it is of the correct type (string).
        It raises an error if any expectation does not meet these criteria.
        """
        if not self.expectations:
            raise ValueError("No expectations are defined for validation.")

        for expectation_name, expectation_instance in self.expectations.items():
            if not hasattr(expectation_instance, 'description'):
                raise AttributeError(f"Expectation {expectation_name} must have 'description' attribute.")

            if not isinstance(expectation_instance.description, str):
                raise TypeError(f"The attribute 'description' of {expectation_name} must be strings.")

    def add_expectations(self, expectations: List[Expectation]) -> 'QualityValidator':
        """
        Adds custom expectations to the validator.

        This method takes a list of expectation instances, validates their attributes, and then
        applies them to the validator. It updates the validator's expectation suite with these
        custom expectations.

        Args:
            expectations (List[Expectation]): A list of Expectation instances to be added.

        Returns:
            QualityValidator: Returns self for chaining.
        """
        self.expectations = {expectation.__class__.__name__: expectation for expectation in expectations}
        self.validate_expectation_attributes()

        for expectation in self.expectations.values():
            expectation(self.validator)

        self.validator.save_expectation_suite(discard_failed_expectations=False)

        return self

    def run(self) -> List[Dict[str, str]]:
        """
        Executes the validation process and returns the results.

        This method runs the validation checks defined in the expectation suite against the
        data batch specified in the batch request. It captures the validation results and
        updates the '_results' attribute with these results.

        Returns:
            List[Dict[str, str]]: A list of dictionaries detailing the validation results.
        """
        results = self.checkpoint.run()

        self._results = results.list_validation_results()[0]

        return self.results
