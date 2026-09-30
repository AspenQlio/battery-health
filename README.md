# Battery Health Monitor

> **[Español] → La documentación completa, con instalación paso a paso y los errores que me encontré, está en [README.es.md](README.es.md).**

A lightweight Linux utility designed to extract and monitor hardware battery telemetry without relying on heavy desktop environments.

## Purpose
Desktop environments often obscure raw hardware metrics. This tool reads directly from the Linux `/sys/class/power_supply` interface to provide accurate cycle counts, current capacity, and design degradation metrics. 

## Features
- Reads raw `sysfs` battery endpoints.
- Calculates true degradation (Full Charge Capacity vs Design Capacity).
- Minimal footprint: runs entirely in the terminal without GUI overhead.
- Experimental Windows support via WMI.

## Usage
Execute the script directly from your terminal to retrieve the health diagnostic:
```bash
python battery_health.py
```
