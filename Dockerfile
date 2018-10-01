FROM ubuntu:bionic
LABEL maintainer="Troy Kinsella <troy.kinsella@gmail.com>"

COPY assets/* /opt/resource/

RUN set -eux; \
    apt-get update -y; \
    apt-get install -y \
      apt-transport-https \
      curl \
      jq;
