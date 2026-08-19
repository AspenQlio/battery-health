$ErrorActionPreference = "Stop"

function Convert-MWhToWh {
    param([double]$Value)
    return [math]::Round($Value / 1000, 2)
}

function Get-BatteryDiagnosis {
    param([double]$Health)

    if ($Health -ge 90) { return "Excelente / casi nueva" }
    if ($Health -ge 75) { return "Buena" }
    if ($Health -ge 60) { return "Usable, pero degradada" }
    return "Muy degradada"
}

$staticBattery = Get-CimInstance -Namespace "root\wmi" -ClassName "BatteryStaticData" -ErrorAction SilentlyContinue | Select-Object -First 1
$fullBattery = Get-CimInstance -Namespace "root\wmi" -ClassName "BatteryFullChargedCapacity" -ErrorAction SilentlyContinue | Select-Object -First 1
$statusBattery = Get-CimInstance -Namespace "root\wmi" -ClassName "BatteryStatus" -ErrorAction SilentlyContinue | Select-Object -First 1
$cycleBattery = Get-CimInstance -Namespace "root\wmi" -ClassName "BatteryCycleCount" -ErrorAction SilentlyContinue | Select-Object -First 1
$winBattery = Get-CimInstance -ClassName "Win32_Battery" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $staticBattery -or -not $fullBattery) {
    Write-Error "Windows no entrego datos suficientes de la bateria por WMI/CIM. Prueba abrir PowerShell como administrador o revisar si el fabricante expone estos datos."
}

$designMWh = [double]$staticBattery.DesignedCapacity
$fullMWh = [double]$fullBattery.FullChargedCapacity
$health = if ($designMWh -gt 0) { [math]::Round(($fullMWh / $designMWh) * 100, 1) } else { $null }
$currentPercent = if ($winBattery.EstimatedChargeRemaining -ne $null) { $winBattery.EstimatedChargeRemaining } else { "N/A" }
$status = if ($winBattery.Status) { $winBattery.Status } else { "N/A" }
$cycles = if ($cycleBattery -and $cycleBattery.CycleCount -ne $null) { $cycleBattery.CycleCount } else { "N/A" }
$name = if ($winBattery.Name) { $winBattery.Name } else { "N/A" }
$manufacturer = if ($winBattery.Manufacturer) { $winBattery.Manufacturer } else { "N/A" }
$serial = if ($staticBattery.SerialNumber) { $staticBattery.SerialNumber } else { "N/A" }

Write-Host "Bateria instalada"
Write-Host "================="
Write-Host ("Fabricante:        {0}" -f $manufacturer)
Write-Host ("Modelo:            {0}" -f $name)
Write-Host ("Serial/fecha:      {0}" -f $serial)
Write-Host ("Estado:            {0}" -f $status)
Write-Host ("Carga actual:      {0}%" -f $currentPercent)
Write-Host ""
Write-Host ("Capacidad maxima:  {0} Wh" -f (Convert-MWhToWh $fullMWh))
Write-Host ("Capacidad diseno:  {0} Wh" -f (Convert-MWhToWh $designMWh))
if ($health -ne $null) {
    Write-Host ("Salud bateria:     {0}%" -f $health)
    Write-Host ("Ciclos:            {0}" -f $cycles)
    Write-Host ("Diagnostico:        {0}" -f (Get-BatteryDiagnosis $health))
} else {
    Write-Host "Salud bateria:     N/A"
    Write-Host ("Ciclos:            {0}" -f $cycles)
}
