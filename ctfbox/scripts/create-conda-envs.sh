#!/bin/bash

set -euo pipefail


# Installing miniconda
mkdir /miniconda && \
  curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
  bash /tmp/miniconda.sh -b -u -p /miniconda && \
  rm -f /tmp/miniconda.sh && \
  /miniconda/bin/conda init && \
  /miniconda/bin/conda init bash && \
  /miniconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
  /miniconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Create env with some common tools
/miniconda/bin/conda create -y -n pwn python=3.12 requests conda-forge::pwntools flask fastapi
