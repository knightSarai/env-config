# env-config

Provisions a fresh Pop!_OS 24.04 (COSMIC) machine. Configs live in [knightSarai/.dotfiles](https://github.com/knightSarai/.dotfiles).

## New machine

```sh
mkdir -p ~/code && cd ~/code
git clone https://github.com/knightSarai/env-config.git && cd env-config
./bootstrap.sh            # asks for sudo password, then the vault password
reboot
```

## Re-run one part

```sh
./bootstrap.sh --tags bin        # tags: core ssh shell bin node fonts tools desktop dotfiles cosmic
```

Tool versions are pinned in `vars/versions.yml`; bump and re-run `--tags bin`.

## Test in Docker (no vault password needed)

```sh
test/run.sh
```

## Manual after first boot

- Sign in to 1Password, Cursor, Brave/Chromium
- COSMIC Settings: fixed workspaces, default terminal = kitty; copy the resulting `~/.config/cosmic/*` files into `~/.dotfiles`
