# Test image only: a bare Ubuntu 24.04 (same base as Pop!_OS 24.04) with a normal user.
# The repo is bind-mounted at runtime by test/run.sh, nothing is copied in.
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
# archive.ubuntu.com is very slow from some regions; test/run.sh passes a closer mirror.
ARG APT_MIRROR=archive.ubuntu.com/ubuntu
RUN sed -i -e "s|http://archive.ubuntu.com/ubuntu/|http://${APT_MIRROR}/|g" \
           -e "s|http://security.ubuntu.com/ubuntu/|http://${APT_MIRROR}/|g" /etc/apt/sources.list.d/ubuntu.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends sudo ca-certificates curl git python3 pipx locales \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# noble ships a default 'ubuntu' user at uid 1000; replace it with ours so bind-mounted
# files (owned by the host uid 1000) belong to the test user.
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupadd --gid 1000 knight \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash knight \
 && echo 'knight ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/knight \
 && chmod 0440 /etc/sudoers.d/knight

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 USER=knight HOME=/home/knight
USER knight
WORKDIR /home/knight
