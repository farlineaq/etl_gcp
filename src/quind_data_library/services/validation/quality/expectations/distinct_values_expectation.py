from typing import List, Any

from quind_data_library.utils.interfaces.quality_expectation import Expectation


class DistinctValuesExpectation(Expectation):
    """
    Validates that the distinct values of specified columns are within a predefined set.

    This expectation is used to ensure that the distinct values found in one or more columns
    of a DataFrame are only those that belong to a specified set of allowed values. It's
    particularly useful for validating categorical data, ensuring data integrity and consistency.

    Attributes:
        columns (List[str]): The list of column names to validate.
        value_set (List[Any]): The set of values that are allowed for the specified columns.
    """
    description = "Expect the column distinct values to be in a set"

    def __init__(self, columns: List[str], value_set: List[Any]):
        """
        Initializes a new instance of the DistinctValuesExpectation.

        Args:
            columns (List[str]): The list of column names to validate.
            value_set (List[Any]): The set of values that are allowed for the specified columns.
        """
        super().__init__(columns)
        self.value_set: List[Any] = value_set

    def validate(self):
        """
        Executes the validation checks against the columns using the validator.

        For each specified column, this method uses the Great Expectations validator to check
        that all distinct values in the column are part of the predefined set (`value_set`). The
        results of these validations are automatically tracked by the Great Expectations framework.
        """
        for column in self.columns:
            self.validator.expect_column_distinct_values_to_be_in_set(
                column,
                self.value_set,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
