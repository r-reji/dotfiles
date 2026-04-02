#!/usr/bin/env bash

sudo apt update
sudo apt install -y tmux fzf eza neovim stow
stow *
