#!/usr/bin/env bash

# Linux Setup - Installation Script
# This script helps automate the setup of dotfiles and configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "Linux Setup Installation Script"
print_info "================================"
echo ""

# Backup existing configs
backup_config() {
	local target="$1"
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
		print_warning "Backing up existing config: $target -> $backup"
		mv "$target" "$backup"
	fi
}

# Create symlink
create_symlink() {
	local source="$1"
	local target="$2"

	if [ -L "$target" ]; then
		print_warning "Symlink already exists: $target"
		return
	fi

	backup_config "$target"

	# Create parent directory if it doesn't exist
	mkdir -p "$(dirname "$target")"

	ln -s "$source" "$target"
	print_success "Linked: $source -> $target"
}

# Main installation
print_info "Starting installation..."
echo ""

# Symlink .config directory contents
if [ -d "$SCRIPT_DIR/.config" ]; then
	print_info "Symlinking .config directories..."
	for dir in "$SCRIPT_DIR/.config"/*; do
		if [ -d "$dir" ]; then
			dir_name=$(basename "$dir")
			create_symlink "$dir" "$HOME/.config/$dir_name"
		fi
	done
	echo ""
fi

# Symlink .local directory contents
if [ -d "$SCRIPT_DIR/.local" ]; then
	print_info "Symlinking .local directories..."
	for item in "$SCRIPT_DIR/.local"/*; do
		if [ -d "$item" ]; then
			item_name=$(basename "$item")
			create_symlink "$item" "$HOME/.local/$item_name"
		fi
	done
	echo ""
fi

# Symlink git config files
print_info "Symlinking git config files..."
if [ -f "$SCRIPT_DIR/.gitconfig" ]; then
	create_symlink "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
fi
if [ -f "$SCRIPT_DIR/.gitconfig-company" ]; then
	create_symlink "$SCRIPT_DIR/.gitconfig-company" "$HOME/.gitconfig-company"
fi
echo ""

# Copy etc files (these typically need root access)
if [ -d "$SCRIPT_DIR/etc" ]; then
	print_warning "etc/ directory found. These files typically need root access."
	print_info "To install system-wide configs, run:"
	echo "  sudo cp -r $SCRIPT_DIR/etc/* /etc/"
	echo ""
fi

print_success "Installation complete!"
echo ""
print_info "Next steps:"
echo "  1. Reload your shell or run: source ~/.config/fish/config.fish"
echo "  2. Install required packages listed in README.md"
echo "  3. Customize configs to your liking"
echo ""
print_info "For more information, check README.md"
