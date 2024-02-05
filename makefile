ENV ?= dev
REGION ?= us-central1
SUBNET ?= default
BUCKET_NAME ?= co-grupo-exito-funnel-mercd-app-data-$(ENV)

TARGET ?= app_files
TEMPLATE_NAME ?= dp-funnel-mercd-workflow-$(ENV)

YAML_PATH := ./deploy/$(ENV)

YAML_FILES := $(wildcard $(YAML_PATH)/*.yaml)

all: clean build workflow

clean:
	@rm -rf ./dist

build: clean
	@echo "Packaging code and dependencies..."
	@mkdir ./dist
	@cp ./src/main/main.py ./dist
	@cp ./src/config/*.toml ./dist
	@cp -r ./src/bubbaloo ./dist && cd ./dist && zip -r bubbaloo.zip bubbaloo && rm -rf bubbaloo
	@cp -r ./src/flows ./dist && cd ./dist && zip -r flows.zip flows && rm -rf flows
	@pip install -r requirements.txt -t ./dist/libs && cd ./dist/libs && zip -r -D ../libs.zip .
	@cd ./dist && rm -rf libs
	@gsutil -m cp -r ./dist gs://$(BUCKET_NAME)/$(TARGET)/
	@echo "Code and dependencies have been packaged successfully"

workflow: $(YAML_FILES)
	$(foreach yaml,$^, \
		gcloud dataproc workflow-templates import $(notdir $(basename $(yaml))) \
			--source=$(yaml) \
			--region=$(REGION) \
			--quiet;)

init:
	@gcloud dataproc workflow-templates instantiate $(flow) \
		--region=$(REGION) \
		--quiet

.PHONY: all clean build workflow init
