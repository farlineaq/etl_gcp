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
                self.conf.bigquery.indicadores.dim_indicadores[script.name]["sp_name"],
                query=script.content,
                query_parameters=self.conf.bigquery.indicadores.dim_indicadores[script.name]
            )

    def _execute(self) -> None:
        script_name: str = self.conf.bigquery.script_names.dim_indicadores.endpoint_carga_inicial
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]

        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_crear_dim_indicadores": self.conf.bigquery.indicadores.dim_indicadores.endpoint_carga_inicial.sp_crear_dim_indicadores,
                "table_name": self.conf.bigquery.indicadores.dim_indicadores.endpoint_carga_inicial.table_name
            }
        )

    def execute(self) -> None:
        if self.execution_type == "full":
            self._create_sp()
            self._execute()
            return
        return
