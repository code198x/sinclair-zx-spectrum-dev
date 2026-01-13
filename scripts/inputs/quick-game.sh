#!/bin/bash
# Input script to play a quick game vs Easy AI to see results screen
# Human makes moves, AI (Easy = random) fills in the rest

sleep 1

# Press 2 to select AI Easy (fastest games)
xdotool keydown 2
sleep 0.1
xdotool keyup 2
sleep 1.5

# Helper function to press a key reliably
press_key() {
    xdotool keydown "$1"
    sleep 0.05
    xdotool keyup "$1"
    sleep 0.8
}

# Human claims cells rapidly - make 32 moves total (human gets 32, AI gets 32)
# The game ends when all 64 cells are claimed

# Row 0: claim across
for i in {1..8}; do
    press_key space
    press_key p
done

# Move down and claim row 1
press_key a
for i in {1..7}; do
    press_key space
    press_key o
done
press_key space

# Move down and claim row 2
press_key a
for i in {1..7}; do
    press_key space
    press_key p
done
press_key space

# Move down and claim row 3
press_key a
for i in {1..7}; do
    press_key space
    press_key o
done
press_key space

# Keep claiming - the AI fills in between our moves
# After ~32 human moves, game should be over

# Final wait for results screen
sleep 2
