ARG GO_BUILDER=registry.access.redhat.com/ubi10/go-toolset:latest@sha256:05f3da136a4dbe077f30606e2e53a4f5cab185989c98309823ea06a9a1c52a50
ARG UBI_RUNTIME=registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:fb2f7f857cc60d88e3fad19da505083a682ca4569d7b55a61f64aaa43641f741

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
