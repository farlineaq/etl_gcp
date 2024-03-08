from typing import Callable

from pyspark.sql import DataFrame
from pyspark.sql.streaming import DataStreamWriter

from quind_data_library.pipeline.stages import Load


class LoadStage(Load):
    def execute(self, dataframe: DataFrame, transform: Callable[..., None]) -> DataStreamWriter | None:
        ...
