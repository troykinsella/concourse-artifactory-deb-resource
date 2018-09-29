FROM ubuntu:bionic

RUN set -eux; \
    apt-get update -y; \
    apt-get install -y \
      apt-transport-https \
      curl \
      jq;

