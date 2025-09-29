# Building neovim from src
FROM debian:bookworm-slim AS nvim-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG NVIM_VERSION=v0.11.4

# Installing packages needed for building
RUN apt-get update && apt-get install -y --no-install-recommends \
  git ca-certificates curl unzip \
  cmake ninja-build g++ \
  gettext libtool-bin autoconf automake pkg-config make \
  && rm -rf /var/lib/apt/lists/*

# Cloning from source
WORKDIR /src/neovim
RUN git clone --depth 1 --branch "${NVIM_VERSION}" https://github.com/neovim/neovim.git . 

# Build & install into /usr/local
RUN make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/usr/local -j"$(nproc)" \
  && make install

FROM debian:bookworm-slim

ARG USERNAME=lore
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG SHELL=/bin/zsh

# Copy installation scripts inside the container
COPY ./devcontainer/scripts/ /scripts/
COPY ./devcontainer/packages/* /packages/

RUN /scripts/install-packages.sh

# Install locale
RUN /scripts/generate-locale.sh
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

RUN /scripts/add-user.sh # Add non root user

# Add neovim inside the final image
COPY --from=nvim-builder /usr/local/ /usr/local/
ENV PATH="/usr/local/bin:${PATH}" \
  LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

WORKDIR /workspace

RUN rm -rf /scripts/ /packages/

USER lore

LABEL com.github.containers.toolbox="true" \
  usage="Use this image with devpod / podman" \
  summary="My opinionated image to be used for devcontainers with neovim and my dotfiles" \
  maintainer="lore-corrias"
