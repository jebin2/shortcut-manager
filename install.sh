#!/bin/bash
set -e

echo "Installing Shortcut Manager..."

# Check if go is installed
if ! command -v go &> /dev/null; then
    echo "Error: 'go' is required to build the application."
    echo "Please install Go (https://go.dev/doc/install) and try again."
    exit 1
fi

tmp=$(mktemp -d)
echo "Cloning repository..."
git clone -q https://github.com/jebin2/shortcut-manager.git "$tmp"
cd "$tmp"

echo "Building Go binary..."
go build -o shortcut-manager .

echo "Installing binary to ~/.local/bin..."
mkdir -p ~/.local/bin
mv shortcut-manager ~/.local/bin/

echo "Installing .desktop launcher..."
mkdir -p ~/.local/share/applications
cp shortcut-manager.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/ || true

rm -rf "$tmp"

echo "Installation complete!"
echo "You can now run 'shortcut-manager' from your terminal or launch it from your application menu."
echo "(Make sure ~/.local/bin is in your system PATH)"
