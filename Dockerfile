FROM ubuntu:jammy
LABEL maintainer="Troy Kinsella <troy.kinsella@gmail.com>"

COPY assets/* /opt/resource/
COPY files/bionic.asc /etc/apt/trusted.gpg.d/

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -y; \
    apt-get install -y \
      apt-transport-https \
      curl \
      gnupg \
      jq; \
    apt-get clean all; \
    rm -rf /var/lib/apt/lists/*; \
    chmod 644 /etc/apt/trusted.gpg.d/bionic.asc

