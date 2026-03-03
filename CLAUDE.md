# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ESPHome firmware for an **Unexpected Maker FeatherS3** (ESP32-S3, 16MB flash, 8MB PSRAM) driving a **Waveshare 4.2" ePaper display** (400×300px, SPI). The device connects exclusively to Home Assistant via native API and runs on LiPo battery with deep sleep.

**Key constraint**: The device has NO direct internet access. All data (time, calendar, temperature, electricity prices) comes from Home Assistant via `api:` (native HA API). Never use `http_request:`, `time: sntp`, or any other component that contacts the internet directly.

## Hardware

- **Board**: `um_feathers3` (ESP32-S3) — use `esp-idf` framework, not Arduino, for proper PSRAM support
- **Display**: Waveshare 4.2" ePaper — try model `4.20in` first, fall back to `4.20in-bV2` or `4.20in-bV3` if refresh fails

### Pin Mapping (ePaper → FeatherS3)

| Signal | GPIO |
|--------|------|
| MOSI   | 11   |
| SCK    | 12   |
| CS     | 10   |
| DC     | 5    |
| RST    | 14   |
| BUSY   | 6    |

### Special FeatherS3 pins
- `GPIO2` — battery voltage sensing (VBAT)
- `GPIO39` — LDO2 enable; set HIGH to power external peripherals, LOW during deep sleep to save power

## ESPHome Commands

```bash
# Validate config without flashing
esphome config feathers3_display.yaml

# Compile only
esphome compile feathers3_display.yaml

# Flash via USB (first time)
esphome run feathers3_display.yaml

# Flash OTA (subsequent updates)
esphome run feathers3_display.yaml --device <IP>

# Monitor serial logs
esphome logs feathers3_display.yaml
```

## Project Structure

```
feathers3-display/
├── feathers3_display.yaml   # Main ESPHome config
├── secrets.yaml             # WiFi + HA API credentials (not committed)
├── fonts/
│   ├── Roboto-Regular.ttf   # Download from Google Fonts
│   ├── Roboto-Bold.ttf      # Download from Google Fonts
│   └── README.md
└── README.md
```

Fonts must be downloaded manually from Google Fonts before compiling. ESPHome will error if font files are missing.

## Architecture & Data Flow

```
Home Assistant
  ├── sensor.outdoor_temperature       → sensor (homeassistant platform)
  ├── sensor.nordpool_kwh_dk1_dkk      → sensor (homeassistant platform)
  ├── calendar.google_kalender         → text_sensor (homeassistant platform)
  ├── alarm_control_panel.home         → text_sensor (homeassistant platform)
  └── (time sync)                      → time (homeassistant platform)
        ↓ native API (port 6053)
FeatherS3
  ├── Connects to HA on boot
  ├── Waits for sensors to update (run_duration: 30s)
  ├── Renders layout to ePaper (update_interval: never — manual trigger)
  └── Enters deep sleep (sleep_duration: 10min)
```

The display `update_interval` is set to `never`; the display is triggered explicitly at the end of the run window before deep sleep activates.

## Display Layout (400×300px)

```
┌─────────────────────────────────────┐
│  Mandag 3. marts 2026        18:45  │  ← date + time (Roboto-Bold 24)
├─────────────────────────────────────┤
│  Ude: 4.2°C                         │  ← outdoor temp (Roboto-Regular 18)
├─────────────────────────────────────┤
│  KALENDER                           │
│  • 09:00 Møde med leverandør        │  ← next 2-3 HA calendar events
│  • 14:30 Tandlæge                   │
├─────────────────────────────────────┤
│  STRØM                              │
│  Nu: 0.82 kr/kWh                   │
│  Billigst: 02-04 (0.31 kr/kWh)     │
├─────────────────────────────────────┤
│  Alarm: ARMED       Vinduer: OK     │
└─────────────────────────────────────┘
```

Fonts used:
- `font_small` — Roboto-Regular 14px (body)
- `font_medium` — Roboto-Regular 18px (sensor values)
- `font_large` — Roboto-Bold 24px (headers, time)

## secrets.yaml

`secrets.yaml` is not committed. The required keys are:

```yaml
wifi_ssid: "..."
wifi_password: "..."
api_password: "..."
```

## Entity IDs to Verify

Before flashing, confirm these entity IDs match your HA instance:

- `sensor.outdoor_temperature`
- `sensor.nordpool_kwh_dk1_dkk`
- `calendar.google_kalender`
- `alarm_control_panel.home`

## ePaper Troubleshooting

- If the display shows garbage or never clears: try a different model string (`4.20in-bV2`, `4.20in-bV3`)
- ePaper full refresh is slow (~2s) — do not call `it.fill()` or trigger updates more than needed during the run window
- `update_interval: never` requires calling `id(epaper).update()` explicitly in a lambda or automation
