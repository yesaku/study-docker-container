FROM alpine:3.23

RUN apk add --no-cache bash curl netcat-openbsd redis jq git

RUN git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core \
    && git clone --depth 1 https://github.com/bats-core/bats-support.git /opt/bats-support \
    && git clone --depth 1 https://github.com/bats-core/bats-assert.git /opt/bats-assert

WORKDIR /tests
ENTRYPOINT ["bats"]
CMD ["--recursive", "/tests"]
