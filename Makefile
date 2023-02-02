FUNC_DIR ?= demo-app
ADMIN_DIR ?= demo-admin

clean:
	rm -rf $(FUNC_DIR)

create: clean
	kn func create -l go $(FUNC_DIR)

write-code:
	@cp snippets/handle.go.txt $(FUNC_DIR)/handle.go
	@cp snippets/handle_test.go.txt $(FUNC_DIR)/handle_test.go

test:
	cd $(FUNC_DIR) && go test

build:
	kn func build -p $(FUNC_DIR)

run:
	kn func run -p $(FUNC_DIR) --build=false

test-e2e-bad:
	curl -X GET localhost:8080

test-e2e-good:
	kn func invoke -p $(FUNC_DIR) --data '{"name": "chicka chicka slim shady"}'

admin-install:
	@echo "installing gitops operator (argo)"
	@oc apply -f $(ADMIN_DIR)/setup/install.yaml

admin-config:
	@echo "installing cluster configs from git"
	@oc apply -f $(ADMIN_DIR)/setup/config.yaml