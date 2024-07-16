# Manuall setup
- Workspaces Bar extension 
  - space-bar@luchrioh
  - bluetooth-quick-connect@bjarosze
- Chromium
- Kitty
- Obsidian 
# Useful Commands
## Install
`mkdir code && cd code && git clone https://github.com/knightSarai/env-config.git && cd env-config`
`./install`
`./install-nerd-fonts`
`sudo -E ansible-playbook -E setup.yml --tags "ssh" --ask-vault-pass`
`./pop-os-conf.sh`
`sudo chown -R $(whoami) ~/.local`
`chsh -s $(which zsh)`
`reboot`

## Test
`sudo docker run --rm -t new-setup bash`
