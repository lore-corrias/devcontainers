#!/bin/bash

set -ue

# Install default packages
for package_list in /packages/*; do
  apt-get update -qq -y && apt-get install -y jq wget gpg \
    && grep -v '^\s*//' "$package_list" | \
      jq -r '.[]' | \
      xargs -r apt-get install -y -qq
done

# Install eza
mkdir -p /etc/apt/keyrings \
  && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
  && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
  && apt-get update -y -qq \
  && apt-get install -y -qq eza

# Clean packages cache
apt-get clean autoclean -qq \
  && apt-get autoremove --yes -qq \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/
