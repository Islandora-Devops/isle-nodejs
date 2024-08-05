# syntax=docker/dockerfile:1.5.1
FROM alpine

ARG TARGETARCH

RUN --mount=type=cache,id=abuild-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add \
        alpine-sdk \
        bash \
        sudo \
    && \
    adduser -G abuild -g "Alpine Package Builder" -s /bin/ash -D builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV PACKAGER="Nigel Banks <nigel.g.banks@gmail.com>"

USER builder

SHELL ["/bin/bash", "-c"]

ARG TARGETARCH

# Platform specific does require arch specific identifier.
RUN --mount=type=bind,readwrite=true,source=build,target=/build \
    --mount=type=cache,id=nodejs-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    export PACKAGES=(\
        ada-dev \
        base64-dev \
        brotli-dev \
        c-ares-dev \
        icu-dev \
        linux-headers \
        nghttp2-dev \
        openssl-dev \
        py3-jinja2 \
        py3-setuptools \
        python3 \
        samurai \
        zlib-dev \
    ) && \
    sudo apk add "${PACKAGES[@]}" && \
    sudo mkdir -p /packages && \
    sudo chown -R builder /build && \
    cd /build && \
    abuild-keygen -ain && \
    abuild-apk update && \
    abuild && \
    sudo apk del "${PACKAGES[@]}" && \
    sudo mv $(find /home/builder/packages/* -type f) /packages
