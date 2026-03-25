# syntax=docker/dockerfile:1
 
ARG GOOCI_VERSION=v0.0.7
 
 
# ── builder ────────────────────────────────────────────────────────────────────
FROM golang:1.25-alpine AS builder
 
ARG GOOCI_VERSION=v0.0.7
# All CCF plugins and policies
ARG PLUGINS="\
  ghcr.io/compliance-framework/plugin-k8s:v0.1.2 \
  ghcr.io/compliance-framework/plugin-k8s-opres-policies:v0.1.1 \
  ghcr.io/compliance-framework/plugin-cloud-custodian:v0.1.1 \
  ghcr.io/compliance-framework/plugin-cloud-custodian-policies:v0.1.0"
 
RUN go install github.com/compliance-framework/gooci@${GOOCI_VERSION}
 
WORKDIR /plugins
 
RUN for ref in $PLUGINS; do \
      name=$(echo "$ref" | sed 's|.*/||; s|:.*||'); \
      echo "Downloading $ref -> /plugins/$name"; \
      gooci download "$ref" "/plugins/$name"; \
    done
 
# Repack any policy directories (those containing .rego files) back into bundle.tar.gz
RUN for dir in /plugins/*/; do \
      if find "$dir" -name "*.rego" | grep -q .; then \
        echo "Repacking $dir -> bundle.tar.gz"; \
        tar -czf "${dir}bundle.tar.gz" -C "$dir" .; \
        find "$dir" -not -name "bundle.tar.gz" -not -path "$dir" -delete; \
      fi; \
    done
 
RUN chmod -R 755 /plugins
 
# ── runtime ────────────────────────────────────────────────────────────────────
FROM alpine:3.20
 
COPY --from=builder /plugins /plugins
 
CMD ["sleep", "infinity"]
