# FeatherS3 ePaper Display

Battery-powered home dashboard built on an **Unexpected Maker FeatherS3** (ESP32-S3) driving a **Waveshare 4.2" ePaper display**. All data is pulled from **Home Assistant** — no direct internet access required. The device wakes every 10 minutes, fetches data, updates the display, and goes back to deep sleep.

```
┌─────────────────────────────────────┐
│  Friday 6. mar 2026          14:31  │
├─────────────────────────────────────┤
│  Partly cloudy, 14.5°    Indoor 23° │
│  Rain from 17                       │
├─────────────────────────────────────┤
│  CALENDAR                           │
│  • Today: Sebastian's birthday      │
│  • Today 15:15: Pick up kids        │
│  • 9. Mar 09:00: Meeting            │
├─────────────────────────────────────┤
│  Alarm: OFF                Bat: 87% │
└─────────────────────────────────────┘
```

---

## Parts List

| Part | Description | Notes |
|------|-------------|-------|
| [Unexpected Maker FeatherS3](https://unexpectedmaker.com/shop.html#!/FeatherS3/p/577111310) | ESP32-S3, 16MB flash, 8MB PSRAM | Main controller |
| [Waveshare 4.2" ePaper (B)](https://www.waveshare.com/4.2inch-e-paper-module.htm) | 400×300px, black/white, SPI | Display |
| LiPo battery | 3.7V, 1000–2000 mAh, JST-PH 2mm | Power source |
| Dupont/jumper wires | Female-female, 7× | ePaper → FeatherS3 |
| R1: 100 kΩ resistor (1%) | Through-hole or SMD | Battery voltage divider top |
| R2: 220 kΩ resistor (1%) | Through-hole or SMD | Battery voltage divider bottom |
| C1: 100 nF ceramic capacitor (X7R) | 0603 or through-hole | ADC filter cap |
| Optional: momentary push button | Normally open | Maintenance mode (GPIO3 to GND) |

> **ePaper model note:** The firmware uses model `4.20in`. If the display shows garbage or never refreshes, try `4.20in-bV2` or `4.20in-bV3` in `feathers3_display.yaml`.

---

## Wiring Diagram

```
Waveshare 4.2" ePaper          FeatherS3 (ESP32-S3)
┌─────────────────┐            ┌──────────────────────┐
│                 │            │                      │
│  VCC  ──────────┼────────────┼─ 3V3_SW (via LDO2)  │
│  GND  ──────────┼────────────┼─ GND                 │
│  DIN  ──────────┼────────────┼─ GPIO11 (MOSI)       │
│  CLK  ──────────┼────────────┼─ GPIO12 (SCK)        │
│  CS   ──────────┼────────────┼─ GPIO10              │
│  DC   ──────────┼────────────┼─ GPIO5               │
│  RST  ──────────┼────────────┼─ GPIO14              │
│  BUSY ──────────┼────────────┼─ GPIO6               │
│                 │            │                      │
└─────────────────┘            │  GPIO39 ── LDO2 EN   │
                               │  GPIO0  ── BOOT btn  │
                               │  GPIO3  ── [button]──┼── GND
                               │                      │  (maintenance mode)
                               └──────────────────────┘

Battery voltage divider (connects to GPIO2):

  Battery +  ──┬──[R1: 100kΩ]──┬──[R2: 220kΩ]── GND
               │               │
           (to charger/       GPIO2 (ADC)
            load circuit)      │
                             [C1: 100nF X7R]
                               │
                              GND
```

> **VCC note:** The ePaper VCC connects to the FeatherS3's switched 3.3V rail controlled by LDO2 (GPIO39). The firmware drives GPIO39 HIGH on boot and LOW before deep sleep to cut power to the display and save battery.

### Pin Summary

| Signal | FeatherS3 GPIO | Function |
|--------|----------------|----------|
| ePaper VCC | 3V3_SW (LDO2) | Power — switched off during sleep |
| ePaper GND | GND | Ground |
| ePaper DIN | GPIO11 | SPI MOSI |
| ePaper CLK | GPIO12 | SPI clock |
| ePaper CS | GPIO10 | SPI chip select |
| ePaper DC | GPIO5 | Data/Command select |
| ePaper RST | GPIO14 | Hardware reset |
| ePaper BUSY | GPIO6 | Busy signal |
| Battery divider mid | GPIO2 | ADC1 — battery voltage sense |
| — | GPIO39 | LDO2 enable (display power switch) |
| — | GPIO3 | Maintenance mode (pull to GND) |
| — | GPIO0 | Deep-sleep wake-up (BOOT button) |

All GPIO assignments are in the `substitutions:` block at the top of `feathers3_display.yaml` — change them there if you need different pins.

---

## Battery Monitoring Circuit

### How it works

The ESP32-S3 ADC maxes out at ~3.1 V (12 dB attenuation). A fully charged 18650 cell sits at 4.2 V, so a voltage divider scales it down before the ADC pin.

The 100 kΩ / 220 kΩ ratio was chosen to:
- Scale 4.2 V max → **2.89 V** at the ADC pin (near full scale → maximum resolution)
- Draw only ~13 µA quiescent current (negligible over battery lifetime)
- Stay well within the ADC's linear range

The 100 nF X7R capacitor in parallel with R2 acts as a charge reservoir. The ADC's internal sampling capacitor draws a brief current spike; the cap supplies it without causing a voltage droop through the high-impedance resistors.

### Component placement

Place the divider **between the battery protection PCB and the rest of the circuit** (i.e. on the raw battery voltage, not the regulated 3.3 V rail). Connect the midpoint to any ADC1 pin on the ESP32-S3.

```
  Li-ion cell
  ┌─────────┐
  │+ ──┬────┴──── to protection PCB / charger
  │    │
  │   [R1] 100 kΩ, 1%
  │    │
  │    ├────────── GPIO2 (ADC)
  │    │
  │   [R2] 220 kΩ, 1%    [C1] 100 nF X7R
  │    │                      │
  │- ──┴──────────────────────┴── GND
  └─────────┘
```

### Component notes

| Component | Value | Why |
|-----------|-------|-----|
| R1 | 100 kΩ, 1% | 1% tolerance for ±10 mV accuracy at 4.2 V |
| R2 | 220 kΩ, 1% | Sets divider ratio; 1% tolerance |
| C1 | 100 nF, X7R ceramic | X7R retains capacitance across temperature; Y5V loses >80% at −30°C |

### Software implementation

- **Oversampling:** The ADC takes 16 hardware readings per update and averages them, suppressing jitter and the brief WiFi-induced voltage sag (~10–50 mV) caused by radio TX current spikes
- **Factory calibration:** ESP32-S3 with esp-idf uses eFuse-burned ADC calibration coefficients automatically — no manual offset needed
- **Divider compensation:** `multiply: 1.4545` (= 320/220) undoes the voltage divider
- **Non-linear LUT:** Li-ion cells follow an S-curve, not a straight line. The firmware uses 13 breakpoints with piecewise-linear interpolation between them:

| Voltage | State of charge |
|---------|----------------|
| 4.20 V | 100% |
| 4.10 V | 90% |
| 4.00 V | 80% |
| 3.90 V | 70% |
| 3.80 V | 60% |
| 3.70 V | 50% |
| 3.60 V | 40% |
| 3.50 V | 30% |
| 3.40 V | 20% |
| 3.30 V | 10% |
| 3.20 V | 5% |
| 3.10 V | 2% |
| 3.00 V | 0% |

### Home Assistant entities

After flashing, two new entities appear automatically in HA:

| Entity | Unit | Description |
|--------|------|-------------|
| `sensor.entre_display_battery_voltage` | V | Raw compensated voltage |
| `sensor.entre_display_battery_percent` | % | Calibrated state of charge |

The percentage is also shown on the ePaper display — bottom-right corner, same line as the alarm state.

---

## Alternative Board: ESP32-S3-WROOM-1 N16R8 (44-pin DevKitC-1)

> **Note:** The firmware (`feathers3_display.yaml`) targets the FeatherS3 (`board: um_feathers3`). The pinout below is provided as a reference for adapters — no pre-built code exists for the DevKit. GPIO numbers are identical between the two boards; what differs is the physical connector layout and the absence of LDO2 and a built-in LiPo charger.

### DevKitC-1 pinout (44-pin, Type-C)

```
                    ┌──── USB-C ────┐
               3V3 ─┤ 1          44 ├─ GND
               3V3 ─┤ 2          43 ├─ GND
                EN ─┤ 3          42 ├─ GPIO19  (ADC2 ⚠ avoid with WiFi)
            GPIO4  ─┤ 4          41 ├─ GPIO20  (ADC2 ⚠ avoid with WiFi)
            GPIO5  ─┤ 5          40 ├─ GPIO21
            GPIO6  ─┤ 6          39 ├─ GPIO47
            GPIO7  ─┤ 7          38 ├─ GPIO48
           GPIO15  ─┤ 8          37 ├─ GPIO45
           GPIO16  ─┤ 9          36 ├─ GPIO0   [BOOT button]
           GPIO17  ─┤10          35 ├─ GPIO35  ⚠ PSRAM (N16R8)
           GPIO18  ─┤11          34 ├─ GPIO36  ⚠ PSRAM (N16R8)
            GPIO8  ─┤12          33 ├─ GPIO37  ⚠ PSRAM (N16R8)
            GPIO3  ─┤13          32 ├─ GPIO38
           GPIO46  ─┤14          31 ├─ GPIO39
            GPIO9  ─┤15          30 ├─ GPIO40
           GPIO10  ─┤16          29 ├─ GPIO41
           GPIO11  ─┤17          28 ├─ GPIO42
           GPIO12  ─┤18          27 ├─ GPIO44 / RX
           GPIO13  ─┤19          26 ├─ GPIO43 / TX
           GPIO14  ─┤20          25 ├─ GPIO2
               5V ─┤21          24 ├─ GPIO1
              GND ─┤22          23 ├─ GND
                    └───────────────┘

⚠  GPIO35–37: internally wired to OPI PSRAM on N16R8 — do not use as GPIO
⚠  GPIO19–20: ADC2 — disabled while WiFi is active — avoid for battery sensing
```

### Signal mapping for this project

| Signal | FeatherS3 GPIO | DevKitC-1 pin | Side |
|--------|---------------|---------------|------|
| ePaper DIN (MOSI) | GPIO11 | pin 17 | Left |
| ePaper CLK (SCK) | GPIO12 | pin 18 | Left |
| ePaper CS | GPIO10 | pin 16 | Left |
| ePaper DC | GPIO5 | pin 5 | Left |
| ePaper RST | GPIO14 | pin 20 | Left |
| ePaper BUSY | GPIO6 | pin 6 | Left |
| Battery ADC | GPIO2 | pin 25 | Right |
| Display power switch | GPIO39 | pin 31 | Right |
| Maintenance mode | GPIO3 | pin 13 | Left |
| Wake-up (BOOT) | GPIO0 | pin 36 | Right |

All project GPIOs are conflict-free on the N16R8 variant.

### Adaptations needed

| Feature | FeatherS3 | DevKitC-1 adaptation |
|---------|-----------|----------------------|
| Display power switch | LDO2 on GPIO39 (built-in) | Add a P-channel MOSFET or load switch IC controlled by GPIO39 |
| LiPo charging | On-board MCP73831 charger | Add external charger module (e.g. TP4056) |
| Battery voltage sense | VBAT available on GPIO2 via on-board divider | Wire external 100 kΩ/220 kΩ divider to GPIO2 (pin 25) |
| Firmware `board:` key | `um_feathers3` | Change to `esp32-s3-devkitc-1` |

To change the board in `feathers3_display.yaml`:

```yaml
esp32:
  board: esp32-s3-devkitc-1   # was: um_feathers3
  variant: esp32s3
  framework:
    type: esp-idf
```

GPIO numbers in the `substitutions:` block stay the same.

---

## Software Requirements

- [ESPHome](https://esphome.io) 2024.x or newer
- Home Assistant with REST API enabled (default)
- Roboto font files (see below)

---

## Project Structure

```
feathers3-display/
├── feathers3_display.yaml     # ESPHome firmware config
├── secrets.yaml               # Credentials (not committed)
├── HA_config_epaper.yaml      # Home Assistant package
├── fonts/
│   ├── Roboto-Regular.ttf     # Download from Google Fonts
│   ├── Roboto-Bold.ttf        # Download from Google Fonts
│   └── README.md
└── README.md
```

---

## Setup

### 1. Install fonts

Download **Roboto Regular** and **Roboto Bold** from [Google Fonts](https://fonts.google.com/specimen/Roboto) and place the `.ttf` files in the `fonts/` directory. ESPHome will error if they are missing.

### 2. Configure secrets

Copy or edit `secrets.yaml` with your own values:
"Bearer" in front of token is needed.

```yaml
wifi_ssid: "YourNetwork"
wifi_password: "YourPassword"
api_encryption_key: "..."        # generate: python3 -c "import base64,os; print(base64.b64encode(os.urandom(32)).decode())"
ha_template_url: "http://192.168.x.x:8123/api/template"
ha_authorization: "Bearer eyJ..."  # HA → Profile → Security → Long-lived access tokens
```

### 3. Set up Home Assistant

Copy `HA_config_epaper.yaml` to your HA `/config/` directory and add to `configuration.yaml`:

```yaml
homeassistant:
  packages:
    epaper: !include HA_config_epaper.yaml
```

Restart HA. This creates:
- `sensor.display_lang` — language/label configuration
- `sensor.display_date_str`, `sensor.display_time_str`, etc. — formatted display data
- `input_text.display_event_1` … `_10` — calendar event slots
- An automation that updates calendar events and weather forecast every 15 minutes

Adjust the calendar entity IDs in the automation to match your HA instance:

```yaml
target:
  entity_id:
    - calendar.your_calendar_1
    - calendar.your_calendar_2
```

Also update the sensor entity IDs in `HA_config_epaper.yaml` to match yours:

| Sensor | Default entity ID |
|--------|-------------------|
| Outdoor temperature | `sensor.dantherm_outdoor_temperature` |
| Indoor temperature | `sensor.dantherm_extract_temperature` |
| Weather | `weather.forecast_home` |
| Alarm | `alarm_control_panel.home` |

### 4. Flash firmware

```bash
# Validate config (no flashing)
esphome config feathers3_display.yaml

# First flash via USB
esphome run feathers3_display.yaml

# Subsequent updates via OTA
esphome run feathers3_display.yaml --device 192.168.x.x
```

### 5. Monitor logs

```bash
esphome logs feathers3_display.yaml
```

Expected log output on successful boot:

```
[I] WiFi OK – fetching data from HA REST API...
[I] ha_pull: Data received and parsed OK
[D] ✓ Data confirmed – updating display
[I] deep_sleep: Sleeping for 600000000us
```

---

## Changing Language

All display text is defined in a single place at the top of `HA_config_epaper.yaml` under `sensor.display_lang`. Edit the attribute values to change language or labels — no firmware reflash needed.

```yaml
- name: "display_lang"
  attributes:
    weekdays: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    months:   ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    weather_map:
      sunny:        "Sunny"
      partlycloudy: "Partly cloudy"
      ...
    cal_header:  "CALENDAR"
    no_events:   "No upcoming events"
    today:       "Today"
    tomorrow:    "Tomorrow"
    day_after:   "Day after tomorrow"
    ...
```

After editing, restart HA (or reload template entities). The display will use the new labels on the next wake cycle.

---

## Maintenance Mode (OTA without deep sleep)

Bridge **GPIO3 to GND** before powering on the device. The device will complete its normal data fetch and display update, then stay awake instead of sleeping — keeping WiFi active so you can flash OTA updates.

```bash
esphome run feathers3_display.yaml --device 192.168.x.x
```

Remove the bridge to restore normal deep sleep operation.

---

## Power & Battery Life

| State | Current draw | Duration |
|-------|-------------|----------|
| Boot + WiFi connect | ~150 mA | ~2s |
| HTTP fetch + display update | ~100 mA | ~12s |
| ePaper refresh | ~30 mA | ~5s |
| Deep sleep | ~20 µA | ~10 min |

With a 1500 mAh LiPo and 10-minute sleep intervals, expect **several weeks** of battery life depending on WiFi connection speed and signal strength.

The battery voltage divider (100 kΩ + 220 kΩ) draws ~13 µA continuously — negligible against deep-sleep current and decades below battery self-discharge.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Display shows `...` for date/time | HA data not received | Check logs for HTTP errors |
| `HTTP error 401` | Wrong or missing Bearer token | Regenerate token in HA → Profile → Security |
| Display shows garbage or flickers | Wrong ePaper model | Try `4.20in-bV2` or `4.20in-bV3` |
| Display never updates | LDO2 not enabled | Check GPIO39 wiring |
| Device never sleeps | Maintenance mode active | Remove GPIO3–GND bridge |
| OTA fails | Device in deep sleep | Use maintenance mode pin or press BOOT |
| `Bat: --` on display | Battery reading NaN | Check R1/R2 divider continuity; verify GPIO2 wiring |
| Battery % reads too high/low | Wrong divider ratio in firmware | Confirm R1=100 kΩ, R2=220 kΩ; `multiply` must be 1.4545 |
