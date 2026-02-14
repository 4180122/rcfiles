#!/bin/bash
#
# macOS Setup Script for rcfiles
# Run this script on a fresh macOS installation to set up your environment
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              macOS Development Environment Setup             ║"
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
#                       Homebrew
######################################################################

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -d /opt/homebrew/bin ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d /usr/local/bin ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

######################################################################
#                       Essential packages
######################################################################

info "Installing essential packages..."

PACKAGES=(
    zsh
    vim
    fzf
    zplug
    most
    git
    coreutils
    findutils
    gnu-sed
    grep
    ripgrep
    fd
    bat
    eza
    jq
    tree
    htop
    btop
    wget
    curl
    tmux
)

for pkg in "${PACKAGES[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
        info "Installing $pkg..."
        brew install "$pkg"
    else
        success "$pkg already installed"
    fi
done

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
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    
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
