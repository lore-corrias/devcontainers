#!/bin/bash

set -ue

# Ensure jq and basic tools are present before loop
dnf install -y jq wget gnupg

# Install default packages from json5 files
for package_list in /packages/*; do
  grep -v '^\s*//' "$package_list" | \
    jq -r '.[]' | \
    xargs -r dnf install -y
done

# Install eza
EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"

echo "Downloading eza from GitHub..."
wget -qO- "$EZA_URL" | tar xz -C /usr/local/bin
chmod +x /usr/local/bin/eza

# Clean packages cache
dnf clean all
rm -rf /var/cache/dnf
