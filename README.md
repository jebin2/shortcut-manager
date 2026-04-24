````md
# Shortcut Manager

A simple terminal-based tool to create, edit, and manage `.desktop` application shortcuts on Linux.  
Built with [`gum`](https://github.com/charmbracelet/gum) for a clean and user-friendly TUI.

## Features

- Create new application shortcuts
- Edit existing shortcuts (user or system)
- Delete user shortcuts
- Hide system shortcuts using local overrides
- Live preview before saving
- Syntax highlighting with [`bat`](https://github.com/sharkdp/bat)
- Includes its own `.desktop` launcher (`shortcut-manager.desktop`)
- Launchable from terminal or app menu

https://github.com/user-attachments/assets/6f86d1b0-04c6-4065-a483-e8a09b4ca42e

---

## Requirements

- `bash`
- [`gum`](https://github.com/charmbracelet/gum)
- [`bat`](https://github.com/sharkdp/bat)
- `base-devel` (for building package on Arch-based systems)

---

## Installation (Arch / CachyOS)

### Recommended Method

```bash
git clone https://github.com/jebin2/shortcut-manager.git
cd shortcut-manager
makepkg -si
````

### One-Line Install

```bash
git clone https://github.com/jebin2/shortcut-manager.git && cd shortcut-manager && makepkg -si
```

---

## Usage

Run from terminal:

```bash
shortcut-manager
```

Or launch from your app menu:

**Shortcut Manager**

---

## Uninstall

```bash
sudo pacman -R shortcut-manager
```

---

## Notes

* User shortcuts are stored in:

```bash
~/.local/share/applications
```

* System shortcuts are safely edited by creating local copies.

---
