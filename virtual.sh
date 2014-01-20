# Swaps Ctrl and Caps lock for Virtual Consoles
# Note: Execute if under Virtual Console.

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
else
    dumpkeys | head -1 > ~/.Caps2Ctrl.map
    echo "keycode 58 = Control #Makes Caps as Ctrl" >> ~/.Caps2Ctrl.map
    loadkeys -v ~/.Caps2Ctrl.map
fi

## To revert: loadkeys -d
