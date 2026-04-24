#!/bin/bash
# Wrapper for the new Go based Shortcut Manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure the binary is built
if [ ! -f "$SCRIPT_DIR/shortcut-manager-bin" ]; then
    export PATH=$PATH:~/.local/go/bin
    cd "$SCRIPT_DIR" && go build -o shortcut-manager-bin .
fi

"$SCRIPT_DIR/shortcut-manager-bin" "$@"
