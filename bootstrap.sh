#!/usr/bin/env bash
# One-shot entry point. Run as your normal user (NOT sudo):
#   ./bootstrap.sh                      # everything
#   ./bootstrap.sh --tags bin           # one part
#   ./bootstrap.sh --skip-tags desktop  # e.g. headless / container
# Any extra args are passed straight to ansible-playbook.
#
# Installs Ansible via pipx (user-local, survives OS upgrades unlike a PPA), pulls the
# collections we use, then runs setup.yml. Sudo is asked for once (-K) and used only by
# tasks that need it. The vault password is read from .vault-pass.txt if present
# (tests / automation), otherwise prompted.
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not root/sudo." >&2
  exit 1
fi

if ! command -v pipx >/dev/null 2>&1; then
  echo "==> Installing pipx"
  sudo apt-get update -qq
  sudo apt-get install -y -qq pipx git curl
fi

export PATH="$HOME/.local/bin:$PATH"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "==> Installing Ansible via pipx"
  pipx install --include-deps ansible
fi

echo "==> Installing Ansible collections"
ansible-galaxy collection install -r requirements.yml >/dev/null

VAULT_ARGS=(--ask-vault-pass)
if [ -f .vault-pass.txt ]; then
  VAULT_ARGS=(--vault-password-file .vault-pass.txt)
fi
# Caller supplied their own vault option: don't add a conflicting one.
case " $* " in
  *" --vault-password-file "*|*" --vault-id "*|*" --ask-vault-pass "*) VAULT_ARGS=() ;;
esac

BECOME_ARGS=(-K)
# Passwordless sudo (containers, CI): skip the prompt.
if sudo -n true 2>/dev/null; then
  BECOME_ARGS=()
fi

echo "==> Running playbook"
exec ansible-playbook setup.yml "${BECOME_ARGS[@]}" "${VAULT_ARGS[@]}" "$@"
