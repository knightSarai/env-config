FROM ubuntu:jammy AS base
WORKDIR /usr/local/bin
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common curl git build-essential sudo && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y curl git ansible build-essential vim && \
    apt-get clean autoclean && \
    apt-get autoremove --yes

FROM base AS knight
ARG TAGS
RUN addgroup --gid 1000 knight
RUN adduser --gecos knight --uid 1000 --gid 1000 --disabled-password knight

RUN echo 'knight ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER knight
WORKDIR /home/knight

FROM knight
COPY . .

RUN echo 'function ansible_run() { sudo -E ansible-playbook --tags "$1" --vault-password-file /home/knight/.vault-pass.txt setup.yml; }' >> /home/knight/.bashrc

