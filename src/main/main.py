from bubbaloo.orchestration import Orchestrator
from bubbaloo.services.local import Logger
from bubbaloo.services.pipeline import Config, PipelineState, GetSpark, ArgumentParser

from flows import trusted


def main():
    parser = ArgumentParser()
    logger = Logger()
    spark = GetSpark()
    conf = Config(env=parser.args.env)
    spark.sparkContext.setLogLevel(conf.log_level)
    state = PipelineState()

    orchestrator = Orchestrator(
        trusted,
        parser.args.entity,
        conf=conf,
        logger=logger,
        spark=spark,
        context=state
    )

    orchestrator.execute()


if __name__ == "__main__":
    main()
