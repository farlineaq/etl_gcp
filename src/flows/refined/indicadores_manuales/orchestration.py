from bubbaloo.services.cloud.google.bigquery.client import BigQueryClient
from bubbaloo.services.cloud.google.bigquery.script_loader import SQLScript
from bubbaloo.services.pipeline import Config
from typing import List, Literal

from bubbaloo.utils.interfaces.bigquery_stage import IBigQueryStage


class BigQueryStage(IBigQueryStage):
    def __init__(
            self,
            sql_loads: List[SQLScript],
            conf: Config,
            bq_client: BigQueryClient,
            execution_type: Literal["full", "delta"],
            granularity: Literal["DAY", "MONTH", "YEAR"]
    ):
        self.sql_loads: List[SQLScript] = sql_loads
        self.bq_client: BigQueryClient = bq_client
        self.conf: Config = conf
        self.execution_type: Literal["full", "delta"] = execution_type
        self.granularity: Literal["DAY", "MONTH", "YEAR"] = granularity
        self.sp_scripts: List[SQLScript] = self._get_scripts_by_prefix("sp_")
        self.endpoint_scripts: List[SQLScript] = self._get_scripts_by_prefix("endpoint_")

    def _get_scripts_by_prefix(self, prefix: str) -> List[SQLScript]:
        new_list = []
        for item in self.sql_loads:
            if item.name.startswith(prefix):
                new_list.append(item)
        return new_list

    def _create_sp(self) -> None:
        for script in self.sp_scripts:
            self.bq_client.create_routine_from_ddl_if_not_exists(
                self.conf.bigquery.indicadores.indicadores_manuales[script.name]["sp_name"],
                query=script.content,
                query_parameters=self.conf.bigquery.indicadores.indicadores_manuales[script.name]
            )

    def _execute(self, granularity: str) -> None:
        script_name: str = self.conf.bigquery.script_names.indicadores_manuales.endpoint_delta
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]

        if granularity != "MONTH":
            raise ValueError("granularity must be 'MONTH'")

        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_merge_indicadores_manuales": self.conf.bigquery.indicadores.indicadores_manuales.endpoint_delta.sp_merge_indicadores_manuales,
                "source_table": self.conf.bigquery.variables.source_fact_table[granularity],
                "target_table": self.conf.bigquery.variables.fact_table[granularity],
            }
        )

    def execute(self) -> None:
        if self.execution_type == "delta":
            self._create_sp()
            self._execute(self.granularity)
            return
        return
