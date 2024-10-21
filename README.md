# Bash Schedules

This project is a Bash script that reads a schedule from a `.txt` file and displays a visual table of the schedules for each day of the week. It helps manage and visualize multiple people's schedules in a clear, easy-to-read format.

![Schedule Preview](./schedule_preview.png)

## Features
- Displays a schedule for the specified day (or the current day by default).
- Visualizes time slots for each person in the schedule.
- Easily customizable to include additional days and times.

## Usage

### 1. Clone the Repository:
```bash
git clone https://github.com/charlielovett/bash-schedules.git
cd bash-schedules
```

### 2. Add your Schedule File:
- Enter the path to your schedule.txt file at the top of schedule_table.sh.
- Replace the schedule.txt file with your own schedules that you want to display using the following format, where times are in military time (HH:MM):
```bash
Name Day StartTime EndTime
```
- Example:
```bash
Charlie Monday 11:00 12:00
Charlie Monday 15:00 15:50
Charlie Monday 16:00 16:50
Ben Monday 11:00 12:20
```

### 3. Run the Script:
- Show today's schedule:
```bash
./schedule_table.sh
```
- Show a specific day's schedule:
```bash
./schedule_table.sh Monday
```
