from typing import Any, Dict
from google.cloud import bigquery
from google.cloud.bigquery import Client


class BigQueryClient:
    _instance = None

    def __new__(cls, project: str, credentials: str = None, **kwargs):
        if not cls._instance:
            cls._instance = super(BigQueryClient, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, project: str, credentials: str = None, **kwargs) -> None:
        if not self._initialized:
            self.project: str = project
            if credentials is None:
                self._client: Client = bigquery.Client(self.project, **kwargs) # noqa
            else:
                self._client: Client = bigquery.Client.from_service_account_json(credentials)
            self._initialized = True

    def sql(
            self,
            query: str,
            query_parameters: Dict[str, Any] | None = None,
            wait: bool = False,
            **kwargs
    ) -> bigquery.job.QueryJob | bigquery.table.RowIterator:

        query = query.format(**query_parameters) if query_parameters is not None else query

        if wait:
            return self._client.query_and_wait(query, **kwargs)
        else:
            return self._client.query(query, **kwargs)

    def create_routine_from_ddl_if_not_exists(
            self,
            routine_reference: str,
            query: str,
            query_parameters: Dict[str, Any] | None = None,
            **kwargs
    ) -> bigquery.routine.RoutineReference:

        dataset = routine_reference.split(".")[1]

        for item in self._client.list_routines(dataset):
            if str(item.reference) == routine_reference:
                return item.reference

        query_job = self.sql(query, query_parameters, **kwargs)
        query_job.result()

        return query_job.ddl_target_routine
