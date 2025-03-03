#!make

TARGETS         := darwin/amd64 linux/amd64 windows/amd64
BINNAME         ?= osm
DIST_DIRS       := find * -type d -exec
CTR_REGISTRY    ?= openservicemesh
CTR_TAG         ?= latest
CTR_DIGEST_FILE ?= /tmp/osm_image_digest_$(CTR_TAG).txt
VERIFY_TAGS     ?= false

GOPATH = $(shell go env GOPATH)
GOBIN  = $(GOPATH)/bin
GOX    = go run github.com/mitchellh/gox
SHA256 = sha256sum
ifeq ($(shell uname),Darwin)
	SHA256 = shasum -a 256
endif

VERSION ?= dev
BUILD_DATE ?=
GIT_SHA=$$(git rev-parse HEAD)
BUILD_DATE_VAR := github.com/openservicemesh/osm/pkg/version.BuildDate
BUILD_VERSION_VAR := github.com/openservicemesh/osm/pkg/version.Version
BUILD_GITCOMMIT_VAR := github.com/openservicemesh/osm/pkg/version.GitCommit
DOCKER_GO_VERSION = 1.17
DOCKER_BUILDX_PLATFORM ?= linux/amd64
# Value for the --output flag on docker buildx build.
# https://docs.docker.com/engine/reference/commandline/buildx_build/#output
DOCKER_BUILDX_OUTPUT ?= type=registry

LDFLAGS ?= "-X $(BUILD_DATE_VAR)=$(BUILD_DATE) -X $(BUILD_VERSION_VAR)=$(VERSION) -X $(BUILD_GITCOMMIT_VAR)=$(GIT_SHA) -s -w"

# These two values are combined and passed to go test
E2E_FLAGS ?= -installType=KindCluster
E2E_FLAGS_DEFAULT := -test.v -ginkgo.v -ginkgo.progress -ctrRegistry $(CTR_REGISTRY) -osmImageTag $(CTR_TAG)

# Installed Go version
# This is the version of Go going to be used to compile this project.
# It will be compared with the minimum requirements for OSM.
GO_VERSION_MAJOR = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f1)
GO_VERSION_MINOR = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f2)
GO_VERSION_PATCH = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f3)
ifeq ($(GO_VERSION_PATCH),)
GO_VERSION_PATCH := 0
endif

check-env:
ifndef CTR_REGISTRY
	$(error CTR_REGISTRY environment variable is not defined; see the .env.example file for more information; then source .env)
endif
ifndef CTR_TAG
	$(error CTR_TAG environment variable is not defined; see the .env.example file for more information; then source .env)
endif

.PHONY: build-osm
build-osm: cmd/cli/chart.tgz
	CGO_ENABLED=0 go build -v -o ./bin/osm -ldflags ${LDFLAGS} ./cmd/cli

cmd/cli/chart.tgz: scripts/generate_chart/generate_chart.go $(shell find charts/osm)
	go run $< > $@

.PHONY: clean-osm
clean-osm:
	@rm -rf bin/osm

.PHONY: codegen
codegen:
	./codegen/gen-crd-client.sh

.PHONY: chart-readme
chart-readme:
	go run github.com/norwoodj/helm-docs/cmd/helm-docs -c charts -t charts/osm/README.md.gotmpl

.PHONY: chart-check-readme
chart-check-readme: chart-readme
	@git diff --exit-code charts/osm/README.md || { echo "----- Please commit the changes made by 'make chart-readme' -----"; exit 1; }

.PHONY: helm-lint
helm-lint:
	@helm lint charts/osm/ || { echo "----- Schema validation failed for OSM chart values -----"; exit 1; }

.PHONY: chart-checks
chart-checks: chart-check-readme helm-lint

.PHONY: check-mocks
check-mocks:
	@go run ./mockspec/generate.go
	@git diff --exit-code || { echo "----- Please commit the changes made by 'go run ./mockspec/generate.go' -----"; exit 1; }

.PHONY: check-codegen
check-codegen:
	@./codegen/gen-crd-client.sh
	@git diff --exit-code || { echo "----- Please commit the changes made by './codegen/gen-crd-client.sh' -----"; exit 1; }

.PHONY: go-checks
go-checks: go-lint go-fmt go-mod-tidy check-mocks check-codegen

.PHONY: go-vet
go-vet:
	go vet ./...

