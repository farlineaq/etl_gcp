from typing import Any, Dict
from google.cloud import bigquery
from google.cloud.bigquery import Client


class BigQueryClient:
    """
    A singleton client for interacting with Google BigQuery.

    This class provides a simplified interface for executing queries and managing BigQuery resources
    such as datasets, tables, and routines. It ensures only a single instance of the client is created
    during the application lifecycle, utilizing a singleton pattern.

    Attributes:
        project (str): The Google Cloud project ID to use for BigQuery operations.
        _client (Client): An instance of the Google Cloud BigQuery client.
    """
    _instance = None

    def __new__(cls, project: str, credentials: str = None, **kwargs):
        """
        Creates a new instance of BigQueryClient or returns the existing instance.

        Args:
            project (str): The Google Cloud project ID.
            credentials (str, optional): Path to service account credentials JSON.
            **kwargs: Additional keyword arguments passed to the BigQuery client.

        Returns:
            BigQueryClient: The singleton instance of the client.
        """
        if not cls._instance:
            cls._instance = super(BigQueryClient, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, project: str, credentials: str = None, **kwargs) -> None:
        """
        Initializes the BigQueryClient with project and credentials.

        Args:
            project (str): The Google Cloud project ID.
            credentials (str, optional): Path to service account credentials JSON.
            **kwargs: Additional keyword arguments passed to the BigQuery client.
        """
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
        """
        Executes a SQL query against BigQuery and optionally waits for the result.

        Args:
            query (str): The SQL query to execute.
            query_parameters (Dict[str, Any] | None, optional): Parameters to format the query with.
            wait (bool, optional): Whether to wait for the query to complete. Defaults to False.
            **kwargs: Additional keyword arguments passed to the BigQuery query method.

        Returns:
            bigquery.job.QueryJob | bigquery.table.RowIterator: The query job or row iterator, depending on 'wait'.
        """

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
        """
        Creates a BigQuery routine from DDL if it does not already exist.

        Args:
            routine_reference (str): The fully qualified routine ID in the form `project.dataset.routine`.
            query (str): The DDL query to create the routine.
            query_parameters (Dict[str, Any] | None, optional): Parameters to format the query with.
            **kwargs: Additional keyword arguments passed to the BigQuery query method.

        Returns:
            bigquery.routine.RoutineReference: The reference to the created or existing routine.
        """
        dataset = routine_reference.split(".")[1]

        for item in self._client.list_routines(dataset):
            if str(item.reference) == routine_reference:
                return item.reference

        query_job = self.sql(query, query_parameters, **kwargs)
        query_job.result()

        return query_job.ddl_target_routine
