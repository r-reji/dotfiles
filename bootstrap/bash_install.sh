#!/usr/bin/env bash

# ===================
# WIP Bootsrap does not work 100% yet
# ===================

# Exit immediately if a command exits with a non-zero status
set -e 

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Helper functions for logging
info() { echo -e "${BLUE}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[x] $1${NC}"; exit 1; }

# ==============================================================================
# System Updates & Base Packages
# ==============================================================================
info "Requesting sudo privileges..."
sudo -v

info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

info "Installing core CLI tools..."
# Added curl, wget, unzip, and build-essential (needed for Pyenv)
sudo apt install -y curl wget unzip git stow tmux neovim build-essential tmuxinator libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python3-openssl

info "Installing eza..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# ==========================================
# Install fzf from source
# ==========================================
echo "Installing fzf..."
# Remove apt version if it exists to prevent conflicts
sudo apt remove -y fzf 

# Only clone and install if the directory doesn't already exist
if [ ! -d "$HOME/dev/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/dev/.fzf"
    
    # Run the installer silently, accepting all defaults (--all) 
    # This enables fuzzy auto-completion and keybindings
    "$HOME/dev/.fzf/install" --all
else
    echo "fzf is already installed in ~/dev/.fzf. Skipping clone."
fi

# ==============================================================================
# Install System Utilities (GNOME Tweaks, Ulauncher)
# ==============================================================================
info "Installing GNOME Tweaks and required packages..."
# Note: Adjust 'apt' if using Fedora/Arch.
sudo apt update
sudo apt install -y gnome-tweaks unzip wget

info "Setting up Ulauncher..."
if ! command -v ulauncher &> /dev/null; then
    sudo add-apt-repository universe -y
    sudo add-apt-repository ppa:agornostal/ulauncher -y
    sudo apt update
    sudo apt install -y ulauncher
    success "Ulauncher installed!"
else
    warn "Ulauncher is already installed, skipping installation..."
fi

info "Setting Ulauncher to autostart on login..."
mkdir -p "$HOME/.config/autostart"
if [ -f /usr/share/applications/ulauncher.desktop ]; then
    cp /usr/share/applications/ulauncher.desktop "$HOME/.config/autostart/"
fi

# ==============================================================================
# Install Custom Tools (Alacritty, Starship, Pyenv)
# ==============================================================================
info "Setting up Alacritty..."
if ! command -v alacritty &> /dev/null; then
    sudo add-apt-repository ppa:aslatter/ppa -y
    sudo apt update
    sudo apt install -y alacritty
else
    warn "Alacritty already installed, skipping..."
fi

info "Setting up Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    warn "Starship already installed, skipping..."
fi

info "Setting up Pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
else
    warn "Pyenv already installed, skipping..."
fi

# ==============================================================================
# Install and Configure keyd
# ==============================================================================
info "Setting up keyd (Caps Lock to Esc/Ctrl)..."

if ! command -v keyd &> /dev/null; then
    info "keyd not found. Cloning and building from source..."

    # Move to the temp directory
    cd /tmp

    # Remove any old cloned folders 
    rm -rf keyd

    # Clone, build, and install
    git clone https://github.com/rvaiya/keyd
    cd keyd
    make
    sudo make install

    # Clean up the temp directory
    cd /tmp
    rm -rf keyd

    success "keyd compiled and installed!"
else
    warn "keyd is already installed, skipping build..."
fi

info "Linking keyd configuration to /etc/keyd..."
# Ensure the directory exists
sudo mkdir -p /etc/keyd

# Create the symlink pointing to your dotfiles repo
sudo ln -sf "$HOME/dotfiles/keyd-config/default.conf" /etc/keyd/default.conf

info "Enabling and starting the keyd background daemon..."
# Reload in case the config changed, and ensure the service is enabled on boot
sudo keyd reload
sudo systemctl enable --now keyd

success "keyd is fully configured"

# ==============================================================================
# Install Fonts
# ==============================================================================
info "Installing JetBrains Mono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
if ! fc-list | grep -qi "JetBrainsMono NFM"; then
    mkdir -p "$FONT_DIR"
    cd /tmp
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -q JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono"
    rm JetBrainsMono.zip
    fc-cache -fv
    success "Font installed!"
else
    warn "JetBrains Mono Nerd Font already installed, skipping..."
fi

# ==============================================================================
# Symlink Dotfiles with GNU Stow
# ==============================================================================
info "Stowing dotfiles..."
DOTFILES_DIR="$HOME/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    
    # Safely stow specific directories instead of using '*'
    # Add or remove folders based on your actual dotfiles repo structure
    STOW_FOLDERS=("alacritty" "bash" "starship" "tmux")
    
    for folder in "${STOW_FOLDERS[@]}"; do
        if [ -d "$folder" ]; then
            stow -R "$folder"
            success "Stowed $folder"
        else
            warn "Folder $folder not found in dotfiles, skipping..."
        fi
    done
else
    error "Dotfiles directory not found at $DOTFILES_DIR"
fi

# ==============================================================================
# Secure Secrets Check
# ==============================================================================
info "Checking for .secrets file..."
if [ ! -f "$HOME/.secrets" ]; then
    touch "$HOME/.secrets"
    chmod 600 "$HOME/.secrets"
    warn "Created a blank ~/.secrets file. Don't forget to paste your tokens inside!"
fi

# ==============================================================================
# GNOME Settings
# ==============================================================================
info "Applying GNOME theme preferences..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

success "Bootstrap complete! Please restart your terminal."
