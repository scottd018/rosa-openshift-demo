.DEFAULT_GOAL := help

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

#admin-install: @ Install the GitOps Operator
admin-install:
	@echo "installing gitops operator (argo)"
	@oc apply -f $(ADMIN_DIR)/setup/install.yaml

#admin-config: @ Configure the GitOps Operator to point at cluster configs in Git
admin-config:
	@echo "installing cluster configs from git"
	@oc apply -f $(ADMIN_DIR)/setup/config.yaml

#
# developer tasks
#
APP_NAME ?= demo-app

#code-clean: @ Delete the microservice code
code-clean:
	@echo "deleting current microservice"
	@rm -rf $(APP_NAME)

#code-create: @ Create a new microservice
code-create: clean
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

#code-deploy: @ Deploy the microservice to a cluster
code-deploy:
	@echo "deploying microservice"
	@kn func deploy -p $(APP_NAME) -n $(APP_NAME) --build=false -v
