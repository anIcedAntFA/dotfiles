#!/bin/bash

# Redirect all output (stdout and stderr) to a log file for debugging
exec > ~/.local/share/waypaper_cycle.log 2>&1

# Define the interval in seconds (e.g., 600 seconds = 10 minutes)
# Adjust this to your desired wallpaper change frequency
INTERVAL_SECONDS=60 # Set to 60 seconds (1 minute) for testing

# Define your wallpaper folder
WALLPAPER_FOLDER="$HOME/workspace/github.com/anIcedAntFA/linux-setup/images/wallpaper" # Verify this path

# Define your monitor names precisely as returned by `swww query`
MONITOR_1="DP-1"
MONITOR_2="HDMI-A-1"

# SWWW Transition Settings (from your config.ini)
TRANSITION_TYPE="grow"
TRANSITION_STEP=1
TRANSITION_ANGLE=0
TRANSITION_DURATION=2000 # milliseconds
TRANSITION_FPS=60

# Function to get a random image from the folder
get_random_image() {
    find "$WALLPAPER_FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | shuf -n 1
}

echo "--- Wallpaper cycling script started at $(date) ---"
echo "Folder: $WALLPAPER_FOLDER"
echo "Monitors: $MONITOR_1, $MONITOR_2"
echo "Interval: $INTERVAL_SECONDS seconds"

# *** ADD THIS INITIAL SLEEP ***
echo "Waiting for swww-daemon to start fully (15 seconds)..."
sleep 15 # Wait for swww-daemon to be fully active (longer than its 10s autostart delay)
echo "Initial wait complete. Starting wallpaper loop."
# *****************************

while true; do
    echo "--- Cycling wallpapers at $(date) ---"

    # Get a random image for Monitor 1
    RANDOM_IMAGE_1=$(get_random_image)
    echo "Setting $RANDOM_IMAGE_1 on $MONITOR_1"
    swww img "$RANDOM_IMAGE_1" \
        --outputs "$MONITOR_1" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-step "$TRANSITION_STEP" \
        --transition-angle "$TRANSITION_ANGLE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS"

    # Get a random image for Monitor 2
    RANDOM_IMAGE_2=$(get_random_image)
    echo "Setting $RANDOM_IMAGE_2 on $MONITOR_2"
    swww img "$RANDOM_IMAGE_2" \
        --outputs "$MONITOR_2" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-step "$TRANSITION_STEP" \
        --transition-angle "$TRANSITION_ANGLE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS"

    echo "Wallpapers updated. Sleeping for $INTERVAL_SECONDS seconds..."
    sleep "$INTERVAL_SECONDS"
done