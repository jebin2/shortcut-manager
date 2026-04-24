#!/bin/bash
tmp=$(mktemp -d)
git clone https://github.com/jebin2/shortcut-manager.git "$tmp"
cd "$tmp"
makepkg -si
rm -rf "$tmp"
