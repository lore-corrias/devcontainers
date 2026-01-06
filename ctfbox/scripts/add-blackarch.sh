#!/bin/bash

set -euo pipefail

CHECKSUM_INSTALL_SCRIPT="00688950aaf5e5804d2abebb8d3d3ea1d28525ed"

curl https://blackarch.org/strap.sh -o /tmp/strap.sh && \
  echo "$CHECKSUM_INSTALL_SCRIPT" /tmp/strap.sh | sha1sum -c && \
  chmod +x /tmp/strap.sh && \
  /tmp/strap.sh && \
  rm -f /tmp/strap.sh
