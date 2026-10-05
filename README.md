# Battery Health Reader

> A lightweight, zero-dependency script to accurately read laptop battery health, design capacity, and charge cycles directly from hardware sensors.

Battery Health Reader bypasses unreliable OS percentage estimates to show you the true physical degradation of your battery. By reading the actual hardware controller data, it calculates the real ratio between current maximum capacity and original design capacity, giving you the true health of the battery.

## Features

- **Hardware-Level Accuracy:** Reads directly from `/sys/class/power_supply` (Linux) or WMI/CIM (Windows).
- **True Health Calculation:** Computes actual degradation instead of current charge level.
- **Cycle Count:** Displays total charge cycles to identify heavily used batteries.
- **Zero Dependencies:** Written in Bash and `awk` for Linux, requires no `sudo` or heavy installations.
- **Diagnosis Output:** Automatically categorizes battery status (Excellent, Good, Degraded).

## Architecture

- **Linux (Primary):** Bash script -> `/sys/class/power_supply/BAT0` -> `awk` processing.
- **Windows (Experimental):** `.cmd` wrapper -> `.ps1` script -> WMI/CIM `Win32_Battery`.

## Tech Stack

- **Primary:** Bash, `awk` (Linux)
- **Experimental:** PowerShell, CMD, WMI (Windows)

## Getting Started

### Prerequisites

- **Linux:** Bash, `awk`, read access to `/sys/class/power_supply/` (standard on most distros).
- **Windows:** Windows 10/11, PowerShell 5+, WMI/CIM enabled.

### Installation & Usage (Linux)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AspenQlio/battery-health.git
   cd battery-health
   ```

2. **Make it executable:**
   ```bash
   chmod +x battery-health.sh
   ```

3. **Run the script:**
   ```bash
   ./battery-health.sh
   ```
   *(If your battery isn't BAT0, specify it: `./battery-health.sh /sys/class/power_supply/BAT1`)*

### Installation & Usage (Windows - Experimental)

1. Download `battery-health.ps1` and `battery-health.cmd` to the same folder.
2. Double-click `battery-health.cmd` to run.
   *Note: Windows support is experimental. If it fails, try running PowerShell as Administrator.*

## License

This project is licensed under the MIT License.
