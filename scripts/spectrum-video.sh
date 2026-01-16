#!/bin/bash
#
# spectrum-video - Capture video from ZX Spectrum program with input injection
#
# Usage:
#   spectrum-video program.sna output.mp4 [OPTIONS]
#   spectrum-video program.tap output.mp4 [OPTIONS]
#
# Options:
#   --wait SECONDS     Wait time before recording (default: 3 for .sna, 8 for .tap)
#   --duration SECONDS Recording duration (default: 10)
#   --fps N            Frame rate (default: 50 for PAL)
#   --scale N          Scale factor 1-4 (default: 2)
#   --machine TYPE     Spectrum model: 48, 128, plus2, plus3 (default: 48)
#   --input SCRIPT     Input script to run after wait
#
# Input Scripts:
#   Input scripts are shell scripts that run in the same X display.
#   Use xdotool to send input:
#
#     #!/bin/bash
#     xdotool key space          # Press space
#     sleep 0.5
#     xdotool key q a o p        # QAOP controls
#
#   Common ZX Spectrum controls:
#     Q/A = up/down, O/P = left/right
#     Space = fire/action
#     0-9 = number keys (menu selection)
#     Enter = confirm
#
# Examples:
#   spectrum-video game.sna gameplay.mp4
#   spectrum-video game.sna demo.mp4 --wait 2 --duration 30
#   spectrum-video game.sna demo.mp4 --input scripts/inputs/gameplay-demo.sh

set -e

# Default values
WAIT_TIME=""
DURATION=10
FPS=50
SCALE=2
MACHINE="48"
DISPLAY_NUM=99
INPUT_SCRIPT=""

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_TIME="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --fps)
            FPS="$2"
            shift 2
            ;;
        --scale)
            SCALE="$2"
            shift 2
            ;;
        --machine)
            MACHINE="$2"
            shift 2
            ;;
        --input)
            INPUT_SCRIPT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: spectrum-video INPUT OUTPUT [OPTIONS]"
            echo ""
            echo "Capture video from a ZX Spectrum program with input injection."
            echo ""
            echo "Arguments:"
            echo "  INPUT   .sna, .z80, .tap, or .tzx file"
            echo "  OUTPUT  Output video file (mp4, webm, gif)"
            echo ""
            echo "Options:"
            echo "  --wait SECONDS     Wait before recording (default: 3/.sna, 8/.tap)"
            echo "  --duration SECONDS Recording length (default: 10)"
            echo "  --fps N            Frame rate (default: 50)"
            echo "  --scale N          Scale factor 1-4 (default: 2)"
            echo "  --machine TYPE     48, 128, plus2, plus3 (default: 48)"
            echo "  --input SCRIPT     Input script for key injection"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Common controls: Q/A up/down, O/P left/right, Space fire"
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
    echo "Usage: spectrum-video INPUT OUTPUT [OPTIONS]"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

if [[ -n "$INPUT_SCRIPT" ]] && [[ ! -f "$INPUT_SCRIPT" ]]; then
    echo "Error: Input script not found: $INPUT_SCRIPT"
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

# Determine output format from extension
OUT_EXT="${OUTPUT_FILE##*.}"
OUT_EXT="${OUT_EXT,,}"

case "$OUT_EXT" in
    mp4)
        # crop=trunc(iw/2)*2:trunc(ih/2)*2 ensures even dimensions for h264
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p"
        ;;
    webm)
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libvpx-vp9 -crf 30 -b:v 0"
        ;;
    gif)
        FFMPEG_CODEC="-vf fps=25,scale=320:-2:flags=lanczos"
        ;;
    *)
        echo "Warning: Unknown output format '$OUT_EXT', using mp4 settings"
        FFMPEG_CODEC="-vf crop=trunc(iw/2)*2:trunc(ih/2)*2 -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p"
        ;;
esac

# Calculate window size (ZX Spectrum: 256x192 display + 48px border each side = 352x296)
# Fuse SDL at 2x is 512x384 by default, but actual window can be 640x480
WIDTH=$((256 * SCALE))
HEIGHT=$((192 * SCALE))

