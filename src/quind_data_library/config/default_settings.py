from quind_data_library.services.local.logger import Logger
from quind_data_library.services.pipeline.get_spark import GetSpark
from quind_data_library.services.pipeline.state import PipelineState

LOGGER = Logger()
SPARK = GetSpark()
CONTEXT = PipelineState()
PIPELINE_NAME = "Default Pipeline"
