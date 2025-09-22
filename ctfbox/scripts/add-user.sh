#!/bin/bash

set -euo pipefail

# Add a user with sudo permissions
groupadd --gid "$USER_GID" "$USERNAME" \
  && useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME" -s "$SHELL" \
  && echo "$USERNAME" ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/"$USERNAME" \
  && chmod 0440 /etc/sudoers.d/"$USERNAME"
