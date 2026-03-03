# FeatherS3 ePaper Display

ESPHome firmware til **Unexpected Maker FeatherS3** med **Waveshare 4.2" ePaper display**.

Viser kalender-events, udetemperatur og strømpriser hentet fra Home Assistant via native API. Kører på LiPo batteri med deep sleep (10 min interval).

## Kom i gang

### 1. Fonts

```bash
# Download Roboto fonts til fonts/-mappen (se fonts/README.md)
```

### 2. Udfyld secrets

Rediger `secrets.yaml` med dine faktiske værdier:
- WiFi SSID og password
- HA API password (fra HA → Indstillinger → Integrationer → Home Assistant API)

### 3. Tilpas entity IDs

Ret disse entity IDs i `feathers3_display.yaml` til at matche din HA instans:

| Felt | Standard entity ID |
|------|--------------------|
| Udetemperatur | `sensor.outdoor_temperature` |
| Strømpris | `sensor.nordpool_kwh_dk1_dkk` |
| Kalender | `calendar.google_kalender` |
| Alarm | `alarm_control_panel.home` |

### 4. Flash

```bash
# Valider config
esphome config feathers3_display.yaml

# Flash første gang via USB
esphome run feathers3_display.yaml

# Efterfølgende via OTA
esphome run feathers3_display.yaml --device <IP-adresse>
```

### 5. Overvåg logs

```bash
esphome logs feathers3_display.yaml
```

## Strømforbrug og deep sleep

- **Run duration**: 30 sekunder (henter data + opdaterer display)
- **Sleep duration**: 10 minutter
- Under deep sleep trækkes LDO2 lav (GPIO39 = LOW) for at spare strøm

## Hardware pins

| Signal | GPIO |
|--------|------|
| MOSI   | 11   |
| SCK    | 12   |
| CS     | 10   |
| DC     | 13   |
| RST    | 14   |
| BUSY   | 15   |
| VBAT   | 2    |
| LDO2   | 39   |

## ePaper model

Konfigureret til `4.20in`. Hvis displayet ikke opdaterer korrekt, prøv:
- `4.20in-bV2`
- `4.20in-bV3`
