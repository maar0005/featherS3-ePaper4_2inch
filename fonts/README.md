# Fonts

TTF-filerne er ikke i git (binære filer). Download dem én gang med:

```bash
curl -fsSL "$(curl -fsSL 'https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' | grep -o 'https://[^)]*\.ttf' | sed -n '1p')" -o fonts/Roboto-Regular.ttf
curl -fsSL "$(curl -fsSL 'https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' | grep -o 'https://[^)]*\.ttf' | sed -n '2p')" -o fonts/Roboto-Bold.ttf
```

Eller via Makefile (fra projekt-roden):

```bash
make fonts
```
