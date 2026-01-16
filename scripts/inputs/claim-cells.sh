#!/bin/bash
# Input script to skip title and claim some cells for a screenshot
# Used for Ink War game screenshots (Unit 7+)
# Uses key down/up events for more reliable input
#
# Environment: FUSE_WINDOW is set by spectrum-video.sh
#

# Focus the Fuse window first
xdotool windowactivate --sync "$FUSE_WINDOW" 2>/dev/null || true
sleep 0.5

# Press 2 to select AI Easy mode (gets us to gameplay fastest)
xdotool key --window "$FUSE_WINDOW" 2
sleep 1.5

# Helper function to press a key reliably
press_key() {
    xdotool key --window "$FUSE_WINDOW" "$1"
    sleep 0.3
}

# Claim first cell (P1 - red) at 0,0
press_key space

# Move right and claim (P2 - blue) at 0,1
press_key p
press_key space

# Move down and claim (P1 - red) at 1,1
press_key a
press_key space

# Move left and claim (P2 - blue) at 1,0
press_key o
press_key space

# Move down and claim (P1 - red) at 2,0
press_key a
press_key space

# Move right twice and claim (P2 - blue) at 2,2
press_key p
press_key p
press_key space

sleep 0.5
