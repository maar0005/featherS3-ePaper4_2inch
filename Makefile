.PHONY: fonts compile run logs

fonts:
	@echo "Downloading Roboto fonts from Google Fonts..."
	@URLS=$$(curl -fsSL 'https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap' | grep -o 'https://[^)]*\.ttf'); \
	REGULAR=$$(echo "$$URLS" | sed -n '1p'); \
	BOLD=$$(echo "$$URLS" | sed -n '2p'); \
	curl -fsSL "$$REGULAR" -o fonts/Roboto-Regular.ttf && echo "  Roboto-Regular.ttf OK"; \
	curl -fsSL "$$BOLD" -o fonts/Roboto-Bold.ttf && echo "  Roboto-Bold.ttf OK"

compile:
	esphome compile feathers3_display.yaml

run:
	esphome run feathers3_display.yaml

logs:
	esphome logs feathers3_display.yaml
