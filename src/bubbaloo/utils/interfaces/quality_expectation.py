from abc import ABC, abstractmethod
from typing import List

from great_expectations.validator.validator import Validator


class Expectation(ABC):
    description: str

    def __init__(self, columns: List[str]):
        self.columns: List[str] = columns
        self.validator: Validator | None = None

    def __call__(self, validator: Validator):
        self.validator = validator
        self.expectation_name = self.__class__.__name__
        self.validate()

    @abstractmethod
    def validate(self):
        pass
