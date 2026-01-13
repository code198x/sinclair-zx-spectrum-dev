#!/bin/bash
# Input script to demo AI Hard mode
# Presses 4 to select AI Hard, then makes a few moves

sleep 1

# Press 4 to select AI Hard mode
xdotool keydown 4
sleep 0.1
xdotool keyup 4
sleep 1.5

# Helper function to press a key reliably
press_key() {
    xdotool keydown "$1"
    sleep 0.1
    xdotool keyup "$1"
    sleep 0.5
}

# Human (P1) claims at 0,0
press_key space
sleep 1

# Human moves down-right and claims
press_key a
press_key p
press_key space
sleep 1

# Human moves down again and claims
press_key a
press_key space
sleep 1

# Final pause for display
sleep 0.5
