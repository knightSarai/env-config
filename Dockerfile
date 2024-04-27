FROM ubuntu:jammy
WORKDIR /usr/local/bin
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y software-properties-common && apt-add-repository -y ppa:ansible/ansible && apt update && apt install -y curl git ansible build-essential
RUN apt install -y sudo

COPY . .

