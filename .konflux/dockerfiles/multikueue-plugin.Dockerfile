ARG GO_BUILDER=registry.redhat.io/ubi9/go-toolset:latest@sha256:4053e919374d739ee6b0007e412d89256b0bd065e0bc690c2b3905bbaab6500e
ARG UBI_RUNTIME=registry.redhat.io/ubi9/ubi-minimal-pqc:latest@sha256:eb807555968d40a35c815329eec6ef52b56a8bb3e6f06c25f7440ead905f8c74

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
    com.redhat.component="openshift-pipelines-multikueue-plugin-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:next::el9" \
    description="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.k8s.description="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.k8s.display-name="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    io.openshift.tags="tekton,openshift,pipelines-multikueue-plugin,multikueue-plugin" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-multikueue-plugin-rhel9" \
    summary="Red Hat OpenShift Pipelines pipelines-multikueue-plugin multikueue-plugin" \
    version="next"

RUN microdnf install -y shadow-utils && \
  groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/controller"]
