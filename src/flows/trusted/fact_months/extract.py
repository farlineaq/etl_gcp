from pyspark.sql import DataFrame

from bubbaloo.pipeline.stages import Extract


class ExtractStage(Extract):
    def execute(self) -> DataFrame:
        ...
