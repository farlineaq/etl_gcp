from typing import List

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class UniqueExpectation(Expectation):
    description = "Expect the compound columns to be unique"

    def __init__(self, columns: List[str]):
        super().__init__(columns)

    def validate(self):
        self.validator.expect_compound_columns_to_be_unique(
            self.columns,
            meta={"expectation_name": self.expectation_name, "description": self.description, "column": self.columns}
        )
