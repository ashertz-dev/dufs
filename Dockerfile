FROM --platform=linux/amd64 messense/rust-musl-cross:x86_64-musl AS amd64
COPY . .
RUN cargo install --path . --root /

FROM --platform=linux/amd64 messense/rust-musl-cross:aarch64-musl AS arm64
COPY . .
RUN cargo install --path . --root /

FROM ${TARGETARCH} AS builder

FROM debian:bookworm-slim

COPY --from=builder /bin/dufs /bin/dufs

STOPSIGNAL SIGINT

ARG USERNAME=pod
ARG UID=1000

RUN echo "deb http://repo.huaweicloud.com/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://repo.huaweicloud.com/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://repo.huaweicloud.com/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://repo.huaweicloud.com/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    apt update && \
    apt install -y --no-install-recommends \
        procps iproute2 iputils-ping net-tools curl vim less sudo && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash --uid ${UID} ${USERNAME} \
    && echo "${USERNAME}:${USERNAME}" | chpasswd \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

WORKDIR /home/${USERNAME}

ENTRYPOINT ["/bin/dufs"]
