#!/usr/bin/env bash
# End-to-end test in a fresh ubuntu:noble container. Needs Docker on the host, nothing else:
# no real vault password, no real SSH key.
#
#   test/run.sh            # lint (in container) -> provision -> smoke test -> idempotency -> desktop repos resolve
#   KEEP=1 test/run.sh     # leave the container running: docker exec -it -u knight env-config-test bash
#   APT_MIRROR=archive.ubuntu.com/ubuntu test/run.sh   # use a different Ubuntu mirror
#
# Secrets: a throwaway ed25519 key + random vault password are generated into a temp dir,
# mounted at /home/knight/test-secrets, and vault-encrypted inside the container. The
# playbook is pointed at them with -e source_key=... so tasks/ssh.yml runs its real code
# path (decrypt, copy, modes, authorized_keys) against a disposable key.
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE=env-config-test
NAME=env-config-test
KEEP="${KEEP:-0}"
SECRETS=/home/knight/test-secrets
# Ubuntu mirror used inside the container (archive.ubuntu.com is very slow from AU).
APT_MIRROR="${APT_MIRROR:-mirror.aarnet.edu.au/pub/ubuntu/archive}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mFAIL: %s\033[0m\n' "$*" >&2; exit 1; }
in_container() { docker exec -u knight -w /home/knight/env-config "$NAME" bash -lc "export PATH=\"\$HOME/.local/bin:\$PATH\"; $*"; }

# ---- 1. throwaway secrets -------------------------------------------------------
TMP="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP"
  if [ "$KEEP" != 1 ]; then docker rm -f "$NAME" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT

log "Generating throwaway SSH key + vault password"
ssh-keygen -q -t ed25519 -N '' -C 'env-config-test' -f "$TMP/id_ed25519"
head -c 32 /dev/urandom | base64 > "$TMP/vault-pass.txt"
TEST_PUBKEY="$(cat "$TMP/id_ed25519.pub")"
chmod 777 "$TMP"   # container user must be able to write the encrypted copies

# ---- 3. container ---------------------------------------------------------------
log "Building image"
docker build -q --build-arg "APT_MIRROR=$APT_MIRROR" -t "$IMAGE" . >/dev/null
docker rm -f "$NAME" >/dev/null 2>&1 || true

log "Starting container"
docker run -d --name "$NAME" \
  -v "$PWD:/home/knight/env-config" \
  -v "$TMP:$SECRETS" \
  -e TEST_PUBKEY="$TEST_PUBKEY" \
  "$IMAGE" sleep infinity >/dev/null

log "Installing ansible + ansible-lint in container"
in_container 'command -v ansible-vault >/dev/null || pipx install --include-deps ansible >/dev/null'
in_container 'command -v ansible-lint  >/dev/null || pipx install ansible-lint >/dev/null'
in_container 'ansible-galaxy collection install -r requirements.yml >/dev/null'

log "Syntax check + ansible-lint (container)"
in_container 'ansible-playbook setup.yml --syntax-check' || fail "syntax check failed"
in_container 'ansible-lint setup.yml' || fail "ansible-lint failed"

log "Vault-encrypting the throwaway key"
in_container "ansible-vault encrypt --vault-password-file $SECRETS/vault-pass.txt $SECRETS/id_ed25519 $SECRETS/id_ed25519.pub"
in_container "head -1 $SECRETS/id_ed25519 | grep -q ANSIBLE_VAULT" || fail "key was not vault-encrypted"

EXTRA="-e source_key=$SECRETS/id_ed25519 -e dotfiles_repo=https://github.com/knightSarai/.dotfiles.git --vault-password-file $SECRETS/vault-pass.txt"

# ---- 4. provision ---------------------------------------------------------------
log "First run: ./bootstrap.sh --skip-tags desktop"
in_container "./bootstrap.sh --skip-tags desktop $EXTRA" || fail "first playbook run failed"

# ---- 5. smoke test --------------------------------------------------------------
log "Smoke test"
in_container 'test/smoke.sh' || fail "smoke test failed"

# ---- 6. idempotency -------------------------------------------------------------
log "Second run (must be changed=0)"
SECOND="$(in_container "./bootstrap.sh --skip-tags desktop $EXTRA")" || fail "second playbook run failed"
echo "$SECOND"
RECAP="$(grep -E '^localhost' <<<"$SECOND" || true)"
echo "$RECAP" | grep -Eq 'changed=0 ' || fail "second run was not idempotent"
echo "$RECAP" | grep -Eq 'failed=0 '  || fail "second run had failures"

# ---- 7. desktop repos for real, then package resolution --------------------------
# Installing Docker/Cursor/1Password/Flatpaks in a container is pointless, but the apt
# repos and signing keys can be set up for real and must make the packages resolvable.
log "Desktop repos + keys (real run), then apt-cache resolution"
in_container "./bootstrap.sh --tags desktop_repos $EXTRA" || fail "desktop repo setup failed"
for pkg in docker-ce cursor 1password; do
  in_container "apt-cache policy $pkg | grep -q 'Candidate: [^(]'" || fail "$pkg does not resolve from its apt repo"
  echo "  ok   $pkg resolves"
done
OBSIDIAN_URL="$(in_container "ansible localhost -m debug -a \"msg=https://github.com/obsidianmd/obsidian-releases/releases/download/v{{ obsidian_version }}/obsidian_{{ obsidian_version }}_amd64.deb\" -e @vars/versions.yml" | grep -o 'https://[^"]*')"
in_container "curl -fsSLI -o /dev/null '$OBSIDIAN_URL'" || fail "Obsidian .deb URL not reachable: $OBSIDIAN_URL"
echo "  ok   obsidian .deb URL reachable"

log "PASS"
if [ "$KEEP" = 1 ]; then echo "Container left running: docker exec -it -u knight $NAME bash"; fi
