# Shortcut Manager

A fast, terminal-based tool to create, edit, and manage `.desktop` application shortcuts on Linux.  
Built in **Go** using the [`Charmbracelet Bubble Tea`](https://github.com/charmbracelet/bubbletea) and [`huh`](https://github.com/charmbracelet/huh) frameworks for a blazing fast, self-contained, and interactive TUI.

## Features

- Create new application shortcuts using a clean, modern form interface
- Edit existing shortcuts (user or system)
- Delete user shortcuts
- Hide system shortcuts using local overrides
- Live filtering and searching of shortcuts
- Completely self-contained binary (no Python or bash dependencies)
- Includes its own `.desktop` launcher (`shortcut-manager.desktop`)
- Launchable from terminal or app menu

https://github.com/user-attachments/assets/6f86d1b0-04c6-4065-a483-e8a09b4ca42e

---

## Requirements

- `go` (for installation)

---

## Installation (Arch / CachyOS)

### Recommended Method

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jebin2/shortcut-manager/main/install.sh)"
````

### Alternative (Manual Build)

```bash
git clone https://github.com/jebin2/shortcut-manager.git
cd shortcut-manager
makepkg -si
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
