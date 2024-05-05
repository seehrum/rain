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
    echo "Usage: $0 [density] [characters] [color code] [speed]"
    echo "  density     : Set the density of the raindrops (default 3)."
    echo "  characters  : Characters to use as raindrops (default '/')."
    echo "  color code  : ANSI color code for the raindrop (default 37 for white)."
    echo "  speed       : Choose speed from 1 (slowest) to 5 (fastest)."
    echo
    echo "Example: $0 5 '/@|' 32 3"
}

# Function to clear the screen and hide the cursor
initialize_screen() {
    clear
    tput civis  # Hide cursor
    stty -echo  # Turn off key echo
    height=$(tput lines)
    width=$(tput cols)
}

# Declare an associative array to hold the active raindrops
declare -A raindrops

# Function to place raindrops based on density and characters
place_raindrop() {
    local chars=($rain_char) # Split characters into an array
    for ((i=0; i<density; i++)); do
        for ch in "${chars[@]}"; do
            local x=$((RANDOM % width))
            local speed=$((RANDOM % speed_range + 1))
            raindrops["$x,0,$ch"]=$speed  # Store character with its speed at initial position
        done
    done
}

# Function to move raindrops
move_raindrops() {
    declare -A new_positions
    # Buffer output for efficiency
    local buffer=""

    # Process each raindrop to update or remove
    for pos in "${!raindrops[@]}"; do
        IFS=',' read -r x y ch <<< "$pos"
        local speed=${raindrops[$pos]}
        local newY=$((y + speed))
        
        # Erase the current position by printing a space
        buffer+="\e[${y};${x}H "

        # Update or remove the raindrop
        if [ $newY -lt $height ]; then
            buffer+="\e[${newY};${x}H\e[${color}m${ch}\e[0m"
            new_positions["$x,$newY,$ch"]=$speed
        fi
    done

    # Update raindrops with new positions
    raindrops=()
    for k in "${!new_positions[@]}"; do
        raindrops["$k"]=${new_positions["$k"]}
    done

    # Output the buffer
    echo -ne "$buffer"
}

# Function to reset terminal settings on exit
cleanup() {
    tput cnorm  # Show cursor
    stty echo   # Turn on key echo
    clear
}

# Handle user interruption
trap cleanup SIGINT SIGTERM EXIT

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Initialize the screen and variables
initialize_screen
density=${1:-2}
rain_char=${2:-'|'}  # Treat input as separate characters for multiple raindrops
color=${3:-'37'}
speed_range=${4:-2}

# Main animation loop
while true; do
    # Non-blocking read setup
    read -s -n 1 -t 0.01 key
    if [[ $key == "q" ]]; then
        cleanup
        exit 0
    fi
    place_raindrop  # Place new raindrops based on density and characters
    move_raindrops  # Move existing raindrops
    sleep 0.01  # Adjust this as necessary for the desired effect
done
