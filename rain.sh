#!/bin/bash

# '31' - Red
# '32' - Green
# '33' - Yellow
# '34' - Blue
# '35' - Magenta
# '36' - Cyan
# '37' - White

# Display help message
show_help() {
    echo "Usage: $0 [density] [character] [color code] [speed]"
    echo "  density     : Set the density of the raindrops (default 3)."
    echo "  character   : Choose the raindrop character (default '/')."
    echo "  color code  : ANSI color code for the raindrop (default 37 for white)."
    echo "  speed       : Choose speed from 1 (slowest) to 5 (fastest)."
    echo
    echo "Example: $0 5 '@' 32 3"
}

# Function to clear the screen and hide the cursor
initialize_screen() {
    clear
    tput civis  # Hide cursor
    height=$(tput lines)
    width=$(tput cols)
}

# Declare an associative array to hold the active raindrops
declare -A raindrops

# Function to place a raindrop at a random position
place_raindrop() {
    local x=$((RANDOM % width))
    local speed=$((RANDOM % (5 - speed_range + 1) + 1))  # Speed adjustments
    raindrops[$x]=0,$speed
}

# Function to move raindrops
move_raindrops() {
    clear  # Always clear the screen for each frame

    # Place new raindrops randomly based on specified density
    for ((i=0; i<density; i++)); do
        place_raindrop
    done

    # Print the raindrops and update their positions
    for x in "${!raindrops[@]}"; do
        IFS=, read y speed <<< "${raindrops[$x]}"
        tput cup $y $x
        echo -en "\e[${color}m${rain_char}\e[0m"  # Use specified color and character

        # Increment the raindrop down at its speed rate
        if ((y + speed < height)); then
            raindrops[$x]=$((y + speed)),$speed
        else
            unset raindrops[$x]  # Remove the raindrop if it reaches the bottom
        fi
    done
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Initialize the screen
initialize_screen

# Set variables from command-line arguments
density=${1:-3}  # Default density is 3
rain_char=${2-'/'}  # Correctly defaults to *, handling special characters
color=${3:-'37'}  # Default color blue (34)
speed_range=${4:-3}  # Default speed range is 3 (1 slowest, 5 fastest)

# Main loop to animate raindrops
trap "cleanup" SIGINT SIGTERM  # Properly handle user interruption
while true; do
    read -t 0.1 -n 1 key
    if [[ $key == "q" ]]; then
        break
    fi
    move_raindrops
done

# Function to reset terminal settings on exit
cleanup() {
    tput cnorm  # Show cursor
    clear
}
trap cleanup EXIT
