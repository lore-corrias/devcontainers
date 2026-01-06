#!/bin/bash

set -euo pipefail

# Capabilities for nmap
setcap cap_net_raw,cap_net_admin+eip "$(which nmap)"
