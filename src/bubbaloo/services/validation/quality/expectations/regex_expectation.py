from typing import List

from bubbaloo.utils.interfaces.quality_expectation import Expectation


class RegexExpectation(Expectation):
    """
    Validates that the values of specified columns match a given regular expression pattern.

    This expectation checks each value in the specified columns to ensure it conforms to a defined
    regex pattern. It's useful for validating string formats, such as phone numbers, email addresses,
    or other standardized data entries that follow a specific pattern.

    Attributes:
        columns (List[str]): The list of column names to validate against the regex pattern.
        pattern (str): The regular expression pattern that column values are expected to match.
    """
    description = "Expect the column values to match a regex pattern"

    def __init__(self, columns: List[str], pattern: str):
        """
        Initializes a new instance of the RegexExpectation.

        Args:
            columns (List[str]): The list of column names to validate against the regex pattern.
            pattern (str): The regular expression pattern that column values are expected to match.
        """
        super().__init__(columns)
        self.pattern: str = pattern

    def validate(self):
        """
        Executes the validation checks against the columns using the validator.

        For each specified column, this method applies the validation rule using the Great Expectations
        validator. It checks that all values in the column match the specified regular expression pattern,
        contributing to data quality assurance by ensuring data format consistency.

        """
        for column in self.columns:
            self.validator.expect_column_values_to_match_regex(
                column,
                self.pattern,
                meta={"expectation_name": self.expectation_name, "description": self.description, "column": column}
            )
