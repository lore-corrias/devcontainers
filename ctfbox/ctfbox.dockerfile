# Builder image for yay and yay packages
FROM docker.io/library/archlinux@sha256:8fe9851fcd8bd23ea0e6bfa99483d8778e40b45e0fd7bb8188c94cbdd8c25a38

ARG USERNAME=lore
ARG USER_UID=1000
ARG USER_GID=1000
ARG SHELL=/bin/zsh

# Copy required scripts to be run
COPY ./ctfbox/scripts/ /scripts/
COPY ./ctfbox/packages/* /packages/

# Install packages
RUN /scripts/install-packages.sh 

# Install locale
RUN /scripts/generate-locale.sh
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

# Add non root user
RUN /scripts/add-user.sh

LABEL com.github.containers.toolbox="true" \
  usage="Use this image with distrobox / podman to have a working environment for solving CTF challenges" \
  summary="CTFs environment for Web challenges" \
  maintainer="lore-corrias"

RUN rm -rf /scripts /packages /tmp/yaybuilt/
