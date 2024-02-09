from pyspark.sql import DataFrame

from quind_data_library.pipeline.stages import Extract


class ExtractStage(Extract):
    def execute(self) -> DataFrame:
        ...
