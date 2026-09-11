#!/usr/bin/env bash
# Assertions run inside the test container (as the normal user) after bootstrap.sh.
# Also safe to run on a real machine after provisioning: test/smoke.sh
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"

PASS=0; FAILED=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mok\033[0m   %s\n' "$*"; }
bad()  { FAILED=$((FAILED+1)); printf '  \033[31mFAIL\033[0m %s\n' "$*"; }
check(){ local msg="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$msg"; else bad "$msg"; fi; }

# Pull pinned versions out of vars/versions.yml (simple key: "value" lines).
ver() { sed -n "s/^$1: \"\(.*\)\"/\1/p" vars/versions.yml; }

echo "== binaries and versions"
check "nvim $(ver neovim_version)"     bash -c "nvim --version | grep -q 'v$(ver neovim_version)'"
check "lazygit $(ver lazygit_version)" bash -c "lazygit --version | grep -q 'version=$(ver lazygit_version)'"
check "fzf $(ver fzf_version)"         bash -c "fzf --version | grep -q '$(ver fzf_version)'"
check "delta $(ver delta_version)"     bash -c "delta --version | grep -q 'delta $(ver delta_version)'"
check "eza $(ver eza_version)"         bash -c "eza --version | grep -q 'v$(ver eza_version)'"
check "fnm $(ver fnm_version)"         bash -c "fnm --version | grep -q 'fnm $(ver fnm_version)'"
check "node (LTS via fnm default)"     bash -c 'eval "$(fnm env --shell bash)"; node --version | grep -Eq "^v[0-9]+"'
check "npm global install works without sudo" bash -c 'eval "$(fnm env --shell bash)"; npm prefix -g | grep -q "$HOME"'
for b in tmux kitty stow wl-copy fd rg zsh git; do
  check "$b on PATH" command -v "$b"
done

echo "== neovim config loads"
check "LazyVim headless start (plugins restore)" bash -c 'out="$(timeout 600 nvim --headless "+Lazy! restore" +qa 2>&1)"; rc=$?; [ $rc -eq 0 ] && ! grep -qE "^E[0-9]+:|Error executing" <<<"$out"'

echo "== stow symlinks point into ~/.dotfiles"
for f in .zshrc .tmux.conf .gitconfig .config/nvim .config/kitty .config/lazygit .config/Cursor/User/settings.json; do
  check "$f" bash -c "readlink -f \"$HOME/$f\" | grep -q \"^$HOME/.dotfiles/\""
done
check "~/.config/Cursor is a real dir (not folded into repo)" bash -c "[ -d \"$HOME/.config/Cursor\" ] && [ ! -L \"$HOME/.config/Cursor\" ]"
check "~/.config/cosmic is a real dir"                           bash -c "[ -d \"$HOME/.config/cosmic\" ] && [ ! -L \"$HOME/.config/cosmic\" ]"
check "COSMIC shortcuts file linked" bash -c "readlink -f \"$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom\" | grep -q '^$HOME/.dotfiles/'"
check "no Cursor cache inside repo"  bash -c "[ ! -e \"$HOME/.dotfiles/.config/Cursor/Cache\" ]"

echo "== ownership"
ROOT_OWNED="$(find "$HOME" -xdev -not -user "$(id -un)" 2>/dev/null | head -20)"
if [ -z "$ROOT_OWNED" ]; then ok "no files in \$HOME owned by another user"; else bad "foreign-owned files in \$HOME:"; echo "$ROOT_OWNED" | sed 's/^/       /'; fi

echo "== shell"
check "login shell is zsh"        bash -c "getent passwd \"$(id -un)\" | cut -d: -f7 | grep -q '/usr/bin/zsh'"
check "oh-my-zsh present"         test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
check "zsh-autosuggestions plugin" test -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check "zsh-vi-mode plugin"         test -d "$HOME/.oh-my-zsh/custom/plugins/zsh-vi-mode"
check "catppuccin theme linked"    test -e "$HOME/.oh-my-zsh/custom/themes/catppuccin.zsh-theme"
check "zsh loads and theme is catppuccin" bash -c "zsh -ic 'echo \$ZSH_THEME' 2>/dev/null | grep -q catppuccin"
check "fnm activated in zsh"       bash -c "zsh -ic 'command -v node' 2>/dev/null | grep -q fnm"

echo "== ssh key"
check "id_ed25519 mode 600"      bash -c "stat -c %a \"$HOME/.ssh/id_ed25519\" | grep -q '^600$'"
check "id_ed25519.pub mode 644"  bash -c "stat -c %a \"$HOME/.ssh/id_ed25519.pub\" | grep -q '^644$'"
check "private key is valid (not still vault ciphertext)" bash -c "ssh-keygen -y -f \"$HOME/.ssh/id_ed25519\" >/dev/null"
if [ -n "${TEST_PUBKEY:-}" ]; then
  check "installed pubkey equals throwaway test key" bash -c "grep -qF \"$(echo "$TEST_PUBKEY" | cut -d' ' -f1-2)\" \"$HOME/.ssh/id_ed25519.pub\""
  check "pubkey present in authorized_keys"          bash -c "grep -qF \"$(echo "$TEST_PUBKEY" | cut -d' ' -f1-2)\" \"$HOME/.ssh/authorized_keys\""
fi

echo "== fonts"
check "JetBrainsMono Nerd Font installed" bash -c "fc-list | grep -qi 'JetBrainsMono Nerd Font'"

echo "== tools"
check "tmux-sessionizer installed" test -x "$HOME/.local/bin/tmux-sessionizer"

echo
echo "passed=$PASS failed=$FAILED"
[ "$FAILED" -eq 0 ]
