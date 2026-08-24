ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:latest
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest

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

FROM $RUNTIME
WORKDIR /

COPY --from=builder /tmp/controller /controller

LABEL \
  com.redhat.component="openshift-pipelines-multikueue-plugin-rhel9-container" \
  cpe="cpe:/a:redhat:openshift_pipelines:next::" \
  description="Red Hat OpenShift Pipelines multikueue-plugin controller" \
  io.k8s.description="Red Hat OpenShift Pipelines multikueue-plugin controller" \
  io.k8s.display-name="Red Hat OpenShift Pipelines multikueue-plugin controller" \
  io.openshift.tags="tekton,openshift,multikueue-plugin,controller" \
  maintainer="pipelines-extcomm@redhat.com" \
  name="openshift-pipelines/pipelines-multikueue-plugin-rhel9" \
  summary="Red Hat OpenShift Pipelines multikueue-plugin controller" \
  version="next"

RUN microdnf install -y shadow-utils && \
  groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/controller"]
