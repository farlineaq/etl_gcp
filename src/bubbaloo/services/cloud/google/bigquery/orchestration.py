import os
import inspect
import importlib
import sys
import zipfile
import re
from copy import deepcopy
from pathlib import Path
from typing import Dict, List, Tuple, Type, Literal, Any

from bubbaloo.services.cloud.google.bigquery.client import BigQueryClient
from bubbaloo.services.cloud.google.bigquery.script_loader import SQLScript, SQLScriptsLoader
from bubbaloo.services.pipeline import Config, PipelineState
from bubbaloo.utils.functions.pipeline_orchestration_helper import get_error
from bubbaloo.utils.interfaces.bigquery_stage import IBigQueryStage
from bubbaloo.utils.interfaces.pipeline_logger import ILogger
from flows.refined.clientes_leales.orchestration import BigQueryStage


class BigQueryOrchestrator:

    def __init__(
            self,
            path_to_flows: str | object,
            conf: Config,
            logger: ILogger,
            bq_client: BigQueryClient,
            execution_type: Literal["full", "delta"],
            granularity: Literal["DAY", "MONTH", "YEAR"],
            flows_to_execute: List[str] | None = None
    ):

        self._path_to_flows: str = self._get_working_path(path_to_flows)
        self._flows_to_execute: List[str] = flows_to_execute if flows_to_execute is not None else []
        self._flows_dir_name: str = self._path_to_flows.split("/")[-1]
        self._conf: Config = conf
        self._logger: ILogger = logger
        self._bq_client: BigQueryClient = bq_client
        self._context: PipelineState = PipelineState()
        self._execution_type: Literal["full", "delta"] = execution_type
        self._granularity: Literal["DAY", "MONTH", "YEAR"] = granularity
        self._stages_list: List[Tuple[str, BigQueryStage]] = []
        self._stage_type: Type[BigQueryStage] = BigQueryStage
        self._resume: List[Dict[str, str]] | str = []
        self._loads: SQLScriptsLoader = SQLScriptsLoader(self._path_to_flows)
        self._scripts_by_flow: Dict[str, List[SQLScript]] = self._get_sql_scripts_from_package()
        self._get_stages_to_execute()

    def _get_sql_scripts_from_package(self) -> Dict[str, List[SQLScript]]:
        return self._loads.load_sql_scripts()

    def _get_working_path(self, path_to_flows: str) -> str:
        tmp_path = path_to_flows.__path__[0] if inspect.ismodule(path_to_flows) else path_to_flows
        path_parts = tmp_path.split("/")

        for i in range(len(path_parts)):
            partial_path = "/".join(path_parts[:i + 1])
            if zipfile.is_zipfile(partial_path):
                result = self._handle_zip_file(partial_path, "/".join(path_parts[i + 1:]))
                break
        else:
            result = tmp_path
            base_dir = os.path.dirname(result)
            if base_dir not in sys.path:
                sys.path.insert(0, base_dir)

        return result

    @staticmethod
    def _handle_zip_file(zip_path: str, sub_path: str):
        working_directory = os.getcwd()
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(working_directory)
        base_dir = os.path.join(working_directory, sub_path.split('/')[0])
        if base_dir not in sys.path:
            sys.path.insert(0, base_dir)
        return os.path.join(working_directory, sub_path)

    @staticmethod
    def _get_module_names_from_package(directory_path: str | Path) -> List[str]:
        module_names: List[str] = []
        with os.scandir(directory_path) as entries:
            for entry in entries:
                match = re.match(r"(\w+)\.py", entry.name)
                if not match:
                    continue
                module_name = match.group(1)
                module_names.append(module_name)
        return module_names

    @staticmethod
    def _get_phases_from_module(module: object) -> List[Tuple[str, Type[IBigQueryStage]]]:
        phases: List[Tuple[str, Type[IBigQueryStage]]] = []
        for name, obj in inspect.getmembers(module, inspect.isclass):
            if issubclass(obj, IBigQueryStage) and obj is not IBigQueryStage:
                phases.append((name, obj))
        return phases

    def _get_phases_from_package(self, flow_name: str) -> List[Tuple[str, Type[BigQueryStage]]]:
        phases: List[Tuple[str, Any]] = []
        for stage_type in self._get_module_names_from_package(os.path.join(self._path_to_flows, flow_name)):
            module_path = f"{self._flows_dir_name}.{flow_name}.{stage_type}"

            try:
                module = importlib.import_module(module_path)
                phase = self._get_phases_from_module(module)
                phases.extend(phase)
            except ModuleNotFoundError as e:
                self._logger.error(f"Cannot import the module {module_path}: {e}")
        return phases

    def _get_stages_to_execute(self):
        for flow_name in os.listdir(self._path_to_flows):
            if not self._flows_to_execute or flow_name in self._flows_to_execute:
                pipeline_phases: List[Tuple[str, Type[BigQueryStage]]] = self._get_phases_from_package(flow_name)
                for _, stage_class in pipeline_phases:
                    stage_instance = stage_class(
                        self._scripts_by_flow[flow_name],
                        self._conf,
                        self._bq_client,
                        self._execution_type,
                        self._granularity,
                    )
                    self._stages_list.append((flow_name, stage_instance))

    def execute(self):
        for flow_name, stage in self._stages_list:
            self._context.entity = flow_name
            self._logger.info(f"Executing stage for flow: {flow_name}")
            try:
                stage.execute()
            except Exception as e:
                self._context.errors["PipelineExecution"] = str(get_error(e))
                self._logger.error(f"Error executing pipeline for flow {flow_name}: {e}")
            self._context.reset()
            self._logger.info(f"The ETL: {flow_name} has finished")

        self._resume = deepcopy(self._context.resume())
        self._logger.info(f"Finished executing pipelines: {self._resume}")
