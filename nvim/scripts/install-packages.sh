#!/bin/bash

set -ue

# Update and install base packages
dnf upgrade -y
dnf install -y jq wget gpg

# Install default packages
for package_list in /packages/*; do
    grep -v '^\s*//' "$package_list" | \
      jq -r '.[]' | \
      xargs -r dnf install -y
done

# Clean packages cache
dnf clean all