.PHONY: go-lint
go-lint: embed-files-test
	docker run --rm -v $$(pwd):/app -w /app golangci/golangci-lint:v1.41.1 golangci-lint run --config .golangci.yml

.PHONY: go-fmt
go-fmt:
	go fmt ./...

.PHONY: go-mod-tidy
go-mod-tidy:
	./scripts/go-mod-tidy.sh

.PHONY: go-test
go-test:
	./scripts/go-test.sh

.PHONY: go-test-coverage
go-test-coverage: embed-files
	./scripts/test-w-coverage.sh

.PHONY: kind-up
kind-up:
	./scripts/kind-with-registry.sh

.PHONY: kind-reset
kind-reset:
	kind delete cluster --name osm

.PHONY: test-e2e
test-e2e: DOCKER_BUILDX_OUTPUT=type=docker
test-e2e: docker-build-osm build-osm docker-build-tcp-echo-server
	go test ./tests/e2e $(E2E_FLAGS_DEFAULT) $(E2E_FLAGS)

.env:
	cp .env.example .env

.PHONY: kind-demo
kind-demo: export CTR_REGISTRY=localhost:5000
kind-demo: .env kind-up clean-osm
	./demo/run-osm-demo.sh

.PHONE: build-bookwatcher
build-bookwatcher:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ./demo/bin/bookwatcher/bookwatcher ./demo/cmd/bookwatcher

DEMO_TARGETS = bookbuyer bookthief bookstore bookwarehouse tcp-echo-server tcp-client
# docker-build-bookbuyer, etc
DOCKER_DEMO_TARGETS = $(addprefix docker-build-, $(DEMO_TARGETS))
.PHONY: $(DOCKER_DEMO_TARGETS)
$(DOCKER_DEMO_TARGETS): NAME=$(@:docker-build-%=%)
$(DOCKER_DEMO_TARGETS):
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/$(NAME):$(CTR_TAG) -f dockerfiles/Dockerfile.demo --build-arg GO_VERSION=$(DOCKER_GO_VERSION) --build-arg BINARY=$(NAME) .

.PHONY: docker-build-demo
docker-build-demo: $(DOCKER_DEMO_TARGETS)

.PHONY: docker-build-init
docker-build-init:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/init:$(CTR_TAG) - < dockerfiles/Dockerfile.init

.PHONY: docker-build-osm-controller
docker-build-osm-controller:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/osm-controller:$(CTR_TAG) -f dockerfiles/Dockerfile.osm-controller --build-arg GO_VERSION=$(DOCKER_GO_VERSION) --build-arg LDFLAGS=$(LDFLAGS) .

.PHONY: docker-build-osm-injector
docker-build-osm-injector:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/osm-injector:$(CTR_TAG) -f dockerfiles/Dockerfile.osm-injector --build-arg GO_VERSION=$(DOCKER_GO_VERSION) --build-arg LDFLAGS=$(LDFLAGS) .

.PHONY: docker-build-osm-crds
docker-build-osm-crds:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/osm-crds:$(CTR_TAG) -f dockerfiles/Dockerfile.osm-crds ./cmd/osm-bootstrap/crds

.PHONY: docker-build-osm-bootstrap
docker-build-osm-bootstrap:
	docker buildx build --builder osm --platform=$(DOCKER_BUILDX_PLATFORM) -o $(DOCKER_BUILDX_OUTPUT) -t $(CTR_REGISTRY)/osm-bootstrap:$(CTR_TAG) -f dockerfiles/Dockerfile.osm-bootstrap --build-arg GO_VERSION=$(DOCKER_GO_VERSION) --build-arg LDFLAGS=$(LDFLAGS) .

OSM_TARGETS = init osm-controller osm-injector osm-crds osm-bootstrap
DOCKER_OSM_TARGETS = $(addprefix docker-build-, $(OSM_TARGETS))

.PHONY: docker-build-osm
docker-build-osm: $(DOCKER_OSM_TARGETS)

.PHONY: buildx-context
buildx-context:
	@if ! docker buildx ls | grep -q "^osm "; then docker buildx create --name osm --driver-opt network=host; fi

check-image-exists-%: NAME=$(@:check-image-exists-%=%)
check-image-exists-%:
	@if [ "$(VERIFY_TAGS)" = "true" ]; then scripts/image-exists.sh $(CTR_REGISTRY)/$(NAME):$(CTR_TAG); fi

