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
│  Alarm: OFF                         │
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
| Optional: momentary push button | Normally open | Maintenance mode pin (GPIO3 to GND) |

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
└─────────────────┘            │  GPIO2  ── VBAT      │
                               │  GPIO39 ── LDO2 EN   │
                               │  GPIO0  ── BOOT btn  │
                               │  GPIO3  ── [button]──┼── GND
                               │                      │  (maintenance mode)
                               └──────────────────────┘
```

> **VCC note:** The ePaper VCC connects to the FeatherS3's switched 3.3V rail controlled by LDO2 (GPIO39). The firmware drives GPIO39 HIGH on boot and LOW before deep sleep to cut power to the display and save battery.

### Pin Summary

| ePaper Signal | FeatherS3 GPIO | Function |
|---------------|----------------|----------|
| VCC | 3V3_SW (LDO2) | Power — switched off during sleep |
| GND | GND | Ground |
| DIN | GPIO11 | SPI MOSI |
| CLK | GPIO12 | SPI clock |
| CS | GPIO10 | SPI chip select |
| DC | GPIO5 | Data/Command select |
| RST | GPIO14 | Hardware reset |
| BUSY | GPIO6 | Busy signal |
| — | GPIO2 | Battery voltage sensing (VBAT) |
| — | GPIO39 | LDO2 enable (display power) |
| — | GPIO3 | Maintenance mode (pull to GND) |

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
