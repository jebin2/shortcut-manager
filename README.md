# Shortcut Manager

A simple terminal-based tool to create, edit, and delete `.desktop` shortcuts on Linux.  
Built with [`gum`](https://github.com/charmbracelet/gum) for a user-friendly TUI.

## Features
- Create new application shortcuts
- Edit existing shortcuts (system or user)
- Delete or hide system shortcuts with local overrides
- Preview changes before saving (with syntax highlighting via `bat`)
- Installed with its own `.desktop` entry (`shortcut-manager.desktop`) so you can launch it from your app menu

![Demo Video](./shortcut-manager.mp4)

## Requirements
- `bash`
- [`gum`](https://github.com/charmbracelet/gum)
- [`bat`](https://github.com/sharkdp/bat)

## Installation (Arch Linux)
```bash
git clone https://github.com/jebin2/shortcut-manager.git
cd shortcut-manager
makepkg -si
````

## Usage

From terminal:

```bash
shortcut-manager
```

Or from your app menu: **Shortcut Manager**
