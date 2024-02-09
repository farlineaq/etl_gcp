from quind_data_library.services.local import Logger
from quind_data_library.services.pipeline import Config, PipelineState, GetSpark, ArgumentParser
from quind_data_library.services.cloud.google.bigquery.client import BigQueryClient
from quind_data_library.services.cloud.google.bigquery.orchestration import BigQueryOrchestrator
from quind_data_library.orchestration import Orchestrator
from quind_data_library.utils.interfaces.pipeline_logger import ILogger

from typing import List, Literal

from pyspark.sql import SparkSession

from flows import trusted, refined


def execute_trusted(
        conf: Config,
        logger: ILogger,
        spark: SparkSession,
        state: PipelineState,
        granularity: Literal["DAY", "MONTH", "YEAR"],
        flows_to_execute: List[str] | None = None
) -> None:
    """
    Executes the 'trusted' layer data processing workflows using Apache Spark.

    This function orchestrates the execution of data processing jobs defined in the 'trusted' namespace.
    It initializes an Orchestrator instance with the specified configurations and triggers the execution
    of the data workflows.

    Args:
        conf (Config): The pipeline configuration settings.
        logger (ILogger): The logging interface instance.
        spark (SparkSession): The Spark session to use for data processing.
        state (PipelineState): The state management object for the pipeline execution.
        granularity (Literal["DAY", "MONTH", "YEAR"]): The data processing granularity.
        flows_to_execute (List[str] | None): An optional list of specific workflow names to execute.
    """
    orchestrator = Orchestrator(
        trusted,
        flows_to_execute,
        conf=conf,
        logger=logger,
        spark=spark,
        context=state,
        granularity=granularity
    )

    orchestrator.execute()


def execute_refined(
        conf: Config,
        logger: ILogger,
        bq_client: BigQueryClient,
        execution_type: Literal["full", "delta"],
        granularity: Literal["DAY", "MONTH", "YEAR"],
        flows_to_execute: List[str] | None = None
) -> None:
    """
    Executes the 'refined' layer data processing workflows in Google BigQuery.

    This function orchestrates the execution of data processing jobs defined in the 'refined' namespace,
    using Google BigQuery as the processing engine. It supports executing workflows based on an execution
    type ('full' or 'delta') and the specified granularity.

    Args:
        conf (Config): The pipeline configuration settings.
        logger (ILogger): The logging interface instance.
        bq_client (BigQueryClient): The BigQuery client for executing SQL queries.
        execution_type (Literal["full", "delta"]): The type of execution, either 'full' or 'delta'.
        granularity (Literal["DAY", "MONTH", "YEAR"]): The data processing granularity.
        flows_to_execute (List[str] | None): An optional list of specific workflow names to execute.
    """
    if flows_to_execute is not None and flows_to_execute[0] == 'false':
        return

    orchestrator = BigQueryOrchestrator(
        refined,
        conf,
        logger,
        bq_client,
        execution_type,
        granularity,
        flows_to_execute
    )

    orchestrator.execute()


def main():
    """
    Main function to orchestrate the execution of data processing workflows.

    This function parses command-line arguments to configure the execution environment, logging level,
    Spark session, and pipeline state. It then proceeds to execute both 'trusted' and 'refined' layer
    workflows based on the provided configuration and command-line arguments.
    """
    parser = ArgumentParser()
    logger = Logger()
    spark = GetSpark()
    conf = Config(env=parser.args.env)
    spark.sparkContext.setLogLevel(conf.log_level)
    state = PipelineState()
    bq_client = BigQueryClient(project=conf.variables.project)
    execution_type = parser.args.execution_type
    granularity = parser.args.granularity
    refined_flows = parser.args.refined_flows
    trusted_flows = parser.args.trusted_flows

    execute_trusted(
        conf=conf,
        logger=logger,
        spark=spark,
        state=state,
        flows_to_execute=trusted_flows,
        granularity=granularity
    )

    execute_refined(
        conf=conf,
        logger=logger,
        bq_client=bq_client,
        execution_type=execution_type,
        granularity=granularity,
        flows_to_execute=refined_flows
    )


if __name__ == "__main__":
    main()
