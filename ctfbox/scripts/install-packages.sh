#!/bin/bash

set -ueo pipefail

YAY_DIR="/tmp/yay"

# 0) Make sure time is sane (PGP cares about clock skew)
timedatectl >/dev/null 2>&1 || true  # ignore in minimal containers
date

# 1) Ensure gnupg + keyring are present and up to date
pacman -Sy --noconfirm archlinux-keyring gnupg

# 2) Initialize and populate pacman’s keyring (from the archlinux-keyring package)
pacman-key --init
pacman-key --populate archlinux

# 3) (Optional but helpful in CI) Set a reliable keyserver for future refreshes
printf 'keyserver hkps://keyserver.ubuntu.com:443\n' > /etc/pacman.d/gnupg/gpg.conf || true

rm -f /var/cache/pacman/pkg/libngtcp2-*.pkg.tar.zst || true
pacman -Syyu --noconfirm

# Install pacman packages and built yay packages
for package_list in /packages/*; do
  # Installation for yay packages
  if [[ "$package_list" == "/packages/install-yay-packages.sh" ]]; then
    git clone https://aur.archlinux.org/yay.git \
      && cd yay \
      && makepkg -s \
      && sudo pacman -U --noconfirm ./*.pkg.tar.zst

    # Build aur packages as non-root
    mkdir -p ${YAY_DIR:?}/built/
    chown -R builder:builder ${YAY_DIR:?}/
    chmod 755 ${YAY_DIR:?}/

    # Change to the build directory for the script runner (optional, but good practice)
    cd ${YAY_DIR:?}/ || { echo "Failed to change directory to /tmp/yay"; exit 1; }

    # Get the list of packages, stripping comments and handling potential empty lines
    PACKAGES=$(grep -v '^#' /packages/ctfbox-yay.packages | xargs)

    for package in $PACKAGES; do
      # clone the directory with the source code and build the package
      yay -G "$package" && cd "$package" && makepkg --syncdeps --noconfirm

      # find all build packages and move them to the built directory, so that they can
      # be moved between images more easily
      find "${YAY_DIR:?}/$package" -maxdepth 1 -name "*.pkg.tar.zst" -exec mv {} ${YAY_DIR:?}/built/ \;
      # clean the directory
      rm -rf "${YAY_DIR:?}/$package"
    done
  # Installation via pacman
  else
    pacman -Sy --noconfirm && pacman -S --noconfirm jq wget gpg \
      && grep -v '^\s*//' "$package_list" | \
        jq '. | to_entries? | .[] | .key + "=" + .value' | \
        xargs pacman -S --noconfirm \
      && printf "y\ny" | pacman -Scc 
     # ^ yeah, this is seriously needed 
  fi
done
