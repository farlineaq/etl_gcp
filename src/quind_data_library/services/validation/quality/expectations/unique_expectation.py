from typing import List

from quind_data_library.utils.interfaces.quality_expectation import Expectation


class UniqueExpectation(Expectation):
    """
    Validates that the combinations of values across specified columns are unique.

    This expectation is crucial for ensuring data integrity, especially in scenarios where a
    combination of columns serves as a composite key or when uniqueness across certain fields
    is required. It verifies that no two rows have the same combination of values in the specified
    columns.

    Attributes:
        columns (List[str]): The list of column names whose combined values are expected to be unique.
    """
    description = "Expect the compound columns to be unique"

    def __init__(self, columns: List[str]):
        super().__init__(columns)

    def validate(self):
        """
        Executes the validation check to ensure the uniqueness of combined column values.

        This method applies the validation rule using the Great Expectations validator to check
        that the compound columns specified during initialization have unique combinations of values
        across all rows in the dataset. It uses the expectation `expect_compound_columns_to_be_unique`
        provided by Great Expectations to perform this validation.

        """
        self.validator.expect_compound_columns_to_be_unique(
            self.columns,
            meta={"expectation_name": self.expectation_name, "description": self.description, "column": self.columns}
        )
