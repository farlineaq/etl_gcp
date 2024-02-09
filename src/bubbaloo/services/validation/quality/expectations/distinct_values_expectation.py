from typing import List, Any

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class DistinctValuesExpectation(Expectation):
    description = "Expect the column distinct values to be in a set"

    def __init__(self, columns: List[str], value_set: List[Any]):
        super().__init__(columns)
        self.value_set: List[Any] = value_set

    def validate(self):
        for column in self.columns:
            self.validator.expect_column_distinct_values_to_be_in_set(
                column,
                self.value_set,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
