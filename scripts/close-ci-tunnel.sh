#!/usr/bin/env bash
set -euo pipefail
: "${RUNNER_TEMP:?Run this script inside GitHub Actions}"
SSH_DIR="$RUNNER_TEMP/dbops-ssh"
if [ -S "$SSH_DIR/control" ] && [ -n "${SSH_HOST:-}" ]; then
  ssh -S "$SSH_DIR/control" -O exit "user@$SSH_HOST" || true
fi
rm -f "$SSH_DIR/private_key" "$SSH_DIR/known_hosts"
