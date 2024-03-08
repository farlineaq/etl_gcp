from typing import List

from quind_data_library.utils.interfaces.quality_expectation import Expectation


class NotNullExpectation(Expectation):
    """
    Validates that the values of specified columns are not null.

    This expectation ensures that each value in the specified columns is not null, allowing for
    a percentage of null values as specified by the 'mostly' parameter. It's useful for ensuring data
    quality and integrity by verifying that critical data fields do not contain null values.

    Attributes:
        columns (List[str]): The list of column names to validate for non-null values.
        mostly (float): A threshold indicating the proportion of values in each column that must be non-null.
                        The value should be between 0 and 1, inclusive, where 1 means 100% non-null is expected.
    """
    description = "Expect the column values to not be null"

    def __init__(self, columns: List[str], mostly: float = 1):
        """
        Initializes a new instance of the NotNullExpectation.

        Args:
            columns (List[str]): The list of column names to validate for non-null values.
            mostly (float, optional): A threshold for the proportion of non-null values required in each column.
                                      Defaults to 1, meaning all values must be non-null.
        """
        super().__init__(columns)
        self.mostly: float = mostly

    def validate(self):
        """
        Executes the validation checks against the columns using the validator.

        This method applies the validation rule to each specified column, using the Great Expectations
        validator to check that the values are not null, according to the 'mostly' threshold. It helps
        in maintaining data quality by ensuring that necessary data fields do not contain null values.
        """
        for column in self.columns:
            self.validator.expect_column_values_to_not_be_null(
                column,
                mostly=self.mostly,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
