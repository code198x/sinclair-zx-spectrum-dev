#!/bin/bash
# Input script to skip title and claim some cells for a screenshot
# Used for Ink War game screenshots (Unit 7+)
# Uses key down/up events for more reliable input

sleep 1

# Press space to skip title screen
xdotool key --delay 100 space
sleep 1

# Helper function to press a key reliably
press_key() {
    xdotool keydown "$1"
    sleep 0.1
    xdotool keyup "$1"
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
