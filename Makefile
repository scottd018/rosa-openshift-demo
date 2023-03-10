.DEFAULT_GOAL := help

ROSA_CLUSTER_NAME ?= poc-dscott
ROSA_CLUSTER_OCP_VERSION ?= 4.12.0

#help: @ List available tasks on this project
.PHONY: help
help:
	@echo "HELP TASKS:"
	@echo "==========="
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | grep 'help' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\t\033[33m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "ADMIN TASKS:"
	@echo "============"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | grep 'admin-' | awk -F'{admin-}' '{print $$1}' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\t\033[32m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "DEVELOPER TASKS:"
	@echo "================"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | grep 'code-' | awk -F'{code-}' '{print $$1}' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\t\033[31m%-30s\033[0m %s\n", $$1, $$2}'

#
# admin tasks
#
ADMIN_DIR ?= demo-admin

#admin-cluster-create: @ Create cluster for demo
admin-cluster-create:
	rosa create cluster \
        	--cluster-name="$(ROSA_CLUSTER_NAME)" \
        	--sts \
        	--multi-az \
        	--enable-autoscaling \
        	--version="$(ROSA_CLUSTER_OCP_VERSION)" \
        	--min-replicas=3 \
        	--max-replicas=6 \
        	--compute-machine-type="t3.xlarge" \
        	--machine-cidr="10.10.0.0/16" \
        	--service-cidr="172.30.0.0/16" \
        	--pod-cidr="10.128.0.0/14" \
        	--host-prefix=23 \
        	--mode=auto \
        	-y

#admin-auth-setup: @ Setup cluster authentication prior to install/config
admin-auth-setup:
	@echo "setting up 'admin' account (htpasswd auth)"
	@rosa create idp \
		--cluster=$(ROSA_CLUSTER_NAME) \
		--name=admin \
		--type=htpasswd \
		--username=admin \
		--password="$$(bw get password rosa-admin-password)"
	@rosa grant user cluster-admin \
		--user=admin \
		--cluster=$(ROSA_CLUSTER_NAME)

	@echo "setting up 'developer' account (gitlab auth)"
	@rosa create idp \
		--cluster=$(ROSA_CLUSTER_NAME) \
		--name=developer \
		--type=gitlab \
		--host-url="$$(bw get uri rosa-gitlab-token)" \
		--client-id="$$(bw get username rosa-gitlab-token)" \
		--client-secret="$$(bw get password rosa-gitlab-token)"

#admin-gitops-install: @ Install the GitOps Operator
admin-gitops-install:
	@echo "installing gitops operator (argo)"
	@oc apply -f $(ADMIN_DIR)/setup/install.yaml

#admin-gitops-config: @ Configure the GitOps Operator to point at cluster configs in Git
admin-gitops-config:
	@echo "installing cluster configs from git"
	@oc apply -f $(ADMIN_DIR)/setup/config.yaml

#admin-operators-install: @ Install the Serverless/Pipelines operators (non GitOps workflow)
admin-operators-install:
	@echo "installing serverless/pipeline operator"
	@oc apply -f $(ADMIN_DIR)/resources/cluster-configs.yaml

#admin-knative-config: @ Configure Knative
admin-knative-config:
	@echo "configuring the knative operator"
	@oc apply -f $(ADMIN_DIR)/resources/knative-configs.yaml

#
# developer tasks
#
APP_NAME ?= demo-app

#code-clean: @ Delete the microservice code
code-clean:
	@echo "deleting current microservice"
	@rm -rf $(APP_NAME)/*

#code-create: @ Create a new microservice
code-create: code-clean
	@echo "creating a new microservice"
	@kn func create -l go $(APP_NAME) -v

#code-write: @ Simulate a developer writing a new microservice with an example from the 'snippets/' directory
code-write:
	@echo "copying pre-built code from 'snippets/' to simulate a developer writing code"
	@cp snippets/handle.go.txt $(APP_NAME)/handle.go
	@cp snippets/handle_test.go.txt $(APP_NAME)/handle_test.go

#code-test-unit: @ Run go unit tests against the microservice
code-test-unit:
	@echo "running go unit tests"
	@cd $(APP_NAME) && go test

#code-build: @ Build the microservice as a container image
code-build:
	@echo "building microservice"
	@kn func build -p $(APP_NAME) -v

#code-run: @ Run the microservice locally
code-run:
	@echo "running code"
	@kn func run -p $(APP_NAME) --build=false -v

#code-test-e2e-good: @ Simulate a successful test against a local microservice run
code-test-e2e-good:
	@echo "testing successful microservice request"
	@kn func invoke -p $(APP_NAME) --data '{"name": "chicka chicka slim shady"}' -v

#code-test-e2e-bad: @ Simulate an unsuccessful test against a local microservice run
code-test-e2e-bad:
	@echo "testing unsuccessful microservice request"
	@curl -X GET localhost:8080

#code-pipeline-deploy: @ Deploy the pipeline to a cluster
code-pipeline-deploy:
	@echo "deploying pipeline"
	@oc apply -f demo-pipeline/resources/tasks/
	@oc apply -f demo-pipeline/resources/triggers/
	@oc apply -f demo-pipeline/resources/pipeline.yaml

#code-pipeline-run: @ Run the pipeline against a cluster
code-pipeline-run:
	@echo "running pipeline"
	@oc create -f demo-pipeline/tests/pipeline-run.yaml

#code-deploy: @ Deploy the microservice to a cluster
code-deploy:
	@echo "deploying microservice"
	@kn func deploy -p $(APP_NAME) --build=false -v
