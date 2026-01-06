#!/bin/bash

set -euo pipefail

# Enabling english locale
sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen
