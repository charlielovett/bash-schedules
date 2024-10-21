#!/bin/bash

# Insert your schedule path here
SCHEDULE_PATH=$path/to/schedule.txt

# Define the time range (e.g., from 8:00 AM to 6:00 PM)
START_TIME="08:00"
END_TIME="19:00"

# Total width of the schedule area in characters
SCHEDULE_WIDTH=66

# Get the day of the week from the argument or default to the current day
if [ $# -gt 0 ]; then
    DAY_OF_WEEK="$1"
else
    DAY_OF_WEEK=$(date +%A)
fi

# Ensure the day of the week is in standard capitalization (e.g., "Monday")
# Convert the first character to uppercase and the rest to lowercase
DAY_OF_WEEK="$(tr '[:lower:]' '[:upper:]' <<< "${DAY_OF_WEEK:0:1}")$(tr '[:upper:]' '[:lower:]' <<< "${DAY_OF_WEEK:1}")"

# Function to convert HH:MM to total minutes
time_to_minutes() {
    IFS=':' read -r hour minute <<< "$1"
    echo $((10#$hour * 60 + 10#$minute))
}

# Function to convert total minutes to 12-hour format without space (e.g., '8am')
minutes_to_ampm() {
    hour=$(($1 / 60))
    ampm="am"
    if (( hour == 0 )); then
        hour=12
    elif (( hour == 12 )); then
        ampm="pm"
    elif (( hour > 12 )); then
        hour=$((hour - 12))
        ampm="pm"
    fi
    printf "%d%s" "$hour" "$ampm"
}

# Arrays to hold friend names and their schedules
names=()
schedules=()

# Read schedule.txt
while read -r name day start end; do
    # Only process entries for the specified day
    if [[ "$day" != "$DAY_OF_WEEK" ]]; then
        continue
    fi

    # Check if the name already exists
    index=-1
    for i in "${!names[@]}"; do
        if [[ "${names[$i]}" == "$name" ]]; then
            index=$i
            break
        fi
    done

    if [[ $index -ge 0 ]]; then
        # Append to existing schedule
        schedules[$index]+=" $start-$end"
    else
        # Add new name and schedule
        names+=("$name")
        schedules+=("$start-$end")
    fi
done < $SCHEDULE_PATH

# Check if there are any schedules for the specified day
if [[ ${#names[@]} -eq 0 ]]; then
    echo "No schedules found for $DAY_OF_WEEK."
    exit 0
fi

# Convert times to minutes
start_minutes=$(time_to_minutes "$START_TIME")
end_minutes=$(time_to_minutes "$END_TIME")
total_minutes=$(( end_minutes - start_minutes ))

# Calculate total table width (Friend column width + schedule width)
FRIEND_COL_WIDTH=10
TOTAL_TABLE_WIDTH=$((FRIEND_COL_WIDTH + SCHEDULE_WIDTH))

# Print the day of the week centered over the table
printf "\n"
printf "%*s\n" $(( (TOTAL_TABLE_WIDTH + ${#DAY_OF_WEEK}) / 2 )) "$DAY_OF_WEEK"
printf "\n"

# Print the header row (times)
printf "%-10s"

# Calculate label intervals (e.g., every hour)
label_interval=60  # in minutes
num_labels=$(( total_minutes / label_interval ))

# Adjust space width for labels
space_width=$(( SCHEDULE_WIDTH / num_labels ))

# Store positions of hour marks for ticks
hour_positions=()

for ((i=0; i<=num_labels; i++)); do
    current_time=$(( start_minutes + i * label_interval ))
    label="$(minutes_to_ampm $current_time)"

    # Calculate the position for the tick
    position=$(( (i * (SCHEDULE_WIDTH - 1)) / num_labels ))
    hour_positions+=($position)

    if (( i < num_labels )); then
        next_position=$(( ((i+1) * (SCHEDULE_WIDTH - 1)) / num_labels ))
        space_width=$(( next_position - position ))
    else
        space_width=$(( SCHEDULE_WIDTH - position ))
    fi

    padding_left=$(( (space_width - ${#label}) / 2 ))
    padding_right=$(( space_width - ${#label} - padding_left ))

    # Modify here: Skip printing the last label
    if (( i < num_labels )); then
        printf "%*s%s%*s" $padding_left "" "$label" $padding_right ""
    else
        # For the last interval, print spaces to maintain alignment
        printf "%*s" $space_width ""
    fi
done
echo

# Print separator line with vertical ticks
printf '%-10s' ""
for ((i=0; i<SCHEDULE_WIDTH; i++)); do
    if printf '%s\n' "${hour_positions[@]}" | grep -q -w "$i"; then
        printf "+"
    else
        printf "-"
    fi
done
echo

# Print the schedule for each friend
for idx in "${!names[@]}"; do
    name="${names[$idx]}"
    printf "%-10s" "$name"

    # Initialize the schedule line as an array with spaces
    line=()
    for ((i=0; i<SCHEDULE_WIDTH; i++)); do
        line[$i]=" "
    done

    # Read the time ranges into an array
    IFS=' ' read -r -a time_ranges <<< "${schedules[$idx]}"
    for time_range in "${time_ranges[@]}"; do
        IFS='-' read -r start_time end_time <<< "$time_range"
        start_min=$(time_to_minutes "$start_time")
        end_min=$(time_to_minutes "$end_time")

        # Skip time ranges that are entirely outside the display range
        if (( end_min <= start_minutes || start_min >= end_minutes )); then
            continue
        fi

        # Adjust start and end times to be within display range
        if (( start_min < start_minutes )); then
            start_min=$start_minutes
        fi
        if (( end_min > end_minutes )); then
            end_min=$end_minutes
        fi

        # Calculate the positions on the schedule line
        start_pos=$(( ((start_min - start_minutes) * SCHEDULE_WIDTH) / total_minutes ))
        end_pos=$(( ((end_min - start_minutes) * SCHEDULE_WIDTH) / total_minutes ))

        # Replace spaces with occupied character
        occupied_char="█"
        for ((i=start_pos; i<end_pos; i++)); do
            line[$i]="$occupied_char"
        done
    done

    # Convert line array to string
    line_str=""
    for ((i=0; i<SCHEDULE_WIDTH; i++)); do
        line_str+="${line[$i]}"
    done

    printf "%s\n" "$line_str"
done

