ARG GO_BUILDER=registry.access.redhat.com/ubi10/go-toolset:latest@sha256:5d2ab83e88506afee6bcc909fdab425ab979725ab30d6ad43a02aaa77e2258ff
ARG UBI_RUNTIME=registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:ab67cd02caf8706e34a695a1432ebe965934f6128ec352a6c3f4048b43a4fb5e

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/pipelines-multikueue-plugin
COPY upstream .
COPY .konflux/patches ./patches
ENV GODEBUG="http2server=0"
ENV GOEXPERIMENT=strictfipsruntime

RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
RUN CGO_ENABLED=1 \
  go build -mod=vendor -tags disable_gcp,strictfipsruntime -v -o /tmp/controller \
  ./cmd/

FROM $UBI_RUNTIME
WORKDIR /

COPY --from=builder /tmp/controller /controller

LABEL \
    com.redhat.component="openshift-pipelines-multikueue-plugin-rhel10-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:nightly::el10" \
    description="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.k8s.description="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.k8s.display-name="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.openshift.tags="tekton,openshift,pipelines-multikueue-plugin,multikueue-plugin" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-multikueue-plugin-rhel10" \
    summary="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    version="nightly"

RUN microdnf install -y shadow-utils && \
  groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/controller"]
