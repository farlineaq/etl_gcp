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
                self.conf.bigquery.indicadores.porcentaje_contactabilidad[script.name]["sp_name"],
                query=script.content,
                query_parameters=self.conf.bigquery.indicadores.porcentaje_contactabilidad[script.name]
            )

    def _execute_delta(self, granularity: str) -> None:
        script_name: str = self.conf.bigquery.script_names.porcentaje_contactabilidad.endpoint_delta
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]

        if granularity != "MONTH":
            raise ValueError("granularity must be 'MONTH'")

        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_delta": self.conf.bigquery.indicadores.porcentaje_contactabilidad.endpoint_delta.sp_delta,
                "date_to_calculate": self.conf.bigquery.variables.delta.date_to_calculate,
                "excluded_sublineaCD": self.conf.bigquery.variables.excluded_sublineaCD,
                "included_direccionCD": self.conf.bigquery.variables.included_direccionCD,
                "excluded_tipoNegociacion": self.conf.bigquery.variables.excluded_tipoNegociacion,
                "included_CadenaCD": self.conf.bigquery.variables.included_CadenaCD,
                "contact_table": self.conf.bigquery.variables.contact_table,
                "sales_table": self.conf.bigquery.variables.sales_table,
                "target_table": self.conf.bigquery.variables.fact_table[granularity],
            }
        )

    def _execute_full(self, granularity: str) -> None:
        script_name: str = self.conf.bigquery.script_names.porcentaje_contactabilidad.endpoint_carga_inicial
        script: SQLScript = list(filter(lambda x: x.name == script_name, self.endpoint_scripts))[0]

        if granularity != "MONTH":
            raise ValueError("granularity must be 'MONTH'")

        self.bq_client.sql(
            script.content,
            query_parameters={
                "sp_carga_inicial": self.conf.bigquery.indicadores.porcentaje_contactabilidad.endpoint_carga_inicial.sp_carga_inicial,
                "start_date": self.conf.bigquery.variables.delta.start_date,
                "end_date": self.conf.bigquery.variables.delta.end_date,
                "excluded_sublineaCD": self.conf.bigquery.variables.excluded_sublineaCD,
                "included_direccionCD": self.conf.bigquery.variables.included_direccionCD,
                "excluded_tipoNegociacion": self.conf.bigquery.variables.excluded_tipoNegociacion,
                "included_CadenaCD": self.conf.bigquery.variables.included_CadenaCD,
                "contact_table": self.conf.bigquery.variables.contact_table,
                "sales_table": self.conf.bigquery.variables.sales_table,
                "target_table": self.conf.bigquery.variables.fact_table[granularity],
            }
        )

    def execute(self) -> None:
        self._create_sp()
        if self.execution_type == "full":
            self._execute_full(self.granularity)
        elif self.execution_type == "delta":
            self._execute_delta(self.granularity)
        else:
            raise ValueError("execution_type must be 'full' or 'delta'")
