#!/bin/bash
#
# spectrum-screenshot - Capture screenshot from ZX Spectrum program
#
# Usage:
#   spectrum-screenshot program.sna output.png [--wait SECONDS]
#   spectrum-screenshot program.tap output.png [--wait SECONDS]
#
# Options:
#   --wait SECONDS   Wait time before capture (default: 3 for .sna, 8 for .tap)
#   --machine TYPE   Spectrum model: 48, 128, plus2, plus3 (default: 48)
#
# Examples:
#   spectrum-screenshot game.sna screenshot.png
#   spectrum-screenshot game.tap screenshot.png --wait 10
#   spectrum-screenshot game.sna screenshot.png --machine 128

set -e

# Default values
WAIT_TIME=""
MACHINE="48"
DISPLAY_NUM=99

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_TIME="$2"
            shift 2
            ;;
        --machine)
            MACHINE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: spectrum-screenshot INPUT OUTPUT [OPTIONS]"
            echo ""
            echo "Capture a screenshot from a ZX Spectrum program."
            echo ""
            echo "Arguments:"
            echo "  INPUT   .sna snapshot or .tap tape file"
            echo "  OUTPUT  Output PNG file path"
            echo ""
            echo "Options:"
            echo "  --wait SECONDS   Wait before capture (default: 3 for .sna, 8 for .tap)"
            echo "  --machine TYPE   48, 128, plus2, plus3 (default: 48)"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            if [[ -z "$INPUT_FILE" ]]; then
                INPUT_FILE="$1"
            elif [[ -z "$OUTPUT_FILE" ]]; then
                OUTPUT_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$INPUT_FILE" ]] || [[ -z "$OUTPUT_FILE" ]]; then
    echo "Error: INPUT and OUTPUT files required"
    echo "Usage: spectrum-screenshot INPUT.sna OUTPUT.png [--wait SECONDS]"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Determine file type and set defaults
EXT="${INPUT_FILE##*.}"
EXT="${EXT,,}"  # lowercase

if [[ "$EXT" == "sna" ]] || [[ "$EXT" == "z80" ]]; then
    LOAD_OPT="--snapshot"
    [[ -z "$WAIT_TIME" ]] && WAIT_TIME=3
elif [[ "$EXT" == "tap" ]] || [[ "$EXT" == "tzx" ]]; then
    LOAD_OPT="--tape"
    [[ -z "$WAIT_TIME" ]] && WAIT_TIME=8
else
    echo "Error: Unknown file type: $EXT (expected .sna, .z80, .tap, or .tzx)"
    exit 1
fi

# Start virtual framebuffer
Xvfb :${DISPLAY_NUM} -screen 0 800x600x24 >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1

# Set display
export DISPLAY=:${DISPLAY_NUM}

# Cleanup function
cleanup() {
    kill $FUSE_PID 2>/dev/null || true
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# Run Fuse
timeout $((WAIT_TIME + 5))s fuse --machine "$MACHINE" --no-sound --auto-load $LOAD_OPT "$INPUT_FILE" >/dev/null 2>&1 &
FUSE_PID=$!

# Wait for Fuse to start
sleep 1

# Dismiss ROM warning dialog (if any)
xdotool key Return 2>/dev/null || true

# Wait for program to run
sleep "$WAIT_TIME"

# Capture screenshot
import -window root "$OUTPUT_FILE"

# Crop to just the Spectrum display area (approximately)
# The Fuse window is typically centered in the 800x600 virtual screen
# We can optionally crop to the actual display area

echo "Screenshot saved: $OUTPUT_FILE"
