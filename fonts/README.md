# Fonts

Ingen manuel download nødvendig.

`feathers3_display.yaml` bruger ESPHome's `gfonts` platform, som automatisk
henter **Roboto Regular** og **Roboto Bold** fra Google Fonts første gang du
kører `esphome compile` eller `esphome run`. Filerne caches i `.esphome/`.

Din host-maskine skal have internetadgang under kompilering — enheden selv
tilgår aldrig internet.
