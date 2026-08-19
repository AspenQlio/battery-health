# Lector de salud de batería para Linux + Windows

> Objetivo: revisar rápido si una batería de laptop está buena o degradada, mostrando capacidad máxima real, capacidad de diseño, porcentaje de salud y ciclos de carga sin instalar programas pesados.

## 1. ¿Por qué esto y no solo mirar el porcentaje de batería?

El porcentaje que muestra el sistema (`80%`, `50%`, etc.) solo dice cuánta carga tiene la batería **en este momento**. No dice cuánta energía puede guardar comparada con cuando era nueva.

Para saber si una batería sirve de verdad hay que mirar tres datos:

- **Capacidad de diseño:** lo que debería guardar nueva, por ejemplo `51 Wh`.
- **Capacidad máxima actual:** lo que realmente logra guardar hoy, por ejemplo `31 Wh`.
- **Ciclos:** cuántas cargas acumuladas reporta el controlador de la batería.

Con eso se calcula la salud:

```text
salud = capacidad maxima actual / capacidad de diseno * 100
```

Si una batería dice tener `31 Wh` de `51 Wh`, su salud real ronda el `61%`. Puede funcionar, pero no es una batería nueva.

## 2. Arquitectura

```text
[Linux]
  battery-health.sh
      |
      v
  /sys/class/power_supply/BAT0
      |
      v
  capacidad, salud, ciclos

[Windows]
  battery-health.cmd
      |
      v
  battery-health.ps1
      |
      v
  WMI / CIM: root\wmi + Win32_Battery
      |
      v
  capacidad, salud, ciclos
```

La idea es la misma en ambos sistemas: leer los datos que ya entrega el firmware/controlador de la batería y presentarlos en un formato fácil de comparar.

## 3. Requisitos

### Linux

- Bash.
- `awk`.
- Acceso de lectura a `/sys/class/power_supply/BAT0`.

No requiere `sudo` para leer la batería en la mayoría de distribuciones.

### Windows

- Windows 10 o Windows 11.
- PowerShell 5 o superior.
- WMI/CIM funcionando.

> **Estado:** la versión de Windows está incluida, pero todavía **no fue testeada en una máquina Windows real**. La dejé documentada para probarla después; la versión Linux sí fue ejecutada y verificada en la HP EliteBook 840 G4.

No debería requerir permisos de administrador. Si Windows no entrega todos los datos, probar abriendo PowerShell como administrador.

## 4. Instalación paso a paso

### 4.1 Linux

Entrar a la carpeta del proyecto:

```bash
cd ~/battery-health
```

Dar permisos de ejecución:

```bash
chmod +x battery-health.sh
```

Ejecutar:

```bash
./battery-health.sh
```

Si la batería no aparece como `BAT0`, se puede pasar la ruta manualmente:

```bash
./battery-health.sh /sys/class/power_supply/BAT1
```

### 4.2 Windows

> **Aviso:** esta sección aún no está testeada en Windows. El script usa WMI/CIM estándar, pero falta validarlo en una instalación real de Windows.

Copiar estos dos archivos a la misma carpeta en Windows:

```text
battery-health.ps1
battery-health.cmd
```

Ejecutar con doble clic sobre:

```text
battery-health.cmd
```

O desde PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\battery-health.ps1
```

El `.cmd` existe para que sea más cómodo: llama al script de PowerShell con `ExecutionPolicy Bypass` solo para esa ejecución.

## 5. Captura y datos reales

Salida real obtenida en la HP EliteBook 840 G4 con la batería instalada al momento de crear este proyecto:

```text
Bateria instalada
=================
Fabricante:        Hewlett-Packard
Modelo:            Primary
Serial/fecha:      00210 2018/05/29
Estado:            Charging
Carga actual:      0%

Capacidad maxima:  31.28 Wh
Capacidad diseno:  51.05 Wh
Salud bateria:     61.3%
Ciclos:            329
Diagnostico:        Usable, pero degradada
```

Interpretación rápida:

| Salud | Diagnóstico |
|---:|---|
| 90% o más | Excelente / casi nueva |
| 75% a 89% | Buena |
| 60% a 74% | Usable, pero degradada |
| Menos de 60% | Muy degradada |

## 6. Verificación

En Linux:

```bash
bash -n battery-health.sh
./battery-health.sh
```

La primera línea revisa que no haya errores de sintaxis. La segunda comprueba que el script realmente pueda leer la batería instalada.

En Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\battery-health.ps1
```

Si imprime capacidad máxima, capacidad de diseño, salud y ciclos, está funcionando.

## 7. Errores que me encontré (y cómo resolverlos)

### Error 1: Linux dice que no encuentra `/sys/class/power_supply/BAT0`

- **Causa:** algunas laptops exponen la batería como `BAT1`, `CMB0` u otro nombre.
- **Solución:** listar las baterías disponibles:

  ```bash
  ls /sys/class/power_supply
  ```

  y pasar la ruta correcta:

  ```bash
  ./battery-health.sh /sys/class/power_supply/BAT1
  ```

### Error 2: Windows muestra capacidad pero no ciclos

- **Causa:** no todos los fabricantes exponen `BatteryCycleCount` por WMI.
- **Solución:** si sale `N/A`, no necesariamente está roto el script; significa que Windows no recibió ese dato desde el firmware de la batería.

### Error 3: PowerShell bloquea el script

- **Causa:** la política de ejecución de Windows puede bloquear scripts `.ps1` descargados o copiados.
- **Solución:** ejecutar el `.cmd`, que usa:

  ```powershell
  -ExecutionPolicy Bypass
  ```

  solo para esa ejecución, sin cambiar la configuración global del sistema.

### Error 4: Una batería "nueva" aparece con muchos ciclos

- **Causa:** el script lee lo que reporta el controlador interno de la batería. Si marca cientos de ciclos y baja salud, probablemente no es nueva aunque físicamente se vea nueva.
- **Solución:** comparar contra la capacidad de diseño. Para una batería realmente nueva, la salud debería estar mucho más cerca de `100%` que de `60%`.

## 8. Conclusiones

- El porcentaje de carga no sirve para saber si una batería está sana.
- La métrica importante es la relación entre **capacidad máxima actual** y **capacidad de diseño**.
- En Linux los datos salen desde `/sys/class/power_supply`.
- En Windows salen desde WMI/CIM.
- Si una batería usada conserva solo `60%` de salud, puede servir, pero no debería venderse como nueva.
