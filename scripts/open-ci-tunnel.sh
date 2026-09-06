#!/usr/bin/env bash
set -euo pipefail
umask 077
: "${SSH_HOST:?Set the SSH_HOST Actions secret}"
: "${SSH_PRIVATE_KEY:?Set the SSH_PRIVATE_KEY Actions secret}"
: "${SSH_KNOWN_HOSTS:?Set the SSH_KNOWN_HOSTS Actions secret}"
: "${RUNNER_TEMP:?Run this script inside GitHub Actions}"
SSH_DIR="$RUNNER_TEMP/dbops-ssh"
mkdir -p "$SSH_DIR"
printf '%s\n' "$SSH_PRIVATE_KEY" > "$SSH_DIR/private_key"
printf '%s\n' "$SSH_KNOWN_HOSTS" > "$SSH_DIR/known_hosts"
chmod 600 "$SSH_DIR/private_key" "$SSH_DIR/known_hosts"
ssh -fNT -M -S "$SSH_DIR/control" \
  -i "$SSH_DIR/private_key" \
  -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=20 \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  -L 127.0.0.1:15432:127.0.0.1:5432 "user@$SSH_HOST"
