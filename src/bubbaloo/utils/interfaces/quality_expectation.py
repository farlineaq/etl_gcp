from abc import ABC, abstractmethod
from typing import List

from great_expectations.validator.validator import Validator


class Expectation(ABC):
    """
    An abstract base class for defining data quality expectations in Great Expectations.

    This class is designed to be subclassed to create specific data quality checks, which can be
    applied to a dataset using the Great Expectations framework. Each subclass should implement
    the `validate` method to define the specific validation logic.

    Attributes:
        description (str): A human-readable description of the expectation.
        columns (List[str]): The list of columns the expectation applies to.
        validator (Validator | None): The Great Expectations Validator instance used for validation.
        expectation_name (str): The name of the expectation, automatically derived from the class name.
    """
    description: str

    def __init__(self, columns: List[str]):
        """
        Initializes the Expectation with a list of columns to apply the validation to.

        Args:
            columns (List[str]): The list of column names the expectation applies to.
        """
        self.columns: List[str] = columns
        self.validator: Validator | None = None

    def __call__(self, validator: Validator):
        """
        Invokes the expectation against a given Validator instance.

        This method assigns the Validator to the expectation and triggers the validation logic defined
        in `validate`. It should be overridden in subclasses to implement specific validation behavior.

        Args:
            validator (Validator): The Great Expectations Validator instance to use for validation.
        """
        self.validator = validator
        self.expectation_name = self.__class__.__name__
        self.validate()

    @abstractmethod
    def validate(self):
        """
        Defines the validation logic to be implemented by subclasses.

        This abstract method must be overridden in each subclass of `Expectation` to define the specific
        data quality checks to be performed. It will be called automatically when the expectation is invoked.
        """
        pass
