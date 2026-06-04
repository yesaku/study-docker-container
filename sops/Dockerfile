FROM alpine:3.23

ARG SOPS_VERSION=3.9.4

# アーキテクチャを自動検出して sops バイナリをインストール
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64)  sops_arch="amd64" ;; \
        aarch64) sops_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac; \
    apk add --no-cache wget; \
    wget -q "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${sops_arch}" \
         -O /usr/local/bin/sops; \
    chmod +x /usr/local/bin/sops; \
    apk del wget; \
    sops --version

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