$(foreach target,$(OSM_TARGETS) $(DEMO_TARGETS),$(eval docker-build-$(target): check-image-exists-$(target) buildx-context))

docker-digest-%: NAME=$(@:docker-digest-%=%)
docker-digest-%:
	@docker buildx imagetools inspect $(CTR_REGISTRY)/$(NAME):$(CTR_TAG) --raw | $(SHA256) | awk '{print "$(NAME): sha256:"$$1}'

.PHONY: docker-digests-osm
docker-digests-osm: $(addprefix docker-digest-, $(OSM_TARGETS))

.PHONY: docker-build
docker-build: docker-build-osm docker-build-demo

.PHONY: docker-build-cross-osm docker-build-cross-demo docker-build-cross
docker-build-cross-osm: DOCKER_BUILDX_PLATFORM=linux/amd64,linux/arm64
docker-build-cross-osm: docker-build-osm
docker-build-cross-demo: DOCKER_BUILDX_PLATFORM=linux/amd64,windows/amd64
docker-build-cross-demo: docker-build-demo
docker-build-cross: docker-build-cross-osm docker-build-cross-demo

.PHONY: embed-files
embed-files: cmd/cli/chart.tgz

.PHONY: embed-files-test
embed-files-test:
	./scripts/generate-dummy-embed.sh

.PHONY: build-ci
build-ci: embed-files
	go build -v ./...

.PHONY: clean-image-digest
clean-image-digest:
	@rm -f "$(CTR_DIGEST_FILE)"

trivy-scan-images:
	wget https://github.com/aquasecurity/trivy/releases/download/v0.18.0/trivy_0.18.0_Linux-64bit.tar.gz
	tar zxvf trivy_0.18.0_Linux-64bit.tar.gz

	# Show all vulnerabilities in logs
	./trivy $(CTR_REGISTRY)/osm-controller:$(CTR_TAG)
	./trivy $(CTR_REGISTRY)/osm-injector:$(CTR_TAG)
	./trivy $(CTR_REGISTRY)/init:$(CTR_TAG)
	./trivy $(CTR_REGISTRY)/osm-bootstrap:$(CTR_TAG)
	./trivy $(CTR_REGISTRY)/osm-crds:$(CTR_TAG)

	# Exit if vulnerability exists
	./trivy --exit-code 1 --ignore-unfixed --severity MEDIUM,HIGH,CRITICAL "$(CTR_REGISTRY)/osm-controller:$(CTR_TAG)" || exit 1
	./trivy --exit-code 1 --ignore-unfixed --severity MEDIUM,HIGH,CRITICAL "$(CTR_REGISTRY)/osm-injector:$(CTR_TAG)" || exit 1
	./trivy --exit-code 1 --ignore-unfixed --severity MEDIUM,HIGH,CRITICAL "$(CTR_REGISTRY)/init:$(CTR_TAG)" || exit 1
	./trivy --exit-code 1 --ignore-unfixed --severity MEDIUM,HIGH,CRITICAL "$(CTR_REGISTRY)/osm-bootstrap:$(CTR_TAG)" || exit 1
	./trivy --exit-code 1 --ignore-unfixed --severity MEDIUM,HIGH,CRITICAL "$(CTR_REGISTRY)/osm-crds:$(CTR_TAG)" || exit 1

.PHONY: shellcheck
shellcheck:
	shellcheck -x $(shell find . -name '*.sh')

.PHONY: install-git-pre-push-hook
install-git-pre-push-hook:
	./scripts/install-git-pre-push-hook.sh

# -------------------------------------------
#  release targets below
# -------------------------------------------

.PHONY: build-cross
build-cross: cmd/cli/chart.tgz
	GO111MODULE=on CGO_ENABLED=0 $(GOX) -ldflags $(LDFLAGS) -parallel=3 -output="_dist/{{.OS}}-{{.Arch}}/$(BINNAME)" -osarch='$(TARGETS)' ./cmd/cli

.PHONY: dist
dist:
	( \
		cd _dist && \
		$(DIST_DIRS) cp ../LICENSE {} \; && \
		$(DIST_DIRS) cp ../README.md {} \; && \
		$(DIST_DIRS) tar -zcf osm-${VERSION}-{}.tar.gz {} \; && \
		$(DIST_DIRS) zip -r osm-${VERSION}-{}.zip {} \; && \
		$(SHA256) osm-* > sha256sums.txt \
	)

.PHONY: release-artifacts
release-artifacts: build-cross dist
