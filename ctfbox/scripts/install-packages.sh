#!/bin/bash
set -ueo pipefail

pacman -Syyu --noconfirm && \
  pacman -S --noconfirm jq

for package_list in /packages/*; do
  pacman -Sy --noconfirm && \
  grep -v '^\s*//' "$package_list" \
    | jq -r '.[]' \
    | xargs -r pacman -S --noconfirm && \
    printf "y\ny" | pacman -Scc --noconfirm
done
