from typing import List

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class NotNullExpectation(Expectation):
    description = "Expect the column values to not be null"

    def __init__(self, columns: List[str], mostly: float = 1):
        super().__init__(columns)
        self.mostly: float = mostly

    def validate(self):
        for column in self.columns:
            self.validator.expect_column_values_to_not_be_null(
                column,
                mostly=self.mostly,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