# Start virtual framebuffer - Fuse window can be up to 640x480 at position ~250,260
# Need at least 1024x900 to accommodate window placement
SCREEN_W=1200
SCREEN_H=1000
Xvfb :${DISPLAY_NUM} -screen 0 ${SCREEN_W}x${SCREEN_H}x24 >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1

# Set display
export DISPLAY=:${DISPLAY_NUM}

# Start window manager (required for xdotool input injection)
openbox >/dev/null 2>&1 &
OPENBOX_PID=$!
sleep 0.5

# Cleanup function
cleanup() {
    kill $FUSE_PID 2>/dev/null || true
    kill $OPENBOX_PID 2>/dev/null || true
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# Total runtime needed
TOTAL_TIME=$((WAIT_TIME + DURATION + 15))

# Run Fuse with SDL backend
echo "Starting Fuse emulator..."
timeout ${TOTAL_TIME}s fuse-sdl \
    --machine "$MACHINE" \
    --no-sound \
    --auto-load \
    -g ${SCALE}x \
    $LOAD_OPT "$INPUT_FILE" >/dev/null 2>&1 &
FUSE_PID=$!

# Wait for Fuse to start and create window
sleep 2

# Dismiss ROM warning dialog (if any)
xdotool key Return 2>/dev/null || true

# Find Fuse window
FUSE_WINDOW=""
for i in {1..10}; do
    FUSE_WINDOW=$(xdotool search --name "Fuse" 2>/dev/null | head -1)
    if [[ -n "$FUSE_WINDOW" ]]; then
        break
    fi
    sleep 0.5
done

if [[ -z "$FUSE_WINDOW" ]]; then
    echo "Warning: Could not find Fuse window, input injection may not work"
fi

# Wait for Spectrum to boot and program to start
echo "Waiting ${WAIT_TIME}s for boot..."
sleep "$WAIT_TIME"

# Run input script if provided
if [[ -n "$INPUT_SCRIPT" ]]; then
    echo "Running input script: $INPUT_SCRIPT"
    # Export window ID for scripts that want it
    export FUSE_WINDOW
    bash "$INPUT_SCRIPT"
    sleep 0.5
fi

echo "Recording ${DURATION}s of video..."

# Get window geometry for precise capture
GRAB_X=0
GRAB_Y=0
GRAB_W=$WIDTH
GRAB_H=$HEIGHT

if [[ -n "$FUSE_WINDOW" ]]; then
    # Get actual window geometry
    GEOM=$(xdotool getwindowgeometry "$FUSE_WINDOW" 2>/dev/null)
    if [[ -n "$GEOM" ]]; then
        # Parse "  Position: X,Y (screen: 0)" and "  Geometry: WxH"
        GRAB_X=$(echo "$GEOM" | grep Position | sed 's/.*Position: \([0-9]*\),.*/\1/')
        GRAB_Y=$(echo "$GEOM" | grep Position | sed 's/.*Position: [0-9]*,\([0-9]*\).*/\1/')
        GEOM_SIZE=$(echo "$GEOM" | grep Geometry | sed 's/.*Geometry: \([0-9]*\)x\([0-9]*\).*/\1x\2/')
        GRAB_W=$(echo "$GEOM_SIZE" | cut -dx -f1)
        GRAB_H=$(echo "$GEOM_SIZE" | cut -dx -f2)
        echo "Window geometry: ${GRAB_W}x${GRAB_H} at ${GRAB_X},${GRAB_Y}"
    fi
fi

# Capture video
ffmpeg -y \
    -f x11grab \
    -framerate "$FPS" \
    -video_size "${GRAB_W}x${GRAB_H}" \
    -i ":${DISPLAY_NUM}+${GRAB_X},${GRAB_Y}" \
    -t "$DURATION" \
    $FFMPEG_CODEC \
    "$OUTPUT_FILE" \
    2>/dev/null

# Report result
if [[ -f "$OUTPUT_FILE" ]]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "Video saved: $OUTPUT_FILE ($SIZE)"
else
    echo "Error: Failed to create video"
    exit 1
fi
