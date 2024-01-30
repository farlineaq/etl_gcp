from bubbaloo.services.local import Logger
from bubbaloo.services.pipeline import Config, PipelineState, GetSpark, ArgumentParser
from bubbaloo.services.cloud.google.bigquery.client import BigQueryClient
from bubbaloo.services.cloud.google.bigquery.orchestration import BigQueryOrchestrator
from bubbaloo.orchestration import Orchestrator
from bubbaloo.utils.interfaces.pipeline_logger import ILogger

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
