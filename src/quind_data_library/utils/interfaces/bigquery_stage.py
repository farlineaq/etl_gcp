from abc import ABC, abstractmethod


class IBigQueryStage(ABC):
    @abstractmethod
    def execute(self, *args):
        pass
