# Battery Health Reader for Linux + Experimental Windows

> Objective: Quickly check if a laptop battery is healthy or degraded by displaying its real maximum capacity, design capacity, health percentage, and charge cycles without installing heavy programs.

## 1. Why use this instead of just checking the battery percentage?

The percentage shown by the OS (`80%`, `50%`, etc.) only tells you how much charge the battery holds **right now**. It does not tell you how much energy it can store compared to when it was brand new.

To know if a battery is truly healthy, you need to look at three metrics:

- **Design Capacity:** How much energy it should store when new, e.g., `51 Wh`.
- **Current Maximum Capacity:** How much energy it can actually store today, e.g., `31 Wh`.
- **Cycles:** How many full charge cycles the battery controller reports.

With these, you can calculate battery health:

```text
health = current maximum capacity / design capacity * 100
```

If a battery reports `31 Wh` out of `51 Wh`, its real health is around `61%`. It might still work, but it is definitely not a new battery.

## 2. Architecture

```text
[Linux - Primary]
  battery-health.sh
      |
      v
  /sys/class/power_supply/BAT0
      |
      v
  capacity, health, cycles

[Windows - Experimental]
  battery-health.cmd
      |
      v
  battery-health.ps1
      |
      v
  WMI / CIM: root\wmi + Win32_Battery
      |
      v
  capacity, health, cycles
```

The concept is the same across both systems: read the data already provided by the battery firmware/controller and present it in an easily comparable format.

## 3. Requirements

### Linux - Primary

- Bash.
- `awk`.
- Read access to `/sys/class/power_supply/BAT0`.

It does not require `sudo` to read battery stats on most distributions.

### Windows - Experimental

- Windows 10 or Windows 11.
- PowerShell 5 or higher.
- WMI/CIM enabled and working.

> **Status:** The Windows version is included as experimental, but **it was tested once and did not work**. We need to capture the exact error message on Windows to fix it. The Linux version was successfully executed and verified on an HP EliteBook 840 G4.

It shouldn't require administrator privileges. If Windows does not return all the data, try opening PowerShell as an administrator.

## 4. Step-by-step Installation

### 4.1 Linux - Primary

Enter the project folder:

```bash
cd ~/battery-health
```

Grant execution permissions:

```bash
chmod +x battery-health.sh
```

Run the script:

```bash
./battery-health.sh
```

If your battery doesn't show up as `BAT0`, you can pass the correct path manually:

```bash
./battery-health.sh /sys/class/power_supply/BAT1
```

### 4.2 Windows - Experimental

> **Warning:** This section is not yet considered functional. The Windows script failed during a real test; we still need to review the exact error to fix the WMI/CIM reading.

Copy these two files to the same folder on Windows:

```text
battery-health.ps1
battery-health.cmd
```

Run it by double-clicking on:

```text
battery-health.cmd
```

Or from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\battery-health.ps1
```

The `.cmd` file calls the PowerShell script using `ExecutionPolicy Bypass` only for that specific execution.

## 5. Real Output and Data

Real output obtained from the HP EliteBook 840 G4 with the battery installed when this project was created:

```text
Installed Battery
=================
Manufacturer:      Hewlett-Packard
Model:             Primary
Serial/Date:       00210 2018/05/29
Status:            Charging
Current Charge:    0%

Max Capacity:      31.28 Wh
Design Capacity:   51.05 Wh
Battery Health:    61.3%
Cycles:            329
Diagnosis:         Usable, but degraded
```

Quick interpretation:

| Health | Diagnosis |
|---:|---|
| 90% or more | Excellent / almost new |
| 75% to 89% | Good |
| 60% to 74% | Usable, but degraded |
| Less than 60% | Highly degraded |

## 6. Verification

On Linux:

```bash
bash -n battery-health.sh
./battery-health.sh
```

The first line checks for syntax errors. The second verifies that the script can actually read the installed battery.

On Windows, the pending test is to run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\battery-health.ps1
```

If it fails, copy the full error message so the experimental version can be fixed.

## 7. Errors I encountered (and how to fix them)

### Error 1: Linux says it cannot find `/sys/class/power_supply/BAT0`

- **Cause:** Some laptops expose the battery as `BAT1`, `CMB0`, or another name.
- **Solution:** List available batteries:

  ```bash
  ls /sys/class/power_supply
  ```

  And pass the correct path:

  ```bash
  ./battery-health.sh /sys/class/power_supply/BAT1
  ```

### Error 2: Windows shows capacity but no cycles

- **Cause:** Not all manufacturers expose `BatteryCycleCount` through WMI.
- **Solution:** If it says `N/A`, the script isn't necessarily broken; it just means Windows didn't receive that data from the battery firmware.

### Error 3: PowerShell blocks the script

- **Cause:** Windows execution policies might block downloaded or copied `.ps1` scripts.
- **Solution:** Run the `.cmd` file, which uses:

  ```powershell
  -ExecutionPolicy Bypass
  ```

  This bypasses the policy only for that execution, without changing global system settings.

### Error 4: A "new" battery shows many cycles

- **Cause:** The script reads what the internal battery controller reports. If it shows hundreds of cycles and low health, it's likely not new even if it looks physically brand new.
- **Solution:** Compare it against the design capacity. For a truly new battery, the health should be much closer to `100%` rather than `60%`.

## 8. Conclusions

- The charge percentage is useless for determining if a battery is healthy.
- The important metric is the ratio between **current maximum capacity** and **design capacity**.
- The primary script is `battery-health.sh` for Linux.
- On Linux, data is read from `/sys/class/power_supply`.
- The Windows version remains experimental because it failed in a real test and the exact error still needs to be reviewed.
- If a used battery retains only `60%` health, it might be usable, but it shouldn't be sold as new.
