#!/usr/bin/env bash
set -euo pipefail

BATTERY_DIR="${1:-/sys/class/power_supply/BAT0}"

read_value() {
  local file="$1"
  if [[ -r "$file" ]]; then
    tr -d '\n' < "$file"
  else
    printf 'N/A'
  fi
}

percent() {
  local current="$1"
  local design="$2"
  awk -v current="$current" -v design="$design" \
    'BEGIN { if (design > 0) printf "%.1f", (current / design) * 100; else print "N/A" }'
}

micro_wh_to_wh() {
  local micro_wh="$1"
  awk -v value="$micro_wh" 'BEGIN { printf "%.2f", value / 1000000 }'
}

charge_to_wh() {
  local micro_amp_hours="$1"
  local micro_volts="$2"
  awk -v charge="$micro_amp_hours" -v voltage="$micro_volts" \
    'BEGIN { printf "%.2f", (charge / 1000000) * (voltage / 1000000) }'
}

diagnosis() {
  local health="$1"
  awk -v health="$health" 'BEGIN {
    if (health >= 90) print "Excelente / casi nueva"
    else if (health >= 75) print "Buena"
    else if (health >= 60) print "Usable, pero degradada"
    else print "Muy degradada"
  }'
}

if [[ ! -d "$BATTERY_DIR" ]]; then
  printf 'No encontre la bateria en: %s\n' "$BATTERY_DIR" >&2
  printf 'Uso: %s [/sys/class/power_supply/BATX]\n' "$(basename "$0")" >&2
  exit 1
fi

manufacturer="$(read_value "$BATTERY_DIR/manufacturer")"
model="$(read_value "$BATTERY_DIR/model_name")"
serial="$(read_value "$BATTERY_DIR/serial_number")"
status="$(read_value "$BATTERY_DIR/status")"
charge_percent="$(read_value "$BATTERY_DIR/capacity")"
cycles="$(read_value "$BATTERY_DIR/cycle_count")"

energy_full="$(read_value "$BATTERY_DIR/energy_full")"
energy_design="$(read_value "$BATTERY_DIR/energy_full_design")"
charge_full="$(read_value "$BATTERY_DIR/charge_full")"
charge_design="$(read_value "$BATTERY_DIR/charge_full_design")"
voltage_design="$(read_value "$BATTERY_DIR/voltage_min_design")"

if [[ "$energy_full" =~ ^[0-9]+$ && "$energy_design" =~ ^[0-9]+$ ]]; then
  full_wh="$(micro_wh_to_wh "$energy_full")"
  design_wh="$(micro_wh_to_wh "$energy_design")"
  health="$(percent "$energy_full" "$energy_design")"
elif [[ "$charge_full" =~ ^[0-9]+$ && "$charge_design" =~ ^[0-9]+$ && "$voltage_design" =~ ^[0-9]+$ ]]; then
  full_wh="$(charge_to_wh "$charge_full" "$voltage_design")"
  design_wh="$(charge_to_wh "$charge_design" "$voltage_design")"
  health="$(percent "$charge_full" "$charge_design")"
else
  full_wh="N/A"
  design_wh="N/A"
  health="N/A"
fi

printf 'Bateria instalada\n'
printf '=================\n'
printf 'Fabricante:        %s\n' "$manufacturer"
printf 'Modelo:            %s\n' "$model"
printf 'Serial/fecha:      %s\n' "$serial"
printf 'Estado:            %s\n' "$status"
printf 'Carga actual:      %s%%\n' "$charge_percent"
printf '\n'
printf 'Capacidad maxima:  %s Wh\n' "$full_wh"
printf 'Capacidad diseno:  %s Wh\n' "$design_wh"
printf 'Salud bateria:     %s%%\n' "$health"
printf 'Ciclos:            %s\n' "$cycles"

if [[ "$health" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  printf 'Diagnostico:        %s\n' "$(diagnosis "$health")"
fi
