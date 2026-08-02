#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
sudo darwin-rebuild switch --flake ~/.dotfiles#mac

# Materialize this machine's GitHub auth/signing keys from the
# "mac-automation" 1Password vault via a read-only Service Account. See
# README: "GitHub SSH authentication & commit signing". Skips quietly on a
# fresh clone before that token exists.
TOKEN_FILE="$HOME/.config/op/service-account-token"
if [[ -f "$TOKEN_FILE" ]]; then
  export OP_SERVICE_ACCOUNT_TOKEN
  OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"
  for name in id_ed25519_mac_auth id_ed25519_mac_signing; do
    op inject --force -i "$DIR/home/.ssh/$name.tmpl" -o "$HOME/.ssh/$name"
    op inject --force -i "$DIR/home/.ssh/$name.pub.tmpl" -o "$HOME/.ssh/$name.pub"
    chmod 600 "$HOME/.ssh/$name"
    chmod 644 "$HOME/.ssh/$name.pub"
  done
  op inject --force -i "$DIR/home/.ssh/allowed_signers.tmpl" -o "$HOME/.ssh/allowed_signers"
  chmod 644 "$HOME/.ssh/allowed_signers"

  mkdir -p "$HOME/.config/git"
  op inject --force -i "$DIR/home/.config/git/config-local.tmpl" -o "$HOME/.config/git/config-local"
  chmod 644 "$HOME/.config/git/config-local"
else
  echo "note: $TOKEN_FILE not found - skipping 1Password key injection (see README)" >&2
fi
