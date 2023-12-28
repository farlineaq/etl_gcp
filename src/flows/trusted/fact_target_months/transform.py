from typing import Callable, Any

from pyspark.sql import DataFrame

from bubbaloo.pipeline.stages import Transform


class TransformStage(Transform):
    def execute(self, *args) -> Callable[..., Any]:
        def batch_func(dataframe: DataFrame, batch_id: int):
            ...

        return batch_func
