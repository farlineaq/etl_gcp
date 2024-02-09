from typing import List

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class RegexExpectation(Expectation):
    description = "Expect the column values to match a regex pattern"

    def __init__(self, columns: List[str], pattern: str):
        super().__init__(columns)
        self.pattern: str = pattern

    def validate(self):
        for column in self.columns:
            self.validator.expect_column_values_to_match_regex(
                column,
                self.pattern,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
