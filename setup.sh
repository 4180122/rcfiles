#!/bin/bash
#
# Linux Setup Script for rcfiles
# Run this script on a fresh Linux installation to set up your environment
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║             Linux Development Environment Setup              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

######################################################################
#                       Detect package manager
######################################################################

if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    PKG_UPDATE="sudo apt update"
    PKG_INSTALL="sudo apt install -y"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PKG_UPDATE="sudo dnf check-update || true"
    PKG_INSTALL="sudo dnf install -y"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
    PKG_UPDATE="sudo yum check-update || true"
    PKG_INSTALL="sudo yum install -y"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    PKG_UPDATE="sudo pacman -Sy"
    PKG_INSTALL="sudo pacman -S --noconfirm"
else
    error "Could not detect package manager (apt, dnf, yum, or pacman)"
    exit 1
fi

info "Detected package manager: $PKG_MANAGER"

######################################################################
#                       Install packages
######################################################################

info "Updating package lists..."
eval "$PKG_UPDATE"

info "Installing essential packages..."

# Package names that are consistent across distros
PACKAGES=(
    zsh
    vim
    git
    curl
    wget
    htop
    tree
    tmux
    most
)

# Install FZF from git since package versions are often outdated
for pkg in "${PACKAGES[@]}"; do
    info "Installing $pkg..."
    eval "$PKG_INSTALL $pkg" || warn "Failed to install $pkg"
done

success "Base packages installed"

######################################################################
#                       Install FZF
######################################################################

if [[ ! -d "$HOME/.fzf" ]]; then
    info "Installing fzf from git..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
    success "FZF installed"
else
    success "FZF already installed"
fi

######################################################################
#                       Install Zplug
######################################################################

if [[ ! -d "$HOME/.zplug" ]]; then
    info "Installing zplug..."
    git clone https://github.com/zplug/zplug "$HOME/.zplug"
    success "Zplug installed"
else
    success "Zplug already installed"
fi

######################################################################
#                       Symlink configuration files
######################################################################

info "Symlinking configuration files..."

# Backup existing files
backup_file() {
    if [[ -e "$1" && ! -L "$1" ]]; then
        backup="$1.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $1 to $backup"
        mv "$1" "$backup"
    fi
}

# Symlink dotfiles
symlink_dotfile() {
    local src="$1"
    local dest="$2"
    
    if [[ -e "$SCRIPT_DIR/$src" ]]; then
        backup_file "$dest"
        ln -sf "$SCRIPT_DIR/$src" "$dest"
        success "Symlinked $src to $dest"
    else
        warn "Source file $src not found, skipping"
    fi
}

symlink_dotfile ".zshrc" "$HOME/.zshrc"
symlink_dotfile ".vimrc" "$HOME/.vimrc"
symlink_dotfile ".vim" "$HOME/.vim"
symlink_dotfile ".screenrc" "$HOME/.screenrc"
symlink_dotfile ".tmux.conf" "$HOME/.tmux.conf"

# Symlink config directories
if [[ -d "$SCRIPT_DIR/config/htop" ]]; then
    mkdir -p "$HOME/.config/htop"
    symlink_dotfile "config/htop/htoprc" "$HOME/.config/htop/htoprc"
fi

if [[ -d "$SCRIPT_DIR/config/btop/themes" ]]; then
    mkdir -p "$HOME/.config/btop/themes"
    symlink_dotfile "config/btop/themes/aurelia.theme" "$HOME/.config/btop/themes/aurelia.theme"
fi

######################################################################
#                       Set zsh as default shell
######################################################################

ZSH_PATH="$(which zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$ZSH_PATH"
    success "Default shell changed to zsh"
else
    success "zsh is already the default shell"
fi

######################################################################
#                       Git configuration
######################################################################

info "Configuring git..."

# Set up useful git aliases
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"

# Prompt for user info if not set
if [[ -z "$(git config --global user.name)" ]]; then
    echo ""
    read -p "Enter your Git name: " git_name
    git config --global user.name "$git_name"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    read -p "Enter your Git email: " git_email
    git config --global user.email "$git_email"
fi

# Sensible defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor vim
git config --global color.ui auto

success "Git configured"

######################################################################
#                       Create useful directories
######################################################################

info "Creating directories..."
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
mkdir -p "$HOME/.zsh/cache"

success "Directories created"

######################################################################
#                       SSH key setup
######################################################################

if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo ""
    read -p "Generate SSH key? [y/N]: " gen_ssh
    if [[ "$gen_ssh" =~ ^[Yy]$ ]]; then
        read -p "Enter email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email"
        success "SSH key generated"
        echo ""
        info "Add this public key to GitHub/GitLab:"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
    fi
else
    success "SSH key already exists"
fi

######################################################################
#                       Done!
######################################################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete! 🎉                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Please restart your terminal or run: source ~/.zshrc"
echo ""
info "Optional: Create ~/.zshrc.local for machine-specific settings"
echo ""
