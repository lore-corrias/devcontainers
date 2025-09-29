#!/bin/bash
set -ueo pipefail

YAY_DIR="/tmp/yay"
YAY_SRC="/tmp/yay-src"

# 0) Make sure time is sane (PGP cares about clock skew)
timedatectl >/dev/null 2>&1 || true  # ignore in minimal containers
date

# 1) Ensure pacman deps for keyring, building, sudo, etc.
pacman -Sy --noconfirm archlinux-keyring gnupg git base-devel sudo jq

# 2) Initialize and populate pacman’s keyring (from the archlinux-keyring package)
pacman-key --init
pacman-key --populate archlinux

# 3) (Optional but helpful in CI) Set a reliable keyserver for future refreshes
printf 'keyserver hkps://keyserver.ubuntu.com:443\n' > /etc/pacman.d/gnupg/gpg.conf || true

# 4) System update (work around transient mirror hiccups)
rm -f /var/cache/pacman/pkg/libngtcp2-*.pkg.tar.zst || true
pacman -Syyu --noconfirm

# 5) Create an unprivileged build user if missing + allow passwordless sudo (root invoking sudo never needs a pw, but this is handy if you later switch)
if ! id -u builder >/dev/null 2>&1; then
  useradd -m -s /bin/bash builder
fi
echo 'builder ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/99_builder_nopasswd
chmod 440 /etc/sudoers.d/99_builder_nopasswd

# 6) Build and install yay as NON-ROOT (only the final pacman -U is root)
if ! command -v yay >/dev/null 2>&1; then
  rm -rf "$YAY_SRC"
  git clone https://aur.archlinux.org/yay.git "$YAY_SRC"
  chown -R builder:builder "$YAY_SRC"
  # Build yay as builder
  sudo -u builder bash -lc "cd '$YAY_SRC' && makepkg -s --noconfirm"
  # Install the built package as root
  pacman -U --noconfirm "$YAY_SRC"/*.pkg.tar.zst
fi

# Ensure build workspace owned by builder
mkdir -p "$YAY_DIR"/built
chown -R builder:builder "$YAY_DIR"
chmod 755 "$YAY_DIR"

# 7) Process package lists
for package_list in /packages/*; do
  # AUR/yay packages
  if [[ "$package_list" == "/packages/ctfbox-yay.json5" ]]; then
    # Read packages (strip JSON5 // comments, output raw list)
    PACKAGES=$(grep -v '^\s*//' "$package_list" | jq -r '.[]' | xargs -r)

    # Build each AUR package as the builder user
    for package in $PACKAGES; do
      # Fetch PKGBUILD into YAY_DIR
      sudo -u builder bash -lc "cd '$YAY_DIR' && yay -G --noconfirm '$package'"
      # Build inside the cloned dir
      sudo -u builder bash -lc "cd '$YAY_DIR/$package' && makepkg --syncdeps --noconfirm"
      # Move built artifacts out
      find "$YAY_DIR/$package" -maxdepth 1 -name "*.pkg.tar.zst" -exec mv {} "$YAY_DIR/built/" \;
      # Clean workspace for next loop
      rm -rf "${YAY_DIR:?}/$package"
    done

  # Official repo packages via pacman
  else
    # Install each listed package (strip JSON5 comments first)
    pacman -Sy --noconfirm && \
    grep -v '^\s*//' "$package_list" \
      | jq -r '.[]' \
      | xargs -r pacman -S --noconfirm && \
      # Clean caches (double 'y' confirmation)
      printf "y\ny" | pacman -Scc
  fi
done

# 8) Delete the builder user
userdel builder
