from typing import Callable

from pyspark.sql import DataFrame
from pyspark.sql.streaming import DataStreamWriter

from bubbaloo.pipeline.stages import Load


class LoadStage(Load):
    def execute(self, dataframe: DataFrame, transform: Callable[..., None]) -> DataStreamWriter | None:
        ...
