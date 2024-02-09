from bubbaloo.services.cloud.google.bigquery.client import BigQueryClient
from bubbaloo.services.cloud.google.bigquery.script_loader import SQLScript
from bubbaloo.services.pipeline import Config
from typing import List, Literal

from bubbaloo.utils.interfaces.bigquery_stage import IBigQueryStage


class BigQueryStage(IBigQueryStage):
    """
    Implements a stage in a BigQuery data processing pipeline.

    This class manages the execution of SQL scripts for data transformation and loading in Google BigQuery,
    supporting both full and delta loads. It uses SQL scripts that are categorized by their filename prefixes
    to differentiate between stored procedures ('sp_') and data loading endpoints ('endpoint_').

    Attributes:
        sql_loads (List[SQLScript]): The SQL scripts to be executed as part of this stage.
        bq_client (BigQueryClient): The BigQuery client used to execute SQL queries.
        conf (Config): Configuration details for the pipeline execution.
        execution_type (Literal["full", "delta"]): Specifies whether the execution is a full load or a delta load.
        granularity (Literal["DAY", "MONTH", "YEAR"]): The granularity of the data processing.
        sp_scripts (List[SQLScript]): Stored procedures extracted from `sql_loads` based on their prefix.
        endpoint_scripts (List[SQLScript]): Endpoint scripts extracted from `sql_loads` based on their prefix.
    """

    def __init__(
            self,
            sql_loads: List[SQLScript],
            conf: Config,
            bq_client: BigQueryClient,
            execution_type: Literal["full", "delta"],
            granularity: Literal["DAY", "MONTH", "YEAR"]
    ):
        """
        Initializes a BigQueryStage with necessary configurations and scripts.

        Args:
            sql_loads (List[SQLScript]): List of SQL scripts for this stage.
            conf (Config): Configuration object with pipeline settings.
            bq_client (BigQueryClient): Client for interacting with BigQuery.
            execution_type (Literal["full", "delta"]): Type of execution, either 'full' or 'delta'.
            granularity (Literal["DAY", "MONTH", "YEAR"]): Data granularity for the stage.
        """
        self.sql_loads: List[SQLScript] = sql_loads
        self.bq_client: BigQueryClient = bq_client
        self.conf: Config = conf
        self.execution_type: Literal["full", "delta"] = execution_type
        self.granularity: Literal["DAY", "MONTH", "YEAR"] = granularity
        self.sp_scripts: List[SQLScript] = self._get_scripts_by_prefix("sp_")
        self.endpoint_scripts: List[SQLScript] = self._get_scripts_by_prefix("endpoint_")

    def _get_scripts_by_prefix(self, prefix: str) -> List[SQLScript]:
        """
        Filters the loaded SQL scripts by their prefix.

        Args:
            prefix (str): The prefix to filter scripts by.

        Returns:
            List[SQLScript]: A list of SQLScript objects whose names start with the given prefix.
        """
        new_list = []
        for item in self.sql_loads:
            if item.name.startswith(prefix):
                new_list.append(item)
        return new_list

    def _create_sp(self) -> None:
        """
        Executes the stored procedures (SP) SQL scripts in BigQuery.

        This method iterates over the stored procedures scripts and creates them in BigQuery using
        the provided configuration and BigQuery client. It specifically targets scripts prefixed with 'sp_'.
        """
        for script in self.sp_scripts:
            self.bq_client.create_routine_from_ddl_if_not_exists(
                self.conf.bigquery.indicadores.clientes_monitoreados[script.name]["sp_name"],
                query=script.content,
                query_parameters=self.conf.bigquery.indicadores.clientes_monitoreados[script.name]
            )

    def _execute_delta(self, granularity: str) -> None:
        """
        Executes the delta load SQL script based on the specified granularity.

        Args:
            granularity (str): The granularity ('DAY', 'MONTH', 'YEAR') of the delta load to be executed.
        """
        script_name: str = self.conf.bigquery.script_names.clientes_monitoreados.endpoint_delta
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]
        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_delta": self.conf.bigquery.indicadores.clientes_monitoreados.endpoint_delta.sp_delta,
                "date_to_calculate": self.conf.bigquery.variables.delta.date_to_calculate,
                "granularity": f"'{granularity}'",
                "excluded_sublineaCD": self.conf.bigquery.variables.excluded_sublineaCD,
                "included_direccionCD": self.conf.bigquery.variables.included_direccionCD,
                "excluded_tipoNegociacion": self.conf.bigquery.variables.excluded_tipoNegociacion,
                "included_CadenaCD": self.conf.bigquery.variables.included_CadenaCD,
                "sales_table": self.conf.bigquery.variables.sales_table,
                "target_table": self.conf.bigquery.variables.fact_table[granularity],
            }
        )

    def _execute_full(self, granularity: str) -> None:
        """
        Executes the full load SQL script based on the specified granularity.

        Args:
            granularity (str): The granularity ('DAY', 'MONTH', 'YEAR') of the full load to be executed.
        """
        script_name: str = self.conf.bigquery.script_names.clientes_monitoreados.endpoint_carga_inicial
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]
        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_carga_inicial": self.conf.bigquery.indicadores.clientes_monitoreados.endpoint_carga_inicial.sp_carga_inicial,
                "start_date": self.conf.bigquery.variables.delta.start_date,
                "end_date": self.conf.bigquery.variables.delta.end_date,
                "granularity": f"'{granularity}'",
                "excluded_sublineaCD": self.conf.bigquery.variables.excluded_sublineaCD,
                "included_direccionCD": self.conf.bigquery.variables.included_direccionCD,
                "excluded_tipoNegociacion": self.conf.bigquery.variables.excluded_tipoNegociacion,
                "included_CadenaCD": self.conf.bigquery.variables.included_CadenaCD,
                "sales_table": self.conf.bigquery.variables.sales_table,
                "target_table": self.conf.bigquery.variables.fact_table[granularity],
            }
        )

    def execute(self) -> None:
        """
        Orchestrates the execution of the BigQuery stage based on the execution type.

        This method first creates the necessary stored procedures and then executes either a full or delta load,
        based on the specified execution type and granularity. It raises a ValueError if the execution type is
        not recognized.
        """
        self._create_sp()
        if self.execution_type == "full":
            self._execute_full(self.granularity)
        elif self.execution_type == "delta":
            self._execute_delta(self.granularity)
        else:
            raise ValueError("execution_type must be 'full' or 'delta'")
